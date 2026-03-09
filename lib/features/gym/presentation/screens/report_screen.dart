import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../providers/gym_provider.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy');

    return BlocBuilder<GymCubit, GymState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final membership = state.activeMembership;

        // Auto-calculate absent dates from membership start to today
        List<DateTime> absentDates = [];
        if (membership != null) {
          final start = DateTime(
            membership.startDate.year,
            membership.startDate.month,
            membership.startDate.day,
          );
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final presentSet = state.presentDates
              .map((d) => DateTime(d.year, d.month, d.day))
              .toSet();

          for (var d = start; d.isBefore(today); d = d.add(const Duration(days: 1))) {
            if (!presentSet.contains(d)) {
              absentDates.add(d);
            }
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary cards row
              Row(
                children: [
                  Expanded(
                    child: _CountCard(
                      label: 'PRESENT',
                      count: state.presentCount,
                      color: Colors.green,
                      icon: Icons.check_circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CountCard(
                      label: 'ABSENT',
                      count: absentDates.length,
                      color: Colors.red,
                      icon: Icons.cancel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Membership section
              if (membership != null) ...[
                Text(
                  'MEMBERSHIP',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _DetailRow(label: 'Plan', value: membership.planLabel),
                        const Divider(height: 20),
                        _DetailRow(
                          label: 'Duration',
                          value: '${membership.durationDays} days',
                        ),
                        const Divider(height: 20),
                        _DetailRow(
                          label: 'Start Date',
                          value: dateFormat.format(membership.startDate),
                        ),
                        const Divider(height: 20),
                        _DetailRow(
                          label: 'End Date',
                          value: dateFormat.format(membership.endDate),
                        ),
                        const Divider(height: 20),
                        _DetailRow(
                          label: 'Days Left',
                          value: '${membership.daysRemaining}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Present dates
              if (state.presentDates.isNotEmpty) ...[
                Text(
                  'PRESENT DATES',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.presentDates.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final date = state.presentDates[index];
                      return Dismissible(
                        key: ValueKey(date),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Text(
                            'Delete',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        confirmDismiss: (_) => _confirmDelete(context, date),
                        child: ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          title: Text(dateFormat.format(date)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Absent dates
              if (absentDates.isNotEmpty) ...[
                Text(
                  'ABSENT DATES',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: absentDates.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      return ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.cancel,
                          color: Colors.red,
                          size: 20,
                        ),
                        title: Text(
                          dateFormat.format(absentDates[index]),
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Water intake - monthly (1st of month to today)
              Builder(
                builder: (context) {
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  final firstOfMonth = DateTime(now.year, now.month, 1);
                  final days = <DateTime>[];
                  for (var d = today;
                      !d.isBefore(firstOfMonth);
                      d = d.subtract(const Duration(days: 1))) {
                    days.add(d);
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WATER INTAKE',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: days.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final date = days[index];
                            final glasses =
                                state.waterHistory[date] ?? 0;
                            final goalMl = state.dailyWaterGoalMl;
                            final currentMl = glasses * 250;
                            final waterColor = glasses == 0
                                ? Colors.red
                                : currentMl >= goalMl
                                    ? Colors.green
                                    : Colors.amber.shade700;
                            return ListTile(
                              dense: true,
                              leading: Icon(
                                Icons.water_drop,
                                color: waterColor,
                                size: 20,
                              ),
                              title: Text(dateFormat.format(date)),
                              trailing: Text(
                                '$glasses ${glasses == 1 ? 'glass' : 'glasses'}',
                                style:
                                    theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: waterColor,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),

              // Steps - monthly (1st of month to today)
              Builder(
                builder: (context) {
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  final firstOfMonth = DateTime(now.year, now.month, 1);
                  final days = <DateTime>[];
                  for (var d = today;
                      !d.isBefore(firstOfMonth);
                      d = d.subtract(const Duration(days: 1))) {
                    days.add(d);
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STEPS',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: days.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final date = days[index];
                            final steps =
                                state.stepsHistory[date] ?? 0;
                            const stepsGoal = 10000;
                            final stepsColor = steps == 0
                                ? Colors.red
                                : steps >= stepsGoal
                                    ? Colors.green
                                    : Colors.amber.shade700;
                            return ListTile(
                              dense: true,
                              leading: Icon(
                                Icons.directions_walk,
                                color: stepsColor,
                                size: 20,
                              ),
                              title: Text(dateFormat.format(date)),
                              trailing: Text(
                                '$steps ${steps == 1 ? 'step' : 'steps'}',
                                style:
                                    theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: stepsColor,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _confirmDelete(BuildContext context, DateTime date) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Attendance'),
        content: const Text(
          'Are you sure you want to delete this attendance record?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<GymCubit>().deleteAttendance(date);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance record deleted')),
        );
      }
      return true;
    }
    return false;
  }
}

class _CountCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _CountCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
