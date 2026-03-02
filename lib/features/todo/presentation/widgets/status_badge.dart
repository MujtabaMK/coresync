import 'package:flutter/material.dart';

import '../../domain/task_status.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final TaskStatus status;

  Color get _backgroundColor {
    switch (status) {
      case TaskStatus.notStarted:
        return Colors.grey.shade200;
      case TaskStatus.working:
        return Colors.orange.shade100;
      case TaskStatus.completed:
        return Colors.green.shade100;
    }
  }

  Color get _textColor {
    switch (status) {
      case TaskStatus.notStarted:
        return Colors.grey.shade700;
      case TaskStatus.working:
        return Colors.orange.shade800;
      case TaskStatus.completed:
        return Colors.green.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: _textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
