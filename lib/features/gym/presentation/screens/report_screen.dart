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
                      count: state.absentCount,
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
                          label: 'Price',
                          value: 'Rs. ${membership.price}',
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
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.presentDates.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      return ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                        title: Text(
                          dateFormat.format(state.presentDates[index]),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Absent dates
              if (state.absentDates.isNotEmpty) ...[
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
                    itemCount: state.absentDates.length,
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
                          dateFormat.format(state.absentDates[index]),
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        );
      },
    );
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
