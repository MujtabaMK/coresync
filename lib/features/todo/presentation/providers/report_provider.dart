import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_helpers.dart';
import '../../domain/task_model.dart';
import '../../domain/task_status.dart';

// ---------------------------------------------------------------------------
// ReportPeriod enum (kept as-is)
// ---------------------------------------------------------------------------

enum ReportPeriod {
  daily,
  weekly,
  monthly,
  yearly;

  String get label {
    switch (this) {
      case ReportPeriod.daily:
        return 'Daily';
      case ReportPeriod.weekly:
        return 'Weekly';
      case ReportPeriod.monthly:
        return 'Monthly';
      case ReportPeriod.yearly:
        return 'Yearly';
    }
  }
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ReportState extends Equatable {
  final ReportPeriod period;
  final Map<String, int> data;

  const ReportState({
    this.period = ReportPeriod.weekly,
    this.data = const {
      'notStarted': 0,
      'working': 0,
      'completed': 0,
      'total': 0,
    },
  });

  ReportState copyWith({
    ReportPeriod? period,
    Map<String, int>? data,
  }) {
    return ReportState(
      period: period ?? this.period,
      data: data ?? this.data,
    );
  }

  @override
  List<Object?> get props => [period, data];
}

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

class ReportCubit extends Cubit<ReportState> {
  ReportCubit() : super(const ReportState());

  /// Change the report period and recalculate from the given tasks.
  void setPeriod(ReportPeriod period, List<TaskModel> tasks) {
    emit(state.copyWith(
      period: period,
      data: _computeReport(tasks, period),
    ));
  }

  /// Recompute report data for the current period with the supplied tasks.
  void computeReport(List<TaskModel> tasks) {
    emit(state.copyWith(
      data: _computeReport(tasks, state.period),
    ));
  }

  // ---- private helpers (same logic as the original provider) ----

  static Map<String, int> _computeReport(
    List<TaskModel> tasks,
    ReportPeriod period,
  ) {
    final now = DateTime.now();
    late final DateTime start;

    switch (period) {
      case ReportPeriod.daily:
        start = DateHelpers.startOfDay(now);
        break;
      case ReportPeriod.weekly:
        start = DateHelpers.startOfWeek(now);
        break;
      case ReportPeriod.monthly:
        start = DateHelpers.startOfMonth(now);
        break;
      case ReportPeriod.yearly:
        start = DateHelpers.startOfYear(now);
        break;
    }

    final filtered = tasks.where((t) => t.createdAt.isAfter(start)).toList();

    int notStarted = 0;
    int working = 0;
    int completed = 0;

    for (final task in filtered) {
      switch (task.status) {
        case TaskStatus.notStarted:
          notStarted++;
          break;
        case TaskStatus.working:
          working++;
          break;
        case TaskStatus.completed:
          completed++;
          break;
      }
    }

    return {
      'notStarted': notStarted,
      'working': working,
      'completed': completed,
      'total': filtered.length,
    };
  }
}
