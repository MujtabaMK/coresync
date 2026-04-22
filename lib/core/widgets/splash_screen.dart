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

  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _initialize();
    // Safety net: if _initialize() hangs for any reason (permissions dialog,
    // database lock, network timeout), force-navigate after 6 seconds so the
    // user never sees an infinite blank screen.
    Future.delayed(const Duration(seconds: 6), _fallbackNavigate);
  }

  void _fallbackNavigate() {
    if (_navigated || !mounted) return;
    _navigated = true;
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    context.go(isLoggedIn ? '/home' : '/login');
  }

  void _navigate(String route) {
    if (_navigated || !mounted) return;
    _navigated = true;
    context.go(route);
  }

  Future<void> _initialize() async {
    try {
      // PushNotificationService.init() is now called in main() to avoid the
      // race condition where app.dart's initState calls saveTokenForUser()
      // before FCM permissions have been requested.
      await NotificationService.init().timeout(const Duration(seconds: 3));
      await NotificationService.requestPermissions().timeout(const Duration(seconds: 3));
    } catch (_) {}

    late final Box appBox;
    try {
      appBox = await Hive.openBox('app_settings').timeout(const Duration(seconds: 3));
    } catch (_) {
      // If Hive fails, navigate to login as a safe fallback
      _navigate('/login');
      return;
    }

    // Initialize food database (seeds from JSON on first launch).
    try {
      if (mounted) setState(() => _status = 'Loading food database...');
      await FoodDatabaseService.instance.initialize().timeout(const Duration(seconds: 5));
    } catch (_) {}

    if (!mounted || _navigated) return;

    // If user is already logged in, skip walkthrough and go to home.
    // This handles both normal launches and reinstalls where Firebase
    // auth persists via Keychain — no need to sign them out.
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    if (isLoggedIn) {
      await appBox.put('walkthrough_shown', true);
      await appBox.put('has_launched_before', true);
      _navigate('/home');
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
        await FirebaseAuth.instance.authStateChanges().first
            .timeout(const Duration(seconds: 3));
      } catch (_) {}
      await appBox.put('has_launched_before', true);
    }

    if (!mounted || _navigated) return;

    // Walkthrough is only for new users who are not logged in.
    final walkthroughShown =
        appBox.get('walkthrough_shown', defaultValue: false);
    if (!walkthroughShown) {
      _navigate('/walkthrough');
    } else {
      _navigate('/login');
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
