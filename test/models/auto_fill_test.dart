import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:planyr/features/board/domain/board.dart';
import 'package:planyr/features/board/domain/board_type.dart';
import 'package:planyr/features/column/domain/board_column.dart';
import 'package:planyr/features/column/domain/column_type.dart';
import 'package:planyr/features/marker/domain/marker.dart';
import 'package:planyr/features/marker/domain/marker_symbol.dart';
import 'package:planyr/features/marker/providers/marker_providers.dart';
import 'package:planyr/features/task/domain/task.dart';
import 'package:planyr/shared/database.dart';
import 'package:planyr/shared/providers.dart';

const _uuid = Uuid();

void main() {
  late ProviderContainer container;
  late PlanyrDatabase db;

  setUp(() {
    db = PlanyrDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [planyrDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  /// Creates a board with 8 fixed weekly columns (M T W T F S S >).
  /// Returns the list of column IDs in order.
  Future<List<String>> seedWeeklyBoard({
    required String boardId,
    DateTime? createdAt,
  }) async {
    final now = createdAt ?? DateTime.now();
    // Normalize to midnight for weekStart comparison.
    final weekStart = DateTime(now.year, now.month, now.day);
    final boardRepo = container.read(boardRepositoryProvider);
    await boardRepo.create(
      Board(
        id: boardId,
        name: 'Test Week',
        type: BoardType.weekly,
        createdAt: now,
        updatedAt: now,
        weekStart: weekStart,
      ),
    );

    final columnRepo = container.read(columnRepositoryProvider);
    final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S', '>'];
    final columnIds = <String>[];
    for (var i = 0; i < labels.length; i++) {
      // Prefix by board id so multi-board tests don't collide on
      // the board_columns.id PRIMARY KEY.
      final id = '$boardId-col-$i';
      columnIds.add(id);
      await columnRepo.create(
        BoardColumn(
          id: id,
          boardId: boardId,
          label: labels[i],
          position: i,
          type: i < 7 ? ColumnType.date : ColumnType.custom,
        ),
      );
    }
    return columnIds;
  }

  Future<void> seedMarker({
    required String taskId,
    required String columnId,
    required String boardId,
    required MarkerSymbol symbol,
  }) async {
    final repo = container.read(markerRepositoryProvider);
    await repo.set(
      Marker(
        id: _uuid.v4(),
        taskId: taskId,
        columnId: columnId,
        boardId: boardId,
        symbol: symbol,
        updatedAt: DateTime.now(),
      ),
    );
  }

  group('auto-fill done early (<)', () {
    test('marking X auto-fills < on later day columns with dots', () async {
      const boardId = 'board-1';
      const taskId = 'task-1';
      final colIds = await seedWeeklyBoard(boardId: boardId);

      // Schedule task for Mon, Wed, Fri (dots)
      await seedMarker(
        taskId: taskId,
        columnId: colIds[0],
        boardId: boardId,
        symbol: MarkerSymbol.dot, // Mon
      );
      await seedMarker(
        taskId: taskId,
        columnId: colIds[2],
        boardId: boardId,
        symbol: MarkerSymbol.dot, // Wed
      );
      await seedMarker(
        taskId: taskId,
        columnId: colIds[4],
        boardId: boardId,
        symbol: MarkerSymbol.dot, // Fri
      );

      // Mark Monday as done (cycle dot→slash→x)
      final actions = container.read(markerActionsProvider);
      await actions.cycleMarker(
        boardId: boardId,
        taskId: taskId,
        columnId: colIds[0],
      ); // dot → slash
      await actions.cycleMarker(
        boardId: boardId,
        taskId: taskId,
        columnId: colIds[0],
      ); // slash → x

      // Wed and Fri should now be < (done early)
      final markerRepo = container.read(markerRepositoryProvider);
      final wed = await markerRepo.get(taskId, colIds[2]);
      final fri = await markerRepo.get(taskId, colIds[4]);

      expect(wed!.symbol, MarkerSymbol.doneEarly);
      expect(fri!.symbol, MarkerSymbol.doneEarly);
    });

    test('cycling X to empty reverts < back to dots', () async {
      const boardId = 'board-1';
      const taskId = 'task-1';
      final colIds = await seedWeeklyBoard(boardId: boardId);

      // Dots on Mon, Wed, Fri
      await seedMarker(
        taskId: taskId,
        columnId: colIds[0],
        boardId: boardId,
        symbol: MarkerSymbol.dot,
      );
      await seedMarker(
        taskId: taskId,
        columnId: colIds[2],
        boardId: boardId,
        symbol: MarkerSymbol.dot,
      );
      await seedMarker(
        taskId: taskId,
        columnId: colIds[4],
        boardId: boardId,
        symbol: MarkerSymbol.dot,
      );

      final actions = container.read(markerActionsProvider);
      // Cycle Mon: dot → slash → x (auto-fills < on Wed, Fri)
      await actions.cycleMarker(
        boardId: boardId,
        taskId: taskId,
        columnId: colIds[0],
      );
      await actions.cycleMarker(
        boardId: boardId,
        taskId: taskId,
        columnId: colIds[0],
      );

      final markerRepo = container.read(markerRepositoryProvider);
      expect(
        (await markerRepo.get(taskId, colIds[2]))!.symbol,
        MarkerSymbol.doneEarly,
      );

      // Now cycle Mon: x → empty (should revert < to dots)
      await actions.cycleMarker(
        boardId: boardId,
        taskId: taskId,
        columnId: colIds[0],
      );

      final wedAfter = await markerRepo.get(taskId, colIds[2]);
      final friAfter = await markerRepo.get(taskId, colIds[4]);
      expect(wedAfter!.symbol, MarkerSymbol.dot);
      expect(friAfter!.symbol, MarkerSymbol.dot);
    });

    test('setMarker clearing X reverts < back to dots', () async {
      const boardId = 'board-1';
      const taskId = 'task-1';
      final colIds = await seedWeeklyBoard(boardId: boardId);

      await seedMarker(
        taskId: taskId,
        columnId: colIds[0],
        boardId: boardId,
        symbol: MarkerSymbol.dot,
      );
      await seedMarker(
        taskId: taskId,
        columnId: colIds[4],
        boardId: boardId,
        symbol: MarkerSymbol.dot,
      );

      final actions = container.read(markerActionsProvider);
      // Set Mon to X (auto-fills < on Fri)
      await actions.setMarker(
        boardId: boardId,
        taskId: taskId,
        columnId: colIds[0],
        symbol: MarkerSymbol.x,
      );

      final markerRepo = container.read(markerRepositoryProvider);
      expect(
        (await markerRepo.get(taskId, colIds[4]))!.symbol,
        MarkerSymbol.doneEarly,
      );

      // Clear Mon via picker (should revert < to dot)
      await actions.setMarker(
        boardId: boardId,
        taskId: taskId,
        columnId: colIds[0],
        symbol: null,
      );

      final friAfter = await markerRepo.get(taskId, colIds[4]);
      expect(friAfter!.symbol, MarkerSymbol.dot);
    });

    test('marking X does not affect earlier day columns', () async {
      const boardId = 'board-1';
      const taskId = 'task-1';
      final colIds = await seedWeeklyBoard(boardId: boardId);

      // Dot on Mon and Wed
      await seedMarker(
        taskId: taskId,
        columnId: colIds[0],
        boardId: boardId,
        symbol: MarkerSymbol.dot,
      );
      await seedMarker(
        taskId: taskId,
        columnId: colIds[2],
        boardId: boardId,
        symbol: MarkerSymbol.dot,
      );

      // Mark Wed as done via setMarker
      final actions = container.read(markerActionsProvider);
      await actions.setMarker(
        boardId: boardId,
        taskId: taskId,
        columnId: colIds[2],
        symbol: MarkerSymbol.x,
      );

      // Mon should still be a dot (it's before Wed)
      final markerRepo = container.read(markerRepositoryProvider);
      final mon = await markerRepo.get(taskId, colIds[0]);
      expect(mon!.symbol, MarkerSymbol.dot);
    });

    test('marking X does not affect the migration column', () async {
      const boardId = 'board-1';
      const taskId = 'task-1';
      final colIds = await seedWeeklyBoard(boardId: boardId);

      // Dot on Fri and > column
      await seedMarker(
        taskId: taskId,
        columnId: colIds[4],
        boardId: boardId,
        symbol: MarkerSymbol.dot,
      );
      await seedMarker(
        taskId: taskId,
        columnId: colIds[7],
        boardId: boardId,
        symbol: MarkerSymbol.dot,
      );

      // Mark Fri as done
      final actions = container.read(markerActionsProvider);
      await actions.setMarker(
        boardId: boardId,
        taskId: taskId,
        columnId: colIds[4],
        symbol: MarkerSymbol.x,
      );

      // > column should still be a dot (it's ColumnType.custom, not date)
      final markerRepo = container.read(markerRepositoryProvider);
      final migration = await markerRepo.get(taskId, colIds[7]);
      expect(migration!.symbol, MarkerSymbol.dot);
    });

    test('only converts dots, not other symbols', () async {
      const boardId = 'board-1';
      const taskId = 'task-1';
      final colIds = await seedWeeklyBoard(boardId: boardId);

      // Mon=dot, Wed=slash (in progress), Fri=dot
      await seedMarker(
        taskId: taskId,
        columnId: colIds[0],
        boardId: boardId,
        symbol: MarkerSymbol.dot,
      );
      await seedMarker(
        taskId: taskId,
        columnId: colIds[2],
        boardId: boardId,
        symbol: MarkerSymbol.slash,
      );
      await seedMarker(
        taskId: taskId,
        columnId: colIds[4],
        boardId: boardId,
        symbol: MarkerSymbol.dot,
      );

      // Mark Mon as X
      final actions = container.read(markerActionsProvider);
      await actions.setMarker(
        boardId: boardId,
        taskId: taskId,
        columnId: colIds[0],
        symbol: MarkerSymbol.x,
      );

      final markerRepo = container.read(markerRepositoryProvider);
      final wed = await markerRepo.get(taskId, colIds[2]);
      final fri = await markerRepo.get(taskId, colIds[4]);

      // Slash should remain unchanged; dot should become <
      expect(wed!.symbol, MarkerSymbol.slash);
      expect(fri!.symbol, MarkerSymbol.doneEarly);
    });

    test('marking X backfills earlier > markers to <', () async {
      // Regression: when a task is auto-migrated (> on past days)
      // and the user later marks it done, monthly view used to
      // count the past days as missed. Backfill > → < so the day
      // summary reflects that the task was completed.
      const boardId = 'board-1';
      const taskId = 'task-1';
      final colIds = await seedWeeklyBoard(boardId: boardId);

      // Task was scheduled Mon-Wed but auto-migrated those past
      // days to >. User comes back Wed and marks done.
      await seedMarker(
        taskId: taskId, boardId: boardId,
        columnId: colIds[0], symbol: MarkerSymbol.migratedForward,
      );
      await seedMarker(
        taskId: taskId, boardId: boardId,
        columnId: colIds[1], symbol: MarkerSymbol.migratedForward,
      );
      await seedMarker(
        taskId: taskId, boardId: boardId,
        columnId: colIds[2], symbol: MarkerSymbol.dot,
      );

      final actions = container.read(markerActionsProvider);
      await actions.setMarker(
        boardId: boardId, taskId: taskId,
        columnId: colIds[2], symbol: MarkerSymbol.x,
      );

      final markerRepo = container.read(markerRepositoryProvider);
      // Past > markers should now be < (done late).
      expect(
        (await markerRepo.get(taskId, colIds[0]))!.symbol,
        MarkerSymbol.doneEarly,
      );
      expect(
        (await markerRepo.get(taskId, colIds[1]))!.symbol,
        MarkerSymbol.doneEarly,
      );
    });

    test('reverting X restores earlier < back to >', () async {
      const boardId = 'board-1';
      const taskId = 'task-1';
      final colIds = await seedWeeklyBoard(boardId: boardId);

      await seedMarker(
        taskId: taskId, boardId: boardId,
        columnId: colIds[0], symbol: MarkerSymbol.migratedForward,
      );
      await seedMarker(
        taskId: taskId, boardId: boardId,
        columnId: colIds[2], symbol: MarkerSymbol.dot,
      );

      final actions = container.read(markerActionsProvider);
      // Mark Wed done — Mon's > becomes <
      await actions.setMarker(
        boardId: boardId, taskId: taskId,
        columnId: colIds[2], symbol: MarkerSymbol.x,
      );
      final markerRepo = container.read(markerRepositoryProvider);
      expect(
        (await markerRepo.get(taskId, colIds[0]))!.symbol,
        MarkerSymbol.doneEarly,
      );

      // Clear Wed — Mon's < should restore to >
      await actions.setMarker(
        boardId: boardId, taskId: taskId,
        columnId: colIds[2], symbol: null,
      );
      expect(
        (await markerRepo.get(taskId, colIds[0]))!.symbol,
        MarkerSymbol.migratedForward,
      );
    });
  });

  group('auto-fill missed days (>)', () {
    test('dots on past days become > for current week board', () async {
      const boardId = 'board-1';
      const taskId = 'task-1';

      // Create board for the current week (Monday of this week)
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final colIds = await seedWeeklyBoard(boardId: boardId, createdAt: monday);

      // Only test if today is not Monday (otherwise no past days)
      if (now.weekday > 1) {
        // Put a dot on Monday (position 0, which is in the past)
        await seedMarker(
          taskId: taskId,
          columnId: colIds[0],
          boardId: boardId,
          symbol: MarkerSymbol.dot,
        );

        final actions = container.read(markerActionsProvider);
        await actions.autoFillMissedDays(boardId: boardId);

        final markerRepo = container.read(markerRepositoryProvider);
        final mon = await markerRepo.get(taskId, colIds[0]);
        expect(mon!.symbol, MarkerSymbol.migratedForward);
      }
    });

    test('dots on past week board all become >', () async {
      const boardId = 'board-1';
      const taskId = 'task-1';

      // Create board from last week
      final lastWeek = DateTime.now().subtract(const Duration(days: 7));
      final colIds = await seedWeeklyBoard(
        boardId: boardId,
        createdAt: lastWeek,
      );

      // Put dots on Mon and Fri
      await seedMarker(
        taskId: taskId,
        columnId: colIds[0],
        boardId: boardId,
        symbol: MarkerSymbol.dot,
      );
      await seedMarker(
        taskId: taskId,
        columnId: colIds[4],
        boardId: boardId,
        symbol: MarkerSymbol.dot,
      );

      final actions = container.read(markerActionsProvider);
      await actions.autoFillMissedDays(boardId: boardId);

      final markerRepo = container.read(markerRepositoryProvider);
      final mon = await markerRepo.get(taskId, colIds[0]);
      final fri = await markerRepo.get(taskId, colIds[4]);

      expect(mon!.symbol, MarkerSymbol.migratedForward);
      expect(fri!.symbol, MarkerSymbol.migratedForward);
    });

    test('does not touch non-dot symbols', () async {
      const boardId = 'board-1';
      const taskId = 'task-1';

      final lastWeek = DateTime.now().subtract(const Duration(days: 7));
      final colIds = await seedWeeklyBoard(
        boardId: boardId,
        createdAt: lastWeek,
      );

      // Mon=x (done), Wed=slash (in progress)
      await seedMarker(
        taskId: taskId,
        columnId: colIds[0],
        boardId: boardId,
        symbol: MarkerSymbol.x,
      );
      await seedMarker(
        taskId: taskId,
        columnId: colIds[2],
        boardId: boardId,
        symbol: MarkerSymbol.slash,
      );

      final actions = container.read(markerActionsProvider);
      await actions.autoFillMissedDays(boardId: boardId);

      final markerRepo = container.read(markerRepositoryProvider);
      final mon = await markerRepo.get(taskId, colIds[0]);
      final wed = await markerRepo.get(taskId, colIds[2]);

      expect(mon!.symbol, MarkerSymbol.x);
      expect(wed!.symbol, MarkerSymbol.slash);
    });

    test('current-week missed dot rolls forward to today, no '
        'migration-column flag', () async {
      // Regression for the user-reported scenario on 2026-04-29:
      // dot on Tuesday, today is Wednesday, current-week board.
      // Used to set > in the migration column AND duplicate the
      // task to next week's board. New behavior: convert Tuesday's
      // dot to >, add a fresh dot on today's column, leave the
      // migration column empty.
      const boardId = 'board-1';
      const taskId = 'test-task';

      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final colIds = await seedWeeklyBoard(boardId: boardId, createdAt: monday);

      // Need a task row — autoFillMissedDays only adds the carry-
      // forward dot if it can resolve the task to determine
      // dot/event symbol.
      final taskRepo = container.read(taskRepositoryProvider);
      await taskRepo.create(Task(
        id: taskId,
        boardId: boardId,
        title: 'test',
        position: 0,
        createdAt: now,
      ));

      // Need at least one past day on the current week and at least
      // one future day for the test to be meaningful — skip if
      // today is Mon (no past) or Sun (no future).
      if (now.weekday <= 1 || now.weekday >= 7) return;
      const pastPos = 0; // Mon
      final todayPos = (now.weekday - 1); // Mon=0..Sun=6
      await seedMarker(
        taskId: taskId,
        columnId: colIds[pastPos],
        boardId: boardId,
        symbol: MarkerSymbol.dot,
      );

      final actions = container.read(markerActionsProvider);
      await actions.autoFillMissedDays(boardId: boardId);

      final markerRepo = container.read(markerRepositoryProvider);
      // Past-day dot flipped to >.
      final past = await markerRepo.get(taskId, colIds[pastPos]);
      expect(past!.symbol, MarkerSymbol.migratedForward);
      // Today gets a fresh dot.
      final today = await markerRepo.get(taskId, colIds[todayPos]);
      expect(today, isNotNull,
          reason: 'today should pick up a carry-forward dot');
      expect(today!.symbol, MarkerSymbol.dot);
      // Migration column (position 7) stays empty.
      final migCol = await markerRepo.get(taskId, colIds[7]);
      expect(migCol, isNull,
          reason: 'mid-week catch-up must not write the migration column');
    });

    test('past-week board still sets the migration-column > '
        '(existing behavior preserved)', () async {
      const boardId = 'board-1';
      const taskId = 'test-task';

      final lastWeek = DateTime.now().subtract(const Duration(days: 7));
      final colIds = await seedWeeklyBoard(
        boardId: boardId,
        createdAt: lastWeek,
      );

      final taskRepo = container.read(taskRepositoryProvider);
      await taskRepo.create(Task(
        id: taskId,
        boardId: boardId,
        title: 'test',
        position: 0,
        createdAt: lastWeek,
      ));

      // A dot somewhere in the past week with no future dot — the
      // task should be flagged for migration to the current week.
      await seedMarker(
        taskId: taskId,
        columnId: colIds[0],
        boardId: boardId,
        symbol: MarkerSymbol.dot,
      );

      final actions = container.read(markerActionsProvider);
      await actions.autoFillMissedDays(boardId: boardId);

      final markerRepo = container.read(markerRepositoryProvider);
      final migCol = await markerRepo.get(taskId, colIds[7]);
      expect(migCol, isNotNull,
          reason: 'past-week boards still flag the migration column');
      expect(migCol!.symbol, MarkerSymbol.migratedForward);
    });
  });

  group('cold-launch catch-up (#69)', () {
    test('autofill on the previous-week board (BoardGridBody catch-up) '
        'migrates a dotted-but-not-completed task forward to the '
        'current week', () async {
      // The user-reported bug: cold-launch on Monday into the new
      // week never visits last week's board, so its dots-on-past-
      // days stay as dots and the corresponding tasks never reach
      // the new week's board. The fix in BoardGridBody runs
      // autoFillMissedDays against the previous-week board on
      // mount; this test verifies the underlying actions-layer
      // behavior the catch-up depends on.
      const lastBoardId = 'last-week';
      const newBoardId = 'this-week';
      const taskId = 'rochester-tickets';

      final lastWeek =
          DateTime.now().subtract(const Duration(days: 7));
      final lastColIds = await seedWeeklyBoard(
        boardId: lastBoardId,
        createdAt: lastWeek,
      );
      // Current week board exists and is empty (the cold-launch
      // shape — user mounts the new week, never visits the old).
      await seedWeeklyBoard(
        boardId: newBoardId,
        createdAt: DateTime.now(),
      );

      final taskRepo = container.read(taskRepositoryProvider);
      await taskRepo.create(Task(
        id: taskId,
        boardId: lastBoardId,
        title: 'Buy tickets to Rochester',
        position: 0,
        createdAt: lastWeek,
      ));
      // Dot on Wednesday, never marked done.
      await seedMarker(
        taskId: taskId,
        columnId: lastColIds[2],
        boardId: lastBoardId,
        symbol: MarkerSymbol.dot,
      );

      // The catch-up: autofill against last week's board.
      await container
          .read(markerActionsProvider)
          .autoFillMissedDays(boardId: lastBoardId);

      // Last week: dot → >.
      final markerRepo = container.read(markerRepositoryProvider);
      final lastWedMarker =
          await markerRepo.get(taskId, lastColIds[2]);
      expect(lastWedMarker?.symbol, MarkerSymbol.migratedForward);

      // The migrated task arrived on the current week's board
      // (the carry-forward target for past-week autofill).
      final newTasks = await taskRepo.getByBoard(newBoardId);
      expect(
        newTasks.any((t) => t.title == 'Buy tickets to Rochester'),
        isTrue,
        reason: 'Catch-up autofill on last week must create the '
            'forward-migrated task on this week',
      );
    });

    test('catch-up is idempotent: running autofill twice on the '
        'same past board does not duplicate the migrated task',
        () async {
      // BoardGridBody re-runs _runDailyMaintenance on every
      // AppLifecycleState.resumed, so the catch-up may fire many
      // times. The carry-forward must dedupe by
      // (migratedFromBoardId, migratedFromTaskId) — proving that
      // here so future regressions get caught at unit-test speed.
      const lastBoardId = 'last-week';
      const newBoardId = 'this-week';
      const taskId = 'task-x';

      final lastWeek =
          DateTime.now().subtract(const Duration(days: 7));
      final lastColIds = await seedWeeklyBoard(
        boardId: lastBoardId,
        createdAt: lastWeek,
      );
      await seedWeeklyBoard(
        boardId: newBoardId,
        createdAt: DateTime.now(),
      );

      final taskRepo = container.read(taskRepositoryProvider);
      await taskRepo.create(Task(
        id: taskId,
        boardId: lastBoardId,
        title: 'task-x',
        position: 0,
        createdAt: lastWeek,
      ));
      await seedMarker(
        taskId: taskId,
        columnId: lastColIds[1],
        boardId: lastBoardId,
        symbol: MarkerSymbol.dot,
      );

      final actions = container.read(markerActionsProvider);
      await actions.autoFillMissedDays(boardId: lastBoardId);
      await actions.autoFillMissedDays(boardId: lastBoardId);
      await actions.autoFillMissedDays(boardId: lastBoardId);

      final newTasks = await taskRepo.getByBoard(newBoardId);
      final matches =
          newTasks.where((t) => t.title == 'task-x').toList();
      expect(matches, hasLength(1),
          reason: 'autoFillMissedDays must dedupe by '
              'migratedFromBoardId + migratedFromTaskId');
    });
  });

  group('migration column constraint', () {
    test('cycleMarker on > column toggles empty ↔ migratedForward', () async {
      const boardId = 'board-1';
      const taskId = 'task-1';
      final colIds = await seedWeeklyBoard(boardId: boardId);
      final migrationColId = colIds[7]; // > column

      final actions = container.read(markerActionsProvider);
      final markerRepo = container.read(markerRepositoryProvider);

      // Empty → >
      await actions.cycleMarker(
        boardId: boardId,
        taskId: taskId,
        columnId: migrationColId,
      );
      final after1 = await markerRepo.get(taskId, migrationColId);
      expect(after1!.symbol, MarkerSymbol.migratedForward);

      // > → empty
      await actions.cycleMarker(
        boardId: boardId,
        taskId: taskId,
        columnId: migrationColId,
      );
      final after2 = await markerRepo.get(taskId, migrationColId);
      expect(after2, isNull);
    });

    test('setMarker rejects non-> symbols on migration column', () async {
      const boardId = 'board-1';
      const taskId = 'task-1';
      final colIds = await seedWeeklyBoard(boardId: boardId);
      final migrationColId = colIds[7];

      final actions = container.read(markerActionsProvider);
      final markerRepo = container.read(markerRepositoryProvider);

      // Try to set a dot — should be silently rejected.
      await actions.setMarker(
        boardId: boardId,
        taskId: taskId,
        columnId: migrationColId,
        symbol: MarkerSymbol.dot,
      );
      final after = await markerRepo.get(taskId, migrationColId);
      expect(after, isNull);

      // Setting > should work.
      await actions.setMarker(
        boardId: boardId,
        taskId: taskId,
        columnId: migrationColId,
        symbol: MarkerSymbol.migratedForward,
      );
      final afterSet = await markerRepo.get(taskId, migrationColId);
      expect(afterSet!.symbol, MarkerSymbol.migratedForward);

      // Clearing should work.
      await actions.setMarker(
        boardId: boardId,
        taskId: taskId,
        columnId: migrationColId,
        symbol: null,
      );
      final afterClear = await markerRepo.get(taskId, migrationColId);
      expect(afterClear, isNull);
    });
  });
}
