import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Firestore firstName (higher priority than displayName).
  /// Populated once by a one-time fetch; triggers userChanges() as backup.
  String? _firestoreName;

  @override
  void initState() {
    super.initState();
    _backfillDisplayName();
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

  static const _features = [
    (
      icon: Icons.checklist_rounded,
      title: 'Todo',
      subtitle: 'Manage your tasks',
      color: Color(0xFF4CAF50),
      branch: 1,
    ),
    (
      icon: Icons.lock_rounded,
      title: 'Passwords',
      subtitle: 'Secure vault',
      color: Color(0xFF2196F3),
      branch: 2,
    ),
    (
      icon: Icons.fitness_center_rounded,
      title: 'Fitness',
      subtitle: 'Track your fitness',
      color: Color(0xFFFF5722),
      branch: 3,
    ),
    (
      icon: Icons.track_changes_rounded,
      title: 'Habits',
      subtitle: 'Build daily habits',
      color: Color(0xFFE91E63),
      branch: 4,
    ),
    (
      icon: Icons.document_scanner_rounded,
      title: 'Scanner',
      subtitle: 'Scan documents',
      color: Color(0xFF9C27B0),
      branch: 5,
    ),
    (
      icon: Icons.qr_code_scanner_rounded,
      title: 'QR / Barcode',
      subtitle: 'Scan & generate',
      color: Color(0xFF009688),
      branch: 6,
    ),
    (
      icon: Icons.calculate_rounded,
      title: 'Calculator',
      subtitle: 'Quick calculations',
      color: Color(0xFFFF9800),
      branch: 7,
    ),
    (
      icon: Icons.translate_rounded,
      title: 'Translator',
      subtitle: 'Voice translation',
      color: Color(0xFF3F51B5),
      branch: 8,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: const Text('CoreSync Go'),
        actions: [
          IconButton(
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
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
              children: _features.map((f) {
                return _FeatureCard(
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
