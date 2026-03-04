import '../../../core/constants/notification_ids.dart';

enum ReminderUiPattern { onceAt, periodic, custom }

enum ReminderType {
  food(
    label: 'Track Food Reminder',
    description: 'Set a Food reminder',
    hivePrefix: 'reminder_food',
    notificationId: 0, // uses multiple IDs
    uiPattern: ReminderUiPattern.custom,
    icon: 'restaurant',
  ),
  water(
    label: 'Water Reminder',
    description: 'Set a water reminder',
    hivePrefix: 'reminder_water',
    notificationId: 0, // uses multiple IDs
    uiPattern: ReminderUiPattern.custom,
    icon: 'water_drop',
  ),
  workout(
    label: 'Workout Reminder',
    description: 'Set a Workout reminder',
    hivePrefix: 'reminder_workout',
    notificationId: NotificationIds.workoutReminder,
    uiPattern: ReminderUiPattern.onceAt,
    icon: 'fitness_center',
  ),
  walk(
    label: 'Walk Reminder',
    description: 'Set a walk reminder',
    hivePrefix: 'reminder_walk',
    notificationId: NotificationIds.walkReminder,
    uiPattern: ReminderUiPattern.onceAt,
    icon: 'directions_walk',
  ),
  weight(
    label: 'Weight Reminder',
    description: 'Set a weight reminder',
    hivePrefix: 'reminder_weight',
    notificationId: NotificationIds.weightReminder,
    uiPattern: ReminderUiPattern.periodic,
    icon: 'monitor_weight',
  ),
  healthLog(
    label: 'Health Log Reminder',
    description: 'Set a health log reminder',
    hivePrefix: 'reminder_health',
    notificationId: NotificationIds.healthLogReminder,
    uiPattern: ReminderUiPattern.periodic,
    icon: 'medical_services',
  );

  const ReminderType({
    required this.label,
    required this.description,
    required this.hivePrefix,
    required this.notificationId,
    required this.uiPattern,
    required this.icon,
  });

  final String label;
  final String description;
  final String hivePrefix;
  final int notificationId;
  final ReminderUiPattern uiPattern;
  final String icon;
}