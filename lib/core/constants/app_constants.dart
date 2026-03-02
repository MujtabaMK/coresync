class AppConstants {
  AppConstants._();

  // App
  static const String appName = 'CoreSync';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String tasksCollection = 'tasks';

  // Hive box names
  static const String passwordsBox = 'passwords';
  static const String membershipBox = 'membership';
  static const String attendanceBox = 'attendance';
  static const String encryptionKeyName = 'coresync_hive_key';

  // Task status values
  static const String statusNotStarted = 'notStarted';
  static const String statusWorking = 'working';
  static const String statusCompleted = 'completed';
}
