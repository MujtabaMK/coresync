import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'diet_chart_service.dart';

class DietChartPdfService {
  static Future<pw.Document> generate({
    required WeeklyDietChart chart,
    required String userName,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy', 'en_US');
    final today = DateTime.now();
    final profile = chart.profile;

    // ── Colors (matching report_pdf_service) ──
    const headerBg = PdfColor.fromInt(0xFF1A1A2E);
    const headerFg = PdfColor.fromInt(0xFFFFFFFF);
    const mealColor = PdfColor.fromInt(0xFF4CAF50);
    const waterColor = PdfColor.fromInt(0xFF2196F3);
    const stepsColor = PdfColor.fromInt(0xFF009688);
    const tipsColor = PdfColor.fromInt(0xFFFF9800);
    const profileColor = PdfColor.fromInt(0xFF6200EA);
    const rdaColor = PdfColor.fromInt(0xFF3F51B5);
    const dayColor = PdfColor.fromInt(0xFF37474F);

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

    // ── Helpers ──
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

    // ── Meal table builder ──
    pw.Widget mealTable(DietMealPlan meal) {
      final rows = meal.foods
          .map((f) => [
                f.name,
                '${f.servings % 1 == 0 ? f.servings.toInt() : f.servings.toStringAsFixed(1)}x ${f.servingSize}',
                '${f.calories.round()}',
                '${f.protein.toStringAsFixed(1)}g',
                '${f.carbs.toStringAsFixed(1)}g',
                '${f.fat.toStringAsFixed(1)}g',
              ])
          .toList();

      rows.add([
        'Total',
        '',
        '${meal.totalCalories}',
        '${meal.totalProtein.toStringAsFixed(1)}g',
        '${meal.totalCarbs.toStringAsFixed(1)}g',
        '${meal.totalFat.toStringAsFixed(1)}g',
      ]);

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: pw.BoxDecoration(
              color: mealColor.shade(.2),
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(6),
                topRight: pw.Radius.circular(6),
              ),
            ),
            child: pw.Text(
              '${meal.mealType.label} (${meal.calorieBudget} kcal budget)',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
          pw.TableHelper.fromTextArray(
            headerStyle: tableHeaderStyle,
            cellStyle: tableCellStyle,
            headerDecoration: const pw.BoxDecoration(color: mealColor),
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.centerLeft,
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2.5),
              2: const pw.FlexColumnWidth(1.2),
              3: const pw.FlexColumnWidth(1.2),
              4: const pw.FlexColumnWidth(1.2),
              5: const pw.FlexColumnWidth(1.2),
            },
            headers: ['Food', 'Serving', 'Kcal', 'Protein', 'Carbs', 'Fat'],
            data: rows,
            oddCellStyle: tableCellStyle,
            cellDecoration: (index, data, rowNum) {
              if (rowNum == rows.length - 1) {
                return const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFE8F5E9),
                );
              }
              return const pw.BoxDecoration();
            },
          ),
        ],
      );
    }

    // ── Tip row helper (using "-" instead of bullet unicode) ──
    pw.Widget tipRow(String text, {PdfColor? color}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('- ',
                style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: color ?? PdfColor.fromInt(0xFF2196F3))),
            pw.Expanded(
              child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
            ),
          ],
        ),
      );
    }

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
              pw.Text('CoreSync Go - 7 Day Diet Chart', style: titleStyle),
              pw.SizedBox(height: 4),
              pw.Text(userName, style: subtitleStyle),
              pw.SizedBox(height: 2),
              pw.Text(
                'Generated on ${dateFormat.format(today)}',
                style: subtitleStyle,
              ),
            ],
          ),
        ),
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
          ),
        ),
        build: (ctx) => [
          // ── 1. Profile Summary ──
          sectionHeader('Profile Summary', profileColor),
          pw.SizedBox(height: 10),
          pw.Row(children: [
            pw.Expanded(
                child: statBox(
                    'BMI',
                    '${profile.bmi.toStringAsFixed(1)} (${profile.bmiCategory})',
                    accent: profileColor)),
            pw.SizedBox(width: 8),
            pw.Expanded(
                child: statBox('Age / Gender',
                    '${profile.age} yrs / ${profile.gender.name[0].toUpperCase()}${profile.gender.name.substring(1)}')),
            pw.SizedBox(width: 8),
            pw.Expanded(
                child: statBox('Weight',
                    '${profile.currentWeight.toStringAsFixed(1)} to ${profile.targetWeight.toStringAsFixed(1)} kg')),
          ]),
          pw.SizedBox(height: 6),
          pw.Row(children: [
            pw.Expanded(
                child: statBox('Goal', profile.goalType.label,
                    accent: profileColor)),
            pw.SizedBox(width: 8),
            pw.Expanded(
                child:
                    statBox('Activity Level', profile.activityLevel.label)),
            pw.SizedBox(width: 8),
            pw.Expanded(
                child: statBox('TDEE', '${profile.tdee.round()} kcal/day')),
          ]),
          pw.SizedBox(height: 6),
          pw.Row(children: [
            pw.Expanded(
                child: statBox(
                    'Diet Type',
                    profile.isVegetarian ? 'Vegetarian' : 'Non-Vegetarian',
                    accent: profile.isVegetarian
                        ? const PdfColor.fromInt(0xFF4CAF50)
                        : profileColor)),
            pw.SizedBox(width: 8),
            pw.Expanded(child: pw.SizedBox()),
            pw.SizedBox(width: 8),
            pw.Expanded(child: pw.SizedBox()),
          ]),
          pw.SizedBox(height: 16),

          // ── 2. Daily Targets ──
          sectionHeader('Daily Targets', mealColor),
          pw.SizedBox(height: 10),
          pw.Row(children: [
            pw.Expanded(
                child: statBox('Calories',
                    '${profile.dailyCalorieTarget.round()} kcal',
                    accent: mealColor)),
            pw.SizedBox(width: 8),
            pw.Expanded(
                child: statBox(
                    'Protein', '${profile.proteinGrams.round()}g',
                    accent: PdfColor.fromInt(0xFF2196F3))),
            pw.SizedBox(width: 8),
            pw.Expanded(
                child: statBox('Carbs', '${profile.carbsGrams.round()}g',
                    accent: PdfColor.fromInt(0xFFFF9800))),
            pw.SizedBox(width: 8),
            pw.Expanded(
                child: statBox('Fat', '${profile.fatGrams.round()}g',
                    accent: PdfColor.fromInt(0xFFF44336))),
          ]),
          pw.SizedBox(height: 8),
          pw.Row(children: [
            pw.Expanded(
                child: statBox('Water Goal',
                    '${(chart.waterGoalMl / 1000).toStringAsFixed(1)} L (${(chart.waterGoalMl / 250).round()} glasses)',
                    accent: waterColor)),
            pw.SizedBox(width: 8),
            pw.Expanded(
                child: statBox('Steps Goal',
                    _formatNumber(chart.stepsGoal),
                    accent: stepsColor)),
            pw.SizedBox(width: 8),
            pw.Expanded(child: pw.SizedBox()),
          ]),
          pw.SizedBox(height: 16),

          // ── 3. Seven Day Meal Plans ──
          ...chart.days.expand((day) => [
                sectionHeader(
                  '${day.dayLabel} (Total: ${day.totalCalories} / ${profile.dailyCalorieTarget.round()} kcal)',
                  dayColor,
                ),
                pw.SizedBox(height: 8),
                ...day.meals.expand((meal) => [
                      mealTable(meal),
                      pw.SizedBox(height: 6),
                    ]),
                pw.SizedBox(height: 10),
              ]),

          // ── 4. Water Tips ──
          sectionHeader('Water Intake Tips', waterColor),
          pw.SizedBox(height: 8),
          tipRow('Drink a glass of water first thing in the morning.'),
          tipRow('Carry a water bottle throughout the day.'),
          tipRow('Drink water before meals to aid digestion and reduce overeating.'),
          pw.SizedBox(height: 16),

          // ── 5. Dietary Tips ──
          sectionHeader('Dietary Tips', tipsColor),
          pw.SizedBox(height: 8),
          ...chart.tips.map((tip) => pw.Padding(
                padding:
                    const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('- ',
                        style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: tipsColor)),
                    pw.Expanded(
                      child: pw.Text(tip,
                          style: const pw.TextStyle(fontSize: 10)),
                    ),
                  ],
                ),
              )),
          pw.SizedBox(height: 16),

          // ── 6. Micronutrient RDA ──
          sectionHeader('Recommended Daily Micronutrients', rdaColor),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headerStyle: tableHeaderStyle,
            cellStyle: tableCellStyle,
            headerDecoration: const pw.BoxDecoration(color: rdaColor),
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.centerLeft,
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
            },
            headers: ['Nutrient', 'RDA'],
            data: [
              ['Fiber', '${profile.fiberRDA.round()}g'],
              ['Sugar (limit)', '< ${profile.sugarLimit.round()}g'],
              ['Sodium (limit)', '< ${profile.sodiumLimit.round()} mg'],
              ['Cholesterol (limit)', '< ${profile.cholesterolLimit.round()} mg'],
              ['Iron', '${profile.ironRDA.round()} mg'],
              ['Calcium', '${profile.calciumRDA.round()} mg'],
              ['Potassium', '${profile.potassiumRDA.round()} mg'],
              ['Vitamin A', '${profile.vitaminARDA.round()} mcg'],
              ['Vitamin B6', '${profile.vitaminB6RDA} mg'],
              ['Vitamin B12', '${profile.vitaminB12RDA} mcg'],
              ['Vitamin C', '${profile.vitaminCRDA.round()} mg'],
              ['Vitamin D', '${profile.vitaminDRDA.round()} mcg'],
              ['Vitamin E', '${profile.vitaminERDA.round()} mg'],
              ['Vitamin K', '${profile.vitaminKRDA.round()} mcg'],
              ['Zinc', '${profile.zincRDA.round()} mg'],
              ['Magnesium', '${profile.magnesiumRDA.round()} mg'],
              ['Folate', '${profile.folateRDA.round()} mcg'],
              ['Phosphorus', '${profile.phosphorusRDA.round()} mg'],
              ['Selenium', '${profile.seleniumRDA.round()} mcg'],
              ['Manganese', '${profile.manganeseRDA} mg'],
            ],
          ),
          pw.SizedBox(height: 20),
        ],
      ),
    );

    return pdf;
  }

  static String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
