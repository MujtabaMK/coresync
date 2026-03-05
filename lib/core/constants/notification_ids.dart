class NotificationIds {
  NotificationIds._();

  // Generic reminders (1000-1099)
  static const int workoutReminder = 1000;
  static const int walkReminder = 1001;
  static const int weightReminder = 1002;
  static const int healthLogReminder = 1003;

  // Meal reminders (1100-1109)
  static const int mealBreakfast = 1100;
  static const int mealMorningSnack = 1101;
  static const int mealLunch = 1102;
  static const int mealEveningSnack = 1103;
  static const int mealDinner = 1104;

  // Water reminders (1200-1249)
  static const int waterOnce = 1200;
  // Interval-based water reminders use 1201-1249
  static int waterInterval(int index) => 1201 + index;

  /// Generates a deterministic notification ID for a medicine dose.
  /// Uses hashCode of the medicineId combined with the dose index
  /// to produce IDs in the 2000+ range.
  static int medicineDose(String medicineId, int doseIndex) {
    return 2000 + (medicineId.hashCode.abs() % 10000) * 10 + doseIndex;
  }

  // Task alarms (3000+ range)
  static int taskAlarm(String taskId) {
    return 3000 + (taskId.hashCode.abs() % 10000);
  }
}