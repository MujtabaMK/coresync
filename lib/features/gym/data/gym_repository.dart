import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/hive_service.dart';
import '../domain/food_scan_model.dart';
import '../domain/membership_model.dart';
import '../domain/sleep_log_model.dart';
import '../domain/tracked_food_model.dart';
import '../domain/weight_loss_profile_model.dart';
import '../domain/workout_log_model.dart';

class GymRepository {
  GymRepository({required this.uid});

  final String uid;

  final _firestore = FirebaseFirestore.instance;

  // Firestore references
  DocumentReference get _userDoc => _firestore.collection('users').doc(uid);
  CollectionReference get _attendanceCol => _userDoc.collection('gym_attendance');
  CollectionReference get _membershipCol => _userDoc.collection('gym_memberships');
  CollectionReference get _waterCol => _userDoc.collection('gym_water');
  CollectionReference get _stepsCol => _userDoc.collection('gym_steps');
  CollectionReference get _foodScansCol =>
      _userDoc.collection('gym_food_scans');
  CollectionReference get _foodTrackingCol =>
      _userDoc.collection('gym_food_tracking');
  CollectionReference get _workoutCol => _userDoc.collection('gym_workouts');
  CollectionReference get _sleepCol => _userDoc.collection('gym_sleep');

  // Local settings box (reminders are device-specific)
  Box? _gymSettingsBox;

  Future<Box> _getGymSettingsBox() async {
    if (_gymSettingsBox != null && _gymSettingsBox!.isOpen) {
      return _gymSettingsBox!;
    }
    _gymSettingsBox = await HiveService.openBox(AppConstants.gymSettingsBox);
    return _gymSettingsBox!;
  }

  Future<Box> getGymSettingsBox() => _getGymSettingsBox();

  // ── Membership ──

  Future<MembershipModel?> getActiveMembership() async {
    final snapshot = await _membershipCol
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    final m = _membershipFromDoc(doc);
    if (m.isExpired) return null;
    return m;
  }

  Future<void> saveMembership(MembershipModel membership) async {
    // Deactivate existing active memberships
    final active = await _membershipCol
        .where('isActive', isEqualTo: true)
        .get();
    for (final doc in active.docs) {
      await doc.reference.update({'isActive': false});
    }
    await _membershipCol.doc(membership.id).set({
      'plan': membership.plan,
      'startDate': Timestamp.fromDate(membership.startDate),
      'endDate': Timestamp.fromDate(membership.endDate),
      'isActive': membership.isActive,
    });
  }

