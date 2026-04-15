import 'dart:ui';

import 'package:uuid/uuid.dart';

enum AnnotationTool { pen, text, checkmark, cross, dot, line, rectangle, signature }

enum StampType { checkmark, cross, dot }

sealed class Annotation {
  Annotation({required this.color, String? id}) : id = id ?? const Uuid().v4();

  final String id;
  final Color color;
}

class StrokeAnnotation extends Annotation {
  StrokeAnnotation({
    required this.points,
    required super.color,
    this.strokeWidth = 3.0,
    super.id,
  });

  /// Normalized 0..1 points relative to image rect.
  final List<Offset> points;
  final double strokeWidth;
}

class LineAnnotation extends Annotation {
  LineAnnotation({
    required this.start,
    required this.end,
    required super.color,
    this.strokeWidth = 3.0,
    super.id,
  });

  final Offset start;
  final Offset end;
  final double strokeWidth;
}

class RectAnnotation extends Annotation {
  RectAnnotation({
    required this.topLeft,
    required this.bottomRight,
    required super.color,
    this.strokeWidth = 3.0,
    super.id,
  });

  final Offset topLeft;
  final Offset bottomRight;
  final double strokeWidth;
}

class TextAnnotation extends Annotation {
  TextAnnotation({
    required this.position,
    required this.text,
    required super.color,
    this.fontSize = 0.04,
    super.id,
  });

  /// Normalized 0..1 position.
  final Offset position;
  final String text;

  /// Normalized font size relative to image height.
  final double fontSize;
}

class StampAnnotation extends Annotation {
  StampAnnotation({
    required this.position,
    required this.stampType,
    required super.color,
    this.size = 0.05,
    super.id,
  });

  final Offset position;
  final StampType stampType;

  /// Normalized size relative to image height.
  final double size;
}

class SignatureAnnotation extends Annotation {
  SignatureAnnotation({
    required this.position,
    required this.strokes,
    required super.color,
    this.scale = 0.25,
    super.id,
  });

  /// Top-left position (normalized 0..1).
  final Offset position;

  /// Signature strokes in 0..1 local coordinates.
  final List<List<Offset>> strokes;

  /// Scale factor relative to image width.
  final double scale;
}
