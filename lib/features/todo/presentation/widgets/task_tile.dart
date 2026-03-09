import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/task_model.dart';
import 'status_badge.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onLongPress,
    this.onSelect,
  });

  final TaskModel task;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: isSelectionMode
            ? onSelect
            : () => context.push('/todo/detail/${task.id}'),
        onLongPress: isSelectionMode ? null : onLongPress,
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 2),
            Text(
              DateFormat('MMM d').format(task.dueDate),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        leading: isSelectionMode
            ? Checkbox(
                value: isSelected,
                onChanged: (_) => onSelect?.call(),
              )
            : StatusBadge(status: task.status),
      ),
    );
  }
}
