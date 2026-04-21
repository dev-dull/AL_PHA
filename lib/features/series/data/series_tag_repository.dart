import 'package:drift/drift.dart';
import 'package:planyr/shared/database.dart';
import 'package:planyr/features/tag/domain/tag.dart';

class SeriesTagRepository {
  final PlanyrDatabase _db;

  SeriesTagRepository(this._db);

  Tag _rowToTag(dynamic row) {
    return Tag(
      id: row.id as String,
      name: row.name as String,
      color: row.color as int,
      position: row.position as int,
      createdAt: row.createdAt as DateTime,
    );
  }

  Future<List<Tag>> getTagsForSeries(String seriesId) async {
    final query = _db.select(_db.seriesTags).join([
      innerJoin(
          _db.tags, _db.tags.id.equalsExp(_db.seriesTags.tagId)),
    ])
      ..where(_db.seriesTags.seriesId.equals(seriesId))
      ..orderBy([OrderingTerm.asc(_db.seriesTags.slot)]);
    return (await query.get())
        .map((row) => _rowToTag(row.readTable(_db.tags)))
        .toList();
  }

  Future<void> setTagsForSeries(
    String seriesId,
    List<String> tagIds,
  ) async {
    assert(tagIds.length <= 4);
    await _db.transaction(() async {
      await (_db.delete(_db.seriesTags)
            ..where((st) => st.seriesId.equals(seriesId)))
          .go();
      for (var i = 0; i < tagIds.length; i++) {
        await _db.into(_db.seriesTags).insert(
          SeriesTagsCompanion.insert(
            seriesId: seriesId,
            tagId: tagIds[i],
            slot: i,
          ),
        );
      }
    });
  }

  Future<void> deleteForSeries(String seriesId) async {
    await (_db.delete(_db.seriesTags)
          ..where((st) => st.seriesId.equals(seriesId)))
        .go();
  }
}
