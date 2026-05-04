import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/utils/share_utils.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/report_pdf_service.dart';
import '../../domain/weight_loss_profile_model.dart';
import '../providers/gym_provider.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool _exporting = false;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  Future<void> _exportPdf(BuildContext context, GymState state,
      {required DateTime rangeStart, required DateTime rangeEnd}) async {
    setState(() => _exporting = true);
    try {
      final authState = context.read<AuthCubit>().state;
      final uid = authState.user?.uid;
      String userName = authState.user?.displayName ?? 'User';
      if (uid != null) {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        final d = snap.data();
        if (d != null) {
          final full = [d['firstName'], d['lastName']]
              .where((s) => s != null && s.toString().isNotEmpty)
              .join(' ');
          if (full.isNotEmpty) userName = full;
          else if (d['displayName'] != null) userName = d['displayName'];
        }
      }

      final pdf = await ReportPdfService.generate(
        state: state,
        userName: userName,
        startDate: rangeStart,
        endDate: rangeEnd,
      );

      final dir = await getTemporaryDirectory();
      final file = XFile(
        '${dir.path}/CoreSyncGo_Report.pdf',
        mimeType: 'application/pdf',
      );
      final bytes = await pdf.save();
      await XFile.fromData(bytes,
              mimeType: 'application/pdf', name: 'CoreSyncGo_Report.pdf')
          .saveTo(file.path);

      if (!mounted) return;
      await shareFiles(
        [file],
        context: context,
        subject: 'CoreSync Go Fitness Report',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

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
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // Membership start (or first of month as fallback)
        final membershipStart = membership != null
            ? DateTime(
                membership.startDate.year,
                membership.startDate.month,
                membership.startDate.day,
              )
            : DateTime(now.year, now.month, 1);

        // User-selected date range (defaults to full membership period)
        final startDate = _rangeStart ?? membershipStart;
        final endDate = _rangeEnd ?? today;

        final presentSet = state.presentDates
            .map((d) => DateTime(d.year, d.month, d.day))
            .toSet();

        // Calculate total days & absent count within range
        int totalDays = 0;
        int absentCount = 0;
        int presentCount = 0;
        final absentDates = <DateTime>[];
        for (var d = startDate;
            !d.isAfter(endDate);
            d = d.add(const Duration(days: 1))) {
          totalDays++;
          if (presentSet.contains(d)) {
            presentCount++;
          } else {
            absentCount++;
            absentDates.add(d);
          }
        }
        final attendanceRate =
            totalDays > 0 ? (presentCount / totalDays * 100) : 0.0;

        // Streaks
        int currentStreak = 0;
        for (var d = endDate;
            !d.isBefore(startDate);
            d = d.subtract(const Duration(days: 1))) {
          if (presentSet.contains(d)) {
            currentStreak++;
          } else {
            break;
          }
        }

        int bestStreak = 0;
        int tempStreak = 0;
        for (var d = startDate;
            !d.isAfter(endDate);
            d = d.add(const Duration(days: 1))) {
          if (presentSet.contains(d)) {
            tempStreak++;
            bestStreak = max(bestStreak, tempStreak);
          } else {
            tempStreak = 0;
          }
        }

        // Water stats (from membership start) — per-day goals
        // Fixed fallback for old days without stored goals (won't change
        // when user updates weight/profile)
        const waterGoalFallback = 2500;
        int waterDaysTracked = 0;
        int waterDaysGoalMet = 0;
        int totalWaterMl = 0;
        for (var d = startDate;
            !d.isAfter(endDate);
            d = d.add(const Duration(days: 1))) {
          final ml = state.waterHistory[d] ?? 0;
          final dayGoal = state.waterGoalHistory[d] ?? waterGoalFallback;
          if (ml > 0) waterDaysTracked++;
          if (dayGoal > 0 && ml >= dayGoal) waterDaysGoalMet++;
          totalWaterMl += ml;
        }
        final avgWaterMl =
            waterDaysTracked > 0 ? totalWaterMl ~/ waterDaysTracked : 0;

        // Steps stats (from membership start) — per-day goals
        const stepsGoalFallback = 10000;
        int stepsDaysTracked = 0;
        int stepsDaysGoalMet = 0;
        int totalSteps = 0;
        for (var d = startDate;
            !d.isAfter(endDate);
            d = d.add(const Duration(days: 1))) {
          final steps = state.stepsHistory[d] ?? 0;
          final dayGoal = state.stepsGoalHistory[d] ?? stepsGoalFallback;
          if (steps > 0) stepsDaysTracked++;
          if (steps >= dayGoal) stepsDaysGoalMet++;
          totalSteps += steps;
        }
        final avgSteps =
            stepsDaysTracked > 0 ? totalSteps ~/ stepsDaysTracked : 0;

        // Food calorie stats — per-day goals
        final foodCalHistory = state.trackedFoodCalorieHistory;
        // Fixed fallback for old days without stored goals
        const calorieGoalFallback = 2000;
        int foodDaysTracked = 0;
        int foodDaysGoalMet = 0;
        double totalFoodCal = 0;
        final goalType = state.weightLossProfile?.goalType;
        for (var d = startDate;
            !d.isAfter(endDate);
            d = d.add(const Duration(days: 1))) {
          final cal = foodCalHistory[d] ?? 0;
          final dayGoal = state.calorieGoalHistory[d] ?? calorieGoalFallback;
          if (cal > 0) foodDaysTracked++;
          if (cal > 0) {
            switch (goalType) {
              case GoalType.lose:
                // Weight loss: equal or up to 500 kcal less than goal
                if (cal <= dayGoal && cal >= dayGoal - 500) foodDaysGoalMet++;
                break;
              case GoalType.gain:
                // Weight gain: equal or up to 500 kcal more than goal
                if (cal >= dayGoal && cal <= dayGoal + 500) foodDaysGoalMet++;
                break;
              default:
                // Maintain: exact match only
                if (cal.round() == dayGoal.round()) foodDaysGoalMet++;
                break;
            }
          }
          totalFoodCal += cal;
        }
        final avgFoodCal =
            foodDaysTracked > 0 ? (totalFoodCal / foodDaysTracked).round() : 0;

        // Sleep stats
        final sleepHist = state.sleepHistory;
        int sleepDaysTracked = 0;
        int totalSleepMin = 0;
        const sleepGoalMin = 480; // 8 hours
        int sleepDaysGoalMet = 0;
        for (var d = startDate;
            !d.isAfter(endDate);
            d = d.add(const Duration(days: 1))) {
          final min = sleepHist[d] ?? 0;
          if (min > 0) sleepDaysTracked++;
          if (min >= sleepGoalMin) sleepDaysGoalMet++;
          totalSleepMin += min;
        }
        final avgSleepMin =
            sleepDaysTracked > 0 ? totalSleepMin ~/ sleepDaysTracked : 0;

        // Build daily lists for collapsible sections (newest first)
        final waterDailyEntries = <MapEntry<DateTime, int>>[];
        for (var d = endDate;
            !d.isBefore(startDate);
            d = d.subtract(const Duration(days: 1))) {
          waterDailyEntries.add(MapEntry(d, state.waterHistory[d] ?? 0));
        }

        final stepsDailyEntries = <MapEntry<DateTime, int>>[];
        for (var d = endDate;
            !d.isBefore(startDate);
            d = d.subtract(const Duration(days: 1))) {
          stepsDailyEntries.add(MapEntry(d, state.stepsHistory[d] ?? 0));
        }

        final foodDailyEntries = <MapEntry<DateTime, int>>[];
        for (var d = endDate;
            !d.isBefore(startDate);
            d = d.subtract(const Duration(days: 1))) {
          foodDailyEntries.add(
              MapEntry(d, (foodCalHistory[d] ?? 0).round()));
        }

        final sleepDailyEntries = <MapEntry<DateTime, int>>[];
        for (var d = endDate;
            !d.isBefore(startDate);
            d = d.subtract(const Duration(days: 1))) {
          sleepDailyEntries.add(MapEntry(d, sleepHist[d] ?? 0));
        }

        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _exporting
                ? null
                : () => _exportPdf(context, state,
                    rangeStart: startDate, rangeEnd: endDate),
            icon: _exporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf),
            label: Text(_exporting ? 'Exporting...' : 'Export PDF'),
          ),
          body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Date Range Picker ──
              Row(
                children: [
                  Expanded(
                    child: ActionChip(
                      avatar: const Icon(Icons.calendar_today, size: 16),
                      label: Text('From: ${dateFormat.format(startDate)}'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: membershipStart,
                          lastDate: endDate,
                        );
                        if (picked != null) {
                          setState(() => _rangeStart = DateTime(
                              picked.year, picked.month, picked.day));
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ActionChip(
                      avatar: const Icon(Icons.calendar_today, size: 16),
                      label: Text('To: ${dateFormat.format(endDate)}'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: endDate,
                          firstDate: startDate,
                          lastDate: today,
                        );
                        if (picked != null) {
                          setState(() => _rangeEnd = DateTime(
                              picked.year, picked.month, picked.day));
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── 4 Summary Stats ──
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 2.2,
                children: [
                  _StatCard(
                    label: 'Present',
                    value: '$presentCount',
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                  _StatCard(
                    label: 'Absent',
                    value: '$absentCount',
                    icon: Icons.cancel,
                    color: Colors.red,
                  ),
                  _StatCard(
                    label: 'Attendance',
                    value: '${attendanceRate.round()}%',
                    icon: Icons.pie_chart,
                    color: attendanceRate >= 80
                        ? Colors.green
                        : attendanceRate >= 50
                            ? Colors.amber.shade700
                            : Colors.red,
                  ),
                  _StatCard(
                    label: 'Streak',
                    value: '$currentStreak days',
                    icon: Icons.local_fire_department,
                    color: Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Membership Card ──
              if (membership != null) ...[
                Card(
                  color: theme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.verified,
                                size: 18,
                                color:
                                    theme.colorScheme.onPrimaryContainer),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                membership.planLabel,
                                style:
                                    theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme
                                      .colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            Text(
                              '${membership.daysRemaining} days left',
                              style:
                                  theme.textTheme.bodySmall?.copyWith(
                                color:
                                    theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              dateFormat.format(membership.startDate),
                              style:
                                  theme.textTheme.bodySmall?.copyWith(
                                color:
                                    theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              dateFormat.format(membership.endDate),
                              style:
                                  theme.textTheme.bodySmall?.copyWith(
                                color:
                                    theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _membershipProgress(membership),
                            minHeight: 6,
                            backgroundColor: theme
                                .colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── Attendance Overview ──
              _SectionHeader(title: 'ATTENDANCE'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _MiniStat(
                              label: 'Current Streak',
                              value: '$currentStreak days',
                              icon: Icons.local_fire_department,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MiniStat(
                              label: 'Best Streak',
                              value: '$bestStreak days',
                              icon: Icons.emoji_events,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _ProgressRow(
                        label: 'Attendance Rate',
                        value: '${attendanceRate.round()}%',
                        progress: attendanceRate / 100,
                        color: attendanceRate >= 80
                            ? Colors.green
                            : attendanceRate >= 50
                                ? Colors.amber.shade700
                                : Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Water Intake ──
              _SectionHeader(title: 'WATER INTAKE'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _MiniStat(
                              label: 'Avg / Day',
                              value:
                                  '${(avgWaterMl / 250).toStringAsFixed(1)} glasses',
                              icon: Icons.water_drop,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MiniStat(
                              label: 'Total',
                              value: totalWaterMl >= 1000
                                  ? '${(totalWaterMl / 1000).toStringAsFixed(1)}L'
                                  : '${totalWaterMl}ml',
                              icon: Icons.local_drink,
                              color: Colors.cyan,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _ProgressRow(
                        label: 'Goal Met',
                        value: '$waterDaysGoalMet / $totalDays days',
                        progress: totalDays > 0
                            ? waterDaysGoalMet / totalDays
                            : 0,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Steps ──
              _SectionHeader(title: 'STEPS'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _MiniStat(
                              label: 'Avg / Day',
                              value: _formatNumber(avgSteps),
                              icon: Icons.directions_walk,
                              color: Colors.teal,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MiniStat(
                              label: 'Total Steps',
                              value: _formatNumber(totalSteps),
                              icon: Icons.trending_up,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _ProgressRow(
                        label: 'Goal Met',
                        value: '$stepsDaysGoalMet / $totalDays days',
                        progress: totalDays > 0
                            ? stepsDaysGoalMet / totalDays
                            : 0,
                        color: Colors.teal,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Food Tracking ──
              _SectionHeader(title: 'FOOD TRACKING'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _MiniStat(
                              label: 'Avg / Day',
                              value: '$avgFoodCal kcal',
                              icon: Icons.restaurant,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MiniStat(
                              label: 'Total',
                              value: '${_formatNumber(totalFoodCal.round())} kcal',
                              icon: Icons.local_fire_department,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _ProgressRow(
                        label: 'Goal Met',
                        value: '$foodDaysGoalMet / $totalDays days',
                        progress: totalDays > 0
                            ? foodDaysGoalMet / totalDays
                            : 0,
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Sleep ──
              _SectionHeader(title: 'SLEEP'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _MiniStat(
                              label: 'Avg / Night',
                              value: '${avgSleepMin ~/ 60}h ${avgSleepMin % 60}m',
                              icon: Icons.bedtime,
                              color: Colors.indigo,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MiniStat(
                              label: 'Days Tracked',
                              value: '$sleepDaysTracked',
                              icon: Icons.calendar_today,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _ProgressRow(
                        label: 'Goal Met (8h)',
                        value: '$sleepDaysGoalMet / $totalDays days',
                        progress: totalDays > 0
                            ? sleepDaysGoalMet / totalDays
                            : 0,
                        color: Colors.indigo,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Present Dates (collapsible, filtered to range) ──
              if (state.presentDates
                  .where((d) {
                    final dn = DateTime(d.year, d.month, d.day);
                    return !dn.isBefore(startDate) && !dn.isAfter(endDate);
                  })
                  .isNotEmpty)
                _CollapsibleDatesSection(
                  title: 'PRESENT DATES',
                  dates: state.presentDates.where((d) {
                    final dn = DateTime(d.year, d.month, d.day);
                    return !dn.isBefore(startDate) && !dn.isAfter(endDate);
                  }).toList(),
                  dateFormat: dateFormat,
                  icon: Icons.check_circle,
                  iconColor: Colors.green,
                  onDelete: (date) => _confirmDelete(context, date),
                ),

              const SizedBox(height: 8),

              // ── Absent Dates (collapsible) ──
              if (absentDates.isNotEmpty)
                _CollapsibleDatesSection(
                  title: 'ABSENT DATES',
                  dates: absentDates.reversed.toList(),
                  dateFormat: dateFormat,
                  icon: Icons.cancel,
                  iconColor: Colors.red,
                ),

              const SizedBox(height: 8),

              // ── Daily Water Intake (collapsible) ──
              _CollapsibleDailySection(
                title: 'DAILY WATER INTAKE',
                entries: waterDailyEntries,
                dateFormat: dateFormat,
                icon: Icons.water_drop,
                goalValue: waterGoalFallback,
                goalHistory: state.waterGoalHistory,
                formatValue: (ml, goal) =>
                    '${(ml / 250).toStringAsFixed(1)} / ${(goal / 250).toStringAsFixed(1)} glasses',
                colorForValue: (ml, goal) => ml == 0
                    ? Colors.red
                    : ml >= goal
                        ? Colors.green
                        : Colors.orange,
              ),

              const SizedBox(height: 8),

              // ── Daily Steps (collapsible) ──
              _CollapsibleDailySection(
                title: 'DAILY STEPS',
                entries: stepsDailyEntries,
                dateFormat: dateFormat,
                icon: Icons.directions_walk,
                goalValue: stepsGoalFallback,
                goalHistory: state.stepsGoalHistory,
                formatValue: (steps, goal) => '$steps / $goal',
                colorForValue: (steps, goal) => steps == 0
                    ? Colors.red
                    : steps >= goal
                        ? Colors.green
                        : Colors.orange,
              ),

              const SizedBox(height: 8),

              // ── Daily Food Calories (collapsible) ──
              _CollapsibleDailySection(
                title: 'DAILY FOOD CALORIES',
                entries: foodDailyEntries,
                dateFormat: dateFormat,
                icon: Icons.restaurant,
                goalValue: calorieGoalFallback,
                goalHistory: Map.fromEntries(
                  state.calorieGoalHistory.entries
                      .map((e) => MapEntry(e.key, e.value.round())),
                ),
                formatValue: (cal, goal) => '$cal / $goal kcal',
                colorForValue: (cal, goal) {
                  if (cal == 0) return Colors.red;
                  switch (goalType) {
                    case GoalType.lose:
                      if (cal <= goal && cal >= goal - 500) return Colors.green;
                      return cal > goal ? Colors.red : Colors.orange;
                    case GoalType.gain:
                      if (cal >= goal && cal <= goal + 500) return Colors.green;
                      return cal < goal ? Colors.red : Colors.orange;
                    default:
                      if (cal == goal) return Colors.green;
                      return cal > goal ? Colors.red : Colors.orange;
                  }
                },
              ),

              const SizedBox(height: 8),

              // ── Daily Sleep (collapsible) ──
              _CollapsibleDailySection(
                title: 'DAILY SLEEP',
                entries: sleepDailyEntries,
                dateFormat: dateFormat,
                icon: Icons.bedtime,
                goalValue: sleepGoalMin,
                formatValue: (min, goal) => min > 0
                    ? '${min ~/ 60}h ${min % 60}m / ${goal ~/ 60}h'
                    : '- / ${goal ~/ 60}h',
                colorForValue: (min, goal) => min == 0
                    ? Colors.red
                    : min >= goal
                        ? Colors.green
                        : Colors.orange,
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
        );
      },
    );
  }

  double _membershipProgress(dynamic membership) {
    final total = membership.endDate.difference(membership.startDate).inDays;
    final elapsed = DateTime.now().difference(membership.startDate).inDays;
    if (total <= 0) return 1.0;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
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

// ─── Widgets ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color color;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.15),
            color: color,
          ),
        ),
      ],
    );
  }
}

class _CollapsibleDatesSection extends StatefulWidget {
  final String title;
  final List<DateTime> dates;
  final DateFormat dateFormat;
  final IconData icon;
  final Color iconColor;
  final Future<bool> Function(DateTime date)? onDelete;

  const _CollapsibleDatesSection({
    required this.title,
    required this.dates,
    required this.dateFormat,
    required this.icon,
    required this.iconColor,
    this.onDelete,
  });

  @override
  State<_CollapsibleDatesSection> createState() =>
      _CollapsibleDatesSectionState();
}

class _CollapsibleDatesSectionState extends State<_CollapsibleDatesSection>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _toggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(
                  widget.title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.dates.length}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: widget.iconColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                RotationTransition(
                  turns: _rotationAnimation,
                  child: Icon(
                    Icons.expand_more,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizeTransition(
          sizeFactor: _expandAnimation,
          child: _expanded || _controller.isAnimating
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.dates.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final date = widget.dates[index];
                        final tile = ListTile(
                          dense: true,
                          leading: Icon(widget.icon,
                              color: widget.iconColor, size: 20),
                          title: Text(widget.dateFormat.format(date)),
                        );
                        if (widget.onDelete != null) {
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
                            confirmDismiss: (_) => widget.onDelete!(date),
                            child: tile,
                          );
                        }
                        return tile;
                      },
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _CollapsibleDailySection extends StatefulWidget {
  final String title;
  final List<MapEntry<DateTime, int>> entries;
  final DateFormat dateFormat;
  final IconData icon;
  final int goalValue;
  final String Function(int value, int goalForDay) formatValue;
  final Color Function(int value, int goalForDay) colorForValue;
  final Map<DateTime, int> goalHistory;

  const _CollapsibleDailySection({
    required this.title,
    required this.entries,
    required this.dateFormat,
    required this.icon,
    required this.goalValue,
    required this.formatValue,
    required this.colorForValue,
    this.goalHistory = const {},
  });

  @override
  State<_CollapsibleDailySection> createState() =>
      _CollapsibleDailySectionState();
}

class _CollapsibleDailySectionState extends State<_CollapsibleDailySection>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trackedCount = widget.entries.where((e) => e.value > 0).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _toggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(
                  widget.title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '$trackedCount / ${widget.entries.length} days',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                RotationTransition(
                  turns: _rotationAnimation,
                  child: Icon(
                    Icons.expand_more,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizeTransition(
          sizeFactor: _expandAnimation,
          child: _expanded || _controller.isAnimating
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.entries.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final entry = widget.entries[index];
                        final dayGoal = widget.goalHistory[entry.key] ?? widget.goalValue;
                        final color = widget.colorForValue(entry.value, dayGoal);
                        return ListTile(
                          dense: true,
                          leading: Icon(widget.icon, color: color, size: 20),
                          title: Text(widget.dateFormat.format(entry.key)),
                          trailing: Text(
                            widget.formatValue(entry.value, dayGoal),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}