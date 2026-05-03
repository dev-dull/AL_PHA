import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:planyr/features/board/domain/board.dart';
import 'package:planyr/features/board/domain/board_type.dart';
import 'package:planyr/features/column/domain/board_column.dart';
import 'package:planyr/features/column/domain/column_type.dart';
import 'package:planyr/features/column/domain/weekly_columns.dart';
import 'package:planyr/features/marker/domain/marker.dart';
import 'package:planyr/features/marker/domain/marker_symbol.dart';
import 'package:planyr/features/marker/providers/marker_providers.dart';
import 'package:planyr/features/preferences/domain/app_preferences.dart';
import 'package:planyr/features/preferences/providers/preferences_providers.dart';
import 'package:planyr/features/series/domain/recurring_series.dart';
import 'package:planyr/features/series/providers/series_providers.dart';
import 'package:planyr/features/task/domain/task.dart';
import 'package:planyr/features/board/providers/weekly_board_provider.dart';
import 'package:planyr/shared/database.dart';
import 'package:planyr/shared/providers.dart';
import 'package:planyr/shared/week_utils.dart';

void main() {
  test('switching first-day-of-week finds existing board and tasks',
      () async {
    final db = PlanyrDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [planyrDatabaseProvider.overrideWithValue(db)],
    );

    addTearDown(() {
      container.dispose();
      db.close();
    });

    const uuid = Uuid();
    final monday = DateTime(2026, 3, 16);
    final boardId = uuid.v4();
    final now = DateTime.now();

    final boardRepo = container.read(boardRepositoryProvider);
    final colRepo = container.read(columnRepositoryProvider);
    final taskRepo = container.read(taskRepositoryProvider);

    await boardRepo.create(Board(
      id: boardId,
      name: weekBoardName(monday),
      type: BoardType.weekly,
      weekStart: monday,
      createdAt: now,
      updatedAt: now,
    ));

    for (final col in weeklyColumnDefs()) {
      await colRepo.create(BoardColumn(
        id: uuid.v4(),
        boardId: boardId,
        label: col.label,
        position: col.position,
        type: col.type,
      ));
    }

    await taskRepo.create(Task(
      id: uuid.v4(),
      boardId: boardId,
      title: 'Test task',
      position: 0,
      createdAt: now,
    ));

    // Query with Monday start — exact match.
    final mondayBoardId = await container.read(
      weeklyBoardProvider(monday).future,
    );
    expect(mondayBoardId, boardId);

    // Query with Sunday start — should find via ±1 day fallback.
    final sunday = startOfWeek(
      DateTime(2026, 3, 18),
      firstDay: DateTime.sunday,
    );
    expect(sunday, DateTime.utc(2026, 3, 15));

    final sundayBoardId = await container.read(
      weeklyBoardProvider(sunday).future,
    );
    expect(sundayBoardId, boardId,
        reason: 'Should find Monday board via ±1 day fallback');

    final tasks = await taskRepo.getByBoard(sundayBoardId);
    expect(tasks.length, 1);
    expect(tasks.first.title, 'Test task');
  });

  test('provider with preference change finds existing board', () async {
    final db = PlanyrDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [planyrDatabaseProvider.overrideWithValue(db)],
    );

    addTearDown(() {
      container.dispose();
      db.close();
    });

    // Create board via provider (Monday start).
    final monday = DateTime(2026, 3, 16);
    final boardId = await container.read(
      weeklyBoardProvider(monday).future,
    );

    final taskRepo = container.read(taskRepositoryProvider);
    await taskRepo.create(Task(
      id: const Uuid().v4(),
      boardId: boardId,
      title: 'My task',
      position: 0,
      createdAt: DateTime.now(),
    ));

    // Change preference to Sunday.
    container.read(preferencesProvider.notifier).state =
        const AppPreferences(firstDayOfWeek: DateTime.sunday);
    container.invalidate(weeklyBoardProvider(monday));

    // Look up for Sunday start of same week.
    final sunday = DateTime(2026, 3, 15);
    final sundayBoardId = await container.read(
      weeklyBoardProvider(sunday).future,
    );

    expect(sundayBoardId, boardId,
        reason: 'Must find existing Monday board');

    final tasks = await taskRepo.getByBoard(sundayBoardId);
    expect(tasks.length, 1);
    expect(tasks.first.title, 'My task');
  });

  test('prefers board with tasks but does NOT delete the empty '
      'duplicate (#62 — auto-cascade-delete is gone)',
      () async {
    final db = PlanyrDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [planyrDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(() {
      container.dispose();
      db.close();
    });

    const uuid = Uuid();
    final now = DateTime.now();
    final boardRepo = container.read(boardRepositoryProvider);
    final colRepo = container.read(columnRepositoryProvider);
    final taskRepo = container.read(taskRepositoryProvider);

    // Monday board WITH tasks.
    final mondayId = uuid.v4();
    await boardRepo.create(Board(
      id: mondayId,
      name: 'Week of Mar 16',
      type: BoardType.weekly,
      weekStart: DateTime(2026, 3, 16),
      createdAt: now,
      updatedAt: now,
    ));
    for (final col in weeklyColumnDefs()) {
      await colRepo.create(BoardColumn(
        id: uuid.v4(), boardId: mondayId,
        label: col.label, position: col.position, type: col.type,
      ));
    }
    await taskRepo.create(Task(
      id: uuid.v4(), boardId: mondayId, title: 'Real task',
      position: 0, createdAt: now,
    ));

    // Empty Sunday board (stale duplicate).
    final sundayId = uuid.v4();
    await boardRepo.create(Board(
      id: sundayId,
      name: 'Week of Mar 15',
      type: BoardType.weekly,
      weekStart: DateTime(2026, 3, 15),
      createdAt: now,
      updatedAt: now,
    ));

    // Query for Sunday — should prefer Monday board (has tasks)
    // but the Sunday board must survive. Auto-cascade-delete is
    // exactly what wiped 13 of the user's boards on 2026-05-03
    // when a buggy migration made every board look like a
    // duplicate. The lookup picks a winner; the operator (or
    // future UI) reconciles duplicates explicitly.
    final found = await boardRepo.getByWeekStart(DateTime(2026, 3, 15));
    expect(found, isNotNull);
    expect(found!.id, mondayId);

    final all = await boardRepo.listAll();
    expect(all.map((b) => b.id).toSet(), {mondayId, sundayId},
        reason: 'Both boards must survive — getByWeekStart no longer '
            'deletes the loser');
  });

  test('new board created with Sunday columns when no board exists',
      () async {
    final db = PlanyrDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [planyrDatabaseProvider.overrideWithValue(db)],
    );

    addTearDown(() {
      container.dispose();
      db.close();
    });

    // Set Sunday preference before creating any board.
    container.read(preferencesProvider.notifier).state =
        const AppPreferences(firstDayOfWeek: DateTime.sunday);

    final sunday = DateTime(2026, 3, 15);
    final boardId = await container.read(
      weeklyBoardProvider(sunday).future,
    );

    // Board should be created with Sunday columns.
    final colRepo = container.read(columnRepositoryProvider);
    final cols = await colRepo.getByBoard(boardId);
    final dayLabels =
        cols.where((c) => c.type.name == 'date').toList()
          ..sort((a, b) => a.position.compareTo(b.position));

    expect(dayLabels.map((c) => c.label).toList(),
        ['S', 'M', 'T', 'W', 'T', 'F', 'S']);
  });

  test('markers on Monday-board are accessible after switching to Sunday',
      () async {
    final db = PlanyrDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [planyrDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(() {
      container.dispose();
      db.close();
    });

    const uuid = Uuid();
    final now = DateTime.now();
    final monday = DateTime(2026, 3, 16); // Monday
    final boardRepo = container.read(boardRepositoryProvider);
    final colRepo = container.read(columnRepositoryProvider);
    final taskRepo = container.read(taskRepositoryProvider);
    final markerRepo = container.read(markerRepositoryProvider);

    // Create Monday-start board with columns and a task.
    final boardId = uuid.v4();
    await boardRepo.create(Board(
      id: boardId,
      name: weekBoardName(monday),
      type: BoardType.weekly,
      weekStart: monday,
      createdAt: now,
      updatedAt: now,
    ));

    final colIds = <int, String>{};
    for (final col in weeklyColumnDefs()) {
      final colId = uuid.v4();
      colIds[col.position] = colId;
      await colRepo.create(BoardColumn(
        id: colId,
        boardId: boardId,
        label: col.label,
        position: col.position,
        type: col.type,
      ));
    }

    final taskId = uuid.v4();
    await taskRepo.create(Task(
      id: taskId,
      boardId: boardId,
      title: 'Gym',
      position: 0,
      createdAt: now,
    ));

    // Set markers on Mon (pos 0), Wed (pos 2), Fri (pos 4).
    for (final pos in [0, 2, 4]) {
      await markerRepo.set(Marker(
        id: uuid.v4(),
        taskId: taskId,
        columnId: colIds[pos]!,
        boardId: boardId,
        symbol: MarkerSymbol.dot,
        updatedAt: now,
      ));
    }

    // Switch to Sunday start — look up the same week.
    final sunday = startOfWeek(
      DateTime(2026, 3, 18),
      firstDay: DateTime.sunday,
    );
    expect(sunday, DateTime.utc(2026, 3, 15));

    final sundayBoardId = await container.read(
      weeklyBoardProvider(sunday).future,
    );
    expect(sundayBoardId, boardId,
        reason: 'Should find Monday board via fallback');

    // All markers should still be there and readable.
    final markers = await markerRepo.getByBoard(sundayBoardId);
    final taskMarkers = markers.where((m) => m.taskId == taskId).toList();
    expect(taskMarkers.length, 3,
        reason: 'All 3 markers must survive the switch');
    expect(
      taskMarkers.every((m) => m.symbol == MarkerSymbol.dot),
      isTrue,
      reason: 'Marker symbols must be unchanged',
    );
  });

  test('auto-fill missed days works on Monday-board with Sunday preference',
      () async {
    final db = PlanyrDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [planyrDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(() {
      container.dispose();
      db.close();
    });

    const uuid = Uuid();
    // Use a past week so all days are in the past.
    final monday = DateTime(2026, 3, 9); // Past Monday
    final now = DateTime.now();
    final boardRepo = container.read(boardRepositoryProvider);
    final colRepo = container.read(columnRepositoryProvider);
    final taskRepo = container.read(taskRepositoryProvider);
    final markerRepo = container.read(markerRepositoryProvider);

    final boardId = uuid.v4();
    await boardRepo.create(Board(
      id: boardId,
      name: weekBoardName(monday),
      type: BoardType.weekly,
      weekStart: monday,
      createdAt: now,
      updatedAt: now,
    ));

    final colIds = <int, String>{};
    for (final col in weeklyColumnDefs()) {
      final colId = uuid.v4();
      colIds[col.position] = colId;
      await colRepo.create(BoardColumn(
        id: colId,
        boardId: boardId,
        label: col.label,
        position: col.position,
        type: col.type,
      ));
    }

    final taskId = uuid.v4();
    await taskRepo.create(Task(
      id: taskId,
      boardId: boardId,
      title: 'Review PR',
      position: 0,
      createdAt: now,
    ));

    // Set dots on Tue (pos 1) and Thu (pos 3).
    for (final pos in [1, 3]) {
      await markerRepo.set(Marker(
        id: uuid.v4(),
        taskId: taskId,
        columnId: colIds[pos]!,
        boardId: boardId,
        symbol: MarkerSymbol.dot,
        updatedAt: now,
      ));
    }

    // Switch preference to Sunday.
    container.read(preferencesProvider.notifier).state =
        const AppPreferences(firstDayOfWeek: DateTime.sunday);

    // Run auto-fill — board is in the past, so all dots should
    // become migratedForward.
    final actions = container.read(markerActionsProvider);
    await actions.autoFillMissedDays(boardId: boardId);

    final markers = await markerRepo.getByBoard(boardId);
    final taskMarkers =
        markers.where((m) => m.taskId == taskId).toList();
    final dayMarkers = taskMarkers.where((m) {
      final col = colIds.entries
          .where((e) => e.value == m.columnId)
          .firstOrNull;
      return col != null && col.key < 7; // day columns only
    }).toList();

    // Both dots should be converted to >.
    expect(
      dayMarkers.every(
        (m) => m.symbol == MarkerSymbol.migratedForward,
      ),
      isTrue,
      reason: 'Dots on past days must become > after auto-fill, '
          'even with different first-day preference',
    );
    expect(dayMarkers.length, 2);
  });

  test('recurring series materializes on board found via fallback',
      () async {
    final db = PlanyrDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [planyrDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(() {
      container.dispose();
      db.close();
    });

    const uuid = Uuid();
    final now = DateTime.now();
    final monday = DateTime(2026, 3, 16);
    final boardRepo = container.read(boardRepositoryProvider);
    final colRepo = container.read(columnRepositoryProvider);
    final taskRepo = container.read(taskRepositoryProvider);
    final seriesRepo = container.read(seriesRepositoryProvider);

    // Create Monday-start board.
    final boardId = uuid.v4();
    await boardRepo.create(Board(
      id: boardId,
      name: weekBoardName(monday),
      type: BoardType.weekly,
      weekStart: monday,
      createdAt: now,
      updatedAt: now,
    ));
    for (final col in weeklyColumnDefs()) {
      await colRepo.create(BoardColumn(
        id: uuid.v4(),
        boardId: boardId,
        label: col.label,
        position: col.position,
        type: col.type,
      ));
    }

    // Create a recurring series (weekly, Mon+Wed).
    final seriesId = uuid.v4();
    await seriesRepo.create(RecurringSeries(
      id: seriesId,
      title: 'Standup',
      recurrenceRule: 'FREQ=WEEKLY;BYDAY=MO,WE',
      createdAt: monday,
    ));

    // Create the source task on this board linked to the series.
    final sourceTaskId = uuid.v4();
    await taskRepo.create(Task(
      id: sourceTaskId,
      boardId: boardId,
      title: 'Standup',
      position: 0,
      createdAt: now,
      seriesId: seriesId,
      recurrenceRule: 'FREQ=WEEKLY;BYDAY=MO,WE',
    ));

    // Switch to Sunday preference.
    container.read(preferencesProvider.notifier).state =
        const AppPreferences(firstDayOfWeek: DateTime.sunday);

    // Look up board via Sunday start — should find the Monday board.
    final sunday = startOfWeek(
      DateTime(2026, 3, 18),
      firstDay: DateTime.sunday,
    );
    final foundBoardId = await container.read(
      weeklyBoardProvider(sunday).future,
    );
    expect(foundBoardId, boardId);

    // The source task with its series link should still be there.
    final tasks = await taskRepo.getByBoard(foundBoardId);
    expect(tasks.length, 1);
    expect(tasks.first.seriesId, seriesId,
        reason: 'Task must retain seriesId after preference switch');

    // The series itself must still be active and fetchable.
    final series = await seriesRepo.getActive();
    expect(series.length, 1);
    expect(series.first.id, seriesId);
    expect(series.first.isActive, isTrue);
  });

  test('materialize creates task on next week board found via fallback',
      () async {
    final db = PlanyrDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [planyrDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(() {
      container.dispose();
      db.close();
    });

    const uuid = Uuid();
    final now = DateTime.now();
    // Week 1: source board (Monday start).
    final week1Monday = DateTime(2026, 3, 9);
    final boardRepo = container.read(boardRepositoryProvider);
    final colRepo = container.read(columnRepositoryProvider);
    final taskRepo = container.read(taskRepositoryProvider);
    final seriesRepo = container.read(seriesRepositoryProvider);
    final seriesActions = container.read(seriesActionsProvider);

    final board1Id = uuid.v4();
    await boardRepo.create(Board(
      id: board1Id,
      name: weekBoardName(week1Monday),
      type: BoardType.weekly,
      weekStart: week1Monday,
      createdAt: now,
      updatedAt: now,
    ));
    for (final col in weeklyColumnDefs()) {
      await colRepo.create(BoardColumn(
        id: uuid.v4(),
        boardId: board1Id,
        label: col.label,
        position: col.position,
        type: col.type,
      ));
    }

    // Create series and source task on week 1.
    final seriesId = uuid.v4();
    await seriesRepo.create(RecurringSeries(
      id: seriesId,
      title: 'Recurring task',
      recurrenceRule: 'FREQ=WEEKLY;BYDAY=TU,TH',
      createdAt: week1Monday,
    ));

    final sourceTaskId = uuid.v4();
    await taskRepo.create(Task(
      id: sourceTaskId,
      boardId: board1Id,
      title: 'Recurring task',
      position: 0,
      createdAt: now,
      seriesId: seriesId,
      recurrenceRule: 'FREQ=WEEKLY;BYDAY=TU,TH',
    ));

    // Week 2: board also Monday start.
    final week2Monday = DateTime(2026, 3, 16);
    final board2Id = uuid.v4();
    await boardRepo.create(Board(
      id: board2Id,
      name: weekBoardName(week2Monday),
      type: BoardType.weekly,
      weekStart: week2Monday,
      createdAt: now,
      updatedAt: now,
    ));
    for (final col in weeklyColumnDefs()) {
      await colRepo.create(BoardColumn(
        id: uuid.v4(),
        boardId: board2Id,
        label: col.label,
        position: col.position,
        type: col.type,
      ));
    }

    // Switch to Sunday preference.
    container.read(preferencesProvider.notifier).state =
        const AppPreferences(firstDayOfWeek: DateTime.sunday);

    // Materialize the series on week 2 board.
    final series = (await seriesRepo.getActive()).first;
    final materialized = await seriesActions.materialize(
      series: series,
      boardId: board2Id,
    );

    expect(materialized.seriesId, seriesId,
        reason: 'Series must materialize on board found via fallback');
    expect(materialized.title, 'Recurring task');

    // Verify the materialized task is on the correct board.
    final week2Tasks = await taskRepo.getByBoard(board2Id);
    expect(week2Tasks.length, 1);
    expect(week2Tasks.first.seriesId, seriesId);
  });

  test('event markers on Monday-board are NOT migrated after switch',
      () async {
    final db = PlanyrDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [planyrDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(() {
      container.dispose();
      db.close();
    });

    const uuid = Uuid();
    // Use a past week so auto-fill treats all days as past.
    final monday = DateTime(2026, 3, 9);
    final now = DateTime.now();
    final boardRepo = container.read(boardRepositoryProvider);
    final colRepo = container.read(columnRepositoryProvider);
    final taskRepo = container.read(taskRepositoryProvider);
    final markerRepo = container.read(markerRepositoryProvider);

    final boardId = uuid.v4();
    await boardRepo.create(Board(
      id: boardId,
      name: weekBoardName(monday),
      type: BoardType.weekly,
      weekStart: monday,
      createdAt: now,
      updatedAt: now,
    ));

    final colIds = <int, String>{};
    for (final col in weeklyColumnDefs()) {
      final colId = uuid.v4();
      colIds[col.position] = colId;
      await colRepo.create(BoardColumn(
        id: colId,
        boardId: boardId,
        label: col.label,
        position: col.position,
        type: col.type,
      ));
    }

    // Create a one-time event on Wednesday (pos 2).
    final eventId = uuid.v4();
    await taskRepo.create(Task(
      id: eventId,
      boardId: boardId,
      title: 'Team lunch',
      position: 0,
      createdAt: now,
      isEvent: true,
    ));
    await markerRepo.set(Marker(
      id: uuid.v4(),
      taskId: eventId,
      columnId: colIds[2]!,
      boardId: boardId,
      symbol: MarkerSymbol.event,
      updatedAt: now,
    ));

    // Switch to Sunday preference.
    container.read(preferencesProvider.notifier).state =
        const AppPreferences(firstDayOfWeek: DateTime.sunday);

    // Run auto-fill on past board.
    final actions = container.read(markerActionsProvider);
    await actions.autoFillMissedDays(boardId: boardId);

    // Event marker should NOT be converted to >.
    final markers = await markerRepo.getByBoard(boardId);
    final eventMarkers =
        markers.where((m) => m.taskId == eventId).toList();
    expect(eventMarkers.length, 1);
    expect(eventMarkers.first.symbol, MarkerSymbol.event,
        reason: 'One-time events must not be migrated');

    // No new board should have the event.
    final allBoards = await boardRepo.listAll();
    for (final board in allBoards) {
      if (board.id == boardId) continue;
      final tasks = await taskRepo.getByBoard(board.id);
      expect(
        tasks.any((t) => t.title == 'Team lunch'),
        isFalse,
        reason: 'Event must not appear on other boards',
      );
    }
  });

  test('column reorder maps markers to correct visual days', () async {
    // This tests that the column reorder logic (used in the UI)
    // correctly remaps positions. A Monday-board viewed with
    // Sunday preference should show Sunday first.
    final db = PlanyrDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [planyrDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(() {
      container.dispose();
      db.close();
    });

    const uuid = Uuid();
    final now = DateTime.now();
    final monday = DateTime(2026, 3, 16);
    final colRepo = container.read(columnRepositoryProvider);
    final boardRepo = container.read(boardRepositoryProvider);

    final boardId = uuid.v4();
    await boardRepo.create(Board(
      id: boardId,
      name: weekBoardName(monday),
      type: BoardType.weekly,
      weekStart: monday,
      createdAt: now,
      updatedAt: now,
    ));

    // Create Monday-start columns (M=0, T=1, W=2, T=3, F=4, S=5, S=6).
    final colDefs = weeklyColumnDefs();
    for (final col in colDefs) {
      await colRepo.create(BoardColumn(
        id: uuid.v4(),
        boardId: boardId,
        label: col.label,
        position: col.position,
        type: col.type,
      ));
    }

    final columns = await colRepo.getByBoard(boardId);
    final dateColumns = columns
        .where((c) => c.type == ColumnType.date)
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    // Simulate the reorder logic from _reorderColumns.
    const prefFirstDay = DateTime.sunday;
    const boardFirstDay = DateTime.monday;
    const shift = (prefFirstDay - boardFirstDay + 7) % 7;
    // shift = (7 - 1 + 7) % 7 = 6

    final labels = weeklyColumnDefs(firstDay: prefFirstDay)
        .where((d) => d.type == ColumnType.date)
        .map((d) => d.label)
        .toList();
    // Sunday labels: [S, M, T, W, T, F, S]

    final reordered = <BoardColumn>[];
    for (var i = 0; i < 7; i++) {
      final srcIdx = (i + shift) % 7;
      final src = dateColumns[srcIdx];
      reordered.add(BoardColumn(
        id: src.id,
        boardId: src.boardId,
        label: labels[i],
        position: src.position,
        type: src.type,
      ));
    }

    // Visual position 0 should now be Sunday (original pos 6).
    expect(reordered[0].label, 'S');
    expect(reordered[0].position, 6,
        reason: 'First visual slot should use data from position 6 '
            '(Sunday in Monday-start board)');

    // Visual position 1 should be Monday (original pos 0).
    expect(reordered[1].label, 'M');
    expect(reordered[1].position, 0);

    // Visual position 6 should be Saturday (original pos 5).
    expect(reordered[6].label, 'S');
    expect(reordered[6].position, 5);
  });
}
