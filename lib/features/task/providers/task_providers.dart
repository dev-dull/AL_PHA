import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:alpha/features/task/domain/task.dart';
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

  Future<Task> complete(String id) async {
    final repo = _ref.read(taskRepositoryProvider);
    return repo.complete(id);
  }

  Future<Task> cancel(String id) async {
    final repo = _ref.read(taskRepositoryProvider);
    return repo.cancel(id);
  }

  Future<void> reorder(String boardId, List<String> taskIds) async {
    final repo = _ref.read(taskRepositoryProvider);
    await repo.reorder(boardId, taskIds);
  }

  Future<void> delete(String id) async {
    final noteRepo = _ref.read(taskNoteRepositoryProvider);
    await noteRepo.deleteByTask(id);
    final repo = _ref.read(taskRepositoryProvider);
    await repo.delete(id);
  }
}
