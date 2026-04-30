import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'main_shell_drawer.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _destinations = [
    (
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Home',
    ),
    (
      icon: Icons.checklist_outlined,
      selectedIcon: Icons.checklist,
      label: 'Todo',
    ),
    (
      icon: Icons.lock_outlined,
      selectedIcon: Icons.lock,
      label: 'Passwords',
    ),
    (
      icon: Icons.fitness_center_outlined,
      selectedIcon: Icons.fitness_center,
      label: 'Fitness',
    ),
    (
      icon: Icons.track_changes_outlined,
      selectedIcon: Icons.track_changes,
      label: 'Habits',
    ),
    (
      icon: Icons.document_scanner_outlined,
      selectedIcon: Icons.document_scanner,
      label: 'Scanner',
    ),
    (
      icon: Icons.qr_code_scanner_outlined,
      selectedIcon: Icons.qr_code_scanner,
      label: 'QR / Barcode',
    ),
    (
      icon: Icons.calculate_outlined,
      selectedIcon: Icons.calculate,
      label: 'Calculator',
    ),
    (
      icon: Icons.translate_outlined,
      selectedIcon: Icons.translate,
      label: 'Translator',
    ),
    (
      icon: Icons.picture_as_pdf_outlined,
      selectedIcon: Icons.picture_as_pdf,
      label: 'PDF Reader',
    ),
  ];

  void _onDestinationSelected(int index) {
    _scaffoldKey.currentState?.closeDrawer();
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentIndex = widget.navigationShell.currentIndex;

    return MainShellDrawer(
      openDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      child: Scaffold(
        key: _scaffoldKey,
        drawer: NavigationDrawer(
          selectedIndex: currentIndex,
          onDestinationSelected: _onDestinationSelected,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
              child: Text(
                'CoreSync Go',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(indent: 28, endIndent: 28),
            ..._destinations.map(
              (d) => NavigationDrawerDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: Text(d.label),
              ),
            ),
          ],
        ),
        body: widget.navigationShell,
      ),
    );
  }
}
