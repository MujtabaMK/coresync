import 'dart:io';

import 'package:image/image.dart' as img;

class ImageProcessingService {
  ImageProcessingService._();

  /// Compresses an image to the given quality (0-100) and saves a copy.
  static Future<String> compressImage(String path, int quality) async {
    final file = File(path);
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');

    final compressed = img.encodeJpg(image, quality: quality);
    final outputPath = path.replaceAll(
      RegExp(r'\.\w+$'),
      '_compressed.jpg',
    );
    await File(outputPath).writeAsBytes(compressed);
    return outputPath;
  }

  /// Applies a grayscale filter and saves a copy.
  static Future<String> applyGrayscaleFilter(String path) async {
    final file = File(path);
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');

    final grayscale = img.grayscale(image);
    final encoded = img.encodeJpg(grayscale, quality: 90);
    final outputPath = path.replaceAll(
      RegExp(r'\.\w+$'),
      '_grayscale.jpg',
    );
    await File(outputPath).writeAsBytes(encoded);
    return outputPath;
  }

  /// Applies brightness adjustment and saves a copy.
  /// [brightness] range: -255 to 255 (positive = brighter)
  static Future<String> applyBrightnessFilter(
    String path,
    double brightness,
  ) async {
    final file = File(path);
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');

    final adjusted = img.adjustColor(image, brightness: brightness / 255.0);
    final encoded = img.encodeJpg(adjusted, quality: 90);
    final outputPath = path.replaceAll(
      RegExp(r'\.\w+$'),
      '_bright.jpg',
    );
    await File(outputPath).writeAsBytes(encoded);
    return outputPath;
  }
}
