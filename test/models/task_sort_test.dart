import 'package:flutter_test/flutter_test.dart';
import 'package:planyr/features/task/domain/task.dart';
import 'package:planyr/features/task/domain/task_sort.dart';

List<Task> _sort(List<Task> tasks, TaskSortMode mode) {
  return sortTasks(
    tasks,
    mode,
    getPosition: (t) => t.position,
    getCreatedAt: (t) => t.createdAt,
    getDeadline: (t) => t.deadline,
    getTitle: (t) => t.title,
    getPriority: (t) => t.priority,
  );
}

void main() {
  final tasks = [
    Task(
      id: '1',
      boardId: 'b',
      title: 'Zebra task',
      position: 2,
      priority: 1,
      createdAt: DateTime(2026, 3, 17),
      deadline: DateTime(2026, 3, 20),
    ),
    Task(
      id: '2',
      boardId: 'b',
      title: 'Alpha task',
      position: 0,
      priority: 3,
      createdAt: DateTime(2026, 3, 15),
      deadline: DateTime(2026, 3, 18),
    ),
    Task(
      id: '3',
      boardId: 'b',
      title: 'Middle task',
      position: 1,
      priority: 2,
      createdAt: DateTime(2026, 3, 16),
    ),
  ];

  group('TaskSortMode', () {
    test('manual sorts by position', () {
      final sorted = _sort(tasks, TaskSortMode.manual);
      expect(sorted.map((t) => t.id), ['2', '3', '1']);
    });

    test('alphabetical sorts by title (case-insensitive)', () {
      final sorted = _sort(tasks, TaskSortMode.alphabetical);
      expect(sorted.map((t) => t.id), ['2', '3', '1']);
    });

    test('dateEntered sorts by createdAt', () {
      final sorted = _sort(tasks, TaskSortMode.dateEntered);
      expect(sorted.map((t) => t.id), ['2', '3', '1']);
    });

    test('dueDate sorts by deadline with nulls last', () {
      final sorted = _sort(tasks, TaskSortMode.dueDate);
      // task 2 (Mar 18) → task 1 (Mar 20) → task 3 (null)
      expect(sorted.map((t) => t.id), ['2', '1', '3']);
    });

    test('priority sorts high to low', () {
      final sorted = _sort(tasks, TaskSortMode.priority);
      // task 2 (pri 3) → task 3 (pri 2) → task 1 (pri 1)
      expect(sorted.map((t) => t.id), ['2', '3', '1']);
    });

    test('nextScheduled sorts by earliest dot position', () {
      // Simulate dot positions: task 1 → day 4, task 2 → day 1, task 3 → null
      final dotPositions = {'1': 4, '2': 1};
      final sorted = sortTasks(
        tasks,
        TaskSortMode.nextScheduled,
        getPosition: (t) => t.position,
        getCreatedAt: (t) => t.createdAt,
        getDeadline: (t) => t.deadline,
        getTitle: (t) => t.title,
        getPriority: (t) => t.priority,
        getNextDotPosition: (t) => dotPositions[t.id],
      );
      // task 2 (day 1) → task 1 (day 4) → task 3 (null, last)
      expect(sorted.map((t) => t.id), ['2', '1', '3']);
    });

    test('does not mutate original list', () {
      final original = List<Task>.of(tasks);
      _sort(tasks, TaskSortMode.priority);
      expect(tasks.map((t) => t.id), original.map((t) => t.id));
    });

    test('all sort modes have display names', () {
      for (final mode in TaskSortMode.values) {
        expect(mode.displayName, isNotEmpty);
      }
    });
  });
}
