import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/notification_service.dart';
import '../services/push_notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.wait([
      NotificationService.init(),
      PushNotificationService.init(),
    ]);
    await NotificationService.requestPermissions();

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

    if (!mounted) return;
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    context.go(isLoggedIn ? '/todo' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Image.asset(
          'assets/splash_screen.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
