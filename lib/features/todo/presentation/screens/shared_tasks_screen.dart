import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/task_model.dart';
import '../../domain/task_status.dart';
import '../providers/todo_provider.dart';
import '../widgets/status_badge.dart';

class SharedTasksScreen extends StatelessWidget {
  const SharedTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodoCubit, TodoState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Shared with Me')),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, TodoState state) {
    if (state.isLoading && state.sharedTasks.isEmpty) {
      return const LoadingWidget(message: 'Loading shared tasks...');
    }

    if (state.error != null && state.sharedTasks.isEmpty) {
      return AppErrorWidget(
        message: state.error!,
        onRetry: () {
          context.read<TodoCubit>().loadSharedTasks();
        },
      );
    }

    final tasks = state.sharedTasks;

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks shared with you yet.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: tasks.length,
      itemBuilder: (context, index) => _SharedTaskTile(task: tasks[index]),
    );
  }
}

class _SharedTaskTile extends StatelessWidget {
  const _SharedTaskTile({required this.task});

  final TaskModel task;

  IconData get _statusIcon {
    switch (task.status) {
      case TaskStatus.notStarted:
        return Icons.circle_outlined;
      case TaskStatus.working:
        return Icons.timelapse;
      case TaskStatus.completed:
        return Icons.check_circle;
    }
  }

  Color get _statusColor {
    switch (task.status) {
      case TaskStatus.notStarted:
        return Colors.grey;
      case TaskStatus.working:
        return Colors.orange;
      case TaskStatus.completed:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: () => context.push('/todo/detail/${task.id}'),
        title: Text(
          task.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description.isNotEmpty)
              Text(
                task.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Text(
              'Owner: ${task.ownerPhone}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
        leading: StatusBadge(status: task.status),
        trailing: Icon(
          _statusIcon,
          color: _statusColor,
        ),
      ),
    );
  }
}
