import 'dart:ui';

class OcrBlock {
  OcrBlock({
    required this.text,
    required this.boundingBox,
  }) : originalText = text;

  String text;
  final String originalText;
  bool isDeleted = false;
  final Rect boundingBox;

  bool get isEdited => text != originalText;
}