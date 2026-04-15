import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../domain/ocr_block.dart';

class OcrService {
  OcrService._();

  static final _textRecognizer = TextRecognizer();

  /// Recognizes text from a single image file.
  static Future<String> recognizeText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognized = await _textRecognizer.processImage(inputImage);
    return recognized.text;
  }

  /// Recognizes text blocks with bounding boxes from a single image.
  static Future<List<OcrBlock>> recognizeBlocks(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognized = await _textRecognizer.processImage(inputImage);
    return recognized.blocks
        .map((b) => OcrBlock(text: b.text, boundingBox: b.boundingBox))
        .toList();
  }

  /// Recognizes text from multiple image files and concatenates results.
  static Future<String> recognizeTextFromPages(
    List<String> imagePaths,
  ) async {
    final buffer = StringBuffer();
    for (var i = 0; i < imagePaths.length; i++) {
      if (i > 0) buffer.writeln('\n--- Page ${i + 1} ---\n');
      final text = await recognizeText(imagePaths[i]);
      buffer.writeln(text);
    }
    return buffer.toString().trim();
  }

  static void dispose() {
    _textRecognizer.close();
  }
}
