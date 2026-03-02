import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/gym_repository.dart';
import '../../domain/membership_model.dart';

class GymState {
  const GymState({
    this.activeMembership,
    this.attendanceMap = const {},
    this.presentCount = 0,
    this.absentCount = 0,
    this.isLoading = false,
    this.error,
  });

  final MembershipModel? activeMembership;
  final Map<DateTime, bool> attendanceMap;
  final int presentCount;
  final int absentCount;
  final bool isLoading;
  final String? error;

  GymState copyWith({
    MembershipModel? activeMembership,
    bool clearMembership = false,
    Map<DateTime, bool>? attendanceMap,
    int? presentCount,
    int? absentCount,
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
      await Future.wait([loadMembership(), loadAttendance()]);
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
      emit(state.copyWith(
        attendanceMap: map,
        presentCount: present,
        absentCount: absent,
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
}
