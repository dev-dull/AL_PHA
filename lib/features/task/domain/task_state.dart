enum TaskState {
  open,
  inProgress,
  complete,
  migrated,
  cancelled;

  String get displayName {
    switch (this) {
      case TaskState.open:
        return 'Open';
      case TaskState.inProgress:
        return 'In Progress';
      case TaskState.complete:
        return 'Complete';
      case TaskState.migrated:
        return 'Migrated';
      case TaskState.cancelled:
        return 'Cancelled';
    }
  }

  bool get isTerminal =>
      this == TaskState.complete ||
      this == TaskState.migrated ||
      this == TaskState.cancelled;
}
