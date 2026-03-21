/// Sort modes for the task list in a board.
enum TaskSortMode {
  manual,
  alphabetical,
  nextScheduled,
  dueDate,
  priority,
  dateEntered;

  String get displayName {
    switch (this) {
      case TaskSortMode.manual:
        return 'Manual';
      case TaskSortMode.alphabetical:
        return 'A–Z';
      case TaskSortMode.nextScheduled:
        return 'Next Scheduled';
      case TaskSortMode.dueDate:
        return 'Due Date';
      case TaskSortMode.priority:
        return 'Priority';
      case TaskSortMode.dateEntered:
        return 'Date Entered';
    }
  }

  IconLabel get iconLabel {
    switch (this) {
      case TaskSortMode.manual:
        return IconLabel.dragHandle;
      case TaskSortMode.alphabetical:
        return IconLabel.sortByAlpha;
      case TaskSortMode.nextScheduled:
        return IconLabel.calendarToday;
      case TaskSortMode.dueDate:
        return IconLabel.event;
      case TaskSortMode.priority:
        return IconLabel.flag;
      case TaskSortMode.dateEntered:
        return IconLabel.schedule;
    }
  }
}

/// Placeholder for icon references used by the UI.
/// Avoids importing flutter/material in the domain layer.
enum IconLabel {
  dragHandle,
  calendarToday,
  schedule,
  sortByAlpha,
  flag,
  event,
}

/// Sorts a list of tasks by the given [mode].
/// Returns a new sorted list (does not mutate the input).
///
/// [getNextDotPosition] is only required for [TaskSortMode.nextScheduled]
/// and returns the lowest column position with a dot/event marker for a
/// task, or `null` if there are none.
List<T> sortTasks<T>(
  List<T> tasks,
  TaskSortMode mode, {
  required int Function(T) getPosition,
  required DateTime Function(T) getCreatedAt,
  required DateTime? Function(T) getDeadline,
  required String Function(T) getTitle,
  required int Function(T) getPriority,
  int? Function(T)? getNextDotPosition,
}) {
  final sorted = List<T>.of(tasks);
  switch (mode) {
    case TaskSortMode.manual:
      sorted.sort((a, b) => getPosition(a).compareTo(getPosition(b)));
    case TaskSortMode.alphabetical:
      sorted.sort(
        (a, b) =>
            getTitle(a).toLowerCase().compareTo(getTitle(b).toLowerCase()),
      );
    case TaskSortMode.nextScheduled:
      sorted.sort((a, b) {
        final pa = getNextDotPosition?.call(a);
        final pb = getNextDotPosition?.call(b);
        if (pa == null && pb == null) return 0;
        if (pa == null) return 1; // no dots → last
        if (pb == null) return -1;
        return pa.compareTo(pb);
      });
    case TaskSortMode.dueDate:
      sorted.sort((a, b) {
        final da = getDeadline(a);
        final db = getDeadline(b);
        if (da == null && db == null) return 0;
        if (da == null) return 1; // nulls last
        if (db == null) return -1;
        return da.compareTo(db);
      });
    case TaskSortMode.priority:
      sorted.sort((a, b) => getPriority(b).compareTo(getPriority(a)));
    case TaskSortMode.dateEntered:
      sorted.sort((a, b) => getCreatedAt(a).compareTo(getCreatedAt(b)));
  }
  return sorted;
}
