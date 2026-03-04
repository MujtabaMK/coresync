import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/services/notification_service.dart';
import 'core/services/push_notification_service.dart';
import 'firebase_options.dart';
import 'features/gym/domain/attendance_model.dart';
import 'features/gym/domain/membership_model.dart';
import 'features/passwords/domain/password_entry_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(PasswordEntryModelAdapter());
  Hive.registerAdapter(MembershipModelAdapter());
  Hive.registerAdapter(AttendanceModelAdapter());

  await NotificationService.init();
  await NotificationService.requestPermissions();
  await PushNotificationService.init();

  // Sign out stale Firebase session after app reinstall.
  // Hive data is deleted on uninstall, but Keychain (Firebase auth) persists.
  final appBox = await Hive.openBox('app_settings');
  final hasLaunchedBefore = appBox.get(
    'has_launched_before',
    defaultValue: false,
  );
  if (!hasLaunchedBefore) {
    await FirebaseAuth.instance.signOut();
    await appBox.put('has_launched_before', true);
  }

  runApp(const CoreSyncApp());
}
