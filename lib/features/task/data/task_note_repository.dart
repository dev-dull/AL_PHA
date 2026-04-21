import 'package:drift/drift.dart';
import 'package:planyr/shared/database.dart';
import 'package:planyr/features/task/domain/task_note.dart';

class TaskNoteRepository {
  final PlanyrDatabase _db;

  TaskNoteRepository(this._db);

  TaskNote _rowToNote(dynamic row) {
    return TaskNote(
      id: row.id as String,
      taskId: row.taskId as String,
      content: row.content as String,
      createdAt: row.createdAt as DateTime,
      updatedAt: row.updatedAt as DateTime,
    );
  }

  Future<TaskNote> create(TaskNote note) async {
    await _db.into(_db.taskNotes).insert(
      TaskNotesCompanion.insert(
        id: note.id,
        taskId: note.taskId,
        content: note.content,
        createdAt: note.createdAt,
        updatedAt: note.updatedAt,
      ),
    );
    return note;
  }

  Future<TaskNote> update(TaskNote note) async {
    await (_db.update(_db.taskNotes)..where((n) => n.id.equals(note.id)))
        .write(
      TaskNotesCompanion(
        content: Value(note.content),
        updatedAt: Value(note.updatedAt),
      ),
    );
    return note;
  }

  Future<void> delete(String id) async {
    await (_db.delete(_db.taskNotes)..where((n) => n.id.equals(id))).go();
  }

  Future<void> deleteByTask(String taskId) async {
    await (_db.delete(_db.taskNotes)..where((n) => n.taskId.equals(taskId)))
        .go();
  }

  Future<List<TaskNote>> getByTask(String taskId) async {
    final query = _db.select(_db.taskNotes)
      ..where((n) => n.taskId.equals(taskId))
      ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]);
    return (await query.get()).map((r) => _rowToNote(r)).toList();
  }

  Stream<List<TaskNote>> watchByTask(String taskId) {
    final query = _db.select(_db.taskNotes)
      ..where((n) => n.taskId.equals(taskId))
      ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]);
    return query
        .watch()
        .map((rows) => rows.map((r) => _rowToNote(r)).toList());
  }
}
