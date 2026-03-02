enum TaskStatus {
  notStarted,
  working,
  completed;

  String get label {
    switch (this) {
      case TaskStatus.notStarted:
        return 'Not Started';
      case TaskStatus.working:
        return 'Working';
      case TaskStatus.completed:
        return 'Completed';
    }
  }

  String get value {
    switch (this) {
      case TaskStatus.notStarted:
        return 'notStarted';
      case TaskStatus.working:
        return 'working';
      case TaskStatus.completed:
        return 'completed';
    }
  }

  static TaskStatus fromString(String value) {
    return TaskStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => TaskStatus.notStarted,
    );
  }
}
