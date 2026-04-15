import 'dart:math';

import 'package:flutter/material.dart';

class BmiGaugeWidget extends StatelessWidget {
  const BmiGaugeWidget({
    super.key,
    required this.bmi,
    required this.category,
  });

  final double bmi;
  final String category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 180,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CustomPaint(
            size: const Size(240, 140),
            painter: _BmiArcPainter(
              bmi: bmi,
              brightness: theme.brightness,
            ),
          ),
          Positioned(
            bottom: 8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  bmi.toStringAsFixed(1),
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _colorForBmi(bmi),
                  ),
                ),
                Text(
                  category,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _colorForBmi(bmi),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Color _colorForBmi(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }
}

class _BmiArcPainter extends CustomPainter {
  _BmiArcPainter({required this.bmi, required this.brightness});

  final double bmi;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 16;
    const strokeWidth = 18.0;
    const startAngle = pi;
    const sweepAngle = pi;

    // Background arc
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.grey.shade200;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Colored segments
    final segments = [
      (Colors.blue, 0.0, 18.5),
      (Colors.green, 18.5, 25.0),
      (Colors.orange, 25.0, 30.0),
      (Colors.red, 30.0, 40.0),
    ];

    for (final (color, minBmi, maxBmi) in segments) {
      final segStart = ((minBmi / 40) * pi) + pi;
      final segSweep = ((maxBmi - minBmi) / 40) * pi;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt
        ..color = color.withValues(alpha: 0.3);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        segStart,
        segSweep,
        false,
        paint,
      );
    }

    // Needle
    final clampedBmi = bmi.clamp(10.0, 40.0);
    final needleAngle = pi + (clampedBmi / 40) * pi;
    final needleEnd = Offset(
      center.dx + (radius - 8) * cos(needleAngle),
      center.dy + (radius - 8) * sin(needleAngle),
    );

    final needlePaint = Paint()
      ..color = BmiGaugeWidget._colorForBmi(bmi)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, needleEnd, needlePaint);

    // Center dot
    canvas.drawCircle(
      center,
      6,
      Paint()..color = BmiGaugeWidget._colorForBmi(bmi),
    );

    // Labels
    final labels = [
      (0.0, '10'),
      (pi / 4, '18.5'),
      (pi / 2, '25'),
      (3 * pi / 4, '30'),
      (pi, '40'),
    ];

    for (final (angle, label) in labels) {
      final labelAngle = pi + angle;
      final labelPos = Offset(
        center.dx + (radius + 14) * cos(labelAngle),
        center.dy + (radius + 14) * sin(labelAngle),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 10,
            color: brightness == Brightness.dark
                ? Colors.white70
                : Colors.grey.shade600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, labelPos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _BmiArcPainter oldDelegate) =>
      oldDelegate.bmi != bmi || oldDelegate.brightness != brightness;
}
