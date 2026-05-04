import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../../../../core/coach_marks/coach_mark_keys.dart';
import '../../../../core/coach_marks/home_coach_marks.dart';
import '../../../../core/services/coach_mark_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Firestore firstName (higher priority than displayName).
  /// Populated once by a one-time fetch; triggers userChanges() as backup.
  String? _firestoreName;
  int _coachMarkVersion = -1;

  @override
  void initState() {
    super.initState();
    _backfillDisplayName();
  }

  void _triggerCoachMark() {
    final v = CoachMarkService.resetVersion;
    if (_coachMarkVersion == v) return;
    _coachMarkVersion = v;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        final box = Hive.box('app_settings');
        final isNewSignup =
            box.get('coach_mark_is_new_signup', defaultValue: false) == true;
        if (isNewSignup) {
          box.put('coach_mark_is_new_signup', false);
          CoachMarkService.forceShow(
            context: context,
            screenKey: 'coach_mark_home_shown',
            targets: homeCoachTargets(),
          );
        } else {
          CoachMarkService.showIfNeeded(
            context: context,
            screenKey: 'coach_mark_home_shown',
            targets: homeCoachTargets(),
          );
        }
      });
    });
  }

  /// One-time Firestore fetch. If displayName is missing on the Auth user,
  /// backfill it so the userChanges() stream updates the greeting reactively.
  Future<void> _backfillDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final firstName = doc.data()?['firstName'] as String?;
      if (firstName != null && firstName.isNotEmpty) {
        if (mounted) setState(() => _firestoreName = firstName);

        // Backfill displayName on the Auth user if missing, so future
        // loads are instant and userChanges() stream picks it up.
        if (user.displayName == null || user.displayName!.isEmpty) {
          final last = doc.data()?['lastName'] as String? ?? '';
          final full = [firstName, last].where((s) => s.isNotEmpty).join(' ');
          if (full.isNotEmpty) await user.updateDisplayName(full);
        }
      }
    } catch (_) {}
  }

  Future<void> _replayTraining() async {
    await CoachMarkService.resetAll();
    // Sync version so the build() trigger doesn't double-fire for home.
    _coachMarkVersion = CoachMarkService.resetVersion;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Training restarted! Tutorials will show again on every screen.'),
      ),
    );
    // Re-show home coach marks immediately
    CoachMarkService.forceShow(
      context: context,
      screenKey: 'coach_mark_home_shown',
      targets: homeCoachTargets(),
    );
  }

  static final _features = [
    (
      icon: Icons.checklist_rounded,
      title: 'Todo',
      subtitle: 'Manage your tasks',
      color: const Color(0xFF4CAF50),
      branch: 1,
      coachKey: CoachMarkKeys.homeTodo,
    ),
    (
      icon: Icons.lock_rounded,
      title: 'Passwords',
      subtitle: 'Secure vault',
      color: const Color(0xFF2196F3),
      branch: 2,
      coachKey: CoachMarkKeys.homePasswords,
    ),
    (
      icon: Icons.fitness_center_rounded,
      title: 'Fitness',
      subtitle: 'Track your fitness',
      color: const Color(0xFFFF5722),
      branch: 3,
      coachKey: CoachMarkKeys.homeFitness,
    ),
    (
      icon: Icons.track_changes_rounded,
      title: 'Habits',
      subtitle: 'Build daily habits',
      color: const Color(0xFFE91E63),
      branch: 4,
      coachKey: CoachMarkKeys.homeHabits,
    ),
    (
      icon: Icons.document_scanner_rounded,
      title: 'Scanner',
      subtitle: 'Scan documents',
      color: const Color(0xFF9C27B0),
      branch: 5,
      coachKey: CoachMarkKeys.homeScanner,
    ),
    (
      icon: Icons.qr_code_scanner_rounded,
      title: 'QR / Barcode',
      subtitle: 'Scan & generate',
      color: const Color(0xFF009688),
      branch: 6,
      coachKey: CoachMarkKeys.homeQr,
    ),
    (
      icon: Icons.calculate_rounded,
      title: 'Calculator',
      subtitle: 'Quick calculations',
      color: const Color(0xFFFF9800),
      branch: 7,
      coachKey: CoachMarkKeys.homeCalculator,
    ),
    (
      icon: Icons.translate_rounded,
      title: 'Translator',
      subtitle: 'Voice translation',
      color: const Color(0xFF3F51B5),
      branch: 8,
      coachKey: CoachMarkKeys.homeTranslator,
    ),
    (
      icon: Icons.picture_as_pdf_rounded,
      title: 'PDF Reader',
      subtitle: 'View & annotate PDFs',
      color: const Color(0xFFE53935),
      branch: 9,
      coachKey: CoachMarkKeys.homePdf,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    _triggerCoachMark();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: CoachMarkKeys.homeMenu,
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: const Text('CoreSync Go'),
        actions: [
          IconButton(
            key: CoachMarkKeys.homeReplayTutorial,
            icon: const Icon(Icons.school_outlined),
            tooltip: 'Restart Training',
            onPressed: _replayTraining,
          ),
          IconButton(
            key: CoachMarkKeys.homeProfile,
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            StreamBuilder<User?>(
              stream: FirebaseAuth.instance.userChanges(),
              builder: (context, snapshot) {
                // Prefer Firestore firstName, fall back to Auth displayName
                final displayName = snapshot.data?.displayName;
                final name = _firestoreName ??
                    (displayName != null && displayName.isNotEmpty
                        ? displayName.split(' ').first
                        : '');
                return Text(
                  name.isEmpty ? 'Welcome!' : 'Welcome, $name!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              'What would you like to do today?',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            GridView.count(
              key: CoachMarkKeys.homeGrid,
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
              children: _features.map((f) {
                return _FeatureCard(
                  key: f.coachKey,
                  icon: f.icon,
                  title: f.title,
                  subtitle: f.subtitle,
                  color: f.color,
                  onTap: () {
                    StatefulNavigationShell.of(context).goBranch(f.branch);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
