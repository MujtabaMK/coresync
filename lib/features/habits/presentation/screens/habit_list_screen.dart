import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/coach_marks/coach_mark_keys.dart';
import '../../../../core/coach_marks/habits_coach_marks.dart';
import '../../../../core/services/coach_mark_service.dart';
import '../../../../core/widgets/main_shell_drawer.dart';
import '../../domain/habit_model.dart';
import '../providers/habit_provider.dart';
import '../widgets/habit_card.dart';

class HabitListScreen extends StatefulWidget {
  const HabitListScreen({super.key});

  @override
  State<HabitListScreen> createState() => _HabitListScreenState();
}

class _HabitListScreenState extends State<HabitListScreen> {
  int _coachMarkVersion = -1;

  @override
  void initState() {
    super.initState();
  }

  void _triggerCoachMark() {
    final v = CoachMarkService.resetVersion;
    if (_coachMarkVersion == v) return;
    _coachMarkVersion = v;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        CoachMarkService.showIfNeeded(
          context: context,
          screenKey: 'coach_mark_habits_shown',
          targets: habitsCoachTargets(),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    _triggerCoachMark();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: MainShellDrawer.of(context),
        ),
        title: BlocBuilder<HabitCubit, HabitState>(
          buildWhen: (p, c) => p.totalCount != c.totalCount,
          builder: (context, state) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Habits',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${state.totalCount}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            key: CoachMarkKeys.habitFilter,
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onPressed: () => _showFilterMenu(context),
          ),
          IconButton(
            key: CoachMarkKeys.habitArchive,
            icon: const Icon(Icons.archive_outlined),
            tooltip: 'Archived habits',
            onPressed: () => _showArchivedSheet(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: BlocBuilder<HabitCubit, HabitState>(
                  builder: (context, state) {
                    if (state.isLoading && state.habits.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state.error != null && state.habits.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: theme.colorScheme.error,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Something went wrong',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                state.error!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              FilledButton.tonal(
                                onPressed: () =>
                                    context.read<HabitCubit>().loadHabits(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final habits = state.habitsForSelectedDate;

                    if (habits.isEmpty) {
                      final hasAnyHabits = state.habits.isNotEmpty;
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              hasAnyHabits
                                  ? 'No habits for this day'
                                  : 'No habits',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hasAnyHabits
                                  ? 'Try selecting a different date'
                                  : "Click '+' to add your first habit",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                      itemCount: habits.length,
                      itemBuilder: (context, index) {
                        final habit = habits[index];
                        return HabitCard(
                          habit: habit,
                          date: state.effectiveDate,
                          onTap: () => context
                              .read<HabitCubit>()
                              .toggleCompletion(habit.id),
                          onEdit: () =>
                              context.go('/habits/edit/${habit.id}'),
                          onArchive: () =>
                              _confirmArchive(context, habit),
                          onDelete: () =>
                              _confirmDelete(context, habit),
                        );
                      },
                    );
                  },
                ),
              ),
              // Date navigator at bottom
              _DateNavigator(key: CoachMarkKeys.habitDateNav),
            ],
          ),

          // Floating fire + completion counter (bottom-right)
          Positioned(
            key: CoachMarkKeys.habitCounter,
            right: 16,
            bottom: 70,
            child: BlocBuilder<HabitCubit, HabitState>(
              buildWhen: (p, c) =>
                  p.completedCount != c.completedCount ||
                  p.totalCount != c.totalCount,
              builder: (context, state) {
                if (state.totalCount == 0) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('\u{1F525}', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 4),
                      Text(
                        '${state.completedCount}/${state.totalCount}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterMenu(BuildContext context) {
    final cubit = context.read<HabitCubit>();
    final RenderBox button = context.findRenderObject() as RenderBox;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        button.size.width - 200,
        kToolbarHeight + MediaQuery.of(context).padding.top,
        16,
        0,
      ),
      items: const [
        PopupMenuItem(value: 'completed', child: Text('Completed first')),
        PopupMenuItem(value: 'incomplete', child: Text('Incomplete first')),
      ],
    ).then((value) {
      if (value == null) return;
      switch (value) {
        case 'completed':
          cubit.setSortOrder(HabitSortOrder.completedFirst);
        case 'incomplete':
          cubit.setSortOrder(HabitSortOrder.incompleteFirst);
      }
    });
  }

  void _confirmArchive(BuildContext context, HabitModel habit) {
    final cubit = context.read<HabitCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Archive habit?'),
        content: Text('Archive "${habit.name}"? You can restore it later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              cubit.archiveHabit(habit.id);
              Navigator.pop(dialogContext);
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, HabitModel habit) {
    final cubit = context.read<HabitCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete habit?'),
        content: Text(
          'Delete "${habit.name}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              cubit.deleteHabit(habit.id);
              Navigator.pop(dialogContext);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showArchivedSheet(BuildContext context) {
    final cubit = context.read<HabitCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ArchivedHabitsSheet(cubit: cubit),
    );
  }
}

class _DateNavigator extends StatelessWidget {
  const _DateNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<HabitCubit, HabitState>(
      buildWhen: (p, c) => p.effectiveDate != c.effectiveDate,
      builder: (context, state) {
        final date = state.effectiveDate;
        final now = DateTime.now();
        final isToday = date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;

        // Format: "Apr, 14" with day number in accent color
        final monthAbbr = DateFormat('MMM').format(date);
        final dayNum = date.day.toString();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outlineVariant,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.chevron_left,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () =>
                      context.read<HabitCubit>().previousDay(),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: isToday
                      ? null
                      : () =>
                          context.read<HabitCubit>().selectDate(now),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$monthAbbr, ',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: dayNum,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.chevron_right,
                    color: isToday
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: isToday
                      ? null
                      : () => context.read<HabitCubit>().nextDay(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ArchivedHabitsSheet extends StatelessWidget {
  const _ArchivedHabitsSheet({required this.cubit});

  final HabitCubit cubit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Archived Habits',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<List<HabitModel>>(
                stream: cubit.watchArchivedHabits(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final archived = snapshot.data!;
                  if (archived.isEmpty) {
                    return Center(
                      child: Text(
                        'No archived habits',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: archived.length,
                    itemBuilder: (context, index) {
                      final habit = archived[index];
                      return ListTile(
                        leading: Text(
                          habit.icon,
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(habit.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () {
                                cubit.unarchiveHabit(habit.id);
                              },
                              child: const Text('Restore'),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                cubit.deleteHabit(habit.id);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
