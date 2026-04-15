import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/habit_model.dart';
import '../providers/habit_provider.dart';

class HabitChartScreen extends StatefulWidget {
  const HabitChartScreen({super.key});

  @override
  State<HabitChartScreen> createState() => _HabitChartScreenState();
}

class _HabitChartScreenState extends State<HabitChartScreen> {
  String _period = 'W'; // W, 2W, M
  bool _isBarChart = true; // true=bar, false=line
  bool _isPercent = true; // true=percent, false=quantity

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

  List<DateTime> get _days {
    switch (_period) {
      case 'W':
        return List.generate(7, (i) => _rangeStart.add(Duration(days: i)));
      case '2W':
        return List.generate(14, (i) => _rangeStart.add(Duration(days: i)));
      case 'M':
        final daysInMonth =
            DateTime(_rangeStart.year, _rangeStart.month + 1, 0).day;
        return List.generate(
          daysInMonth,
          (i) => DateTime(_rangeStart.year, _rangeStart.month, i + 1),
        );
      default:
        return [];
    }
  }

  DateTime get _rangeEnd {
    final days = _days;
    return days.isNotEmpty ? days.last : _rangeStart;
  }

  void _previousRange() {
    setState(() {
      switch (_period) {
        case 'W':
          _rangeStart = _rangeStart.subtract(const Duration(days: 7));
        case '2W':
          _rangeStart = _rangeStart.subtract(const Duration(days: 14));
        case 'M':
          _rangeStart = DateTime(_rangeStart.year, _rangeStart.month - 1, 1);
      }
    });
  }

  void _nextRange() {
    setState(() {
      switch (_period) {
        case 'W':
          _rangeStart = _rangeStart.add(const Duration(days: 7));
        case '2W':
          _rangeStart = _rangeStart.add(const Duration(days: 14));
        case 'M':
          _rangeStart = DateTime(_rangeStart.year, _rangeStart.month + 1, 1);
      }
    });
  }

