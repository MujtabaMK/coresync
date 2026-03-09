import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'features/gym/domain/attendance_model.dart';
import 'features/gym/domain/membership_model.dart';
import 'features/passwords/domain/password_entry_model.dart';
import 'firebase_options.dart';

/// Top-level background message handler for FCM.
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // FCM automatically shows the notification on Android when the app is in
  // background/terminated and the message contains a `notification` payload.
  // No additional handling needed here.
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    Hive.initFlutter(),
  ]);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  Hive.registerAdapter(PasswordEntryModelAdapter());
  Hive.registerAdapter(MembershipModelAdapter());
  Hive.registerAdapter(AttendanceModelAdapter());
  runApp(const CoreSyncApp());
}
