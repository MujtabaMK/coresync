class AppConstants {
  AppConstants._();

  // App
  static const String appName = 'CoreSync Go';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String tasksCollection = 'tasks';
  static const String passwordsSyncCollection = 'passwords';
  static const String recipesCollection = 'recipes';
  static const String foodTrackingCollection = 'gym_food_tracking';

  // Hive box names
  static const String passwordsBox = 'passwords';
  static const String membershipBox = 'membership';
  static const String attendanceBox = 'attendance';
  static const String waterIntakeBox = 'water_intake';
  static const String gymSettingsBox = 'gym_settings';
  static const String medicinesBox = 'medicines';
  static const String scannedDocumentsBox = 'scanned_documents';
  static const String qrScanHistoryBox = 'qr_scan_history';
  static const String encryptionKeyName = 'coresync_hive_key';

  // Gemini AI
  static const String geminiApiKey = 'AIzaSyBIz78WEnVerSQxP0NbfNuMb7TyFF6TeuY';
  static const String geminiModel = 'gemini-2.0-flash';

  // Task status values
  static const String statusNotStarted = 'notStarted';
  static const String statusWorking = 'working';
  static const String statusCompleted = 'completed';
}
