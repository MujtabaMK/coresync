import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/task_model.dart';
import '../../domain/task_status.dart';
import 'status_badge.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({super.key, required this.task});

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
        subtitle: task.description.isNotEmpty
            ? Text(
                task.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        leading: StatusBadge(status: task.status),
        trailing: Icon(
          _statusIcon,
          color: _statusColor,
        ),
      ),
    );
  }
}
