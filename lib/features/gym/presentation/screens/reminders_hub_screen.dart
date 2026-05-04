import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/coach_marks/coach_mark_keys.dart';
import '../../../../core/coach_marks/gym_coach_marks.dart';
import '../../../../core/services/coach_mark_service.dart';
import '../../domain/reminder_type.dart';

class RemindersHubScreen extends StatefulWidget {
  const RemindersHubScreen({super.key});

  @override
  State<RemindersHubScreen> createState() => _RemindersHubScreenState();

  static IconData _iconFor(ReminderType type) {
    switch (type) {
      case ReminderType.food:
        return Icons.restaurant;
      case ReminderType.water:
        return Icons.water_drop;
      case ReminderType.workout:
        return Icons.fitness_center;
      case ReminderType.walk:
        return Icons.directions_walk;
      case ReminderType.weight:
        return Icons.monitor_weight;
      case ReminderType.healthLog:
        return Icons.medical_services;
    }
  }

  static Color _colorFor(ReminderType type) {
    switch (type) {
      case ReminderType.food:
        return Colors.orange;
      case ReminderType.water:
        return Colors.blue;
      case ReminderType.workout:
        return Colors.deepPurple;
      case ReminderType.walk:
        return Colors.green;
      case ReminderType.weight:
        return Colors.purple;
      case ReminderType.healthLog:
        return Colors.red;
    }
  }
}

class _RemindersHubScreenState extends State<RemindersHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        CoachMarkService.showIfNeeded(
          context: context,
          screenKey: 'coach_mark_reminders_shown',
          targets: remindersCoachTargets(),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // All reminder types + medicine at bottom
    final types = ReminderType.values;

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...types.indexed.map((e) {
            final (index, type) = e;
            final color = RemindersHubScreen._colorFor(type);
            return Column(
              key: index == 0 ? CoachMarkKeys.remindersListView : null,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(RemindersHubScreen._iconFor(type), color: color),
                  ),
                  title: Text(
                    type.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(type.description),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.go('/gym/reminders/${type.name}'),
                ),
                const Divider(height: 1),
              ],
            );
          }),
          // Medicine reminder entry
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.teal.withValues(alpha: 0.15),
              child: const Icon(Icons.medication, color: Colors.teal),
            ),
            title: Text(
              'Medicine Reminder',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text('Click to edit Medicine reminder'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.go('/gym/medicines'),
          ),
        ],
      ),
    );
  }
}
