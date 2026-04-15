import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/nfc_service.dart';
import '../../data/qr_scanner_repository.dart';
import '../../domain/scan_result_model.dart';

class QrScannerState extends Equatable {
  const QrScannerState({
    this.history = const [],
    this.isLoading = false,
    this.error,
  });

  final List<ScanResultModel> history;
  final bool isLoading;
  final String? error;

  QrScannerState copyWith({
    List<ScanResultModel>? history,
    bool? isLoading,
    String? error,
  }) {
    return QrScannerState(
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [history, isLoading, error];
}

class QrScannerCubit extends Cubit<QrScannerState> {
  QrScannerCubit({
    required QrScannerRepository repository,
    NfcService? nfcService,
  })  : _repository = repository,
        _nfcService = nfcService ?? NfcService(),
        super(const QrScannerState());

  final QrScannerRepository _repository;
  final NfcService _nfcService;

  Future<void> loadHistory() async {
    emit(state.copyWith(isLoading: true));
    try {
      final items = await _repository.getHistory();
      emit(state.copyWith(history: items, isLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<ScanResultModel> addScan({
    required String value,
    required String type,
  }) async {
    final model = await _repository.addScan(value: value, type: type);
    await loadHistory();
    return model;
  }

  Future<void> deleteScan(String id) async {
    await _repository.deleteScan(id);
    await loadHistory();
  }

  Future<void> clearHistory() async {
    await _repository.clearHistory();
    emit(state.copyWith(history: []));
  }

  Future<bool> isNfcAvailable() => _nfcService.isAvailable();

  NfcService get nfcService => _nfcService;
}
