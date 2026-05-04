import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/coach_marks/coach_mark_keys.dart';
import '../../../../core/coach_marks/todo_coach_marks.dart';
import '../../../../core/services/coach_mark_service.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/main_shell_drawer.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/task_model.dart';
import '../../domain/task_status.dart';
import '../providers/todo_provider.dart';
import '../widgets/task_tile.dart';

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  TaskStatus? _selectedFilter;
  bool _isSelectionMode = false;
  final Set<String> _selectedTaskIds = {};
  int _coachMarkVersion = -1;

  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
  }

  void _triggerCoachMark() {
    final v = CoachMarkService.resetVersion;
    if (_coachMarkVersion == v) return;
    _coachMarkVersion = v;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        CoachMarkService.showIfNeeded(
          context: context,
          screenKey: 'coach_mark_todo_shown',
          targets: todoCoachTargets(),
        );
      });
    });
  }

  void _enterSelectionMode(String taskId) {
    setState(() {
      _isSelectionMode = true;
      _selectedTaskIds.add(taskId);
    });
  }

  void _toggleSelection(String taskId) {
    setState(() {
      if (_selectedTaskIds.contains(taskId)) {
        _selectedTaskIds.remove(taskId);
        if (_selectedTaskIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedTaskIds.add(taskId);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedTaskIds.clear();
    });
  }

  Future<void> _deleteSelected() async {
    final count = _selectedTaskIds.length;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete $count ${count == 1 ? 'task' : 'tasks'}?',
      content: 'This action cannot be undone.',
    );
    if (!confirmed || !mounted) return;

    final ids = _selectedTaskIds.toList();
    _exitSelectionMode();
    try {
      await context.read<TodoCubit>().deleteTasks(ids);
      if (mounted) {
        showSuccessSnackBar(
          context,
          '$count ${count == 1 ? 'task' : 'tasks'} deleted',
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Failed to delete: $e');
      }
    }
  }

  void _shareSelected() {
    final ids = _selectedTaskIds.toList();
    _exitSelectionMode();
    context.push('/todo/share-multiple', extra: ids);
  }

  @override
  Widget build(BuildContext context) {
    _triggerCoachMark();
    return BlocBuilder<TodoCubit, TodoState>(
      builder: (context, state) {
        return Scaffold(
          appBar: _isSelectionMode
              ? AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _exitSelectionMode,
                  ),
                  title: Text('${_selectedTaskIds.length} selected'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.share),
                      tooltip: 'Share selected',
                      onPressed:
                          _selectedTaskIds.isEmpty ? null : _shareSelected,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: 'Delete selected',
                      onPressed:
                          _selectedTaskIds.isEmpty ? null : _deleteSelected,
                    ),
                  ],
                )
              : AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: MainShellDrawer.of(context),
                  ),
                  title: const Text('Todo'),
                  actions: [
                    IconButton(
                      key: CoachMarkKeys.todoShared,
                      icon: const Icon(Icons.people_outline),
                      tooltip: 'Shared Tasks',
                      onPressed: () => context.push('/todo/shared'),
                    ),
                    IconButton(
                      key: CoachMarkKeys.todoReports,
                      icon: const Icon(Icons.bar_chart),
                      tooltip: 'Reports',
                      onPressed: () => context.push('/todo/reports'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_outline),
                      tooltip: 'Profile',
                      onPressed: () => context.push('/profile'),
                    ),
                  ],
                ),
          body: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SegmentedButton<TaskStatus?>(
                  key: CoachMarkKeys.todoFilter,
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    textStyle: WidgetStatePropertyAll(
                      Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  segments: const [
                    ButtonSegment(value: null, label: Text('All')),
                    ButtonSegment(
                      value: TaskStatus.notStarted,
                      label: Text('Not Started'),
                    ),
                    ButtonSegment(
                      value: TaskStatus.working,
                      label: Text('Working'),
                    ),
                    ButtonSegment(
                      value: TaskStatus.completed,
                      label: Text('Completed'),
                    ),
                  ],
                  selected: {_selectedFilter},
                  onSelectionChanged: (selection) {
                    setState(() => _selectedFilter = selection.first);
                    context.read<TodoCubit>().setFilter(selection.first);
                  },
                ),
              ),
              if (!_isSelectionMode && state.filteredTasks.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Long press a task to select multiple',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                  ),
                ),
              Expanded(
                child: _buildBody(context, state),
              ),
            ],
          ),
          floatingActionButton: _isSelectionMode
              ? null
              : FloatingActionButton(
                  key: CoachMarkKeys.todoFab,
                  heroTag: 'todoFab',
                  onPressed: () => context.push('/todo/add'),
                  child: const Icon(Icons.add),
                ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, TodoState state) {
    if (state.isLoading && state.myTasks.isEmpty) {
      return const LoadingWidget(message: 'Loading tasks...');
    }

    if (state.error != null && state.myTasks.isEmpty) {
      return AppErrorWidget(
        message: state.error!,
        onRetry: () {
          context.read<TodoCubit>().loadMyTasks();
        },
      );
    }

    final filtered = state.filteredTasks;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.task_alt,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == null
                  ? 'No tasks yet.\nTap + to add one.'
                  : 'No ${_selectedFilter!.label.toLowerCase()} tasks.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    final grouped = _groupByDate(filtered);
    final sortedDates = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final tasks = grouped[date]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                _formatDateHeader(date),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            ...tasks.map((task) {
              final isOwned = task.ownerId == _currentUid;
              return TaskTile(
                task: task,
                isSelectionMode: _isSelectionMode,
                isSelected: _selectedTaskIds.contains(task.id),
                onLongPress: isOwned
                    ? () => _enterSelectionMode(task.id)
                    : null,
                onSelect: isOwned
                    ? () => _toggleSelection(task.id)
                    : null,
              );
            }),
          ],
        );
      },
    );
  }

  Map<DateTime, List<TaskModel>> _groupByDate(List<TaskModel> tasks) {
    final map = <DateTime, List<TaskModel>>{};
    for (final task in tasks) {
      final dateOnly = DateTime(
        task.dueDate.year,
        task.dueDate.month,
        task.dueDate.day,
      );
      map.putIfAbsent(dateOnly, () => []).add(task);
    }
    return map;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    if (date == today) return 'Today';
    if (date == tomorrow) return 'Tomorrow';
    return DateFormat('MMM d, yyyy').format(date);
  }
}
