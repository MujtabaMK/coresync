import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/exercise_data.dart';
import '../../domain/exercise_model.dart';
import '../../domain/workout_program_model.dart';

enum WorkoutStatus { idle, exercising, resting, paused, completed }

class WorkoutState {
  final WorkoutStatus status;
  final int currentIndex;
  final int timeRemaining;
  final WorkoutProgram program;
  final WorkoutStatus statusBeforePause;

  const WorkoutState({
    required this.status,
    required this.currentIndex,
    required this.timeRemaining,
    required this.program,
    this.statusBeforePause = WorkoutStatus.exercising,
  });

  ExerciseModel? get currentExercise {
    if (currentIndex >= program.exercises.length) return null;
    return ExerciseData.getById(program.exercises[currentIndex].exerciseId);
  }

  WorkoutExercise? get currentWorkoutExercise {
    if (currentIndex >= program.exercises.length) return null;
    return program.exercises[currentIndex];
  }

  bool get isTimeBased {
    final exercise = currentExercise;
    if (exercise == null) return false;
    final we = currentWorkoutExercise!;
    return exercise.isTimeBased || we.durationSecs != null;
  }

  int get displayReps {
    final we = currentWorkoutExercise;
    final exercise = currentExercise;
    if (we == null || exercise == null) return 0;
    return we.reps ?? exercise.defaultReps;
  }

  int get totalExercises => program.exercises.length;

  ExerciseModel? get nextExercise {
    final nextIdx = currentIndex + 1;
    if (nextIdx >= program.exercises.length) return null;
    return ExerciseData.getById(program.exercises[nextIdx].exerciseId);
  }

  WorkoutState copyWith({
    WorkoutStatus? status,
    int? currentIndex,
    int? timeRemaining,
    WorkoutProgram? program,
    WorkoutStatus? statusBeforePause,
  }) {
    return WorkoutState(
      status: status ?? this.status,
      currentIndex: currentIndex ?? this.currentIndex,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      program: program ?? this.program,
      statusBeforePause: statusBeforePause ?? this.statusBeforePause,
    );
  }
}

class WorkoutCubit extends Cubit<WorkoutState> {
  static const _restDurationSecs = 15;
  Timer? _timer;

  WorkoutCubit(WorkoutProgram program)
      : super(WorkoutState(
          status: WorkoutStatus.idle,
          currentIndex: 0,
          timeRemaining: 0,
          program: program,
        ));

  void start() {
    emit(state.copyWith(
      status: WorkoutStatus.exercising,
      currentIndex: 0,
    ));
    _startExerciseTimer();
  }

  void _startExerciseTimer() {
    _timer?.cancel();
    if (state.isTimeBased) {
      final we = state.currentWorkoutExercise!;
      final exercise = state.currentExercise!;
      final duration =
          we.durationSecs ?? exercise.defaultDurationSecs;
      emit(state.copyWith(timeRemaining: duration));
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (state.status == WorkoutStatus.paused) return;
        final remaining = state.timeRemaining - 1;
        if (remaining <= 0) {
          _timer?.cancel();
          _onExerciseComplete();
        } else {
          emit(state.copyWith(timeRemaining: remaining));
        }
      });
    }
  }

  void markRepsDone() {
    if (state.status != WorkoutStatus.exercising) return;
    if (state.isTimeBased) return;
    _onExerciseComplete();
  }

  void _onExerciseComplete() {
    _timer?.cancel();
    final nextIndex = state.currentIndex + 1;
    if (nextIndex >= state.totalExercises) {
      emit(state.copyWith(status: WorkoutStatus.completed));
      return;
    }
    // Start rest
    emit(state.copyWith(
      status: WorkoutStatus.resting,
      timeRemaining: _restDurationSecs,
    ));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status == WorkoutStatus.paused) return;
      final remaining = state.timeRemaining - 1;
      if (remaining <= 0) {
        _timer?.cancel();
        _moveToNextExercise(nextIndex);
      } else {
        emit(state.copyWith(timeRemaining: remaining));
      }
    });
  }

  void _moveToNextExercise(int index) {
    emit(state.copyWith(
      status: WorkoutStatus.exercising,
      currentIndex: index,
    ));
    _startExerciseTimer();
  }

  void skipRest() {
    if (state.status != WorkoutStatus.resting) return;
    _timer?.cancel();
    _moveToNextExercise(state.currentIndex + 1);
  }

  void togglePause() {
    if (state.status == WorkoutStatus.paused) {
      emit(state.copyWith(status: state.statusBeforePause));
    } else if (state.status == WorkoutStatus.exercising ||
        state.status == WorkoutStatus.resting) {
      emit(state.copyWith(
        status: WorkoutStatus.paused,
        statusBeforePause: state.status,
      ));
    }
  }

  void skipToNext() {
    _timer?.cancel();
    _onExerciseComplete();
  }

  void goToPrevious() {
    if (state.currentIndex <= 0) return;
    _timer?.cancel();
    _moveToNextExercise(state.currentIndex - 1);
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
