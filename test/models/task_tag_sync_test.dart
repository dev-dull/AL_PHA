import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:planyr/features/board/domain/board.dart';
import 'package:planyr/features/board/domain/board_type.dart';
import 'package:planyr/features/sync/data/change_tracker.dart';
import 'package:planyr/features/tag/domain/tag.dart';
import 'package:planyr/features/task/domain/task.dart';
import 'package:planyr/shared/database.dart';
import 'package:planyr/shared/providers.dart';
import 'package:planyr/shared/week_utils.dart';

/// Regression: tag changes must reach the cloud (and then other
/// devices). Before the fix, `setTagsForTask` modified the
/// `task_tags` junction without bumping the parent task's
/// `updated_at`, so the change-tracker's join-based scan
/// (`SELECT … FROM task_tags JOIN tasks WHERE tasks.updated_at > ?`)
/// missed the new junction row entirely. Push didn't include it,
/// pull on the second device couldn't see it, and tags appeared
/// only on the device they were added on.
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

  Future<String> createBoard() async {
    final boardId = uuid.v4();
    final now = DateTime.now().toUtc();
    await container.read(boardRepositoryProvider).create(Board(
          id: boardId,
          name: weekBoardName(DateTime(2026, 3, 23)),
          type: BoardType.weekly,
          weekStart: DateTime(2026, 3, 23),
          createdAt: now,
          updatedAt: now,
        ));
    return boardId;
  }

  Future<DateTime?> readTaskUpdatedAt(String taskId) async {
    final row = await (db.select(db.tasks)
          ..where((t) => t.id.equals(taskId)))
        .getSingle();
    return row.updatedAt;
  }

  test('setTagsForTask bumps the parent task.updated_at so sync '
      'picks up the change', () async {
    final boardId = await createBoard();
    final taskRepo = container.read(taskRepositoryProvider);
    final tagRepo = container.read(tagRepositoryProvider);
    final taskTagRepo = container.read(taskTagRepositoryProvider);

    final taskId = uuid.v4();
    final created = DateTime.utc(2026, 3, 24, 12);
    await taskRepo.create(Task(
      id: taskId,
      boardId: boardId,
      title: 'Edit homelab 3 video',
      position: 0,
      createdAt: created,
    ));
    // Force updated_at into the past so we can detect the bump.
    final stale = DateTime.utc(2026, 3, 24, 12);
    await (db.update(db.tasks)..where((t) => t.id.equals(taskId)))
        .write(TasksCompanion(updatedAt: Value(stale)));

    final tagId = uuid.v4();
    await tagRepo.create(Tag(
      id: tagId,
      name: 'YouTube',
      color: 0xFFFFCC00,
      position: 0,
      createdAt: DateTime.now().toUtc(),
    ));

    await taskTagRepo.setTagsForTask(taskId, [tagId]);

    final after = await readTaskUpdatedAt(taskId);
    expect(after, isNotNull);
    expect(after!.isAfter(stale), isTrue,
        reason: 'updated_at must advance when tags change');
  });

  test('ChangeTracker emits the new task_tags row to push after '
      'a tag-only edit (the bug that hid YouTube from Android)',
      () async {
    final boardId = await createBoard();
    final taskRepo = container.read(taskRepositoryProvider);
    final tagRepo = container.read(tagRepositoryProvider);
    final taskTagRepo = container.read(taskTagRepositoryProvider);

    // Sync cursor: "everything before T0 is already pushed."
    final t0 = DateTime.utc(2026, 4, 1);

    // Task and tag exist before the cursor — neither is "new" in
    // the eyes of the change tracker.
    final taskId = uuid.v4();
    await taskRepo.create(Task(
      id: taskId,
      boardId: boardId,
      title: 'Edit video about SUS',
      position: 0,
      createdAt: t0.subtract(const Duration(days: 7)),
    ));
    await (db.update(db.tasks)..where((t) => t.id.equals(taskId)))
        .write(TasksCompanion(
            updatedAt: Value(t0.subtract(const Duration(days: 7)))));

    final tagId = uuid.v4();
    await tagRepo.create(Tag(
      id: tagId,
      name: 'YouTube',
      color: 0xFFFFCC00,
      position: 0,
      createdAt: t0.subtract(const Duration(days: 7)),
    ));

    // *Now* (after the cursor) the user assigns the tag.
    await taskTagRepo.setTagsForTask(taskId, [tagId]);

    final tracker = ChangeTracker(db);
    final changes = await tracker.getChangesSince(t0);

    final taskTagPushes = changes
        .where((c) => c.table == 'task_tags' && !c.deleted)
        .toList();
    expect(taskTagPushes, hasLength(1));
    expect(taskTagPushes.single.data['task_id'], taskId);
    expect(taskTagPushes.single.data['tag_id'], tagId);
  });
}
