import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:planyr/features/sync/data/change_tracker.dart';
import 'package:planyr/features/tag/domain/tag.dart';
import 'package:planyr/shared/database.dart';
import 'package:planyr/shared/providers.dart';

/// Regression: tag rename / recolor / reorder must reach the
/// cloud. Before the schema-v11 fix, the change-tracker scanned
/// the `tags` table by `created_at`, which never moves after
/// initial insert — so any subsequent edit (color change, rename,
/// reorder) was invisible to the sync push and other devices kept
/// showing the old values.
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

  test('updating a tag bumps updated_at so push picks up the edit',
      () async {
    final tagRepo = container.read(tagRepositoryProvider);
    final id = uuid.v4();
    final created = DateTime.utc(2026, 4, 1);
    await tagRepo.create(Tag(
      id: id,
      name: 'Home',
      color: 0xFFFF0000, // red
      position: 0,
      createdAt: created,
    ));
    // Force updated_at into the past so we can see it move.
    final stale = DateTime.utc(2026, 4, 1);
    await (db.update(db.tags)..where((t) => t.id.equals(id)))
        .write(TagsCompanion(updatedAt: Value(stale)));

    // User changes the color to yellow.
    await tagRepo.update(Tag(
      id: id,
      name: 'Home',
      color: 0xFFFFFF00, // yellow
      position: 0,
      createdAt: created,
    ));

    final row = await (db.select(db.tags)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    expect(row.updatedAt, isNotNull);
    expect(row.updatedAt!.isAfter(stale), isTrue,
        reason: 'updated_at must advance on tag edits');
  });

  test('ChangeTracker pushes a tag color change after the cursor '
      '(the bug that hid the yellow Home from Android)', () async {
    final tagRepo = container.read(tagRepositoryProvider);

    // Sync cursor: "everything before T0 is already pushed."
    final t0 = DateTime.utc(2026, 4, 15);

    // Tag created BEFORE the cursor — the change tracker should
    // not pick it up by virtue of created_at.
    final id = uuid.v4();
    await tagRepo.create(Tag(
      id: id,
      name: 'Home',
      color: 0xFFFF0000,
      position: 0,
      createdAt: t0.subtract(const Duration(days: 14)),
    ));
    // Force updated_at to be old too.
    await (db.update(db.tags)..where((t) => t.id.equals(id)))
        .write(TagsCompanion(
          updatedAt: Value(t0.subtract(const Duration(days: 14))),
        ));

    // *Now* the user changes the color.
    await tagRepo.update(Tag(
      id: id,
      name: 'Home',
      color: 0xFFFFFF00,
      position: 0,
      createdAt: t0.subtract(const Duration(days: 14)),
    ));

    final tracker = ChangeTracker(db);
    final changes = await tracker.getChangesSince(t0);

    final tagPushes = changes
        .where((c) => c.table == 'tags' && !c.deleted)
        .toList();
    expect(tagPushes, hasLength(1));
    expect(tagPushes.single.id, id);
    expect(tagPushes.single.data['color'], 0xFFFFFF00);
  });
}
