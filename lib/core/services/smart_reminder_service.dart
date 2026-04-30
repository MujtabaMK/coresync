import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../constants/app_constants.dart';
import '../constants/notification_ids.dart';
import '../../features/gym/presentation/providers/gym_provider.dart';
import 'hive_service.dart';
import 'notification_service.dart';

class SmartReminderService {
  SmartReminderService._();

  // Reserved notification IDs for smart reminders (auto-fire)
  static const _sleepId = 5005;
  static const _attendanceId = NotificationIds.attendanceReminder;
  static const _gymTimeId = NotificationIds.gymTimeReminder;

  /// Schedule automatic smart reminders. Call after GymCubit.loadAll() completes.
  /// Performs a full nuke-and-resync of ALL reminder notifications to prevent
  /// stale OS-level alarms (e.g. from device reboot, OEM battery optimization,
  /// or ScheduledNotificationBootReceiver re-registering cancelled alarms).
  static Future<void> scheduleAll(GymState state, {required String uid}) async {
    // Ensure the notification plugin is fully initialized before any
    // cancel/schedule calls. Prevents the race where GymCubit.loadAll()
    // fires before the splash screen's NotificationService.init() completes.
    await NotificationService.init();

    // ── Phase 1: Cancel ALL known reminder IDs ──
    // This guarantees a clean slate — no stale notifications survive.
    await _cancelAllReminderIds();

    // ── Phase 2: Re-schedule only enabled reminders from Hive settings ──
    await _syncMealReminders();
    await _syncWaterReminders();
    await _syncGenericReminders();

    // ── Phase 3: Re-schedule Firestore-backed reminders ──
    await _syncMedicineReminders(uid);
    await _syncHabitReminders(uid);

    // ── Phase 4: Conditional smart reminders ──

    // Attendance reminder — only fire if user hasn't marked today
    await _scheduleAttendanceReminder(state);

    // Gym time reminder — 15 min before gym if user set a gym time
    await _scheduleGymTimeReminder(state);

    // Sleep reminder — 30 min before user's last sleep time
    await _scheduleSleepReminder(state);
  }

  /// Cancel every notification ID in known Hive-backed reminder ranges.
  /// Medicine (2000+) and habit (4000+) IDs are cancelled inside their
  /// respective _sync methods (requires Firestore doc IDs).
  /// Task alarms (3000+) are managed by the Todo module.
  static Future<void> _cancelAllReminderIds() async {
    // Smart reminder IDs
    await NotificationService.cancel(_sleepId);
    await NotificationService.cancel(_attendanceId);
    await NotificationService.cancel(_gymTimeId);

    // Generic reminder IDs (1000-1003)
    await NotificationService.cancel(NotificationIds.workoutReminder);
    await NotificationService.cancel(NotificationIds.walkReminder);
    await NotificationService.cancel(NotificationIds.weightReminder);
    await NotificationService.cancel(NotificationIds.healthLogReminder);

    // Meal reminder IDs (1099-1104)
    await NotificationService.cancel(NotificationIds.mealBreakfast - 1); // once-at
    await NotificationService.cancel(NotificationIds.mealBreakfast);
    await NotificationService.cancel(NotificationIds.mealMorningSnack);
    await NotificationService.cancel(NotificationIds.mealLunch);
    await NotificationService.cancel(NotificationIds.mealEveningSnack);
    await NotificationService.cancel(NotificationIds.mealDinner);

    // Water reminder IDs (1200-1249)
    await NotificationService.cancel(NotificationIds.waterOnce);
    for (var i = 0; i < 50; i++) {
      await NotificationService.cancel(NotificationIds.waterInterval(i));
    }
  }

  /// Attendance reminder — only schedules if user hasn't marked today.
  /// Uses a one-time alarm (not repeating) so it won't fire on days
  /// when attendance is already marked. Re-evaluated on each app launch.
  static Future<void> _scheduleAttendanceReminder(GymState state) async {
    final now = DateTime.now();
    final todayKey = DateTime(now.year, now.month, now.day);

    // Check if user already marked attendance today
    final markedToday = state.attendanceMap.containsKey(todayKey);
    if (markedToday) return; // No notification needed

    // Schedule one-time at 8 PM today (or skip if already past)
    var scheduledDate = DateTime(now.year, now.month, now.day, 20, 0);
    if (scheduledDate.isBefore(now)) return; // Past 8 PM, skip

    await NotificationService.scheduleOnceAlarm(
      id: _attendanceId,
      title: 'Mark Your Attendance!',
      body: "Don't forget to mark today's gym attendance.",
      scheduledDate: scheduledDate,
    );
  }

