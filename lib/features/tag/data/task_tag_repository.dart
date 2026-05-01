import 'package:drift/drift.dart';
import 'package:planyr/features/sync/data/tombstone_repository.dart';
import 'package:planyr/shared/database.dart';
import 'package:planyr/features/tag/domain/tag.dart';

class TaskTagRepository {
  final PlanyrDatabase _db;
  final TombstoneRepository? _tombstones;

  TaskTagRepository(this._db, [this._tombstones]);

  Tag _rowToTag(dynamic row) {
    return Tag(
      id: row.id as String,
      name: row.name as String,
      color: row.color as int,
      position: row.position as int,
      createdAt: row.createdAt as DateTime,
    );
  }

  /// Returns the tags assigned to a task, ordered by slot (0-3).
  Future<List<Tag>> getTagsForTask(String taskId) async {
    final query = _db.select(_db.taskTags).join([
      innerJoin(_db.tags, _db.tags.id.equalsExp(_db.taskTags.tagId)),
    ])
      ..where(_db.taskTags.taskId.equals(taskId))
      ..orderBy([OrderingTerm.asc(_db.taskTags.slot)]);
    final rows = await query.get();
    return rows.map((row) => _rowToTag(row.readTable(_db.tags))).toList();
  }

  /// Watches the tags assigned to a task.
  Stream<List<Tag>> watchTagsForTask(String taskId) {
    final query = _db.select(_db.taskTags).join([
      innerJoin(_db.tags, _db.tags.id.equalsExp(_db.taskTags.tagId)),
    ])
      ..where(_db.taskTags.taskId.equals(taskId))
      ..orderBy([OrderingTerm.asc(_db.taskTags.slot)]);
    return query.watch().map(
      (rows) =>
          rows.map((row) => _rowToTag(row.readTable(_db.tags))).toList(),
    );
  }

  /// Returns tag assignments for all tasks on a board,
  /// keyed by task ID.
  Stream<Map<String, List<Tag>>> watchTagsByBoard(String boardId) {
    final query = _db.select(_db.taskTags).join([
      innerJoin(_db.tags, _db.tags.id.equalsExp(_db.taskTags.tagId)),
      innerJoin(
        _db.tasks,
        _db.tasks.id.equalsExp(_db.taskTags.taskId),
      ),
    ])
      ..where(_db.tasks.boardId.equals(boardId))
      ..orderBy([OrderingTerm.asc(_db.taskTags.slot)]);

    return query.watch().map((rows) {
      final result = <String, List<Tag>>{};
      for (final row in rows) {
        final taskId = row.readTable(_db.taskTags).taskId;
        final tag = _rowToTag(row.readTable(_db.tags));
        result.putIfAbsent(taskId, () => []).add(tag);
      }
      return result;
    });
  }

  /// Sets the tags for a task (max 4). Replaces existing assignments.
  ///
  /// Also bumps the parent `tasks.updated_at`. The sync change-tracker
  /// scans `task_tags` via `JOIN tasks WHERE t.updated_at > ?` because
  /// the junction has no per-row timestamp of its own; without bumping
  /// the parent here, tag changes never reach the cloud and other
  /// devices keep showing stale tag state.
  Future<void> setTagsForTask(String taskId, List<String> tagIds) async {
    assert(tagIds.length <= 4, 'Max 4 tags per task');
    await _db.transaction(() async {
      // Tombstone the old set so removed tags propagate.
      final tombs = _tombstones;
      if (tombs != null) {
        final newSet = tagIds.toSet();
        for (final old in await (_db.select(_db.taskTags)
              ..where((tt) => tt.taskId.equals(taskId)))
            .get()) {
          if (!newSet.contains(old.tagId)) {
            await tombs.recordComposite(
              'task_tags',
              old.taskId,
              old.tagId,
            );
          }
        }
      }
      await (_db.delete(_db.taskTags)
            ..where((tt) => tt.taskId.equals(taskId)))
          .go();
      for (var i = 0; i < tagIds.length; i++) {
        await _db.into(_db.taskTags).insert(
          TaskTagsCompanion.insert(
            taskId: taskId,
            tagId: tagIds[i],
            slot: i,
          ),
        );
      }
      await _touchTask(taskId);
    });
  }

  /// Bumps `tasks.updated_at` so the change-tracker's timestamp scan
  /// picks up the related junction-row changes.
  Future<void> _touchTask(String taskId) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId)))
        .write(TasksCompanion(updatedAt: Value(DateTime.now().toUtc())));
  }

  /// Removes all tag assignments for a task.
  Future<void> deleteByTask(String taskId) async {
    final tombs = _tombstones;
    if (tombs != null) {
      for (final tt in await (_db.select(_db.taskTags)
            ..where((tt) => tt.taskId.equals(taskId)))
          .get()) {
        await tombs.recordComposite('task_tags', tt.taskId, tt.tagId);
      }
    }
    await (_db.delete(_db.taskTags)
          ..where((tt) => tt.taskId.equals(taskId)))
        .go();
  }
}
