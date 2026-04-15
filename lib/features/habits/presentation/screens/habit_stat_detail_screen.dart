import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/habit_model.dart';
import '../providers/habit_provider.dart';

class HabitStatDetailScreen extends StatefulWidget {
  const HabitStatDetailScreen({super.key, required this.habit});
  final HabitModel habit;

  @override
  State<HabitStatDetailScreen> createState() => _HabitStatDetailScreenState();
}

class _HabitStatDetailScreenState extends State<HabitStatDetailScreen> {
  late DateTime _displayMonth;
  late int _selectedYear;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayMonth = DateTime(now.year, now.month, 1);
    _selectedYear = now.year;
  }

  void _previousMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1, 1);
    });
  }

  void _onDateTapped(DateTime date) {
    setState(() {
      if (_selectedDate != null &&
          _selectedDate!.year == date.year &&
          _selectedDate!.month == date.month &&
          _selectedDate!.day == date.day) {
        _selectedDate = null;
      } else {
        _selectedDate = date;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<HabitCubit, HabitState>(
      builder: (context, state) {
        final habit = state.habits.firstWhere(
          (h) => h.id == widget.habit.id,
          orElse: () => widget.habit,
        );

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              habit.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Calendar
                _MonthCalendar(
                  displayMonth: _displayMonth,
                  habit: habit,
                  selectedDate: _selectedDate,
                  onPreviousMonth: _previousMonth,
                  onNextMonth: _nextMonth,
                  onDateTapped: _onDateTapped,
                  theme: theme,
                ),

                // Selected date info
                if (_selectedDate != null) ...[
                  const SizedBox(height: 12),
                  _SelectedDateInfo(
                    date: _selectedDate!,
                    habit: habit,
                    theme: theme,
                  ),
                ],

                const SizedBox(height: 20),

                // Yearly status grid
                _YearlyStatusGrid(
                  habit: habit,
                  year: _selectedYear,
                  onYearChanged: (y) => setState(() => _selectedYear = y),
                  theme: theme,
                ),
                const SizedBox(height: 20),

                // Stats cards
                _StatsCards(
                  habit: habit,
                  displayMonth: _displayMonth,
                  theme: theme,
                ),

                const SizedBox(height: 20),

                // Weekly chart
                _WeeklyChart(habit: habit, theme: theme),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Selected Date Info ──

class _SelectedDateInfo extends StatelessWidget {
  const _SelectedDateInfo({
    required this.date,
    required this.habit,
    required this.theme,
  });

  final DateTime date;
  final HabitModel habit;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scheduled = habit.isScheduledOn(date);
    final completed = scheduled && habit.isCompletedOn(date);
    final count = habit.completionsOnDate(date);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              completed
                  ? Icons.check_circle
                  : scheduled
                      ? Icons.radio_button_unchecked
                      : Icons.block,
              color: completed
                  ? Colors.green
                  : scheduled
                      ? theme.colorScheme.onSurfaceVariant
                      : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, MMM d, yyyy').format(date),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    !scheduled
                        ? 'Not scheduled'
                        : completed
                            ? 'Completed ($count)'
                            : 'Not completed',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Month Calendar with selectable dates ──

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.displayMonth,
    required this.habit,
    required this.selectedDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onDateTapped,
    required this.theme,
  });

  final DateTime displayMonth;
  final HabitModel habit;
  final DateTime? selectedDate;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onDateTapped;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth =
        DateTime(displayMonth.year, displayMonth.month + 1, 0).day;
    final firstWeekday =
        DateTime(displayMonth.year, displayMonth.month, 1).weekday;
    final startOffset = firstWeekday % 7;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(displayMonth),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 22),
                  onPressed: onPreviousMonth,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 22),
                  onPressed: onNextMonth,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT']
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            ...List.generate(6, (row) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: List.generate(7, (col) {
                    final dayIndex = row * 7 + col - startOffset + 1;
                    if (dayIndex < 1 || dayIndex > daysInMonth) {
                      return const Expanded(child: SizedBox(height: 36));
                    }

                    final date = DateTime(
                      displayMonth.year,
                      displayMonth.month,
                      dayIndex,
                    );
                    final isToday = date.year == now.year &&
                        date.month == now.month &&
                        date.day == now.day;
                    final isCompleted =
                        habit.isScheduledOn(date) && habit.isCompletedOn(date);
                    final isSelected = selectedDate != null &&
                        selectedDate!.year == date.year &&
                        selectedDate!.month == date.month &&
                        selectedDate!.day == date.day;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onDateTapped(date),
                        child: Center(
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : isToday
                                      ? theme.colorScheme.primary
                                      : isCompleted
                                          ? theme.colorScheme.primary
                                              .withValues(alpha: 0.15)
                                          : null,
                              border: isSelected && !isToday
                                  ? null
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                '$dayIndex',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: (isToday || isSelected)
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: (isToday || isSelected)
                                      ? Colors.white
                                      : isCompleted
                                          ? theme.colorScheme.primary
                                          : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Yearly Status Grid ──

class _YearlyStatusGrid extends StatelessWidget {
  const _YearlyStatusGrid({
    required this.habit,
    required this.year,
    required this.onYearChanged,
    required this.theme,
  });

  final HabitModel habit;
  final int year;
  final ValueChanged<int> onYearChanged;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    int totalCompleted = 0;
    int totalScheduled = 0;
    final now = DateTime.now();

    final firstDay = DateTime(year, 1, 1);
    final lastDay = DateTime(year, 12, 31);
    final totalDays = lastDay.difference(firstDay).inDays + 1;

    final dayStatuses = <bool?>[];
    for (int i = 0; i < totalDays; i++) {
      final date = firstDay.add(Duration(days: i));
      if (date.isAfter(now)) {
        dayStatuses.add(null);
        continue;
      }
      if (!habit.isScheduledOn(date)) {
        dayStatuses.add(null);
        continue;
      }
      totalScheduled++;
      if (habit.isCompletedOn(date)) {
        totalCompleted++;
        dayStatuses.add(true);
      } else {
        dayStatuses.add(false);
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Yearly status',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                PopupMenuButton<int>(
                  onSelected: onYearChanged,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$year', style: theme.textTheme.labelLarge),
                        const Icon(Icons.keyboard_arrow_down, size: 16),
                      ],
                    ),
                  ),
                  itemBuilder: (_) => [
                    for (int y = now.year; y >= now.year - 3; y--)
                      PopupMenuItem(value: y, child: Text('$y')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: Wrap(
                spacing: 2,
                runSpacing: 2,
                children: dayStatuses.map((status) {
                  Color color;
                  if (status == null) {
                    color = theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.3);
                  } else if (status) {
                    color = theme.colorScheme.primary;
                  } else {
                    color = theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.3);
                  }
                  return Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$totalCompleted/$totalScheduled',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stats Cards ──

class _StatsCards extends StatelessWidget {
  const _StatsCards({
    required this.habit,
    required this.displayMonth,
    required this.theme,
  });

  final HabitModel habit;
  final DateTime displayMonth;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final doneInMonth = habit.daysCompletedInMonth(
      displayMonth.year,
      displayMonth.month,
    );
    final totalDone = habit.totalDaysDone;
    final streak = habit.currentStreak;
    final bestStreak = habit.bestStreak;
    final monthName = DateFormat('MMMM').format(displayMonth);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.local_fire_department,
                iconColor: Colors.deepOrange,
                value: '$doneInMonth Days',
                label: 'Done in $monthName',
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle,
                iconColor: Colors.green,
                value: '$totalDone Days',
                label: 'Total done',
                theme: theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.local_fire_department,
                iconColor: Colors.red,
                value: '$streak Days',
                label: 'Streak',
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.emoji_events,
                iconColor: Colors.amber,
                value: '$bestStreak Days',
                label: 'Best streak',
                theme: theme,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.theme,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
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
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Weekly Line+Bar Chart in detail screen ──

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.habit, required this.theme});

  final HabitModel habit;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(
      7,
      (i) => now.subtract(Duration(days: 6 - i)),
    );

    final spots = <FlSpot>[];
    final barGroups = <BarChartGroupData>[];
    double maxY = 1;

    for (int i = 0; i < 7; i++) {
      final value = habit.completionsOnDate(days[i]).toDouble();
      if (value > maxY) maxY = value;
      spots.add(FlSpot(i.toDouble(), value));
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: value,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
              width: 14,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }
    if (maxY == 0) maxY = 1;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last 7 days',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: BarChart(
                BarChartData(
                  maxY: maxY + 1,
                  barGroups: barGroups,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          if (value == value.roundToDouble()) {
                            return Text(
                              '${value.toInt()}',
                              style: theme.textTheme.labelSmall,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= 7) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              DateFormat('E')
                                  .format(days[idx])
                                  .substring(0, 1),
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}