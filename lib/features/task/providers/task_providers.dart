import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:alpha/features/task/domain/task.dart';
import 'package:alpha/features/task/domain/task_state.dart';
import 'package:alpha/shared/providers.dart';

part 'task_providers.g.dart';

@riverpod
Stream<List<Task>> taskList(TaskListRef ref, String boardId) {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.watchByBoard(boardId);
}

/// Helper class for task mutations. Access via ref.read.
@riverpod
TaskActions taskActions(TaskActionsRef ref) {
  return TaskActions(ref);
}

class TaskActions {
  final TaskActionsRef _ref;

  TaskActions(this._ref);

  Future<Task> create(Task task) async {
    final repo = _ref.read(taskRepositoryProvider);
    return repo.create(task);
  }

  Future<Task> update(Task task) async {
    final repo = _ref.read(taskRepositoryProvider);
    return repo.update(task);
  }

  Future<void> reorder(String boardId, List<String> taskIds) async {
    final repo = _ref.read(taskRepositoryProvider);
    await repo.reorder(boardId, taskIds);
  }

  Future<Task> reopen(String id) async {
    final repo = _ref.read(taskRepositoryProvider);
    final task = await repo.getById(id);
    if (task == null) throw StateError('Task $id not found');
    final updated = task.copyWith(
      state: TaskState.open,
      completedAt: null,
    );
    return repo.update(updated);
  }

  Future<Task> wontDo(String id) async {
    final repo = _ref.read(taskRepositoryProvider);
    final task = await repo.getById(id);
    if (task == null) throw StateError('Task $id not found');
    final updated = task.copyWith(state: TaskState.wontDo);
    return repo.update(updated);
  }

  Future<void> delete(String id) async {
    final noteRepo = _ref.read(taskNoteRepositoryProvider);
    await noteRepo.deleteByTask(id);
    final tagRepo = _ref.read(taskTagRepositoryProvider);
    await tagRepo.deleteByTask(id);
    final repo = _ref.read(taskRepositoryProvider);
    await repo.delete(id);
  }

  /// Updates all instances of a recurring series with the same
  /// title, description, priority, recurrence rule, etc.
  /// Preserves each instance's board, position, and state.
  /// If [tagIds] is provided, applies the same tags to all.
  Future<void> updateSeries(
    Task updated, {
    List<String>? tagIds,
  }) async {
    final repo = _ref.read(taskRepositoryProvider);
    final tagRepo = _ref.read(taskTagRepositoryProvider);
    final instances = await repo.findSeriesInstances(updated);
    for (final instance in instances) {
      await repo.update(instance.copyWith(
        title: updated.title,
        description: updated.description,
        priority: updated.priority,
        deadline: updated.deadline,
        isEvent: updated.isEvent,
        scheduledTime: updated.scheduledTime,
        recurrenceRule: updated.recurrenceRule,
      ));
      if (tagIds != null) {
        await tagRepo.setTagsForTask(instance.id, tagIds);
      }
    }
  }

  /// Deletes all instances of a recurring series across all boards.
  Future<void> deleteSeries(Task task) async {
    final repo = _ref.read(taskRepositoryProvider);
    final noteRepo = _ref.read(taskNoteRepositoryProvider);
    final instances = await repo.findSeriesInstances(task);
    for (final instance in instances) {
      await noteRepo.deleteByTask(instance.id);
      await repo.delete(instance.id);
    }
  }
}