  MembershipModel _membershipFromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MembershipModel(
      id: doc.id,
      plan: data['plan'] as String,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      isActive: data['isActive'] as bool,
    );
  }

  // ── Attendance ──

  Future<List<Map<String, dynamic>>> getAllAttendanceRaw() async {
    final snapshot = await _attendanceCol.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'date': (data['date'] as Timestamp).toDate(),
        'isPresent': data['isPresent'] as bool,
      };
    }).toList();
  }

  Future<void> markAttendance(DateTime date, bool isPresent) async {
    final key = DateFormat('yyyy-MM-dd').format(date);
    await _attendanceCol.doc(key).set({
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'isPresent': isPresent,
    });
  }

  Future<void> deleteAttendance(DateTime date) async {
    final key = DateFormat('yyyy-MM-dd').format(date);
    await _attendanceCol.doc(key).delete();
  }

  Future<void> deleteAllAttendance() async {
    final snapshot = await _attendanceCol.get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<Map<DateTime, bool>> getAttendanceMap() async {
    final snapshot = await _attendanceCol.get();
    final map = <DateTime, bool>{};
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      final normalizedDate = DateTime(date.year, date.month, date.day);
      map[normalizedDate] = data['isPresent'] as bool;
    }
    return map;
  }

  Future<int> getPresentCount() async {
    final snapshot = await _attendanceCol
        .where('isPresent', isEqualTo: true)
        .get();
    return snapshot.docs.length;
  }

  Future<int> getAbsentCount() async {
    final snapshot = await _attendanceCol
        .where('isPresent', isEqualTo: false)
        .get();
    return snapshot.docs.length;
  }

  Future<List<DateTime>> getPresentDates() async {
    final snapshot = await _attendanceCol
        .where('isPresent', isEqualTo: true)
        .get();
    final dates = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      return DateTime(date.year, date.month, date.day);
    }).toList();
    dates.sort((a, b) => b.compareTo(a));
    return dates;
  }

  Future<List<DateTime>> getAbsentDates() async {
    final snapshot = await _attendanceCol
        .where('isPresent', isEqualTo: false)
        .get();
    final dates = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      return DateTime(date.year, date.month, date.day);
    }).toList();
    dates.sort((a, b) => b.compareTo(a));
    return dates;
  }

  // ── Water Intake (stored as ml) ──

  Future<int> getWaterIntakeForDate(DateTime date) async {
    final key = DateFormat('yyyy-MM-dd').format(date);
    final doc = await _waterCol.doc(key).get();
    if (!doc.exists) return 0;
    final data = doc.data() as Map<String, dynamic>?;
    // Support legacy 'glasses' field: convert to ml (1 glass = 250ml)
    if (data?.containsKey('ml') == true) {
      return data?['ml'] as int? ?? 0;
    }
    final glasses = data?['glasses'] as int? ?? 0;
    return glasses * 250;
  }

  Future<void> addWaterMl(DateTime date, int ml, {int? goalMl}) async {
    final key = DateFormat('yyyy-MM-dd').format(date);
    final doc = _waterCol.doc(key);
    final snapshot = await doc.get();
    int current = 0;
    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data?.containsKey('ml') == true) {
        current = data?['ml'] as int? ?? 0;
      } else {
        current = ((data?['glasses'] as int?) ?? 0) * 250;
      }
    }
    final fields = <String, dynamic>{'ml': current + ml};
    if (goalMl != null) fields['goalMl'] = goalMl;
    await doc.set(fields, SetOptions(merge: true));
  }

  Future<void> removeWaterMl(DateTime date, int ml, {int? goalMl}) async {
    final key = DateFormat('yyyy-MM-dd').format(date);
    final doc = _waterCol.doc(key);
    final snapshot = await doc.get();
    int current = 0;
    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data?.containsKey('ml') == true) {
        current = data?['ml'] as int? ?? 0;
      } else {
        current = ((data?['glasses'] as int?) ?? 0) * 250;
      }
    }
    final newValue = (current - ml).clamp(0, current);
    final fields = <String, dynamic>{'ml': newValue};
    if (goalMl != null) fields['goalMl'] = goalMl;
    await doc.set(fields, SetOptions(merge: true));
  }

  Future<void> resetWaterIntake(DateTime date, {int? goalMl}) async {
    final key = DateFormat('yyyy-MM-dd').format(date);
    final fields = <String, dynamic>{'ml': 0};
    if (goalMl != null) fields['goalMl'] = goalMl;
    await _waterCol.doc(key).set(fields, SetOptions(merge: true));
  }

  Future<void> saveWaterGoal(DateTime date, int goalMl) async {
    final key = DateFormat('yyyy-MM-dd').format(date);
    await _waterCol.doc(key).set({'goalMl': goalMl}, SetOptions(merge: true));
  }

  Future<Map<DateTime, int>> getWaterIntakeHistory() async {
    final result = await getWaterIntakeAndGoalHistory();
    return result.$1;
  }

  Future<Map<DateTime, int>> getWaterGoalHistory() async {
    final result = await getWaterIntakeAndGoalHistory();
    return result.$2;
  }

  /// Returns both water intake history and water goal history in a single read.
  Future<(Map<DateTime, int>, Map<DateTime, int>)> getWaterIntakeAndGoalHistory() async {
    final snapshot = await _waterCol.get();
    final intakeMap = <DateTime, int>{};
    final goalMap = <DateTime, int>{};
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = DateFormat('yyyy-MM-dd').parse(doc.id);
      final normalized = DateTime(date.year, date.month, date.day);

      int ml;
      if (data.containsKey('ml')) {
        ml = (data['ml'] as num?)?.toInt() ?? 0;
      } else {
        ml = ((data['glasses'] as num?)?.toInt() ?? 0) * 250;
      }
      if (ml > 0) intakeMap[normalized] = ml;

      final goalMl = (data['goalMl'] as num?)?.toInt();
      if (goalMl != null && goalMl > 0) goalMap[normalized] = goalMl;
    }
    return (intakeMap, goalMap);
  }

  // ── Steps ──

  Future<int> getStepsForDate(DateTime date) async {
    final key = DateFormat('yyyy-MM-dd').format(date);
    final doc = await _stepsCol.doc(key).get();
    if (!doc.exists) return 0;
    final data = doc.data() as Map<String, dynamic>?;
    return data?['steps'] as int? ?? 0;
  }

  Future<void> saveStepsForDate(DateTime date, int steps, {int? goalSteps}) async {
    final key = DateFormat('yyyy-MM-dd').format(date);
    // Never downgrade: only write if new steps >= existing
    final doc = await _stepsCol.doc(key).get();
    final existing = (doc.data() as Map<String, dynamic>?)?['steps'] as int? ?? 0;
    final fields = <String, dynamic>{};
    if (steps > existing) fields['steps'] = steps;
    if (goalSteps != null) fields['goalSteps'] = goalSteps;
    if (fields.isNotEmpty) {
      await _stepsCol.doc(key).set(fields, SetOptions(merge: true));
    }
  }

  Future<Map<DateTime, int>> getStepsHistory() async {
    final result = await getStepsAndGoalHistory();
    return result.$1;
  }

  Future<Map<DateTime, int>> getStepsGoalHistory() async {
    final result = await getStepsAndGoalHistory();
    return result.$2;
  }

  /// Removes backfilled goalSteps from all step documents so that
  /// the report falls back to the default goal for historical dates.
  Future<void> clearAllStepGoals() async {
    final snapshot = await _stepsCol.get();
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('goalSteps')) {
        await doc.reference.update({'goalSteps': FieldValue.delete()});
      }
    }
  }

  /// Removes goalSteps from step documents dated before [cutoff].
  Future<void> clearStepGoalsBefore(DateTime cutoff) async {
    final cutoffKey = DateFormat('yyyy-MM-dd').format(cutoff);
    final snapshot = await _stepsCol.get();
    for (final doc in snapshot.docs) {
      if (doc.id.compareTo(cutoffKey) < 0) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('goalSteps')) {
          await doc.reference.update({'goalSteps': FieldValue.delete()});
        }
      }
    }
  }

  /// Removes backfilled goalMl from all water documents so that
  /// the report falls back to the default goal for historical dates.
  Future<void> clearAllWaterGoals() async {
    final snapshot = await _waterCol.get();
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('goalMl')) {
        await doc.reference.update({'goalMl': FieldValue.delete()});
      }
    }
  }

  /// Returns both steps history and steps goal history in a single read.
  Future<(Map<DateTime, int>, Map<DateTime, int>)> getStepsAndGoalHistory() async {
    final snapshot = await _stepsCol.get();
    final stepsMap = <DateTime, int>{};
    final goalMap = <DateTime, int>{};
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = DateFormat('yyyy-MM-dd').parse(doc.id);
      final normalized = DateTime(date.year, date.month, date.day);

      final steps = (data['steps'] as num?)?.toInt() ?? 0;
      if (steps > 0) stepsMap[normalized] = steps;

      final goal = (data['goalSteps'] as num?)?.toInt();
      if (goal != null && goal > 0) goalMap[normalized] = goal;
    }
    return (stepsMap, goalMap);
  }

  // ── User Metrics ──

  Future<void> saveUserMetrics({
    required double height,
    required double weight,
  }) async {
    await _userDoc.set({
      'userHeight': height,
      'userWeight': weight,
    }, SetOptions(merge: true));
  }

  Future<Map<String, double?>> getUserMetrics() async {
    final doc = await _userDoc.get();
    if (!doc.exists) return {'height': null, 'weight': null};
    final data = doc.data() as Map<String, dynamic>?;
    return {
      'height': (data?['userHeight'] as num?)?.toDouble(),
      'weight': (data?['userWeight'] as num?)?.toDouble(),
    };
  }

  // ── Food Scans ──

  Future<void> saveFoodScan(FoodScanModel scan) async {
    await _foodScansCol.doc(scan.id).set(scan.toFirestore());
  }

  Future<List<FoodScanModel>> getFoodScansForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final snapshot = await _foodScansCol
        .where('scannedAt',
            isGreaterThanOrEqualTo: start.millisecondsSinceEpoch)
        .where('scannedAt', isLessThan: end.millisecondsSinceEpoch)
        .get();
    return snapshot.docs
        .map((doc) => FoodScanModel.fromFirestore(
            doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<double> getDailyCalories(DateTime date) async {
    final scans = await getFoodScansForDate(date);
    return scans.fold<double>(0, (total, scan) => total + scan.totalCalories);
  }

  Future<void> deleteFoodScan(String scanId) async {
    await _foodScansCol.doc(scanId).delete();
  }

  Future<Map<DateTime, double>> getCalorieHistory() async {
    final snapshot = await _foodScansCol.get();
    final map = <DateTime, double>{};
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final ms = data['scannedAt'] as num? ?? 0;
      final date = DateTime.fromMillisecondsSinceEpoch(ms.toInt());
      final normalized = DateTime(date.year, date.month, date.day);
      final calories = (data['totalCalories'] as num?)?.toDouble() ?? 0;
      map[normalized] = (map[normalized] ?? 0) + calories;
    }
    return map;
  }

  // ── Weight Loss Profile ──

  Future<WeightLossProfileModel?> getWeightLossProfile() async {
    final doc = await _userDoc.get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null || data['wl_age'] == null) return null;
    return WeightLossProfileModel.fromFirestore(data);
  }

  Future<void> saveWeightLossProfile(WeightLossProfileModel profile) async {
    await _userDoc.set(profile.toFirestore(), SetOptions(merge: true));
  }

  Future<void> deleteWeightLossProfile() async {
    await _userDoc.update({
      'wl_age': FieldValue.delete(),
      'wl_gender': FieldValue.delete(),
      'wl_activityLevel': FieldValue.delete(),
      'wl_currentWeight': FieldValue.delete(),
      'wl_targetWeight': FieldValue.delete(),
      'wl_heightCm': FieldValue.delete(),
      'wl_weeklyGoalKg': FieldValue.delete(),
    });
  }

  // ── Food Tracking ──

  Future<void> saveTrackedFood(TrackedFoodModel food) async {
    await _foodTrackingCol.doc(food.id).set(food.toFirestore());
  }

  Future<List<TrackedFoodModel>> getTrackedFoodForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final snapshot = await _foodTrackingCol
        .where('trackedAt',
            isGreaterThanOrEqualTo: start.millisecondsSinceEpoch)
        .where('trackedAt', isLessThan: end.millisecondsSinceEpoch)
        .get();
    final list = snapshot.docs
        .map((doc) => TrackedFoodModel.fromFirestore(
            doc.id, doc.data() as Map<String, dynamic>))
        .toList();
    list.sort((a, b) => b.trackedAt.compareTo(a.trackedAt));
    return list;
  }

  Future<void> deleteTrackedFood(String id) async {
    await _foodTrackingCol.doc(id).delete();
  }

  Future<Map<DateTime, double>> getTrackedFoodCalorieHistory() async {
    final snapshot = await _foodTrackingCol.get();
    final map = <DateTime, double>{};
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final ms = data['trackedAt'] as num? ?? 0;
      final date = DateTime.fromMillisecondsSinceEpoch(ms.toInt());
      final normalized = DateTime(date.year, date.month, date.day);
      final cal = (data['calories'] as num?)?.toDouble() ?? 0;
      final qty = (data['quantity'] as num?)?.toDouble() ?? 1;
      map[normalized] = (map[normalized] ?? 0) + (cal * qty);
    }
    return map;
  }

  // ── Calorie Goals (per-day) ──

  CollectionReference get _calorieGoalsCol =>
      _userDoc.collection('gym_calorie_goals');

  Future<void> saveCalorieGoalForDate(DateTime date, double goal) async {
    final key = DateFormat('yyyy-MM-dd').format(date);
    await _calorieGoalsCol.doc(key).set({'goalCalories': goal}, SetOptions(merge: true));
  }

  Future<Map<DateTime, double>> getCalorieGoalHistory() async {
    final snapshot = await _calorieGoalsCol.get();
    final map = <DateTime, double>{};
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final goal = (data['goalCalories'] as num?)?.toDouble();
      if (goal != null && goal > 0) {
        final date = DateFormat('yyyy-MM-dd').parse(doc.id);
        map[DateTime(date.year, date.month, date.day)] = goal;
      }
    }
    return map;
  }

  // ── Workout Logs ──

  Future<void> saveWorkoutLog(WorkoutLogModel workout) async {
    await _workoutCol.doc(workout.id).set(workout.toFirestore());
  }

  Future<List<WorkoutLogModel>> getWorkoutsForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final snapshot = await _workoutCol
        .where('loggedAt',
            isGreaterThanOrEqualTo: start.millisecondsSinceEpoch)
        .where('loggedAt', isLessThan: end.millisecondsSinceEpoch)
        .get();
    final list = snapshot.docs
        .map((doc) => WorkoutLogModel.fromFirestore(
            doc.id, doc.data() as Map<String, dynamic>))
        .toList();
    list.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    return list;
  }

  Future<void> deleteWorkoutLog(String id) async {
    await _workoutCol.doc(id).delete();
  }

  // ── Sleep Logs ──

  Future<void> saveSleepLog(SleepLogModel sleep) async {
    await _sleepCol.doc(sleep.id).set(sleep.toFirestore());
  }

  Future<List<SleepLogModel>> getSleepForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final snapshot = await _sleepCol
        .where('loggedAt',
            isGreaterThanOrEqualTo: start.millisecondsSinceEpoch)
        .where('loggedAt', isLessThan: end.millisecondsSinceEpoch)
        .get();
    final list = snapshot.docs
        .map((doc) => SleepLogModel.fromFirestore(
            doc.id, doc.data() as Map<String, dynamic>))
        .toList();
    list.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    return list;
  }

  Future<void> deleteSleepLog(String id) async {
    await _sleepCol.doc(id).delete();
  }

  /// Returns a map of date -> sleep duration in minutes (sums all entries per day)
  Future<Map<DateTime, int>> getSleepHistory() async {
    final snapshot = await _sleepCol.get();
    final map = <DateTime, int>{};
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final loggedMs = data['loggedAt'] as num? ?? 0;
      final loggedDate = DateTime.fromMillisecondsSinceEpoch(loggedMs.toInt());
      final normalized =
          DateTime(loggedDate.year, loggedDate.month, loggedDate.day);
      final sleepMs = data['sleepTime'] as num? ?? 0;
      final wakeMs = data['wakeTime'] as num? ?? 0;
      final sleepTime =
          DateTime.fromMillisecondsSinceEpoch(sleepMs.toInt());
      final wakeTime =
          DateTime.fromMillisecondsSinceEpoch(wakeMs.toInt());
      final durationMin = wakeTime.difference(sleepTime).inMinutes;
      if (durationMin > 0) {
        map[normalized] = (map[normalized] ?? 0) + durationMin;
      }
    }
    return map;
  }

  // ── Reminder Settings (stays local in Hive) ──

  Future<Map<String, dynamic>> getReminderSettings(String hivePrefix) async {
    final box = await _getGymSettingsBox();
    return {
      'enabled': box.get('${hivePrefix}_enabled', defaultValue: false) as bool,
      'hour': box.get('${hivePrefix}_hour', defaultValue: 8) as int,
      'minute': box.get('${hivePrefix}_minute', defaultValue: 0) as int,
      'frequency': box.get('${hivePrefix}_frequency', defaultValue: 'weekly') as String,
      'dayOfWeek': box.get('${hivePrefix}_dayOfWeek', defaultValue: 1) as int,
      'dayOfMonth': box.get('${hivePrefix}_dayOfMonth', defaultValue: 1) as int,
    };
  }

  Future<void> saveReminderSettings(
    String hivePrefix,
    Map<String, dynamic> settings,
  ) async {
    final box = await _getGymSettingsBox();
    for (final entry in settings.entries) {
      await box.put('${hivePrefix}_${entry.key}', entry.value);
    }
  }
}