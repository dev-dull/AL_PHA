import 'package:drift/drift.dart';
import 'package:planyr/features/sync/data/tombstone_repository.dart';
import 'package:planyr/shared/database.dart';
import 'package:planyr/features/tag/domain/tag.dart';

class SeriesTagRepository {
  final PlanyrDatabase _db;
  final TombstoneRepository? _tombstones;

  SeriesTagRepository(this._db, [this._tombstones]);

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

  /// Sets the tag set for a series. Replaces existing assignments.
  ///
  /// Also bumps the parent `recurring_series.updated_at` so the
  /// sync change-tracker's series_tags scan (which joins through
  /// the series row) picks up the edit. Without this, tag-set
  /// changes on existing series silently never reach the cloud
  /// (#52).
  Future<void> setTagsForSeries(
    String seriesId,
    List<String> tagIds,
  ) async {
    assert(tagIds.length <= 4);
    await _db.transaction(() async {
      final tombs = _tombstones;
      if (tombs != null) {
        final newSet = tagIds.toSet();
        for (final old in await (_db.select(_db.seriesTags)
              ..where((st) => st.seriesId.equals(seriesId)))
            .get()) {
          if (!newSet.contains(old.tagId)) {
            await tombs.recordComposite(
              'series_tags',
              old.seriesId,
              old.tagId,
            );
          }
        }
      }
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
      await _touchSeries(seriesId);
    });
  }

  Future<void> deleteForSeries(String seriesId) async {
    final tombs = _tombstones;
    if (tombs != null) {
      for (final st in await (_db.select(_db.seriesTags)
            ..where((st) => st.seriesId.equals(seriesId)))
          .get()) {
        await tombs.recordComposite('series_tags', st.seriesId, st.tagId);
      }
    }
    await (_db.delete(_db.seriesTags)
          ..where((st) => st.seriesId.equals(seriesId)))
        .go();
    await _touchSeries(seriesId);
  }

  /// Bumps `recurring_series.updated_at` so the change-tracker
  /// notices the junction-row change. Same shape as the task_tags
  /// fix in #55.
  Future<void> _touchSeries(String seriesId) async {
    await (_db.update(_db.recurringSeriesTable)
          ..where((s) => s.id.equals(seriesId)))
        .write(RecurringSeriesTableCompanion(
          updatedAt: Value(DateTime.now().toUtc()),
        ));
  }
}
