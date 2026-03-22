import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:alpha/features/task/domain/task_note.dart';
import 'package:alpha/shared/providers.dart';

part 'task_note_providers.g.dart';

@riverpod
Stream<List<TaskNote>> taskNoteList(
  TaskNoteListRef ref,
  String taskId,
) {
  final repo = ref.watch(taskNoteRepositoryProvider);
  return repo.watchByTask(taskId);
}

@riverpod
TaskNoteActions taskNoteActions(TaskNoteActionsRef ref) {
  return TaskNoteActions(ref);
}

class TaskNoteActions {
  final TaskNoteActionsRef _ref;
  static const _uuid = Uuid();

  TaskNoteActions(this._ref);

  Future<TaskNote> create({
    required String taskId,
    required String content,
  }) async {
    final repo = _ref.read(taskNoteRepositoryProvider);
    final now = DateTime.now();
    final note = TaskNote(
      id: _uuid.v4(),
      taskId: taskId,
      content: content,
      createdAt: now,
      updatedAt: now,
    );
    return repo.create(note);
  }

  Future<void> delete(String id) async {
    final repo = _ref.read(taskNoteRepositoryProvider);
    await repo.delete(id);
  }
}
