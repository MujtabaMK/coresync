import 'package:flutter/material.dart';

import '../../domain/habit_model.dart';

class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.habit,
    required this.date,
    required this.onTap,
    required this.onEdit,
    required this.onArchive,
    required this.onDelete,
  });

  final HabitModel habit;
  final DateTime date;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = habit.isCompletedOn(date);
    final count = habit.completionsOnDate(date);
    final streak = habit.currentStreak;
    final weekly = habit.weeklyCompletion;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(habit.icon, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        habit.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (habit.executionType == ExecutionType.trackVolume)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '$count',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: count >= habit.dailyVolume
                                      ? Colors.green
                                      : Colors.deepOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: '/',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.deepOrange,
                                ),
                              ),
                              TextSpan(
                                text: '${habit.dailyVolume}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Icon(
                      completed ? Icons.check : Icons.close,
                      color: completed ? Colors.green : Colors.red,
                      size: 28,
                    ),
                    const SizedBox(width: 2),
                    Column(
                      children: [
                        _FireBadge(streak: streak),
                        const SizedBox(height: 4),
                      ],
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            onEdit();
                          case 'archive':
                            onArchive();
                          case 'delete':
                            onDelete();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(
                          value: 'archive',
                          child: Text('Archive'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.more_vert,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: _WeeklyProgressBar(weekly: weekly)),
                    const SizedBox(width: 8),
                    _CompletionCountBadge(
                      count: count,
                      completed: completed,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FireBadge extends StatelessWidget {
  const _FireBadge({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.local_fire_department,
            size: 22,
            color: streak > 0 ? Colors.deepOrange : Colors.deepOrange.shade200,
          ),
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: streak > 0 ? Colors.deepOrange : Colors.grey,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$streak',
                style: const TextStyle(
                  fontSize: 8,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionCountBadge extends StatelessWidget {
  const _CompletionCountBadge({
    required this.count,
    required this.completed,
  });

  final int count;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = completed ? Colors.green : theme.colorScheme.primary;

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Center(
        child: count > 0
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, size: 10, color: color),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 9,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Icon(Icons.check, size: 12, color: color),
      ),
    );
  }
}

class _WeeklyProgressBar extends StatelessWidget {
  const _WeeklyProgressBar({required this.weekly});

  final List<bool?> weekly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Row(
      children: List.generate(7, (i) {
        final day = now.subtract(Duration(days: 6 - i));
        final status = weekly[i];

        Color color;
        if (status == null) {
          color = theme.colorScheme.surfaceContainerHighest;
        } else if (status) {
          color = Colors.green;
        } else {
          final isToday = day.year == now.year &&
              day.month == now.month &&
              day.day == now.day;
          color = isToday
              ? theme.colorScheme.surfaceContainerHighest
              : Colors.red;
        }

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 6 ? 4 : 0),
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
        );
      }),
    );
  }
}