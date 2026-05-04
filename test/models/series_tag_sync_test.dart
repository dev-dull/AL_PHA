import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:planyr/features/series/domain/recurring_series.dart';
import 'package:planyr/features/sync/data/change_tracker.dart';
import 'package:planyr/features/tag/domain/tag.dart';
import 'package:planyr/shared/database.dart';
import 'package:planyr/shared/providers.dart';

/// Regression for #52.
///
/// `series_tags` is a junction without a per-row timestamp. The
/// change-tracker joins through `recurring_series` to detect
/// changes — pre-fix, on `recurring_series.created_at`, which
/// never moves after row creation. Tag-set edits to existing
/// series silently never pushed.
///
/// The fix gives `recurring_series` an `updated_at` column,
/// bumped by `SeriesTagRepository.setTagsForSeries` /
/// `deleteForSeries` and by every other series mutation. The
/// scan and the LWW comparison both move to that column.
void main() {
  late PlanyrDatabase db;
  late ProviderContainer container;
  const uuid = Uuid();

  setUp(() {
    db = PlanyrDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [planyrDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() {
    container.dispose();
    db.close();
  });

  Future<RecurringSeries> seedSeries(DateTime created) async {
    final repo = container.read(seriesRepositoryProvider);
    final s = RecurringSeries(
      id: uuid.v4(),
      title: 'Take meds',
      recurrenceRule: 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU',
      createdAt: created,
    );
    return repo.create(s);
  }

  Future<DateTime?> readSeriesUpdatedAt(String id) async {
    final row = await (db.select(db.recurringSeriesTable)
          ..where((s) => s.id.equals(id)))
        .getSingle();
    return row.updatedAt;
  }

  test('setTagsForSeries bumps recurring_series.updated_at so the '
      'sync change-tracker picks up the edit', () async {
    final created = DateTime.utc(2026, 4, 1);
    final series = await seedSeries(created);

    // Force updated_at into the past so we can detect the bump.
    final stale = DateTime.utc(2026, 4, 1);
    await (db.update(db.recurringSeriesTable)
          ..where((s) => s.id.equals(series.id)))
        .write(RecurringSeriesTableCompanion(updatedAt: Value(stale)));

    final tagId = uuid.v4();
    await container.read(tagRepositoryProvider).create(Tag(
          id: tagId,
          name: 'Not dead yet',
          color: 0xFF00FF00,
          position: 0,
          createdAt: created,
        ));

    await container
        .read(seriesTagRepositoryProvider)
        .setTagsForSeries(series.id, [tagId]);

    final after = await readSeriesUpdatedAt(series.id);
    expect(after, isNotNull);
    expect(after!.isAfter(stale), isTrue,
        reason: 'updated_at must advance when series tags change');
  });

  test('ChangeTracker emits the new series_tags row to push after '
      'a tag-only edit on an existing series (the bug that hid '
      'series tag changes from other devices)', () async {
    // Sync cursor: "everything before T0 is already pushed."
    final t0 = DateTime.utc(2026, 4, 15);

    // Series + tag created BEFORE the cursor — neither is "new"
    // in the eyes of the change tracker.
    final series = await seedSeries(t0.subtract(const Duration(days: 7)));
    await (db.update(db.recurringSeriesTable)
          ..where((s) => s.id.equals(series.id)))
        .write(RecurringSeriesTableCompanion(
            updatedAt: Value(t0.subtract(const Duration(days: 7)))));

    final tagId = uuid.v4();
    await container.read(tagRepositoryProvider).create(Tag(
          id: tagId,
          name: 'Not dead yet',
          color: 0xFF00FF00,
          position: 0,
          createdAt: t0.subtract(const Duration(days: 7)),
        ));

    // *Now* (after the cursor) the user assigns the tag.
    await container
        .read(seriesTagRepositoryProvider)
        .setTagsForSeries(series.id, [tagId]);

    final tracker = ChangeTracker(db);
    final changes = await tracker.getChangesSince(t0);

    final stPushes = changes
        .where((c) => c.table == 'series_tags' && !c.deleted)
        .toList();
    expect(stPushes, hasLength(1));
    expect(stPushes.single.data['series_id'], series.id);
    expect(stPushes.single.data['tag_id'], tagId);

    // Series row itself should also push because its updated_at
    // was bumped.
    final seriesPushes = changes
        .where((c) => c.table == 'recurring_series' && !c.deleted)
        .toList();
    expect(seriesPushes, hasLength(1));
    expect(seriesPushes.single.id, series.id);
  });

  test('deleteForSeries also bumps updated_at + tombstones each '
      'junction row', () async {
    final series = await seedSeries(DateTime.utc(2026, 4, 1));
    final tagId = uuid.v4();
    await container.read(tagRepositoryProvider).create(Tag(
          id: tagId,
          name: 't',
          color: 0xFF000000,
          position: 0,
          createdAt: DateTime.utc(2026, 4, 1),
        ));
    final stRepo = container.read(seriesTagRepositoryProvider);
    await stRepo.setTagsForSeries(series.id, [tagId]);

    // Drift stores DateTime as integer SECONDS, so two writes in
    // the same second round to the same value. Force preDelete
    // into the past explicitly so the comparison can detect the
    // bump.
    final stale = DateTime.utc(2026, 4, 1);
    await (db.update(db.recurringSeriesTable)
          ..where((s) => s.id.equals(series.id)))
        .write(RecurringSeriesTableCompanion(updatedAt: Value(stale)));

    await stRepo.deleteForSeries(series.id);

    final postDelete = await readSeriesUpdatedAt(series.id);
    expect(postDelete!.isAfter(stale), isTrue);
  });
}
