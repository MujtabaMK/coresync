import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../features/gym/data/food_database_service.dart';
import '../services/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _status = '';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // PushNotificationService.init() is now called in main() to avoid the
      // race condition where app.dart's initState calls saveTokenForUser()
      // before FCM permissions have been requested.
      await NotificationService.init();
      await NotificationService.requestPermissions();
    } catch (_) {}

    late final Box appBox;
    try {
      appBox = await Hive.openBox('app_settings');
    } catch (_) {
      // If Hive fails, navigate to login as a safe fallback
      if (mounted) context.go('/login');
      return;
    }

    // Initialize food database (seeds from JSON on first launch).
    try {
      if (mounted) setState(() => _status = 'Loading food database...');
      await FoodDatabaseService.instance.initialize();
    } catch (_) {}

    if (!mounted) return;

    // If user is already logged in, skip walkthrough and go to home.
    // This handles both normal launches and reinstalls where Firebase
    // auth persists via Keychain — no need to sign them out.
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    if (isLoggedIn) {
      await appBox.put('walkthrough_shown', true);
      await appBox.put('has_launched_before', true);
      context.go('/home');
      return;
    }

    // Sign out stale Firebase session after app reinstall.
    // Hive data is deleted on uninstall, but Keychain (Firebase auth) persists.
    final hasLaunchedBefore = appBox.get(
      'has_launched_before',
      defaultValue: false,
    );
    if (!hasLaunchedBefore) {
      try {
        await FirebaseAuth.instance.signOut();
        // Wait for auth to fully settle after sign-out before navigating.
        await FirebaseAuth.instance.authStateChanges().first;
      } catch (_) {}
      await appBox.put('has_launched_before', true);
    }

    if (!mounted) return;

    // Walkthrough is only for new users who are not logged in.
    final walkthroughShown =
        appBox.get('walkthrough_shown', defaultValue: false);
    if (!walkthroughShown) {
      context.go('/walkthrough');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD5D8DE),
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/splash_screen.jpg',
              fit: BoxFit.cover,
            ),
            if (_status.isNotEmpty)
              Positioned(
                bottom: 48,
                left: 0,
                right: 0,
                child: Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
