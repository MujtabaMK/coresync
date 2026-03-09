import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'features/gym/domain/attendance_model.dart';
import 'features/gym/domain/membership_model.dart';
import 'features/passwords/domain/password_entry_model.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    Hive.initFlutter(),
  ]);
  Hive.registerAdapter(PasswordEntryModelAdapter());
  Hive.registerAdapter(MembershipModelAdapter());
  Hive.registerAdapter(AttendanceModelAdapter());
  runApp(const CoreSyncApp());
}
