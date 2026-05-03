import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:planyr/features/sync/data/board_deduper.dart';
import 'package:planyr/features/sync/data/tombstone_repository.dart';
import 'package:planyr/shared/database.dart';

void main() {
  late PlanyrDatabase db;
  late TombstoneRepository tombstones;
  late BoardDeduper deduper;

  setUp(() {
    db = PlanyrDatabase.forTesting(NativeDatabase.memory());
    tombstones = TombstoneRepository(db);
    deduper = BoardDeduper(db, tombstones);
  });

  tearDown(() async {
    await db.close();
  });

  /// Insert a weekly board with [colCount] columns at positions
  /// 0..colCount-1. Returns the board id and column ids in order.
  Future<({String boardId, List<String> colIds})> insertBoard({
    required String idPrefix,
    required DateTime weekStart,
    required DateTime createdAt,
    int colCount = 8,
  }) async {
    final boardId = '$idPrefix-board';
    await db.into(db.boards).insert(BoardsCompanion.insert(
          id: boardId,
          name: 'Week of ${weekStart.toIso8601String()}',
          type: 'weekly',
          createdAt: createdAt,
          updatedAt: createdAt,
          weekStart: Value(weekStart),
        ));
    final colIds = <String>[];
    for (var i = 0; i < colCount; i++) {
      final colId = '$idPrefix-col-$i';
      await db.into(db.boardColumns).insert(BoardColumnsCompanion.insert(
            id: colId,
            boardId: boardId,
            label: 'C$i',
            position: i,
            type: Value(i == 7 ? 'migration' : 'date'),
          ));
      colIds.add(colId);
    }
    return (boardId: boardId, colIds: colIds);
  }

  Future<void> insertTask({
    required String id,
    required String boardId,
    int position = 0,
  }) async {
    await db.into(db.tasks).insert(TasksCompanion.insert(
          id: id,
          boardId: boardId,
          title: 'Task $id',
          position: position,
          createdAt: DateTime.utc(2026, 4, 20),
        ));
  }

  Future<void> insertMarker({
    required String id,
    required String taskId,
    required String columnId,
    required String boardId,
    String symbol = 'dot',
  }) async {
    await db.into(db.markers).insert(MarkersCompanion.insert(
          id: id,
          taskId: taskId,
          columnId: columnId,
          boardId: boardId,
          symbol: symbol,
          updatedAt: DateTime.utc(2026, 4, 20),
        ));
  }

  test('no duplicates → no changes', () async {
    final ws = DateTime.utc(2026, 4, 20);
    await insertBoard(
      idPrefix: 'a',
      weekStart: ws,
      createdAt: DateTime.utc(2026, 4, 20),
    );

    final deletes = await deduper.dedupeWeeklyBoards();
    expect(deletes, isEmpty);

    final boards = await db.select(db.boards).get();
    expect(boards.length, 1);
  });

  test('empty duplicate merges into canonical (the legit '
      'two-devices-offline case)', () async {
    // The scenario this dedupe code exists for: two devices each
    // create a fresh weekly board for the same week while offline.
    // After they sync, both boards land in each other's local DB.
    // The newer one is empty (it hadn't been used yet), so merging
    // it into the older canonical is safe.
    final ws = DateTime.utc(2026, 4, 20);
    final canon = await insertBoard(
      idPrefix: 'canon',
      weekStart: ws,
      createdAt: DateTime.utc(2026, 4, 20, 8),
    );
    final dup = await insertBoard(
      idPrefix: 'dup',
      weekStart: ws,
      createdAt: DateTime.utc(2026, 4, 20, 12),
    );

    // Canonical has user data; duplicate is empty.
    await insertTask(id: 'taskCanon', boardId: canon.boardId);
    await insertMarker(
      id: 'mCanon',
      taskId: 'taskCanon',
      columnId: canon.colIds[0],
      boardId: canon.boardId,
    );

    final deletes = await deduper.dedupeWeeklyBoards();
    expect(deletes, hasLength(1));
    expect(deletes.first.id, dup.boardId);
    expect(deletes.first.deleted, isTrue);

    // Only the canonical board survives; canonical's task + marker
    // are untouched.
    final boards = await db.select(db.boards).get();
    expect(boards, hasLength(1));
    expect(boards.first.id, canon.boardId);
    final tasks = await db.select(db.tasks).get();
    expect(tasks, hasLength(1));
    expect(tasks.first.boardId, canon.boardId);
    final markers = await db.select(db.markers).get();
    expect(markers, hasLength(1));
    expect(markers.first.boardId, canon.boardId);
  });

  test('duplicate WITH user data is NOT auto-merged (#62 safety '
      'gate against silent re-FK of real data)', () async {
    // 2026-05-03 incident: a buggy migration made every board look
    // like a week-duplicate. The deduper would have re-FK'd every
    // board's tasks onto the oldest board ("canonical"), turning a
    // schema bug into a data scramble. The safety gate now refuses
    // to auto-merge if the loser has its own tasks/markers — the
    // operator (or a future UI) has to reconcile explicitly.
    final ws = DateTime.utc(2026, 4, 20);
    final canon = await insertBoard(
      idPrefix: 'canon',
      weekStart: ws,
      createdAt: DateTime.utc(2026, 4, 20, 8),
    );
    final dup = await insertBoard(
      idPrefix: 'dup',
      weekStart: ws,
      createdAt: DateTime.utc(2026, 4, 20, 12),
    );

    // Both boards have their own user data.
    await insertTask(id: 'taskCanon', boardId: canon.boardId);
    await insertTask(id: 'taskDup', boardId: dup.boardId);
    await insertMarker(
      id: 'mDup',
      taskId: 'taskDup',
      columnId: dup.colIds[2],
      boardId: dup.boardId,
    );

    final deletes = await deduper.dedupeWeeklyBoards();
    expect(deletes, isEmpty,
        reason: 'No merge should be queued when the dup has user data');

    // Both boards survive intact; nothing was re-FK'd.
    final boards = await db.select(db.boards).get();
    expect(boards.map((b) => b.id).toSet(),
        {canon.boardId, dup.boardId});
    final tasks = await db.select(db.tasks).get();
    expect(tasks.firstWhere((t) => t.id == 'taskCanon').boardId,
        canon.boardId);
    expect(tasks.firstWhere((t) => t.id == 'taskDup').boardId,
        dup.boardId);
    final markers = await db.select(db.markers).get();
    expect(markers.first.boardId, dup.boardId);
  });

  test('duplicate with ONLY a marker (no tasks) is also blocked', () async {
    // Markers count as user data even without tasks — they could
    // represent intent the user expressed. Don't silently move them.
    final ws = DateTime.utc(2026, 4, 20);
    final canon = await insertBoard(
      idPrefix: 'canon',
      weekStart: ws,
      createdAt: DateTime.utc(2026, 4, 20, 8),
    );
    final dup = await insertBoard(
      idPrefix: 'dup',
      weekStart: ws,
      createdAt: DateTime.utc(2026, 4, 20, 12),
    );
    // Task on canon (so the marker on dup has a task to reference).
    await insertTask(id: 'sharedTask', boardId: canon.boardId);
    await insertMarker(
      id: 'mDup',
      taskId: 'sharedTask',
      columnId: dup.colIds[0],
      boardId: dup.boardId,
    );

    final deletes = await deduper.dedupeWeeklyBoards();
    expect(deletes, isEmpty);
    final boards = await db.select(db.boards).get();
    expect(boards, hasLength(2));
  });

  test('merging tombstones every duplicate column for cloud cleanup '
      '(issue #41)', () async {
    // Regression: BoardDeduper used to hard-delete the duplicate's
    // columns locally with no tombstone, leaving them on the cloud
    // forever as orphans pointing at a now-deleted board. We caught
    // 128 such orphans in the 2026-04-26 audit.
    final ws = DateTime.utc(2026, 4, 20);
    final canon = await insertBoard(
      idPrefix: 'canon',
      weekStart: ws,
      createdAt: DateTime.utc(2026, 4, 20, 8),
    );
    final dup = await insertBoard(
      idPrefix: 'dup',
      weekStart: ws,
      createdAt: DateTime.utc(2026, 4, 20, 12),
    );

    await deduper.dedupeWeeklyBoards();

    // The dup's 8 column ids should now appear in DeletedRecords as
    // 'board_columns' tombstones, ready for the next sync push to
    // propagate them to the cloud.
    final tombs = await tombstones.changesSince(null);
    final colTombKeys = tombs
        .where((t) => t.targetTable == 'board_columns')
        .map((t) => t.rowKey)
        .toSet();
    expect(colTombKeys, dup.colIds.toSet(),
        reason: 'every duplicate column id must be tombstoned');
    // Sanity: canonical's columns are NOT tombstoned.
    expect(
      colTombKeys.intersection(canon.colIds.toSet()),
      isEmpty,
      reason: "canonical's columns must not be touched",
    );
  });

  test('dedupe without a TombstoneRepository still merges (legacy ctor)',
      () async {
    // The old single-arg constructor must keep working — tests that
    // don't care about sync still pass it just the DB.
    final legacy = BoardDeduper(db);
    final ws = DateTime.utc(2026, 4, 20);
    await insertBoard(
      idPrefix: 'a',
      weekStart: ws,
      createdAt: DateTime.utc(2026, 4, 20, 8),
    );
    await insertBoard(
      idPrefix: 'b',
      weekStart: ws,
      createdAt: DateTime.utc(2026, 4, 20, 12),
    );
    final deletes = await legacy.dedupeWeeklyBoards();
    expect(deletes, hasLength(1));
    final boards = await db.select(db.boards).get();
    expect(boards, hasLength(1));
  });

  test('canonical chosen by oldest createdAt regardless of insert order',
      () async {
    final ws = DateTime.utc(2026, 4, 20);
    // Insert newer first.
    await insertBoard(
      idPrefix: 'newer',
      weekStart: ws,
      createdAt: DateTime.utc(2026, 4, 20, 12),
    );
    // Then older.
    final older = await insertBoard(
      idPrefix: 'older',
      weekStart: ws,
      createdAt: DateTime.utc(2026, 4, 20, 8),
    );

    final deletes = await deduper.dedupeWeeklyBoards();

    final boards = await db.select(db.boards).get();
    expect(boards, hasLength(1));
    expect(boards.first.id, older.boardId);
    expect(deletes.single.id, isNot(older.boardId));
  });

  test('marker conflict on same (task, column) — merge is now blocked '
      'by the safety gate, both boards survive', () async {
    // Pre-#62 this test asserted that the merge proceeded and the
    // duplicate's marker won the (task_id, column_id) collision.
    // After #62 the merge is refused entirely because the duplicate
    // has its own marker. That's the safer outcome — the previous
    // path silently overwrote canonical-side markers, which could
    // be the user's actual state.
    final ws = DateTime.utc(2026, 4, 20);
    final canon = await insertBoard(
      idPrefix: 'canon',
      weekStart: ws,
      createdAt: DateTime.utc(2026, 4, 20, 8),
    );
    final dup = await insertBoard(
      idPrefix: 'dup',
      weekStart: ws,
      createdAt: DateTime.utc(2026, 4, 20, 12),
    );

    await insertTask(id: 'sameTask', boardId: canon.boardId);
    await insertMarker(
      id: 'mCanon',
      taskId: 'sameTask',
      columnId: canon.colIds[0],
      boardId: canon.boardId,
      symbol: 'dot',
    );

    await insertTask(id: 'sameTask2', boardId: dup.boardId);
    await insertMarker(
      id: 'mDup',
      taskId: 'sameTask2',
      columnId: dup.colIds[0],
      boardId: dup.boardId,
      symbol: 'slash',
    );

    final deletes = await deduper.dedupeWeeklyBoards();
    expect(deletes, isEmpty);

    // Both boards + both markers untouched.
    final boards = await db.select(db.boards).get();
    expect(boards, hasLength(2));
    final markers = await db.select(db.markers).get();
    expect(markers, hasLength(2));
    expect(markers.firstWhere((m) => m.id == 'mCanon').boardId,
        canon.boardId);
    expect(markers.firstWhere((m) => m.id == 'mDup').boardId,
        dup.boardId);
  });

  test('three duplicates collapse to one', () async {
    final ws = DateTime.utc(2026, 4, 20);
    final canon = await insertBoard(
      idPrefix: 'a',
      weekStart: ws,
      createdAt: DateTime.utc(2026, 4, 20, 8),
    );
    await insertBoard(
      idPrefix: 'b',
      weekStart: ws,
      createdAt: DateTime.utc(2026, 4, 20, 9),
    );
    await insertBoard(
      idPrefix: 'c',
      weekStart: ws,
      createdAt: DateTime.utc(2026, 4, 20, 10),
    );

    final deletes = await deduper.dedupeWeeklyBoards();
    expect(deletes, hasLength(2));

    final boards = await db.select(db.boards).get();
    expect(boards, hasLength(1));
    expect(boards.first.id, canon.boardId);
  });

  test('different week_starts not merged', () async {
    await insertBoard(
      idPrefix: 'wk1',
      weekStart: DateTime.utc(2026, 4, 13),
      createdAt: DateTime.utc(2026, 4, 13),
    );
    await insertBoard(
      idPrefix: 'wk2',
      weekStart: DateTime.utc(2026, 4, 20),
      createdAt: DateTime.utc(2026, 4, 20),
    );

    final deletes = await deduper.dedupeWeeklyBoards();
    expect(deletes, isEmpty);
    final boards = await db.select(db.boards).get();
    expect(boards, hasLength(2));
  });

  test('dedupe wakes Drift watch streams (UI refresh)', () async {
    // Regression: customStatement bypasses Drift's change tracker, so
    // earlier the dedupe silently mutated the DB and watch() Streams
    // didn't emit — the UI showed stale data until the user navigated
    // away. notifyUpdates fixes that.
    final ws = DateTime.utc(2026, 4, 20);
    await insertBoard(
      idPrefix: 'a',
      weekStart: ws,
      createdAt: DateTime.utc(2026, 4, 20, 8),
    );
    await insertBoard(
      idPrefix: 'b',
      weekStart: ws,
      createdAt: DateTime.utc(2026, 4, 20, 12),
    );

    final emissions = <int>[];
    final sub = db.select(db.boards).watch().listen(
          (rows) => emissions.add(rows.length),
        );
    // Wait for the initial emission (count=2).
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(emissions.last, 2);

    await deduper.dedupeWeeklyBoards();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(emissions.last, 1,
        reason: 'watch() should emit again after the merge so the UI '
            'sees the consolidated board without re-navigating');

    await sub.cancel();
  });

  test('archived board not considered for dedupe', () async {
    final ws = DateTime.utc(2026, 4, 20);
    await db.into(db.boards).insert(BoardsCompanion.insert(
          id: 'archived',
          name: 'Archived',
          type: 'weekly',
          createdAt: DateTime.utc(2026, 4, 20, 8),
          updatedAt: DateTime.utc(2026, 4, 20, 8),
          weekStart: Value(ws),
          archived: const Value(true),
        ));
    await insertBoard(
      idPrefix: 'active',
      weekStart: ws,
      createdAt: DateTime.utc(2026, 4, 20, 12),
    );

    final deletes = await deduper.dedupeWeeklyBoards();
    expect(deletes, isEmpty);
  });
}
