import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'habit_list_screen.dart';
import 'habit_meanings_screen.dart';
import 'habit_statistics_screen.dart';

class HabitShellScreen extends StatefulWidget {
  const HabitShellScreen({super.key});

  @override
  State<HabitShellScreen> createState() => _HabitShellScreenState();
}

class _HabitShellScreenState extends State<HabitShellScreen> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    HabitListScreen(),
    HabitMeaningsScreen(),
    SizedBox.shrink(), // Placeholder for Add (handled by onTap)
    HabitStatisticsScreen(),
  ];

  void _onTabTapped(int index) {
    if (index == 2) {
      context.go('/habits/add');
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  isSelected: _currentIndex == 0,
                  onTap: () => _onTabTapped(0),
                  primaryColor: primaryColor,
                ),
                _NavItem(
                  icon: Icons.edit_rounded,
                  isSelected: _currentIndex == 1,
                  onTap: () => _onTabTapped(1),
                  primaryColor: primaryColor,
                ),
                // Center Add button
                GestureDetector(
                  onTap: () => _onTabTapped(2),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: primaryColor,
                      size: 28,
                    ),
                  ),
                ),
                _NavItem(
                  icon: Icons.calendar_month_rounded,
                  isSelected: _currentIndex == 3,
                  onTap: () => _onTabTapped(3),
                  primaryColor: primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.primaryColor,
  });

  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: isSelected
              ? Colors.white
              : Theme.of(context).colorScheme.onSurfaceVariant,
          size: 24,
        ),
      ),
    );
  }
}