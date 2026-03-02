import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'features/gym/domain/attendance_model.dart';
import 'features/gym/domain/membership_model.dart';
import 'features/passwords/domain/password_entry_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(PasswordEntryModelAdapter());
  Hive.registerAdapter(MembershipModelAdapter());
  Hive.registerAdapter(AttendanceModelAdapter());

  runApp(const CoreSyncApp());
}
