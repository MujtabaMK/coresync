import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/share_repository.dart';
import '../../data/todo_repository.dart';
import '../../domain/task_model.dart';
import '../../domain/task_status.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class TodoState extends Equatable {
  final List<TaskModel> myTasks;
  final List<TaskModel> sharedTasks;
  final TaskStatus? filter;
  final bool isLoading;
  final String? error;

  const TodoState({
    this.myTasks = const [],
    this.sharedTasks = const [],
    this.filter,
    this.isLoading = false,
    this.error,
  });

  TodoState copyWith({
    List<TaskModel>? myTasks,
    List<TaskModel>? sharedTasks,
    TaskStatus? Function()? filter,
    bool? isLoading,
    String? Function()? error,
  }) {
    return TodoState(
      myTasks: myTasks ?? this.myTasks,
      sharedTasks: sharedTasks ?? this.sharedTasks,
      filter: filter != null ? filter() : this.filter,
      isLoading: isLoading ?? this.isLoading,
      error: error != null ? error() : this.error,
    );
  }

  List<TaskModel> get filteredTasks {
    if (filter == null) return myTasks;
    return myTasks.where((t) => t.status == filter).toList();
  }

  @override
  List<Object?> get props => [myTasks, sharedTasks, filter, isLoading, error];
}

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

class TodoCubit extends Cubit<TodoState> {
  TodoCubit({
    required TodoRepository todoRepository,
    required ShareRepository shareRepository,
    required String uid,
  })  : _todoRepository = todoRepository,
        _shareRepository = shareRepository,
        _uid = uid,
        super(const TodoState(isLoading: true));

  final TodoRepository _todoRepository;
  final ShareRepository _shareRepository;
  final String _uid;

  StreamSubscription<List<TaskModel>>? _myTasksSub;
  StreamSubscription<List<TaskModel>>? _sharedTasksSub;

  /// Public getters so screens can perform one-off repository operations.
  TodoRepository get repository => _todoRepository;
  ShareRepository get shareRepository => _shareRepository;

  /// Subscribe to the current user's own tasks.
  void loadMyTasks() {
    _myTasksSub?.cancel();
    _myTasksSub = _todoRepository.watchMyTasks(_uid).listen(
      (tasks) {
        emit(state.copyWith(myTasks: tasks, isLoading: false, error: () => null));
      },
      onError: (Object e) {
        emit(state.copyWith(isLoading: false, error: () => e.toString()));
      },
    );
  }

  /// Subscribe to tasks shared with the current user.
  void loadSharedTasks() {
    _sharedTasksSub?.cancel();
    _sharedTasksSub = _todoRepository.watchSharedTasks(_uid).listen(
      (tasks) {
        emit(state.copyWith(sharedTasks: tasks, error: () => null));
      },
      onError: (Object e) {
        emit(state.copyWith(error: () => e.toString()));
      },
    );
  }

  /// Set / clear the task‐status filter applied to myTasks.
  void setFilter(TaskStatus? status) {
    emit(state.copyWith(filter: () => status));
  }

  @override
  Future<void> close() {
    _myTasksSub?.cancel();
    _sharedTasksSub?.cancel();
    return super.close();
  }
}
