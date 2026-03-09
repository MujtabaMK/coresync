import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/gym_repository.dart';
import '../../domain/membership_model.dart';

class GymState {
  const GymState({
    this.activeMembership,
    this.attendanceMap = const {},
    this.presentCount = 0,
    this.absentCount = 0,
    this.presentDates = const [],
    this.absentDates = const [],
    this.waterGlasses = 0,
    this.dailyWaterGoalMl = 0,
    this.waterHistory = const {},
    this.stepsHistory = const {},
    this.userHeight,
    this.userWeight,
    this.isLoading = false,
    this.error,
  });

  final MembershipModel? activeMembership;
  final Map<DateTime, bool> attendanceMap;
  final int presentCount;
  final int absentCount;
  final List<DateTime> presentDates;
  final List<DateTime> absentDates;
  final int waterGlasses;
  final int dailyWaterGoalMl;
  final Map<DateTime, int> waterHistory;
  final Map<DateTime, int> stepsHistory;
  final double? userHeight;
  final double? userWeight;
  final bool isLoading;
  final String? error;

  GymState copyWith({
    MembershipModel? activeMembership,
    bool clearMembership = false,
    Map<DateTime, bool>? attendanceMap,
    int? presentCount,
    int? absentCount,
    List<DateTime>? presentDates,
    List<DateTime>? absentDates,
    int? waterGlasses,
    int? dailyWaterGoalMl,
    Map<DateTime, int>? waterHistory,
    Map<DateTime, int>? stepsHistory,
    double? userHeight,
    bool clearHeight = false,
    double? userWeight,
    bool clearWeight = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return GymState(
      activeMembership:
          clearMembership ? null : (activeMembership ?? this.activeMembership),
      attendanceMap: attendanceMap ?? this.attendanceMap,
      presentCount: presentCount ?? this.presentCount,
      absentCount: absentCount ?? this.absentCount,
      presentDates: presentDates ?? this.presentDates,
      absentDates: absentDates ?? this.absentDates,
      waterGlasses: waterGlasses ?? this.waterGlasses,
      dailyWaterGoalMl: dailyWaterGoalMl ?? this.dailyWaterGoalMl,
      waterHistory: waterHistory ?? this.waterHistory,
      stepsHistory: stepsHistory ?? this.stepsHistory,
      userHeight: clearHeight ? null : (userHeight ?? this.userHeight),
      userWeight: clearWeight ? null : (userWeight ?? this.userWeight),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class GymCubit extends Cubit<GymState> {
  GymCubit({required GymRepository repository})
      : _repository = repository,
        super(const GymState());

  final GymRepository _repository;

  GymRepository get repository => _repository;

  Future<void> loadAll() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await Future.wait([
        loadMembership(),
        loadAttendance(),
        loadWaterIntake(),
        loadUserMetrics(),
        loadStepsHistory(),
      ]);
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> loadMembership() async {
    try {
      final membership = await _repository.getActiveMembership();
      if (membership == null) {
        emit(state.copyWith(
          clearMembership: true,
          isLoading: false,
          clearError: true,
        ));
      } else {
        emit(state.copyWith(
          activeMembership: membership,
          isLoading: false,
          clearError: true,
        ));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> loadAttendance() async {
    try {
      final map = await _repository.getAttendanceMap();
      final present = await _repository.getPresentCount();
      final absent = await _repository.getAbsentCount();
      final presentDates = await _repository.getPresentDates();
      final absentDates = await _repository.getAbsentDates();
      emit(state.copyWith(
        attendanceMap: map,
        presentCount: present,
        absentCount: absent,
        presentDates: presentDates,
        absentDates: absentDates,
        isLoading: false,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> saveMembership(MembershipModel membership) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await _repository.saveMembership(membership);
      await loadMembership();
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> markAttendance(DateTime date, bool isPresent) async {
    try {
      await _repository.markAttendance(date, isPresent);
      await loadAttendance();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> deleteAttendance(DateTime date) async {
    try {
      await _repository.deleteAttendance(date);
      await loadAttendance();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> deleteAllAttendance() async {
    try {
      await _repository.deleteAllAttendance();
      await loadAttendance();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> loadWaterIntake() async {
    try {
      final glasses = await _repository.getWaterIntakeForDate(DateTime.now());
      final history = await _repository.getWaterIntakeHistory();
      emit(state.copyWith(waterGlasses: glasses, waterHistory: history));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> addWaterGlass() async {
    try {
      await _repository.addWaterGlass(DateTime.now());
      await loadWaterIntake();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> removeWaterGlass() async {
    try {
      await _repository.removeWaterGlass(DateTime.now());
      await loadWaterIntake();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> resetWaterIntake() async {
    try {
      await _repository.resetWaterIntake(DateTime.now());
      await loadWaterIntake();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> loadUserMetrics() async {
    try {
      final metrics = await _repository.getUserMetrics();
      final height = metrics['height'];
      final weight = metrics['weight'];
      final goalMl = weight != null ? (weight * 33).round() : 0;
      emit(state.copyWith(
        userHeight: height,
        userWeight: weight,
        dailyWaterGoalMl: goalMl,
        clearHeight: height == null,
        clearWeight: weight == null,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> saveUserMetrics({
    required double height,
    required double weight,
  }) async {
    try {
      await _repository.saveUserMetrics(height: height, weight: weight);
      await loadUserMetrics();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> loadStepsHistory() async {
    try {
      final history = await _repository.getStepsHistory();
      emit(state.copyWith(stepsHistory: history));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> saveSteps(DateTime date, int steps) async {
    try {
      final normalized = DateTime(date.year, date.month, date.day);
      await _repository.saveStepsForDate(normalized, steps);
      final newHistory = Map<DateTime, int>.from(state.stepsHistory);
      newHistory[normalized] = steps;
      emit(state.copyWith(stepsHistory: newHistory));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