  /// Gym time reminder — schedules 15 min before gym time if user has
  /// set a gym time in their weight loss profile.
  static Future<void> _scheduleGymTimeReminder(GymState state) async {
    final gymHour = state.weightLossProfile?.gymTimeHour;
    if (gymHour == null) return; // No gym time set

    // Calculate 15 minutes before gym time
    int reminderHour = gymHour;
    int reminderMinute = -15;
    if (reminderMinute < 0) {
      reminderMinute += 60;
      reminderHour -= 1;
      if (reminderHour < 0) reminderHour += 24;
    }

    // Format gym time for display
    final period = gymHour >= 12 ? 'PM' : 'AM';
    final displayHour = gymHour == 0
        ? 12
        : gymHour > 12
            ? gymHour - 12
            : gymHour;
    final timeStr = '$displayHour:00 $period';

    // Schedule as one-time for today (re-scheduled on each app launch)
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year, now.month, now.day, reminderHour, reminderMinute,
    );

    // If time already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await NotificationService.scheduleOnceAlarm(
      id: _gymTimeId,
      title: 'Gym Time Soon!',
      body: 'Your gym session starts at $timeStr. Get ready!',
      scheduledDate: scheduledDate,
    );
  }

  static Future<void> _scheduleSleepReminder(GymState state) async {
    await NotificationService.scheduleDailyNotification(
      id: _sleepId,
      title: 'Time to Sleep',
      body: "It's 9:30 PM. Wind down and get a good night's rest!",
      hour: 21,
      minute: 30,
    );
  }

  /// Full sync for meal reminders: re-schedule only enabled ones.
  /// All IDs are already cancelled by [_cancelAllReminderIds].
  static Future<void> _syncMealReminders() async {
    const prefix = 'reminder_food';
    final Box box = await HiveService.openBox(AppConstants.gymSettingsBox);
    final masterEnabled = box.get('${prefix}_enabled', defaultValue: false) as bool;

    // If master is off, we're done — everything is already cancelled
    if (!masterEnabled) return;

    // Once-at reminder
    const onceAtId = NotificationIds.mealBreakfast - 1;
    final onceAtEnabled = box.get('${prefix}_once_enabled', defaultValue: false) as bool;
    if (onceAtEnabled) {
      final hour = box.get('${prefix}_once_hour', defaultValue: 21) as int;
      final minute = box.get('${prefix}_once_minute', defaultValue: 30) as int;
      await NotificationService.scheduleDailyNotification(
        id: onceAtId,
        title: 'Meal Reminder',
        body: 'Time to track your meals!',
        hour: hour,
        minute: minute,
      );
    }

    // Per-meal slot reminders
    const mealSlots = [
      ('breakfast', NotificationIds.mealBreakfast, 'Breakfast', 9, 0),
      ('morning_snack', NotificationIds.mealMorningSnack, 'Morning Snack', 11, 0),
      ('lunch', NotificationIds.mealLunch, 'Lunch', 13, 0),
      ('evening_snack', NotificationIds.mealEveningSnack, 'Evening Snack', 17, 0),
      ('dinner', NotificationIds.mealDinner, 'Dinner', 20, 0),
    ];

    for (final (key, id, label, defaultHour, defaultMinute) in mealSlots) {
      final enabled = box.get('${prefix}_${key}_enabled', defaultValue: false) as bool;
      if (enabled) {
        final hour = box.get('${prefix}_${key}_hour', defaultValue: defaultHour) as int;
        final minute = box.get('${prefix}_${key}_minute', defaultValue: defaultMinute) as int;
        await NotificationService.scheduleDailyNotification(
          id: id,
          title: 'Meal Reminder',
          body: 'Time for $label!',
          hour: hour,
          minute: minute,
        );
      }
    }
  }

  /// Full sync for water reminders: re-schedule only enabled ones.
  /// All IDs are already cancelled by [_cancelAllReminderIds].
  static Future<void> _syncWaterReminders() async {
    const prefix = 'reminder_water';
    final Box box = await HiveService.openBox(AppConstants.gymSettingsBox);
    final masterEnabled = box.get('${prefix}_enabled', defaultValue: false) as bool;

    // If master is off, we're done
    if (!masterEnabled) return;

    // Re-schedule once-at
    final onceAtEnabled = box.get('${prefix}_once_enabled', defaultValue: false) as bool;
    if (onceAtEnabled) {
      final hour = box.get('${prefix}_once_hour', defaultValue: 21) as int;
      final minute = box.get('${prefix}_once_minute', defaultValue: 30) as int;
      await NotificationService.scheduleDailyNotification(
        id: NotificationIds.waterOnce,
        title: 'Water Reminder',
        body: 'Time to drink water!',
        hour: hour,
        minute: minute,
      );
    }

    // Re-schedule interval-based reminders
    final startHour = box.get('${prefix}_start_hour', defaultValue: 9) as int;
    final startMinute = box.get('${prefix}_start_minute', defaultValue: 30) as int;
    final endHour = box.get('${prefix}_end_hour', defaultValue: 21) as int;
    final endMinute = box.get('${prefix}_end_minute', defaultValue: 30) as int;
    final intervalMode = box.get('${prefix}_interval_mode', defaultValue: 'count') as String;
    final count = box.get('${prefix}_count', defaultValue: 6) as int;
    final intervalMinutes = box.get('${prefix}_interval_minutes', defaultValue: 30) as int;

    final startMinutesTotal = startHour * 60 + startMinute;
    final endMinutesTotal = endHour * 60 + endMinute;
    if (endMinutesTotal <= startMinutesTotal) return;

    final totalMinutes = endMinutesTotal - startMinutesTotal;
    List<int> reminderTimes = [];

    if (intervalMode == 'count' && count > 0) {
      final interval = totalMinutes ~/ count;
      for (var i = 0; i < count; i++) {
        reminderTimes.add(startMinutesTotal + interval * i);
      }
    } else if (intervalMode == 'minutes' && intervalMinutes > 0) {
      var current = startMinutesTotal;
      while (current <= endMinutesTotal) {
        reminderTimes.add(current);
        current += intervalMinutes;
      }
    }

    for (var i = 0; i < reminderTimes.length && i < 48; i++) {
      final t = reminderTimes[i];
      await NotificationService.scheduleDailyNotification(
        id: NotificationIds.waterInterval(i),
        title: 'Water Reminder',
        body: 'Time to drink water!',
        hour: t ~/ 60,
        minute: t % 60,
      );
    }
  }

  /// Re-schedule medicine reminders from Firestore.
  /// Each medicine can have up to 10 dose-time notifications.
  static Future<void> _syncMedicineReminders(String uid) async {
    if (uid.isEmpty) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('medicines')
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final id = doc.id;

        // Cancel all possible dose IDs for this medicine first
        for (var i = 0; i < 10; i++) {
          await NotificationService.cancel(
            NotificationIds.medicineDose(id, i),
          );
        }

        final reminderEnabled = data['reminderEnabled'] as bool? ?? false;
        final schedulerEnabled = data['schedulerEnabled'] as bool? ?? false;
        final doseTimes =
            (data['doseTimes'] as List<dynamic>?)?.cast<String>() ?? [];

        if (schedulerEnabled && reminderEnabled && doseTimes.isNotEmpty) {
          final name = data['name'] as String? ?? 'Medicine';
          for (var i = 0; i < doseTimes.length; i++) {
            final parts = doseTimes[i].split(':');
            if (parts.length < 2) continue;
            final hour = int.tryParse(parts[0]);
            final minute = int.tryParse(parts[1]);
            if (hour == null || minute == null) continue;
            await NotificationService.scheduleDailyNotification(
              id: NotificationIds.medicineDose(id, i),
              title: 'Medicine Reminder',
              body: 'Time to take $name',
              hour: hour,
              minute: minute,
            );
          }
        }
      }
    } catch (_) {
      // Firestore read may fail offline; reminders will sync on next launch
    }
  }

  /// Re-schedule habit reminders from Firestore.
  /// Each habit can have up to 7 weekly notifications (one per reminder day).
  static Future<void> _syncHabitReminders(String uid) async {
    if (uid.isEmpty) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('habits')
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final id = doc.id;

        // Cancel all 7 possible day IDs for this habit first
        for (var day = 1; day <= 7; day++) {
          await NotificationService.cancel(
            NotificationIds.habitReminder(id, day),
          );
        }

        final reminderEnabled = data['reminderEnabled'] as bool? ?? false;
        final isArchived = data['isArchived'] as bool? ?? false;

        if (reminderEnabled && !isArchived) {
          final hour = (data['reminderHour'] as num?)?.toInt() ?? 9;
          final minute = (data['reminderMinute'] as num?)?.toInt() ?? 0;
          final reminderDays = (data['reminderDays'] as List<dynamic>?)
                  ?.map((e) => (e as num).toInt())
                  .toList() ??
              [1, 2, 3, 4, 5, 6, 7];
          final icon = data['icon'] as String? ?? '';
          final name = data['name'] as String? ?? 'Habit';

          // Check if habit is already completed today so we don't
          // re-schedule a notification the user already dismissed.
          final now = DateTime.now();
          final todayKey = DateFormat('yyyy-MM-dd').format(now);
          final todayDow = now.weekday;
          final completions =
              (data['completions'] as Map<String, dynamic>?) ?? {};
          final todayCount =
              (completions[todayKey] as num?)?.toInt() ?? 0;
          final execType = data['executionType'] as String?;
          final dailyVolume =
              (data['dailyVolume'] as num?)?.toInt() ?? 1;
          final completedToday =
              (execType == 'multiple' || execType == 'trackVolume')
                  ? todayCount >= dailyVolume
                  : todayCount >= 1;

          for (final day in reminderDays) {
            // Skip today if habit is already completed
            if (day == todayDow && completedToday) continue;

            await NotificationService.scheduleWeeklyNotification(
              id: NotificationIds.habitReminder(id, day),
              title: '$icon $name',
              body: 'Time to complete your habit!',
              dayOfWeek: day,
              hour: hour,
              minute: minute,
            );
          }
        }
      }
    } catch (_) {
      // Firestore read may fail offline; reminders will sync on next launch
    }
  }

  /// Sync generic reminders (workout, walk, weight, healthLog) from Hive.
  /// These were previously only managed by their individual settings screens
  /// and could become stale after device reboot.
  static Future<void> _syncGenericReminders() async {
    final Box box = await HiveService.openBox(AppConstants.gymSettingsBox);

    const reminders = [
      (
        prefix: 'reminder_workout',
        id: NotificationIds.workoutReminder,
        label: 'Workout Reminder',
        desc: 'Set a Workout reminder',
        pattern: 'onceAt',
      ),
      (
        prefix: 'reminder_walk',
        id: NotificationIds.walkReminder,
        label: 'Walk Reminder',
        desc: 'Set a walk reminder',
        pattern: 'onceAt',
      ),
      (
        prefix: 'reminder_weight',
        id: NotificationIds.weightReminder,
        label: 'Weight Reminder',
        desc: 'Set a weight reminder',
        pattern: 'periodic',
      ),
      (
        prefix: 'reminder_health',
        id: NotificationIds.healthLogReminder,
        label: 'Health Log Reminder',
        desc: 'Set a health log reminder',
        pattern: 'periodic',
      ),
    ];

    for (final r in reminders) {
      final enabled = box.get('${r.prefix}_enabled', defaultValue: false) as bool;
      if (!enabled) continue;

      final hour = box.get('${r.prefix}_hour', defaultValue: 8) as int;
      final minute = box.get('${r.prefix}_minute', defaultValue: 0) as int;

      if (r.pattern == 'onceAt') {
        await NotificationService.scheduleDailyNotification(
          id: r.id,
          title: r.label,
          body: r.desc,
          hour: hour,
          minute: minute,
        );
      } else {
        // periodic — weekly or monthly
        final frequency = box.get('${r.prefix}_frequency', defaultValue: 'weekly') as String;
        if (frequency == 'weekly') {
          final dayOfWeek = box.get('${r.prefix}_dayOfWeek', defaultValue: 1) as int;
          await NotificationService.scheduleWeeklyNotification(
            id: r.id,
            title: r.label,
            body: r.desc,
            dayOfWeek: dayOfWeek,
            hour: hour,
            minute: minute,
          );
        } else {
          final dayOfMonth = box.get('${r.prefix}_dayOfMonth', defaultValue: 1) as int;
          await NotificationService.scheduleMonthlyNotification(
            id: r.id,
            title: r.label,
            body: r.desc,
            dayOfMonth: dayOfMonth,
            hour: hour,
            minute: minute,
          );
        }
      }
    }
  }
}
