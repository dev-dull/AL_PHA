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
      final id = 'col-$i';
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
