import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/scan_result_model.dart';

class QrScannerRepository {
  Box<ScanResultModel>? _box;

  Future<Box<ScanResultModel>> get box async {
    _box ??= await Hive.openBox<ScanResultModel>(AppConstants.qrScanHistoryBox);
    return _box!;
  }

  Future<List<ScanResultModel>> getHistory() async {
    final b = await box;
    final items = b.values.toList()
      ..sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    return items;
  }

  Future<ScanResultModel> addScan({
    required String value,
    required String type,
  }) async {
    final b = await box;
    final model = ScanResultModel(
      id: const Uuid().v4(),
      value: value,
      type: type,
      contentType: ScanResultModel.detectContentType(value),
      scannedAt: DateTime.now(),
    );
    await b.put(model.id, model);
    return model;
  }

  Future<void> deleteScan(String id) async {
    final b = await box;
    await b.delete(id);
  }

  Future<void> clearHistory() async {
    final b = await box;
    await b.clear();
  }
}
