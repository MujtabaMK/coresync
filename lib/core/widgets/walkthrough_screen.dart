import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

class WalkthroughScreen extends StatefulWidget {
  const WalkthroughScreen({super.key});

  @override
  State<WalkthroughScreen> createState() => _WalkthroughScreenState();
}

class _WalkthroughScreenState extends State<WalkthroughScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pages = <_PageData>[
    _PageData(
      icon: Icons.hub,
      title: 'Welcome to CoreSync Go',
      description:
          'Your all-in-one productivity & health companion.\n'
          'Everything you need, synced in one place.',
    ),
    _PageData(
      icon: Icons.checklist,
      title: 'Task Manager',
      description:
          'Create, organize, and share tasks.\n'
          'Track progress from not started to completed.',
    ),
    _PageData(
      icon: Icons.lock,
      title: 'Password Vault',
      description:
          'Securely store and manage all your passwords with encryption.',
    ),
    _PageData(
      icon: Icons.fitness_center,
      title: 'Gym & Health Tracker',
      description:
          'Track workouts, water intake, steps, food calories, sleep, '
          'and gym attendance — all in one place.',
    ),
    _PageData(
      icon: Icons.repeat,
      title: 'Habit Tracker',
      description:
          'Build positive habits with daily tracking, streaks, '
          'reminders, and weekly progress insights.',
    ),
    _PageData(
      icon: Icons.document_scanner,
      title: 'Document Scanner',
      description:
          'Scan documents, extract text with OCR, fill & sign, '
          'and export as PDF.',
    ),
    _PageData(
      icon: Icons.translate,
      title: 'Voice Translator',
      description:
          'Translate speech in real time across 20+ languages.\n'
          'Perfect for conversations on the go.',
    ),
    _PageData(
      icon: Icons.qr_code_scanner,
      title: 'QR & NFC Scanner',
      description: 'Scan QR codes, barcodes, and NFC tags instantly.',
    ),
    _PageData(
      icon: Icons.calculate,
      title: 'Calculator & Converter',
      description:
          'Simple calculator, scientific calculator, '
          'and unit/currency converter.',
    ),
    _PageData(
      icon: Icons.picture_as_pdf,
      title: 'PDF Reader',
      description:
          'Import, read, and annotate PDF files.\n'
          'Search your library and listen with text-to-speech.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    final box = Hive.box('app_settings');
    await box.put('walkthrough_shown', true);
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _complete,
                child: const Text('Skip'),
              ),
            ),
            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            page.icon,
                            size: 56,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          page.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.description,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Dot indicators
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  final isActive = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            // Bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: isLastPage
                      ? _complete
                      : () => _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                  child: Text(isLastPage ? 'Get Started' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageData {
  const _PageData({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
