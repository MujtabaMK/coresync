import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../providers/gym_provider.dart';
import '../widgets/membership_card.dart';

class GymHomeScreen extends StatelessWidget {
  const GymHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<GymCubit, GymState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final membership = state.activeMembership;

        return RefreshIndicator(
          onRefresh: () => context.read<GymCubit>().loadAll(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Active membership summary
                if (membership != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: MembershipCard(membership: membership),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      color: theme.colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Icon(
                              Icons.card_membership,
                              size: 32,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'No Active Plan',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme
                                          .colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Go to Plans tab to activate a membership',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme
                                          .colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // Quick stats - only show attendance when active membership
                if (membership != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Builder(
                      builder: (context) {
                        final today = DateTime.now();
                        final start = membership.startDate;
                        final daysSinceStart =
                            today.difference(start).inDays + 1;
                        final absentCount =
                            (daysSinceStart - state.presentCount)
                                .clamp(0, daysSinceStart);
                        return Row(
                          children: [
                            Expanded(
                              child: _QuickStatCard(
                                icon: Icons.check_circle,
                                label: 'Present',
                                value: '${state.presentCount}',
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _QuickStatCard(
                                icon: Icons.cancel,
                                label: 'Absent',
                                value: '$absentCount',
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _QuickStatCard(
                                icon: Icons.water_drop,
                                label: 'Water',
                                value: '${state.waterGlasses}',
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Builder(
                                builder: (context) {
                                  final now = DateTime.now();
                                  final today = DateTime(now.year, now.month, now.day);
                                  final todaySteps = state.stepsHistory[today] ?? 0;
                                  const stepsGoal = 10000;
                                  final stepsColor = todaySteps == 0
                                      ? Colors.red
                                      : todaySteps >= stepsGoal
                                          ? Colors.green
                                          : Colors.amber.shade700;
                                  return _QuickStatCard(
                                    icon: Icons.directions_walk,
                                    label: 'Steps',
                                    value: '$todaySteps',
                                    color: stepsColor,
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Quick Access',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _NavCard(
                        icon: Icons.fitness_center,
                        label: 'Exercises',
                        subtitle: 'Browse workout routines',
                        color: Colors.orange,
                        onTap: () => context.go('/gym/exercises'),
                      ),
                      const SizedBox(height: 10),
                      _NavCard(
                        icon: Icons.notifications_active,
                        label: 'Reminders',
                        subtitle: 'Set workout & health reminders',
                        color: Colors.blue,
                        onTap: () => context.go('/gym/reminders'),
                      ),
                      const SizedBox(height: 10),
                      _NavCard(
                        icon: Icons.medication,
                        label: 'Medicine Cabinet',
                        subtitle: 'Track your supplements & meds',
                        color: Colors.green,
                        onTap: () => context.go('/gym/medicines'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _NavCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}