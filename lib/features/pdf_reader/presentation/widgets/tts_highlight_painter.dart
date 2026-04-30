import 'package:flutter/material.dart';

class TtsHighlightPainter extends CustomPainter {
  TtsHighlightPainter({
    required this.normalizedBounds,
    required this.widgetSize,
    required this.pdfPageAspectRatio,
  });

  final Rect normalizedBounds;
  final Size widgetSize;
  final double pdfPageAspectRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final widgetAspect = widgetSize.width / widgetSize.height;
    double renderWidth, renderHeight, offsetX, offsetY;

    if (pdfPageAspectRatio > widgetAspect) {
      renderWidth = widgetSize.width;
      renderHeight = widgetSize.width / pdfPageAspectRatio;
      offsetX = 0;
      offsetY = (widgetSize.height - renderHeight) / 2;
    } else {
      renderHeight = widgetSize.height;
      renderWidth = widgetSize.height * pdfPageAspectRatio;
      offsetX = (widgetSize.width - renderWidth) / 2;
      offsetY = 0;
    }

    final wordRect = Rect.fromLTRB(
      offsetX + normalizedBounds.left * renderWidth,
      offsetY + normalizedBounds.top * renderHeight,
      offsetX + normalizedBounds.right * renderWidth,
      offsetY + normalizedBounds.bottom * renderHeight,
    );

    // ── Full-width reading guide band ──
    const vPad = 3.0;
    final lineRect = Rect.fromLTRB(
      offsetX,
      wordRect.top - vPad,
      offsetX + renderWidth,
      wordRect.bottom + vPad,
    );

    // Soft gradient band — transparent edges, tinted center
    final bandPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0x00FFC107),
          const Color(0x18FFC107),
          const Color(0x18FFC107),
          const Color(0x00FFC107),
        ],
        stops: const [0.0, 0.05, 0.95, 1.0],
      ).createShader(lineRect);
    canvas.drawRect(lineRect, bandPaint);

    // Thin horizontal rules at top & bottom of the band
    final rulePaint = Paint()
      ..color = const Color(0x30FFC107)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(lineRect.left + 8, lineRect.top),
      Offset(lineRect.right - 8, lineRect.top),
      rulePaint,
    );
    canvas.drawLine(
      Offset(lineRect.left + 8, lineRect.bottom),
      Offset(lineRect.right - 8, lineRect.bottom),
      rulePaint,
    );

    // ── Highlighted word ──
    final wordPadded = Rect.fromLTRB(
      wordRect.left - 3,
      wordRect.top - vPad,
      wordRect.right + 3,
      wordRect.bottom + vPad,
    );
    final wordRRect =
        RRect.fromRectAndRadius(wordPadded, const Radius.circular(4));

    // Word background fill
    final wordFill = Paint()
      ..color = const Color(0x44FFC107)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(wordRRect, wordFill);

    // Word border
    final wordBorder = Paint()
      ..color = const Color(0x66FF9800)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(wordRRect, wordBorder);

    // Bold underline beneath the word
    final underlineY = wordPadded.bottom - 1.5;
    final underlinePaint = Paint()
      ..color = const Color(0xBBFF9800)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(wordPadded.left + 2, underlineY),
      Offset(wordPadded.right - 2, underlineY),
      underlinePaint,
    );
  }

  @override
  bool shouldRepaint(TtsHighlightPainter oldDelegate) {
    return normalizedBounds != oldDelegate.normalizedBounds;
  }
}
