import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/notification_ids.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/medicine_repository.dart';

class MedicineState {
  const MedicineState({
    this.medicines = const [],
    this.isLoading = false,
    this.error,
  });

  final List<Map<String, dynamic>> medicines;
  final bool isLoading;
  final String? error;

  MedicineState copyWith({
    List<Map<String, dynamic>>? medicines,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return MedicineState(
      medicines: medicines ?? this.medicines,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class MedicineCubit extends Cubit<MedicineState> {
  MedicineCubit({required MedicineRepository repository})
      : _repository = repository,
        super(const MedicineState());

  final MedicineRepository _repository;

  Future<void> loadMedicines() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final medicines = await _repository.getAllMedicines();
      emit(state.copyWith(medicines: medicines, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> saveMedicine(Map<String, dynamic> medicine) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await _repository.saveMedicine(medicine);

      // Schedule notifications if reminder is enabled
      final reminderEnabled = medicine['reminderEnabled'] as bool? ?? false;
      final schedulerEnabled = medicine['schedulerEnabled'] as bool? ?? false;
      final id = medicine['id'] as String;
      final doseTimes = (medicine['doseTimes'] as List?)?.cast<String>() ?? [];

      if (schedulerEnabled && reminderEnabled && doseTimes.isNotEmpty) {
        for (var i = 0; i < doseTimes.length; i++) {
          final parts = doseTimes[i].split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          await NotificationService.scheduleDailyNotification(
            id: NotificationIds.medicineDose(id, i),
            title: 'Medicine Reminder',
            body: 'Time to take ${medicine['name']}',
            hour: hour,
            minute: minute,
          );
        }
      } else {
        // Cancel any existing notifications for this medicine
        for (var i = 0; i < 10; i++) {
          await NotificationService.cancel(
              NotificationIds.medicineDose(id, i));
        }
      }

      await loadMedicines();
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> deleteMedicine(String id) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      // Cancel all notifications for this medicine
      for (var i = 0; i < 10; i++) {
        await NotificationService.cancel(NotificationIds.medicineDose(id, i));
      }
      await _repository.deleteMedicine(id);
      await loadMedicines();
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
