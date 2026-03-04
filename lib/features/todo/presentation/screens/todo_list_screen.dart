import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodoCubit, TodoState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Todo'),
            actions: [
              IconButton(
                icon: const Icon(Icons.people_outline),
                tooltip: 'Shared Tasks',
                onPressed: () => context.push('/todo/shared'),
              ),
              IconButton(
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
              Expanded(
                child: _buildBody(context, state),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
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
            ...tasks.map((task) => TaskTile(task: task)),
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
