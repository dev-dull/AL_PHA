enum TaskState {
  open,
  inProgress,
  complete,
  migrated,
  cancelled,
  wontDo;

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
      case TaskState.wontDo:
        return "Won't Do";
    }
  }

  bool get isTerminal =>
      this == TaskState.complete ||
      this == TaskState.migrated ||
      this == TaskState.cancelled ||
      this == TaskState.wontDo;
}
