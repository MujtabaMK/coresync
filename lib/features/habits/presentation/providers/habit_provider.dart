import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/notification_ids.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/habit_repository.dart';
import '../../domain/habit_model.dart';

enum HabitSortOrder { none, completedFirst, incompleteFirst }

class HabitState extends Equatable {
  const HabitState({
    this.habits = const [],
    this.selectedDate,
    this.isLoading = false,
    this.error,
    this.sortOrder = HabitSortOrder.none,
  });

  final List<HabitModel> habits;
  final DateTime? selectedDate;
  final bool isLoading;
  final String? error;
  final HabitSortOrder sortOrder;

  DateTime get effectiveDate => selectedDate ?? DateTime.now();

  List<HabitModel> get habitsForSelectedDate {
    final date = effectiveDate;
    final filtered = habits.where((h) => h.isScheduledOn(date)).toList();
    switch (sortOrder) {
      case HabitSortOrder.completedFirst:
        filtered.sort((a, b) {
          final ac = a.isCompletedOn(date) ? 0 : 1;
          final bc = b.isCompletedOn(date) ? 0 : 1;
          return ac.compareTo(bc);
        });
      case HabitSortOrder.incompleteFirst:
        filtered.sort((a, b) {
          final ac = a.isCompletedOn(date) ? 1 : 0;
          final bc = b.isCompletedOn(date) ? 1 : 0;
          return ac.compareTo(bc);
        });
      case HabitSortOrder.none:
        break;
    }
    return filtered;
  }

  int get completedCount {
    final date = effectiveDate;
    return habitsForSelectedDate.where((h) => h.isCompletedOn(date)).length;
  }

  int get totalCount => habitsForSelectedDate.length;

  HabitState copyWith({
    List<HabitModel>? habits,
    DateTime? Function()? selectedDate,
    bool? isLoading,
    String? error,
    bool clearError = false,
    HabitSortOrder? sortOrder,
  }) {
    return HabitState(
      habits: habits ?? this.habits,
      selectedDate:
          selectedDate != null ? selectedDate() : this.selectedDate,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [habits, selectedDate, isLoading, error, sortOrder];
}

class HabitCubit extends Cubit<HabitState> {
  HabitCubit({required HabitRepository repository})
      : _repository = repository,
        super(const HabitState());

  final HabitRepository _repository;
  StreamSubscription<List<HabitModel>>? _subscription;

  bool _remindersScheduled = false;

  void loadHabits() {
    emit(state.copyWith(isLoading: true, clearError: true));
    _subscription?.cancel();
    _subscription = _repository.watchHabits().listen(
      (habits) {
        emit(state.copyWith(habits: habits, isLoading: false));
        if (!_remindersScheduled) {
          _remindersScheduled = true;
          _rescheduleAllReminders(habits);
        }
      },
      onError: (e) {
        emit(state.copyWith(isLoading: false, error: e.toString()));
      },
    );
  }

  Future<void> _rescheduleAllReminders(List<HabitModel> habits) async {
    for (final habit in habits) {
      if (habit.reminderEnabled) {
        await scheduleHabitReminders(habit);
      }
    }
  }

  void setSortOrder(HabitSortOrder order) {
    emit(state.copyWith(sortOrder: order));
  }

  void selectDate(DateTime date) {
    emit(state.copyWith(selectedDate: () => date));
  }

  void nextDay() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = state.effectiveDate;
    final currentDay = DateTime(current.year, current.month, current.day);
    if (!currentDay.isBefore(today)) return;
    final next = current.add(const Duration(days: 1));
    emit(state.copyWith(selectedDate: () => next));
  }

  void previousDay() {
    final prev = state.effectiveDate.subtract(const Duration(days: 1));
    emit(state.copyWith(selectedDate: () => prev));
  }

  Future<void> toggleCompletion(String habitId) async {
    try {
      final habit = state.habits.firstWhere((h) => h.id == habitId);
      final date = state.effectiveDate;

      switch (habit.executionType) {
        case ExecutionType.oneTime:
        case ExecutionType.dayCounter:
          await _repository.toggleCompletion(habitId, date);
          break;
        case ExecutionType.multiple:
          final current = habit.completionsOnDate(date);
          if (current >= habit.dailyVolume) {
            // Already complete – reset to 0
            await _repository.decrementCompletion(habitId, date);
          } else {
            await _repository.incrementCompletion(habitId, date);
          }
          break;
        case ExecutionType.trackVolume:
          final current = habit.completionsOnDate(date);
          if (current >= habit.dailyVolume) {
            await _repository.decrementCompletion(habitId, date);
          } else {
            await _repository.incrementCompletion(
              habitId,
              date,
              amount: habit.volumePerPress,
            );
          }
          break;
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> incrementCompletion(String habitId) async {
    try {
      final habit = state.habits.firstWhere((h) => h.id == habitId);
      final date = state.effectiveDate;
      final amount = habit.executionType == ExecutionType.trackVolume
          ? habit.volumePerPress
          : 1;
      await _repository.incrementCompletion(habitId, date, amount: amount);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> addHabit(HabitModel habit) async {
    try {
      await _repository.addHabit(habit);
      if (habit.reminderEnabled) {
        await scheduleHabitReminders(habit);
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> updateHabit(HabitModel habit) async {
    try {
      await _repository.updateHabit(habit);
      await cancelHabitReminders(habit.id);
      if (habit.reminderEnabled) {
        await scheduleHabitReminders(habit);
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> deleteHabit(String habitId) async {
    try {
      await cancelHabitReminders(habitId);
      await _repository.deleteHabit(habitId);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> archiveHabit(String habitId) async {
    try {
      await cancelHabitReminders(habitId);
      await _repository.setArchived(habitId, true);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> saveMeaning(String habitId, String question, String answer) async {
    try {
      await _repository.saveMeaning(habitId, question, answer);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> deleteMeaning(String habitId, String question) async {
    try {
      await _repository.deleteMeaning(habitId, question);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Stream<List<HabitModel>> watchArchivedHabits() {
    return _repository.watchArchivedHabits();
  }

  Future<void> unarchiveHabit(String habitId) async {
    try {
      await _repository.setArchived(habitId, false);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> scheduleHabitReminders(HabitModel habit) async {
    for (final day in habit.reminderDays) {
      await NotificationService.scheduleWeeklyNotification(
        id: NotificationIds.habitReminder(habit.id, day),
        title: '${habit.icon} ${habit.name}',
        body: 'Time to complete your habit!',
        dayOfWeek: day,
        hour: habit.reminderHour,
        minute: habit.reminderMinute,
      );
    }
  }

  Future<void> cancelHabitReminders(String habitId) async {
    for (var day = 1; day <= 7; day++) {
      await NotificationService.cancel(
        NotificationIds.habitReminder(habitId, day),
      );
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
