/// Sort modes for the task list in a board.
enum TaskSortMode {
  manual,
  dueDate,
  dateEntered,
  alphabetical,
  priority;

  String get displayName {
    switch (this) {
      case TaskSortMode.manual:
        return 'Manual';
      case TaskSortMode.dueDate:
        return 'Due Date';
      case TaskSortMode.dateEntered:
        return 'Date Entered';
      case TaskSortMode.alphabetical:
        return 'A–Z';
      case TaskSortMode.priority:
        return 'Priority';
    }
  }

  IconLabel get iconLabel {
    switch (this) {
      case TaskSortMode.manual:
        return IconLabel.dragHandle;
      case TaskSortMode.dueDate:
        return IconLabel.calendarToday;
      case TaskSortMode.dateEntered:
        return IconLabel.schedule;
      case TaskSortMode.alphabetical:
        return IconLabel.sortByAlpha;
      case TaskSortMode.priority:
        return IconLabel.flag;
    }
  }
}

/// Placeholder for icon references used by the UI.
/// Avoids importing flutter/material in the domain layer.
enum IconLabel { dragHandle, calendarToday, schedule, sortByAlpha, flag }

/// Sorts a list of tasks by the given [mode].
/// Returns a new sorted list (does not mutate the input).
List<T> sortTasks<T>(
  List<T> tasks,
  TaskSortMode mode, {
  required int Function(T) getPosition,
  required DateTime Function(T) getCreatedAt,
  required DateTime? Function(T) getDeadline,
  required String Function(T) getTitle,
  required int Function(T) getPriority,
}) {
  final sorted = List<T>.of(tasks);
  switch (mode) {
    case TaskSortMode.manual:
      sorted.sort((a, b) => getPosition(a).compareTo(getPosition(b)));
    case TaskSortMode.dueDate:
      sorted.sort((a, b) {
        final da = getDeadline(a);
        final db = getDeadline(b);
        if (da == null && db == null) return 0;
        if (da == null) return 1; // nulls last
        if (db == null) return -1;
        return da.compareTo(db);
      });
    case TaskSortMode.dateEntered:
      sorted.sort((a, b) => getCreatedAt(a).compareTo(getCreatedAt(b)));
    case TaskSortMode.alphabetical:
      sorted.sort(
        (a, b) =>
            getTitle(a).toLowerCase().compareTo(getTitle(b).toLowerCase()),
      );
    case TaskSortMode.priority:
      sorted.sort((a, b) => getPriority(b).compareTo(getPriority(a)));
  }
  return sorted;
}
