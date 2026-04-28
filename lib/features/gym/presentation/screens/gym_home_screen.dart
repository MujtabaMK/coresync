import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/step_counter_service.dart';
import '../providers/gym_provider.dart';
import '../widgets/membership_card.dart';

class GymHomeScreen extends StatefulWidget {
  const GymHomeScreen({super.key});

  @override
  State<GymHomeScreen> createState() => _GymHomeScreenState();
}

class _GymHomeScreenState extends State<GymHomeScreen>
    with WidgetsBindingObserver {
  final _stepService = StepCounterService.instance;
  late final GymCubit _gymCubit;
  StreamSubscription<int>? _stepSub;
  StreamSubscription<void>? _healthMetricsSub;
  int _liveSteps = 0;
  bool _stepsLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _gymCubit = context.read<GymCubit>();
    _initSteps();
  }

  int? _computeStepGoal() {
    final state = _gymCubit.state;
    final heightCm = state.userHeight;
    if (heightCm != null && state.userWeight != null) {
      final heightM = heightCm / 100;
      final bmi = state.userWeight! / (heightM * heightM);
      if (bmi < 18.5) return 8000;
      if (bmi < 25) return 10000;
      if (bmi < 30) return 12000;
      return 15000;
    }
    return null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _stepService.refreshOnResume();
    }
  }

  Future<void> _initSteps() async {
    // 1. Show Firestore data IMMEDIATELY — this is the highest priority source
    try {
      final saved = await _gymCubit.repository.getStepsForDate(DateTime.now());
      if (saved > 0) {
        _stepService.setMinSteps(saved);
        if (mounted) {
          setState(() {
            _liveSteps = saved;
            _stepsLoading = false;
          });
        }
      }
    } catch (_) {}

    // 2. Listen for live updates BEFORE initialize() so we catch every update
    _stepSub = _stepService.stepsStream.listen((steps) {
      if (mounted) {
        setState(() {
          _liveSteps = steps;
          _stepsLoading = false;
        });
        final now = DateTime.now();
        final todayKey = DateTime(now.year, now.month, now.day);
        final current = _gymCubit.state.stepsHistory[todayKey] ?? 0;
        if (steps > current) {
          _gymCubit.saveSteps(now, steps, goalSteps: _computeStepGoal());
        }
      }
    });

    // 2b. Rebuild UI when HealthKit kcal refreshes
    _healthMetricsSub = _stepService.healthMetricsStream.listen((_) {
      if (mounted) setState(() {});
    });

    // 3. Initialize sensor + Health Connect (may update _liveSteps via stream)
    await _stepService.initialize();

    // 4. Use the best known value after all sources are checked
    if (mounted && _stepService.currentSteps > _liveSteps) {
      setState(() {
        _liveSteps = _stepService.currentSteps;
        _stepsLoading = false;
      });
    }

    // Sync current steps to GymState so other screens see them
    if (_stepService.currentSteps > 0) {
      _gymCubit.saveSteps(DateTime.now(), _stepService.currentSteps,
          goalSteps: _computeStepGoal());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stepSub?.cancel();
    _healthMetricsSub?.cancel();
    super.dispose();
  }

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
                        // Personalized step goal based on BMI
                        int stepsGoal = 10000;
                        final heightCm = state.userHeight;
                        if (heightCm != null && state.userWeight != null) {
                          final heightM = heightCm / 100;
                          final bmi = state.userWeight! / (heightM * heightM);
                          if (bmi < 18.5) {
                            stepsGoal = 8000;
                          } else if (bmi < 25) {
                            stepsGoal = 10000;
                          } else if (bmi < 30) {
                            stepsGoal = 12000;
                          } else {
                            stepsGoal = 15000;
                          }
                        }
                        final stepsColor = _stepsLoading
                            ? Colors.grey
                            : _liveSteps == 0
                                ? Colors.red
                                : _liveSteps >= stepsGoal
                                    ? Colors.green
                                    : Colors.amber.shade700;
                        final weight = state.userWeight ?? 70.0;
                        final stepCalories =
                            _stepService.cachedActiveEnergy?.round() ??
                            StepCounterService.calculateStepCalories(
                              steps: _liveSteps,
                              weightKg: weight,
                              heightCm: heightCm,
                            ).round();
                        final workoutCalories =
                            state.todayWorkoutCalories.round();
                        final totalBurnt = stepCalories + workoutCalories;
                        return Column(
                          children: [
                            Row(
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
                                    value: (state.waterMl / 250).toStringAsFixed(1),
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _QuickStatCard(
                                    icon: Icons.directions_walk,
                                    label: 'Steps',
                                    value: _stepsLoading ? '...' : '$_liveSteps',
                                    color: stepsColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _QuickStatCard(
                                    icon: Icons.restaurant,
                                    label: 'Food Cal',
                                    value:
                                        '${state.trackedCalories.round()}',
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _QuickStatCard(
                                    icon: Icons.bedtime,
                                    label: 'Sleep',
                                    value: state.todaySleepFormatted,
                                    color: Colors.indigo,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _QuickStatCard(
                                    icon: Icons.local_fire_department,
                                    label: 'Step kcal',
                                    value: _stepsLoading ? '...' : '$stepCalories',
                                    color: _stepsLoading ? Colors.grey : Colors.teal,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _QuickStatCard(
                                    icon: Icons.fitness_center,
                                    label: 'Workout kcal',
                                    value: '$workoutCalories',
                                    color: Colors.deepOrange,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _QuickStatCard(
                                    icon: Icons.local_fire_department,
                                    label: 'Total Burnt',
                                    value: _stepsLoading ? '...' : '$totalBurnt',
                                    color: _stepsLoading ? Colors.grey : Colors.orange,
                                  ),
                                ),
                              ],
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
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.3,
                    children: [
                      _DashCard(
                        icon: Icons.fitness_center,
                        label: 'Exercises',
                        subtitle: 'Fitness routines',
                        color: Colors.orange,
                        onTap: () => context.go('/gym/exercises'),
                      ),
                      _DashCard(
                        icon: Icons.notifications_active,
                        label: 'Reminders',
                        subtitle: 'Health reminders',
                        color: Colors.blue,
                        onTap: () => context.go('/gym/reminders'),
                      ),
                      _DashCard(
                        icon: Icons.medication,
                        label: 'Medicine',
                        subtitle: 'Supplements & meds',
                        color: Colors.green,
                        onTap: () => context.go('/gym/medicines'),
                      ),
                      _DashCard(
                        icon: Icons.monitor_weight,
                        label: 'Weight Plan',
                        subtitle: 'Lose, gain, maintain',
                        color: Colors.purple,
                        onTap: () => context.go('/gym/weight-loss'),
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
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
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

class _DashCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DashCard({
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}