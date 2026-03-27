import 'package:drift/drift.dart';
import 'package:alpha/shared/database.dart';
import 'package:alpha/features/tag/domain/tag.dart';

class TagRepository {
  final AlphaDatabase _db;

  TagRepository(this._db);

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
      ),
    );
    return tag;
  }

  Future<void> delete(String id) async {
    // Remove tag assignments first.
    await (_db.delete(_db.taskTags)
          ..where((tt) => tt.tagId.equals(id)))
        .go();
    await (_db.delete(_db.tags)..where((t) => t.id.equals(id))).go();
  }

  Future<void> reorder(List<String> orderedIds) async {
    await _db.transaction(() async {
      for (var i = 0; i < orderedIds.length; i++) {
        await (_db.update(_db.tags)
              ..where((t) => t.id.equals(orderedIds[i])))
            .write(TagsCompanion(position: Value(i)));
      }
    });
  }
}
