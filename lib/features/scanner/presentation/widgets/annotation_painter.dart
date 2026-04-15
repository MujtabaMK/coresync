import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/annotation_model.dart';

class AnnotationPainter extends CustomPainter {
  AnnotationPainter({
    required this.annotations,
    required this.imageRect,
    this.selectedId,
  });

  final List<Annotation> annotations;

  /// The actual rect where the image is rendered within the widget.
  final Rect imageRect;

  /// ID of the currently selected annotation (shows handles).
  final String? selectedId;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(imageRect);

    for (final a in annotations) {
      if (a is StrokeAnnotation) {
        _drawStroke(canvas, a);
      } else if (a is LineAnnotation) {
        _drawLine(canvas, a);
      } else if (a is RectAnnotation) {
        _drawRect(canvas, a);
      } else if (a is TextAnnotation) {
        _drawText(canvas, a);
      } else if (a is StampAnnotation) {
        _drawStamp(canvas, a);
      } else if (a is SignatureAnnotation) {
        _drawSignature(canvas, a);
      }

      if (a.id == selectedId) {
        _drawSelectionHandles(canvas, a);
      }
    }

    canvas.restore();
  }

  Offset _toCanvas(Offset normalized) {
    return Offset(
      imageRect.left + normalized.dx * imageRect.width,
      imageRect.top + normalized.dy * imageRect.height,
    );
  }

  void _drawStroke(Canvas canvas, StrokeAnnotation stroke) {
    if (stroke.points.length < 2) return;

    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final first = _toCanvas(stroke.points[0]);
    path.moveTo(first.dx, first.dy);
    for (var i = 1; i < stroke.points.length; i++) {
      final p = _toCanvas(stroke.points[i]);
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);
  }

  void _drawLine(Canvas canvas, LineAnnotation line) {
    final paint = Paint()
      ..color = line.color
      ..strokeWidth = line.strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(_toCanvas(line.start), _toCanvas(line.end), paint);
  }

  void _drawRect(Canvas canvas, RectAnnotation rect) {
    final paint = Paint()
      ..color = rect.color
      ..strokeWidth = rect.strokeWidth
      ..style = PaintingStyle.stroke;

    final r = Rect.fromPoints(
      _toCanvas(rect.topLeft),
      _toCanvas(rect.bottomRight),
    );
    canvas.drawRect(r, paint);
  }

  void _drawText(Canvas canvas, TextAnnotation textAnnotation) {
    final fontSize = textAnnotation.fontSize * imageRect.height;
    final tp = TextPainter(
      text: TextSpan(
        text: textAnnotation.text,
        style: TextStyle(color: textAnnotation.color, fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: imageRect.width * 0.8);
    tp.paint(canvas, _toCanvas(textAnnotation.position));
  }

  void _drawStamp(Canvas canvas, StampAnnotation stamp) {
    final center = _toCanvas(stamp.position);
    final halfSize = stamp.size * imageRect.height / 2;
    final paint = Paint()
      ..color = stamp.color
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    switch (stamp.stampType) {
      case StampType.checkmark:
        final path = Path()
          ..moveTo(center.dx - halfSize * 0.6, center.dy)
          ..lineTo(center.dx - halfSize * 0.1, center.dy + halfSize * 0.5)
          ..lineTo(center.dx + halfSize * 0.6, center.dy - halfSize * 0.5);
        canvas.drawPath(path, paint);
      case StampType.cross:
        canvas.drawLine(
          Offset(center.dx - halfSize * 0.5, center.dy - halfSize * 0.5),
          Offset(center.dx + halfSize * 0.5, center.dy + halfSize * 0.5),
          paint,
        );
        canvas.drawLine(
          Offset(center.dx + halfSize * 0.5, center.dy - halfSize * 0.5),
          Offset(center.dx - halfSize * 0.5, center.dy + halfSize * 0.5),
          paint,
        );
      case StampType.dot:
        canvas.drawCircle(
          center,
          halfSize * 0.4,
          paint..style = PaintingStyle.fill,
        );
    }
  }

  void _drawSignature(Canvas canvas, SignatureAnnotation sig) {
    final paint = Paint()
      ..color = sig.color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final originX = imageRect.left + sig.position.dx * imageRect.width;
    final originY = imageRect.top + sig.position.dy * imageRect.height;
    final w = sig.scale * imageRect.width;
    final h = w * 0.5; // aspect ratio

    for (final stroke in sig.strokes) {
      if (stroke.length < 2) continue;
      final path = Path();
      final first = stroke[0];
      path.moveTo(originX + first.dx * w, originY + first.dy * h);
      for (var i = 1; i < stroke.length; i++) {
        final p = stroke[i];
        path.lineTo(originX + p.dx * w, originY + p.dy * h);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawSelectionHandles(Canvas canvas, Annotation a) {
    Rect? bounds;

    if (a is StrokeAnnotation && a.points.isNotEmpty) {
      double minX = double.infinity, minY = double.infinity;
      double maxX = -double.infinity, maxY = -double.infinity;
      for (final p in a.points) {
        final c = _toCanvas(p);
        minX = min(minX, c.dx);
        minY = min(minY, c.dy);
        maxX = max(maxX, c.dx);
        maxY = max(maxY, c.dy);
      }
      bounds = Rect.fromLTRB(minX, minY, maxX, maxY);
    } else if (a is LineAnnotation) {
      bounds = Rect.fromPoints(_toCanvas(a.start), _toCanvas(a.end));
    } else if (a is RectAnnotation) {
      bounds = Rect.fromPoints(_toCanvas(a.topLeft), _toCanvas(a.bottomRight));
    } else if (a is TextAnnotation) {
      final pos = _toCanvas(a.position);
      final fontSize = a.fontSize * imageRect.height;
      bounds = Rect.fromLTWH(pos.dx, pos.dy, fontSize * a.text.length * 0.6, fontSize * 1.2);
    } else if (a is StampAnnotation) {
      final center = _toCanvas(a.position);
      final halfSize = a.size * imageRect.height / 2;
      bounds = Rect.fromCenter(center: center, width: halfSize * 2, height: halfSize * 2);
    } else if (a is SignatureAnnotation) {
      final originX = imageRect.left + a.position.dx * imageRect.width;
      final originY = imageRect.top + a.position.dy * imageRect.height;
      final w = a.scale * imageRect.width;
      final h = w * 0.5;
      bounds = Rect.fromLTWH(originX, originY, w, h);
    }

    if (bounds == null) return;

    final borderPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final expanded = bounds.inflate(6);
    canvas.drawRect(expanded, borderPaint);

    final handlePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    const handleRadius = 5.0;
    for (final corner in [
      expanded.topLeft,
      expanded.topRight,
      expanded.bottomLeft,
      expanded.bottomRight,
    ]) {
      canvas.drawCircle(corner, handleRadius, handlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant AnnotationPainter oldDelegate) {
    return annotations != oldDelegate.annotations ||
        imageRect != oldDelegate.imageRect ||
        selectedId != oldDelegate.selectedId;
  }
}
