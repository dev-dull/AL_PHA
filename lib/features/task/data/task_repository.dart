import 'package:drift/drift.dart';
import 'package:alpha/shared/database.dart';
import 'package:alpha/features/task/domain/task.dart';
import 'package:alpha/features/task/domain/task_state.dart' as domain;

class TaskRepository {
  final AlphaDatabase _db;

  TaskRepository(this._db);

  Task _rowToTask(dynamic row) {
    return Task(
      id: row.id as String,
      boardId: row.boardId as String,
      title: row.title as String,
      description: row.description as String,
      state: domain.TaskState.values.byName(row.state as String),
      priority: row.priority as int,
      position: row.position as int,
      createdAt: row.createdAt as DateTime,
      completedAt: row.completedAt as DateTime?,
      deadline: row.deadline as DateTime?,
      migratedFromBoardId: row.migratedFromBoardId as String?,
      migratedFromTaskId: row.migratedFromTaskId as String?,
      isEvent: row.isEvent as bool,
      scheduledTime: row.scheduledTime as String?,
      recurrenceRule: row.recurrenceRule as String?,
    );
  }

  Future<Task> create(Task task) async {
    await _db
        .into(_db.tasks)
        .insert(
          TasksCompanion.insert(
            id: task.id,
            boardId: task.boardId,
            title: task.title,
            description: Value(task.description),
            state: Value(task.state.name),
            priority: Value(task.priority),
            position: task.position,
            createdAt: task.createdAt,
            completedAt: Value(task.completedAt),
            deadline: Value(task.deadline),
            migratedFromBoardId: Value(task.migratedFromBoardId),
            migratedFromTaskId: Value(task.migratedFromTaskId),
            isEvent: Value(task.isEvent),
            scheduledTime: Value(task.scheduledTime),
            recurrenceRule: Value(task.recurrenceRule),
          ),
        );
    return task;
  }

  Future<List<Task>> getByBoard(String boardId) async {
    final query = _db.select(_db.tasks)
      ..where((t) => t.boardId.equals(boardId))
      ..orderBy([(t) => OrderingTerm.asc(t.position)]);
    return (await query.get()).map((r) => _rowToTask(r)).toList();
  }

  Future<Task?> getById(String id) async {
    final query = _db.select(_db.tasks)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _rowToTask(row) : null;
  }

  Future<Task> update(Task task) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(task.id))).write(
      TasksCompanion(
        title: Value(task.title),
        description: Value(task.description),
        state: Value(task.state.name),
        priority: Value(task.priority),
        position: Value(task.position),
        completedAt: Value(task.completedAt),
        deadline: Value(task.deadline),
        isEvent: Value(task.isEvent),
        scheduledTime: Value(task.scheduledTime),
        recurrenceRule: Value(task.recurrenceRule),
      ),
    );
    return task;
  }

  Future<Task> complete(String id) async {
    final now = DateTime.now();
    await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        state: Value(domain.TaskState.complete.name),
        completedAt: Value(now),
      ),
    );
    final task = await getById(id);
    return task!;
  }

  Future<Task> cancel(String id) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(state: Value(domain.TaskState.cancelled.name)),
    );
    final task = await getById(id);
    return task!;
  }

  Future<void> reorder(String boardId, List<String> taskIds) async {
    await _db.transaction(() async {
      for (var i = 0; i < taskIds.length; i++) {
        await (_db.update(_db.tasks)..where((t) => t.id.equals(taskIds[i])))
            .write(TasksCompanion(position: Value(i)));
      }
    });
  }

  Future<void> delete(String id) async {
    await (_db.delete(_db.tasks)..where((t) => t.id.equals(id))).go();
  }

  Future<int> getNextPosition(String boardId) async {
    final query = _db.select(_db.tasks)
      ..where((t) => t.boardId.equals(boardId))
      ..orderBy([(t) => OrderingTerm.desc(t.position)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return (row?.position ?? -1) + 1;
  }

  Stream<List<Task>> watchByBoard(String boardId) {
    final query = _db.select(_db.tasks)
      ..where((t) => t.boardId.equals(boardId))
      ..orderBy([(t) => OrderingTerm.asc(t.position)]);
    return query.watch().map((rows) => rows.map((r) => _rowToTask(r)).toList());
  }
}
