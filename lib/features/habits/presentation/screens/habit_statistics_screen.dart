import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/habit_model.dart';
import '../providers/habit_provider.dart';
import 'habit_chart_screen.dart';
import 'habit_stat_detail_screen.dart';

class HabitStatisticsScreen extends StatefulWidget {
  const HabitStatisticsScreen({super.key});

  @override
  State<HabitStatisticsScreen> createState() => _HabitStatisticsScreenState();
}

class _HabitStatisticsScreenState extends State<HabitStatisticsScreen> {
  String _period = 'Week';
  late DateTime _rangeStart;

  @override
  void initState() {
    super.initState();
    _rangeStart = _weekStart(DateTime.now());
  }

  static DateTime _weekStart(DateTime date) {
    final diff = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - diff);
  }

  DateTime get _rangeEnd {
    switch (_period) {
      case 'Week':
        return _rangeStart.add(const Duration(days: 6));
      case 'Month':
        return DateTime(_rangeStart.year, _rangeStart.month + 1, 0);
      case 'Year':
        return DateTime(_rangeStart.year, 12, 31);
      default:
        return _rangeStart.add(const Duration(days: 6));
    }
  }

  void _changePeriod(String period) {
    setState(() {
      _period = period;
      final now = DateTime.now();
      switch (period) {
        case 'Week':
          _rangeStart = _weekStart(now);
        case 'Month':
          _rangeStart = DateTime(now.year, now.month, 1);
        case 'Year':
          _rangeStart = DateTime(now.year, 1, 1);
      }
    });
  }

  void _previousRange() {
    setState(() {
      switch (_period) {
        case 'Week':
          _rangeStart = _rangeStart.subtract(const Duration(days: 7));
        case 'Month':
          _rangeStart = DateTime(_rangeStart.year, _rangeStart.month - 1, 1);
        case 'Year':
          _rangeStart = DateTime(_rangeStart.year - 1, 1, 1);
      }
    });
  }

  bool get _isCurrentRange {
    final now = DateTime.now();
    switch (_period) {
      case 'Week':
        final currentWeekStart = _weekStart(now);
        return !_rangeStart.isBefore(currentWeekStart);
      case 'Month':
        return _rangeStart.year == now.year && _rangeStart.month == now.month;
      case 'Year':
        return _rangeStart.year == now.year;
      default:
        return false;
    }
  }

  void _nextRange() {
    if (_isCurrentRange) return;
    setState(() {
      switch (_period) {
        case 'Week':
          _rangeStart = _rangeStart.add(const Duration(days: 7));
        case 'Month':
          _rangeStart = DateTime(_rangeStart.year, _rangeStart.month + 1, 1);
        case 'Year':
          _rangeStart = DateTime(_rangeStart.year + 1, 1, 1);
      }
    });
  }

  String get _rangeLabel {
    switch (_period) {
      case 'Week':
        final end = _rangeEnd;
        return '${DateFormat('MMM d').format(_rangeStart)} \u2013 ${DateFormat('MMM d').format(end)}';
      case 'Month':
        return DateFormat('MMMM yyyy').format(_rangeStart);
      case 'Year':
        return '${_rangeStart.year}';
      default:
        return '';
    }
  }

  List<DateTime> get _periodDays {
    switch (_period) {
      case 'Week':
        return List.generate(7, (i) => _rangeStart.add(Duration(days: i)));
      case 'Month':
        final daysInMonth =
            DateTime(_rangeStart.year, _rangeStart.month + 1, 0).day;
        return List.generate(
          daysInMonth,
          (i) => DateTime(_rangeStart.year, _rangeStart.month, i + 1),
        );
      case 'Year':
        return List.generate(
          12,
          (i) => DateTime(_rangeStart.year, i + 1, 1),
        );
      default:
        return [];
    }
  }

  int _totalCompletedInRange(HabitModel habit) {
    if (_period == 'Year') {
      int total = 0;
      for (int m = 1; m <= 12; m++) {
        total += habit.daysCompletedInMonth(_rangeStart.year, m);
      }
      return total;
    }
    int count = 0;
    for (final day in _periodDays) {
      if (habit.isScheduledOn(day) && habit.isCompletedOn(day)) count++;
    }
    return count;
  }

  int _totalScheduledInRange(HabitModel habit) {
    if (_period == 'Year') {
      int total = 0;
      final now = DateTime.now();
      for (int m = 1; m <= 12; m++) {
        final daysInMonth = DateTime(_rangeStart.year, m + 1, 0).day;
        for (int d = 1; d <= daysInMonth; d++) {
          final date = DateTime(_rangeStart.year, m, d);
          if (date.isAfter(now)) break;
          if (habit.isScheduledOn(date)) total++;
        }
      }
      return total;
    }
    int count = 0;
    final now = DateTime.now();
    for (final day in _periodDays) {
      if (day.isAfter(now)) break;
      if (habit.isScheduledOn(day)) count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Statistics',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.bar_chart_rounded,
              color: theme.colorScheme.primary,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<HabitCubit>(),
                    child: const HabitChartScreen(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<HabitCubit, HabitState>(
        builder: (context, state) {
          final habits = state.habits;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period header
                _PeriodHeader(
                  rangeLabel: _rangeLabel,
                  period: _period,
                  onPrevious: _previousRange,
                  onNext: _isCurrentRange ? null : _nextRange,
                  onChangePeriod: _changePeriod,
                  theme: theme,
                ),
                const SizedBox(height: 8),

                // Period-specific day cells
                if (_period == 'Week')
                  _WeekDayCells(
                    days: _periodDays,
                    habits: habits,
                    theme: theme,
                    selectedDate: state.selectedDate,
                    onDateSelected: (date) =>
                        context.read<HabitCubit>().selectDate(date),
                  ),
                if (_period == 'Month')
                  _MonthDayCells(
                    rangeStart: _rangeStart,
                    habits: habits,
                    theme: theme,
                    selectedDate: state.selectedDate,
                    onDateSelected: (date) =>
                        context.read<HabitCubit>().selectDate(date),
                  ),
                if (_period == 'Year')
                  _YearMonthCells(
                    rangeStart: _rangeStart,
                    habits: habits,
                    theme: theme,
                  ),

                const SizedBox(height: 16),

                // Habits list with progress
                ...habits.map((habit) {
                  final completed = _totalCompletedInRange(habit);
                  final scheduled = _totalScheduledInRange(habit);

                  return _StatHabitCard(
                    habit: habit,
                    completed: completed,
                    scheduled: scheduled,
                    periodDays: _period == 'Week' ? _periodDays : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: context.read<HabitCubit>(),
                            child: HabitStatDetailScreen(habit: habit),
                          ),
                        ),
                      );
                    },
                    theme: theme,
                  );
                }),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Period Header ──

class _PeriodHeader extends StatelessWidget {
  const _PeriodHeader({
    required this.rangeLabel,
    required this.period,
    required this.onPrevious,
    required this.onNext,
    required this.onChangePeriod,
    required this.theme,
  });

  final String rangeLabel;
  final String period;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<String> onChangePeriod;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: onPrevious,
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: Text(
                rangeLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: onNext,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: const Icon(Icons.filter_list, size: 20),
              onPressed: () {},
              visualDensity: VisualDensity.compact,
            ),
            PopupMenuButton<String>(
              onSelected: onChangePeriod,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      period,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'Week', child: Text('Week')),
                PopupMenuItem(value: 'Month', child: Text('Month')),
                PopupMenuItem(value: 'Year', child: Text('Year')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Week Day Cells ──

class _WeekDayCells extends StatelessWidget {
  const _WeekDayCells({
    required this.days,
    required this.habits,
    required this.theme,
    required this.onDateSelected,
    this.selectedDate,
  });

  final List<DateTime> days;
  final List<HabitModel> habits;
  final ThemeData theme;
  final ValueChanged<DateTime> onDateSelected;
  final DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Row(
      children: days.map((day) {
        int completedCount = 0;
        for (final habit in habits) {
          if (habit.isScheduledOn(day) && habit.isCompletedOn(day)) {
            completedCount++;
          }
        }
        final isToday = _isToday(day);
        final isFuture = day.isAfter(now);
        final isSelected = selectedDate != null &&
            day.year == selectedDate!.year &&
            day.month == selectedDate!.month &&
            day.day == selectedDate!.day;

        return Expanded(
          child: GestureDetector(
            onTap: isFuture ? null : () => onDateSelected(day),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.2)
                    : isToday
                        ? theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.5)
                        : theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: isSelected
                    ? Border.all(
                        color: theme.colorScheme.primary,
                        width: 2,
                      )
                    : null,
              ),
              child: Column(
                children: [
                  Text(
                    '${day.day}.${day.month.toString().padLeft(2, '0')}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$completedCount',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('E').format(day).substring(0, 3),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }
}

// ── Month Day Cells (scrollable) ──

class _MonthDayCells extends StatelessWidget {
  const _MonthDayCells({
    required this.rangeStart,
    required this.habits,
    required this.theme,
    required this.onDateSelected,
    this.selectedDate,
  });

  final DateTime rangeStart;
  final List<HabitModel> habits;
  final ThemeData theme;
  final ValueChanged<DateTime> onDateSelected;
  final DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateTime(rangeStart.year, rangeStart.month + 1, 0).day;
    final now = DateTime.now();

    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: daysInMonth,
        itemBuilder: (context, i) {
          final day = DateTime(rangeStart.year, rangeStart.month, i + 1);
          int completedCount = 0;
          for (final habit in habits) {
            if (habit.isScheduledOn(day) && habit.isCompletedOn(day)) {
              completedCount++;
            }
          }
          final isToday = day.year == now.year &&
              day.month == now.month &&
              day.day == now.day;
          final isFuture = day.isAfter(now);
          final isSelected = selectedDate != null &&
              day.year == selectedDate!.year &&
              day.month == selectedDate!.month &&
              day.day == selectedDate!.day;

          return GestureDetector(
            onTap: isFuture ? null : () => onDateSelected(day),
            child: Container(
              width: 48,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.2)
                    : isToday
                        ? theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.5)
                        : theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: isSelected
                    ? Border.all(
                        color: theme.colorScheme.primary,
                        width: 2,
                      )
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${day.day}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$completedCount',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('E').format(day).substring(0, 2),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Year Month Cells ──

class _YearMonthCells extends StatelessWidget {
  const _YearMonthCells({
    required this.rangeStart,
    required this.habits,
    required this.theme,
  });

  final DateTime rangeStart;
  final List<HabitModel> habits;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(12, (i) {
        final month = DateTime(rangeStart.year, i + 1, 1);
        int completedCount = 0;
        for (final habit in habits) {
          completedCount +=
              habit.daysCompletedInMonth(rangeStart.year, i + 1);
        }
        final isCurrentMonth =
            month.year == now.year && month.month == now.month;

        return Container(
          width: 78,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isCurrentMonth
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                : theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                DateFormat('MMM').format(month),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$completedCount',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ── Stat Habit Card ──

class _StatHabitCard extends StatelessWidget {
  const _StatHabitCard({
    required this.habit,
    required this.completed,
    required this.scheduled,
    this.periodDays,
    required this.onTap,
    required this.theme,
  });

  final HabitModel habit;
  final int completed;
  final int scheduled;
  final List<DateTime>? periodDays;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(habit.icon, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        habit.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(Icons.star, color: Colors.orange.shade300, size: 20),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: completed > 0
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$completed/$scheduled',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: completed > 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (periodDays != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: periodDays!.map((day) {
                      final done =
                          habit.isScheduledOn(day) && habit.isCompletedOn(day);
                      final isScheduled = habit.isScheduledOn(day);
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 3),
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: !isScheduled
                                  ? theme.colorScheme.surfaceContainerHighest
                                  : done
                                      ? Colors.green
                                      : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
