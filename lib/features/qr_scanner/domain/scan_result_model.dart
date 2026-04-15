import 'package:hive/hive.dart';

part 'scan_result_model.g.dart';

@HiveType(typeId: 4)
class ScanResultModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String value;

  @HiveField(2)
  final String type; // 'qr', 'barcode', 'nfc'

  @HiveField(3)
  final String contentType; // 'url', 'email', 'phone', 'text'

  @HiveField(4)
  final DateTime scannedAt;

  ScanResultModel({
    required this.id,
    required this.value,
    required this.type,
    required this.contentType,
    required this.scannedAt,
  });

  /// Auto-detect content type from the scanned value.
  static String detectContentType(String value) {
    final v = value.trim().toLowerCase();
    if (v.startsWith('http://') || v.startsWith('https://') || v.startsWith('www.')) {
      return 'url';
    }
    if (v.startsWith('mailto:') || RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]+$').hasMatch(v)) {
      return 'email';
    }
    if (v.startsWith('tel:') || RegExp(r'^\+?[\d\s\-()]{7,}$').hasMatch(v)) {
      return 'phone';
    }
    return 'text';
  }
}