  void _changePeriod(String period) {
    setState(() {
      _period = period;
      final now = DateTime.now();
      switch (period) {
        case 'W':
          _rangeStart = _weekStart(now);
        case '2W':
          _rangeStart = _weekStart(now).subtract(const Duration(days: 7));
        case 'M':
          _rangeStart = DateTime(now.year, now.month, 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Chart',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.bar_chart_rounded, color: Colors.white),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: BlocBuilder<HabitCubit, HabitState>(
        builder: (context, state) {
          final habits = state.habits;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 8),

                // Period toggle (W, 2W, M)
                _PeriodToggle(
                  selected: _period,
                  onChanged: _changePeriod,
                  theme: theme,
                ),
                const SizedBox(height: 16),

                // Chart card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Chart header + type toggles
                        Row(
                          children: [
                            Text(
                              'Chart',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            _ChartTypeToggle(
                              icon: Icons.show_chart,
                              isSelected: !_isBarChart,
                              onTap: () =>
                                  setState(() => _isBarChart = false),
                              theme: theme,
                            ),
                            const SizedBox(width: 8),
                            _ChartTypeToggle(
                              icon: Icons.bar_chart_rounded,
                              isSelected: _isBarChart,
                              onTap: () =>
                                  setState(() => _isBarChart = true),
                              theme: theme,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Quantity / Percent toggle
                        Row(
                          children: [
                            Expanded(
                              child: _DataModeToggle(
                                label: 'Quantity',
                                isSelected: !_isPercent,
                                onTap: () =>
                                    setState(() => _isPercent = false),
                                theme: theme,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _DataModeToggle(
                                label: 'Percent',
                                isSelected: _isPercent,
                                onTap: () =>
                                    setState(() => _isPercent = true),
                                theme: theme,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // The chart
                        SizedBox(
                          height: 280,
                          child: _buildChart(habits, theme),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Date range navigator
                _DateRangeNavigator(
                  rangeStart: _rangeStart,
                  rangeEnd: _rangeEnd,
                  onPrevious: _previousRange,
                  onNext: _nextRange,
                  theme: theme,
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChart(List<HabitModel> habits, ThemeData theme) {
    final days = _days;
    if (days.isEmpty || habits.isEmpty) {
      return const Center(child: Text('No data'));
    }

    // Calculate values for each day
    // For "Percent" mode: percentage of habits completed that day
    // For "Quantity" mode: total completions that day
    final values = <double>[];
    final topLabels = <String>[];
    double maxY = 1;

    for (final day in days) {
      if (_isPercent) {
        int scheduled = 0;
        int completed = 0;
        for (final habit in habits) {
          if (habit.isScheduledOn(day)) {
            scheduled++;
            if (habit.isCompletedOn(day)) completed++;
          }
        }
        final pct = scheduled > 0 ? (completed / scheduled * 100) : 0.0;
        values.add(pct);
        topLabels.add('${pct.round()}%');
        if (pct > maxY) maxY = pct;
      } else {
        double total = 0;
        for (final habit in habits) {
          total += habit.completionsOnDate(day).toDouble();
        }
        values.add(total);
        topLabels.add('${total.toInt()}');
        if (total > maxY) maxY = total;
      }
    }

    if (maxY == 0) maxY = _isPercent ? 100 : 1;
    final chartMaxY = _isPercent ? 100.0 : maxY + 1;

    if (_isBarChart) {
      return _buildBarChart(days, values, topLabels, chartMaxY, theme);
    } else {
      return _buildLineChart(days, values, topLabels, chartMaxY, theme);
    }
  }

  Widget _buildBarChart(List<DateTime> days, List<double> values,
      List<String> topLabels, double chartMaxY, ThemeData theme) {
    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < days.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: values[i],
              color: theme.colorScheme.primary,
              width: _period == 'M' ? 6 : _period == '2W' ? 10 : 20,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: chartMaxY,
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
              ),
            ),
          ],
          showingTooltipIndicators: [],
        ),
      );
    }

    return Column(
      children: [
        // Top labels row
        SizedBox(
          height: 20,
          child: Row(
            children: [
              const SizedBox(width: 40),
              ...List.generate(days.length, (i) {
                return Expanded(
                  child: Center(
                    child: Text(
                      topLabels[i],
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 8,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        Expanded(
          child: BarChart(
            BarChartData(
              maxY: chartMaxY,
              barGroups: barGroups,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _isPercent ? 10 : (chartMaxY / 5).ceilToDouble().clamp(1, double.infinity),
                getDrawingHorizontalLine: (value) => FlLine(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  strokeWidth: 1,
                ),
              ),
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
                    reservedSize: 40,
                    interval: _isPercent ? 10 : null,
                    getTitlesWidget: (value, meta) {
                      if (_isPercent) {
                        if (value % 10 == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              '${value.toInt()}%',
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(fontSize: 9),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                      if (value == value.roundToDouble()) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            '${value.toInt()}',
                            style: theme.textTheme.labelSmall,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) =>
                        _bottomLabel(value.toInt(), days, theme),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart(List<DateTime> days, List<double> values,
      List<String> topLabels, double chartMaxY, ThemeData theme) {
    final spots = <FlSpot>[];
    for (int i = 0; i < days.length; i++) {
      spots.add(FlSpot(i.toDouble(), values[i]));
    }

    return Column(
      children: [
        // Top labels row
        SizedBox(
          height: 20,
          child: Row(
            children: [
              const SizedBox(width: 40),
              ...List.generate(days.length, (i) {
                return Expanded(
                  child: Center(
                    child: Text(
                      topLabels[i],
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 8,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        Expanded(
          child: LineChart(
            LineChartData(
              maxY: chartMaxY,
              minY: 0,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: false,
                  color: Colors.deepOrange,
                  barWidth: 2,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.deepOrange.withValues(alpha: 0.08),
                  ),
                ),
              ],
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _isPercent ? 10 : (chartMaxY / 5).ceilToDouble().clamp(1, double.infinity),
                getDrawingHorizontalLine: (value) => FlLine(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  left: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                  bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
              ),
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
                    reservedSize: 40,
                    interval: _isPercent ? 10 : null,
                    getTitlesWidget: (value, meta) {
                      if (_isPercent) {
                        if (value % 10 == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              '${value.toInt()}%',
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(fontSize: 9),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                      if (value == value.roundToDouble()) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            '${value.toInt()}',
                            style: theme.textTheme.labelSmall,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) =>
                        _bottomLabel(value.toInt(), days, theme),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomLabel(int index, List<DateTime> days, ThemeData theme) {
    if (index < 0 || index >= days.length) return const SizedBox.shrink();
    final day = days[index];
    // For month view, show every 5th
    if (_period == 'M' && day.day % 5 != 1 && day.day != 1) {
      return const SizedBox.shrink();
    }
    // For 2W, show every other
    if (_period == '2W' && index % 2 != 0) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '${day.day}',
        style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
      ),
    );
  }
}

// ── Period Toggle (W, 2W, M) ──

class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({
    required this.selected,
    required this.onChanged,
    required this.theme,
  });

  final String selected;
  final ValueChanged<String> onChanged;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: ['W', '2W', 'M'].map((p) {
          final isSelected = p == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(p),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.primary : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    p,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Chart Type Toggle (line/bar icons) ──

class _ChartTypeToggle extends StatelessWidget {
  const _ChartTypeToggle({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color:
              isSelected ? theme.colorScheme.primary : Colors.transparent,
          shape: BoxShape.circle,
          border: isSelected
              ? null
              : Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Icon(
          icon,
          color: isSelected
              ? Colors.white
              : theme.colorScheme.onSurfaceVariant,
          size: 22,
        ),
      ),
    );
  }
}

// ── Data Mode Toggle (Quantity/Percent) ──

class _DataModeToggle extends StatelessWidget {
  const _DataModeToggle({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? null
              : Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: isSelected
                  ? Colors.white
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Date Range Navigator ──

class _DateRangeNavigator extends StatelessWidget {
  const _DateRangeNavigator({
    required this.rangeStart,
    required this.rangeEnd,
    required this.onPrevious,
    required this.onNext,
    required this.theme,
  });

  final DateTime rangeStart;
  final DateTime rangeEnd;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final startLabel =
        '${DateFormat('MMM').format(rangeStart)}, ${rangeStart.day.toString().padLeft(2, '0')}';
    final endLabel =
        '${DateFormat('MMM').format(rangeEnd)}, ${rangeEnd.day.toString().padLeft(2, '0')}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left, color: theme.colorScheme.primary),
          onPressed: onPrevious,
        ),
        const SizedBox(width: 8),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: startLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              TextSpan(
                text: ' \u2013 ',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text: endLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant),
          onPressed: onNext,
        ),
      ],
    );
  }
}