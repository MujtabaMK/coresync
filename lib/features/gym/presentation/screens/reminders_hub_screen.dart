import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/reminder_type.dart';

class RemindersHubScreen extends StatelessWidget {
  const RemindersHubScreen({super.key});

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
          ...types.map((type) {
            final color = _colorFor(type);
            return Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(_iconFor(type), color: color),
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