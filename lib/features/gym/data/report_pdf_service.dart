import 'dart:math';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/weight_loss_profile_model.dart';
import '../presentation/providers/gym_provider.dart';

class ReportPdfService {
  static Future<pw.Document> generate({
    required GymState state,
    required String userName,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy', 'en_US');
    final today = endDate;

    final membership = state.activeMembership;

    // ── Compute all stats (mirrors report_screen.dart) ──

    final presentSet =
        state.presentDates.map((d) => DateTime(d.year, d.month, d.day)).toSet();

    int totalDays = 0;
    int absentCount = 0;
    int presentCount = 0;
    for (var d = startDate;
        !d.isAfter(today);
        d = d.add(const Duration(days: 1))) {
      totalDays++;
      if (presentSet.contains(d)) {
        presentCount++;
      } else {
        absentCount++;
      }
    }
    final attendanceRate =
        totalDays > 0 ? (presentCount / totalDays * 100) : 0.0;

    int currentStreak = 0;
    for (var d = today;
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
        !d.isAfter(today);
        d = d.add(const Duration(days: 1))) {
      if (presentSet.contains(d)) {
        tempStreak++;
        bestStreak = max(bestStreak, tempStreak);
      } else {
        tempStreak = 0;
      }
    }

    // Water
    const waterGoalFallback = 2500;
    int waterDaysTracked = 0;
    int waterDaysGoalMet = 0;
    int totalWaterMl = 0;
    final waterDaily = <_DailyEntry>[];
    for (var d = startDate;
        !d.isAfter(today);
        d = d.add(const Duration(days: 1))) {
      final ml = state.waterHistory[d] ?? 0;
      final dayGoal = state.waterGoalHistory[d] ?? waterGoalFallback;
      if (ml > 0) waterDaysTracked++;
      if (dayGoal > 0 && ml >= dayGoal) waterDaysGoalMet++;
      totalWaterMl += ml;
      waterDaily.add(_DailyEntry(d, ml, dayGoal));
    }
    final avgWaterMl =
        waterDaysTracked > 0 ? totalWaterMl ~/ waterDaysTracked : 0;

    // Steps
    const stepsGoalFallback = 10000;
    int stepsDaysTracked = 0;
    int stepsDaysGoalMet = 0;
    int totalSteps = 0;
    final stepsDaily = <_DailyEntry>[];
    for (var d = startDate;
        !d.isAfter(today);
        d = d.add(const Duration(days: 1))) {
      final steps = state.stepsHistory[d] ?? 0;
      final dayGoal = state.stepsGoalHistory[d] ?? stepsGoalFallback;
      if (steps > 0) stepsDaysTracked++;
      if (steps >= dayGoal) stepsDaysGoalMet++;
      totalSteps += steps;
      stepsDaily.add(_DailyEntry(d, steps, dayGoal));
    }
    final avgSteps =
        stepsDaysTracked > 0 ? totalSteps ~/ stepsDaysTracked : 0;

    // Food
    final foodCalHistory = state.trackedFoodCalorieHistory;
    const calorieGoalFallback = 2000;
    int foodDaysTracked = 0;
    int foodDaysGoalMet = 0;
    double totalFoodCal = 0;
    final foodDaily = <_DailyEntry>[];
    final goalType = state.weightLossProfile?.goalType;
    for (var d = startDate;
        !d.isAfter(today);
        d = d.add(const Duration(days: 1))) {
      final cal = foodCalHistory[d] ?? 0;
      final dayGoal = state.calorieGoalHistory[d] ?? calorieGoalFallback;
      if (cal > 0) foodDaysTracked++;
      if (cal > 0) {
        switch (goalType) {
          case GoalType.lose:
            if (cal <= dayGoal && cal >= dayGoal - 500) foodDaysGoalMet++;
            break;
          case GoalType.gain:
            if (cal >= dayGoal && cal <= dayGoal + 500) foodDaysGoalMet++;
            break;
          default:
            if (cal.round() == dayGoal.round()) foodDaysGoalMet++;
            break;
        }
      }
      totalFoodCal += cal;
      foodDaily.add(_DailyEntry(d, cal.round(), dayGoal.round()));
    }
    final avgFoodCal =
        foodDaysTracked > 0 ? (totalFoodCal / foodDaysTracked).round() : 0;

    // Sleep
    final sleepHist = state.sleepHistory;
    const sleepGoalMin = 480;
    int sleepDaysTracked = 0;
    int sleepDaysGoalMet = 0;
    int totalSleepMin = 0;
    final sleepDaily = <_DailyEntry>[];
    for (var d = startDate;
        !d.isAfter(today);
        d = d.add(const Duration(days: 1))) {
      final m = sleepHist[d] ?? 0;
      if (m > 0) sleepDaysTracked++;
      if (m >= sleepGoalMin) sleepDaysGoalMet++;
      totalSleepMin += m;
      sleepDaily.add(_DailyEntry(d, m, sleepGoalMin));
    }
    final avgSleepMin =
        sleepDaysTracked > 0 ? totalSleepMin ~/ sleepDaysTracked : 0;

    // ── Colors ──
    const headerBg = PdfColor.fromInt(0xFF1A1A2E);
    const headerFg = PdfColor.fromInt(0xFFFFFFFF);
    const waterColor = PdfColor.fromInt(0xFF2196F3);
    const stepsColor = PdfColor.fromInt(0xFF009688);
    const foodColor = PdfColor.fromInt(0xFF4CAF50);
    const sleepColor = PdfColor.fromInt(0xFF3F51B5);
    const attendColor = PdfColor.fromInt(0xFFFF9800);

    // ── Styles ──
    final titleStyle = pw.TextStyle(
      fontSize: 22,
      fontWeight: pw.FontWeight.bold,
      color: headerFg,
    );
    final subtitleStyle = pw.TextStyle(fontSize: 11, color: headerFg);
    final sectionStyle = pw.TextStyle(
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    final labelStyle = pw.TextStyle(
      fontSize: 10,
      color: PdfColor.fromInt(0xFF888888),
    );
    final valueStyle = pw.TextStyle(
      fontSize: 13,
      fontWeight: pw.FontWeight.bold,
    );
    final tableHeaderStyle = pw.TextStyle(
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    final tableCellStyle = const pw.TextStyle(fontSize: 9);

    // ── Helper: section header ──
    pw.Widget sectionHeader(String title, PdfColor color) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Text(title, style: sectionStyle),
      );
    }

    // ── Helper: stat box ──
    pw.Widget statBox(String label, String value, {PdfColor? accent}) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColor.fromInt(0xFFDDDDDD)),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(value,
                style: valueStyle.copyWith(
                    color: accent ?? PdfColor.fromInt(0xFF333333))),
            pw.SizedBox(height: 2),
            pw.Text(label, style: labelStyle),
          ],
        ),
      );
    }

    // ── Helper: daily data table ──
    pw.Widget dailyTable(
      List<_DailyEntry> entries,
      PdfColor accent,
      String Function(_DailyEntry) formatVal,
    ) {
      // Show newest first, cap to keep PDF reasonable
      final reversed = entries.reversed.toList();
      return pw.TableHelper.fromTextArray(
        headerStyle: tableHeaderStyle,
        cellStyle: tableCellStyle,
        headerDecoration: pw.BoxDecoration(color: accent),
        cellAlignment: pw.Alignment.centerLeft,
        headerAlignment: pw.Alignment.centerLeft,
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(3),
        },
        headers: ['Date', 'Value'],
        data: reversed
            .map((e) => [dateFormat.format(e.date), formatVal(e)])
            .toList(),
      );
    }

    // ── Helper: progress text ──
    String pct(int met, int total) =>
        total > 0 ? '${(met / total * 100).round()}%' : '0%';

    // ── Build pages ──
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(16),
          margin: const pw.EdgeInsets.only(bottom: 16),
          decoration: pw.BoxDecoration(
            color: headerBg,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('CoreSync Go Fitness Report', style: titleStyle),
              pw.SizedBox(height: 4),
              pw.Text(userName, style: subtitleStyle),
              pw.SizedBox(height: 2),
              pw.Text(
                '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                style: subtitleStyle,
              ),
            ],
          ),
        ),
        footer: (ctx) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '\u00a9 CoreSync Go',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
            ),
            pw.Text(
              'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
            ),
          ],
        ),
        build: (ctx) => [
          // ── Attendance Summary ──
          sectionHeader('Attendance Summary', attendColor),
          pw.SizedBox(height: 10),
          pw.Row(children: [
            pw.Expanded(child: statBox('Present Days', '$presentCount', accent: PdfColor.fromInt(0xFF4CAF50))),
            pw.SizedBox(width: 8),
            pw.Expanded(child: statBox('Absent Days', '$absentCount', accent: PdfColor.fromInt(0xFFF44336))),
            pw.SizedBox(width: 8),
            pw.Expanded(child: statBox('Attendance Rate', '${attendanceRate.round()}%', accent: attendColor)),
            pw.SizedBox(width: 8),
            pw.Expanded(child: statBox('Current Streak', '$currentStreak days', accent: attendColor)),
          ]),
          pw.SizedBox(height: 4),
          pw.Row(children: [
            pw.Expanded(child: statBox('Best Streak', '$bestStreak days', accent: PdfColor.fromInt(0xFFFFC107))),
            pw.Expanded(child: pw.SizedBox()),
            pw.Expanded(child: pw.SizedBox()),
            pw.Expanded(child: pw.SizedBox()),
          ]),
          pw.SizedBox(height: 16),

          // ── Membership Card ──
          if (membership != null) ...[
            sectionHeader('Membership', PdfColor.fromInt(0xFF6200EA)),
            pw.SizedBox(height: 10),
            pw.Row(children: [
              pw.Expanded(child: statBox('Plan', membership.planLabel)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: statBox('Start', dateFormat.format(membership.startDate))),
              pw.SizedBox(width: 8),
              pw.Expanded(child: statBox('End', dateFormat.format(membership.endDate))),
              pw.SizedBox(width: 8),
              pw.Expanded(child: statBox('Days Left', '${membership.daysRemaining}')),
            ]),
            pw.SizedBox(height: 16),
          ],

          // ── Water Intake ──
          sectionHeader('Water Intake', waterColor),
          pw.SizedBox(height: 10),
          pw.Row(children: [
            pw.Expanded(child: statBox('Avg / Day', '${(avgWaterMl / 250).toStringAsFixed(1)} glasses', accent: waterColor)),
            pw.SizedBox(width: 8),
            pw.Expanded(child: statBox('Total', totalWaterMl >= 1000 ? '${(totalWaterMl / 1000).toStringAsFixed(1)}L' : '${totalWaterMl}ml', accent: waterColor)),
            pw.SizedBox(width: 8),
            pw.Expanded(child: statBox('Goal Met', '$waterDaysGoalMet / $totalDays days (${pct(waterDaysGoalMet, totalDays)})', accent: waterColor)),
          ]),
          pw.SizedBox(height: 8),
          dailyTable(waterDaily, waterColor, (e) {
            return '${(e.value / 250).toStringAsFixed(1)} / ${(e.goal / 250).toStringAsFixed(1)} glasses';
          }),
          pw.SizedBox(height: 16),

          // ── Steps ──
          sectionHeader('Steps', stepsColor),
          pw.SizedBox(height: 10),
          pw.Row(children: [
            pw.Expanded(child: statBox('Avg / Day', _formatNumber(avgSteps), accent: stepsColor)),
            pw.SizedBox(width: 8),
            pw.Expanded(child: statBox('Total', _formatNumber(totalSteps), accent: stepsColor)),
            pw.SizedBox(width: 8),
            pw.Expanded(child: statBox('Goal Met', '$stepsDaysGoalMet / $totalDays days (${pct(stepsDaysGoalMet, totalDays)})', accent: stepsColor)),
          ]),
          pw.SizedBox(height: 8),
          dailyTable(stepsDaily, stepsColor, (e) {
            return '${e.value} / ${e.goal}';
          }),
          pw.SizedBox(height: 16),

          // ── Food Tracking ──
          sectionHeader('Food Tracking', foodColor),
          pw.SizedBox(height: 10),
          pw.Row(children: [
            pw.Expanded(child: statBox('Avg / Day', '$avgFoodCal kcal', accent: foodColor)),
            pw.SizedBox(width: 8),
            pw.Expanded(child: statBox('Total', '${_formatNumber(totalFoodCal.round())} kcal', accent: foodColor)),
            pw.SizedBox(width: 8),
            pw.Expanded(child: statBox('Goal Met', '$foodDaysGoalMet / $totalDays days (${pct(foodDaysGoalMet, totalDays)})', accent: foodColor)),
          ]),
          pw.SizedBox(height: 8),
          dailyTable(foodDaily, foodColor, (e) {
            return '${e.value} / ${e.goal} kcal';
          }),
          pw.SizedBox(height: 16),

          // ── Sleep ──
          sectionHeader('Sleep', sleepColor),
          pw.SizedBox(height: 10),
          pw.Row(children: [
            pw.Expanded(child: statBox('Avg / Night', '${avgSleepMin ~/ 60}h ${avgSleepMin % 60}m', accent: sleepColor)),
            pw.SizedBox(width: 8),
            pw.Expanded(child: statBox('Days Tracked', '$sleepDaysTracked', accent: sleepColor)),
            pw.SizedBox(width: 8),
            pw.Expanded(child: statBox('Goal Met (8h)', '$sleepDaysGoalMet / $totalDays days (${pct(sleepDaysGoalMet, totalDays)})', accent: sleepColor)),
          ]),
          pw.SizedBox(height: 8),
          dailyTable(sleepDaily, sleepColor, (e) {
            return e.value > 0
                ? '${e.value ~/ 60}h ${e.value % 60}m / ${e.goal ~/ 60}h'
                : '- / ${e.goal ~/ 60}h';
          }),
          pw.SizedBox(height: 20),
        ],
      ),
    );

    return pdf;
  }

  static String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _DailyEntry {
  final DateTime date;
  final int value;
  final int goal;
  const _DailyEntry(this.date, this.value, this.goal);
}
