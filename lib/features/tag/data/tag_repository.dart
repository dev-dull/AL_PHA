import 'package:drift/drift.dart';
import 'package:planyr/features/sync/data/tombstone_repository.dart';
import 'package:planyr/shared/database.dart';
import 'package:planyr/features/tag/domain/tag.dart';

class TagRepository {
  final PlanyrDatabase _db;
  final TombstoneRepository? _tombstones;

  TagRepository(this._db, [this._tombstones]);

  Tag _rowToTag(dynamic row) {
    return Tag(
      id: row.id as String,
      name: row.name as String,
      color: row.color as int,
      position: row.position as int,
      createdAt: row.createdAt as DateTime,
    );
  }

  Future<List<Tag>> getAll() async {
    final query = _db.select(_db.tags)
      ..orderBy([(t) => OrderingTerm.asc(t.position)]);
    return (await query.get()).map((r) => _rowToTag(r)).toList();
  }

  Stream<List<Tag>> watchAll() {
    final query = _db.select(_db.tags)
      ..orderBy([(t) => OrderingTerm.asc(t.position)]);
    return query
        .watch()
        .map((rows) => rows.map((r) => _rowToTag(r)).toList());
  }

  Future<Tag> create(Tag tag) async {
    await _db.into(_db.tags).insert(
      TagsCompanion.insert(
        id: tag.id,
        name: tag.name,
        color: tag.color,
        position: tag.position,
        createdAt: tag.createdAt,
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    return tag;
  }

  Future<Tag> update(Tag tag) async {
    await (_db.update(_db.tags)..where((t) => t.id.equals(tag.id)))
        .write(
      TagsCompanion(
        name: Value(tag.name),
        color: Value(tag.color),
        position: Value(tag.position),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    return tag;
  }

  Future<void> delete(String id) async {
    // Tombstone every task_tag assignment so the cloud cleans them
    // up too — otherwise other devices would have orphan task_tag
    // rows pointing at a deleted tag.
    final assignments = await (_db.select(_db.taskTags)
          ..where((tt) => tt.tagId.equals(id)))
        .get();
    for (final tt in assignments) {
      await _tombstones?.recordComposite(
        'task_tags',
        tt.taskId,
        tt.tagId,
      );
    }
    await (_db.delete(_db.taskTags)
          ..where((tt) => tt.tagId.equals(id)))
        .go();
    await (_db.delete(_db.tags)..where((t) => t.id.equals(id))).go();
    await _tombstones?.record('tags', id);
  }

  Future<void> reorder(List<String> orderedIds) async {
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      for (var i = 0; i < orderedIds.length; i++) {
        await (_db.update(_db.tags)
              ..where((t) => t.id.equals(orderedIds[i])))
            .write(
          TagsCompanion(position: Value(i), updatedAt: Value(now)),
        );
      }
    });
  }
}
