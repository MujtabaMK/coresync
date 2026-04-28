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
  @override
  void initState() {
    super.initState();
    _initialize();
    // Safety net: if _initialize() hangs for any reason (permissions dialog,
    // database lock, network timeout), force-navigate after 6 seconds so the
    // user never sees an infinite blank screen.
    Future.delayed(const Duration(seconds: 6), _fallbackNavigate);
  }

  bool _navigated = false;

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

    // Initialize food database in background — never block navigation.
    FoodDatabaseService.instance.initialize().then((_) {
      // One-time: upload existing local custom foods to Firestore
      FoodDatabaseService.instance.syncCustomFoodsToFirestore().catchError((_) {});
    }).catchError((_) {});

    if (!mounted || _navigated) return;

    // If user is already logged in, skip walkthrough and go to home.
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    if (isLoggedIn) {
      await appBox.put('walkthrough_shown', true);
      await appBox.put('has_launched_before', true);
      _navigate('/home');
      return;
    }

    // Sign out stale Firebase session after app reinstall.
    final hasLaunchedBefore = appBox.get(
      'has_launched_before',
      defaultValue: false,
    );
    if (!hasLaunchedBefore) {
      try {
        await FirebaseAuth.instance.signOut();
        await FirebaseAuth.instance.authStateChanges().first
            .timeout(const Duration(seconds: 3));
      } catch (_) {}
      await appBox.put('has_launched_before', true);
    }

    if (!mounted || _navigated) return;

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
        child: Image.asset(
          'assets/splash_screen.jpg',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
