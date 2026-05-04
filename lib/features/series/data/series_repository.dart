import 'package:drift/drift.dart';
import 'package:planyr/features/sync/data/tombstone_repository.dart';
import 'package:planyr/shared/database.dart';
import 'package:planyr/features/series/domain/recurring_series.dart';

class SeriesRepository {
  final PlanyrDatabase _db;
  final TombstoneRepository? _tombstones;

  SeriesRepository(this._db, [this._tombstones]);

  RecurringSeries _rowToSeries(dynamic row) {
    return RecurringSeries(
      id: row.id as String,
      title: row.title as String,
      description: row.description as String,
      priority: row.priority as int,
      recurrenceRule: row.recurrenceRule as String,
      isEvent: row.isEvent as bool,
      scheduledTime: row.scheduledTime as String?,
      createdAt: row.createdAt as DateTime,
      endedAt: row.endedAt as DateTime?,
    );
  }

  Future<RecurringSeries> create(RecurringSeries series) async {
    await _db.into(_db.recurringSeriesTable).insert(
      RecurringSeriesTableCompanion.insert(
        id: series.id,
        title: series.title,
        description: Value(series.description),
        priority: Value(series.priority),
        recurrenceRule: series.recurrenceRule,
        isEvent: Value(series.isEvent),
        scheduledTime: Value(series.scheduledTime),
        createdAt: series.createdAt,
        // Bumped on every mutation so series_tags edits push (#52).
        // Set on create to match createdAt for consistency.
        updatedAt: Value(series.createdAt),
        endedAt: Value(series.endedAt),
      ),
    );
    return series;
  }

  Future<RecurringSeries> update(RecurringSeries series) async {
    await (_db.update(_db.recurringSeriesTable)
          ..where((s) => s.id.equals(series.id)))
        .write(
      RecurringSeriesTableCompanion(
        title: Value(series.title),
        description: Value(series.description),
        priority: Value(series.priority),
        recurrenceRule: Value(series.recurrenceRule),
        isEvent: Value(series.isEvent),
        scheduledTime: Value(series.scheduledTime),
        endedAt: Value(series.endedAt),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    return series;
  }

  Future<RecurringSeries?> getById(String id) async {
    final query = _db.select(_db.recurringSeriesTable)
      ..where((s) => s.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _rowToSeries(row) : null;
  }

  Future<List<RecurringSeries>> getActive() async {
    final query = _db.select(_db.recurringSeriesTable)
      ..where((s) => s.endedAt.isNull());
    return (await query.get())
        .map((r) => _rowToSeries(r))
        .toList();
  }

  Stream<List<RecurringSeries>> watchActive() {
    final query = _db.select(_db.recurringSeriesTable)
      ..where((s) => s.endedAt.isNull());
    return query
        .watch()
        .map((rows) => rows.map((r) => _rowToSeries(r)).toList());
  }

  Stream<List<RecurringSeries>> watchAll() {
    final query = _db.select(_db.recurringSeriesTable);
    return query
        .watch()
        .map((rows) => rows.map((r) => _rowToSeries(r)).toList());
  }

  Future<void> end(String id) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.recurringSeriesTable)
          ..where((s) => s.id.equals(id)))
        .write(
      RecurringSeriesTableCompanion(
        endedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> delete(String id) async {
    final tombs = _tombstones;
    if (tombs != null) {
      for (final st in await (_db.select(_db.seriesTags)
            ..where((st) => st.seriesId.equals(id)))
          .get()) {
        await tombs.recordComposite('series_tags', st.seriesId, st.tagId);
      }
    }
    // Delete series tags first.
    await (_db.delete(_db.seriesTags)
          ..where((st) => st.seriesId.equals(id)))
        .go();
    await (_db.delete(_db.recurringSeriesTable)
          ..where((s) => s.id.equals(id)))
        .go();
    await tombs?.record('recurring_series', id);
  }
}
