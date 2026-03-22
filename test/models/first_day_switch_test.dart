import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:alpha/features/board/domain/board.dart';
import 'package:alpha/features/board/domain/board_type.dart';
import 'package:alpha/features/column/domain/board_column.dart';
import 'package:alpha/features/column/domain/weekly_columns.dart';
import 'package:alpha/features/task/domain/task.dart';
import 'package:alpha/features/preferences/domain/app_preferences.dart';
import 'package:alpha/features/preferences/providers/preferences_providers.dart';
import 'package:alpha/features/board/providers/weekly_board_provider.dart';
import 'package:alpha/shared/database.dart';
import 'package:alpha/shared/providers.dart';
import 'package:alpha/shared/week_utils.dart';

void main() {
  test('switching first-day-of-week finds existing board and tasks',
      () async {
    final db = AlphaDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [alphaDatabaseProvider.overrideWithValue(db)],
    );

    addTearDown(() {
      container.dispose();
      db.close();
    });

    // Create a board for the Monday-start week of March 16.
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

    // Verify tasks exist on the Monday-start board.
    final mondayBoardId = await container.read(
      weeklyBoardProvider(monday).future,
    );
    expect(mondayBoardId, boardId);
    final mondayTasks = await taskRepo.getByBoard(mondayBoardId);
    expect(mondayTasks.length, 1);
    expect(mondayTasks.first.title, 'Test task');

    // Now switch to Sunday start and look up the same week.
    final sunday = startOfWeek(
      DateTime(2026, 3, 18), // a Wednesday in the same week
      firstDay: DateTime.sunday,
    );
    // Sunday start of the week containing March 18 = March 15.
    expect(sunday, DateTime(2026, 3, 15));

    // Look up the board for Sunday March 15.
    final sundayBoardId = await container.read(
      weeklyBoardProvider(sunday).future,
    );

    // Should find the SAME board (via fallback), not create a new one.
    expect(
      sundayBoardId,
      boardId,
      reason: 'Should find the Monday-start board when querying '
          'for Sunday-start week',
    );

    // Tasks should still be there.
    final sundayTasks = await taskRepo.getByBoard(sundayBoardId);
    expect(sundayTasks.length, 1);
    expect(sundayTasks.first.title, 'Test task');

    // Verify no extra board was created.
    final allBoards = await boardRepo.listAll();
    expect(allBoards.length, 1, reason: 'Should not create a duplicate board');
  });

  test('weeklyBoardProvider with preference change does not create duplicate',
      () async {
    final db = AlphaDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [alphaDatabaseProvider.overrideWithValue(db)],
    );

    addTearDown(() {
      container.dispose();
      db.close();
    });

    // Step 1: Create board via provider (Monday start, default).
    final monday = DateTime(2026, 3, 16);
    final boardId = await container.read(
      weeklyBoardProvider(monday).future,
    );

    // Add a task.
    final taskRepo = container.read(taskRepositoryProvider);
    await taskRepo.create(Task(
      id: const Uuid().v4(),
      boardId: boardId,
      title: 'My task',
      position: 0,
      createdAt: DateTime.now(),
    ));

    // Step 2: Change preference to Sunday (set state directly
    // to avoid SharedPreferences binding requirement in tests).
    container.read(preferencesProvider.notifier).state =
        const AppPreferences(firstDayOfWeek: DateTime.sunday);

    // Step 3: Invalidate the old provider (simulates what happens
    // when the widget rebuilds with a new weekStart).
    container.invalidate(weeklyBoardProvider(monday));

    // Step 4: Look up for Sunday start of same week.
    final sunday = DateTime(2026, 3, 15);
    final sundayBoardId = await container.read(
      weeklyBoardProvider(sunday).future,
    );

    expect(sundayBoardId, boardId,
        reason: 'Must find existing Monday board');

    final tasks = await taskRepo.getByBoard(sundayBoardId);
    expect(tasks.length, 1);
    expect(tasks.first.title, 'My task');

    final boardRepo = container.read(boardRepositoryProvider);
    final allBoards = await boardRepo.listAll();
    expect(allBoards.length, 1,
        reason: 'Must not create a duplicate board');
  });

  test('prefers board with tasks over empty duplicate', () async {
    final db = AlphaDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [alphaDatabaseProvider.overrideWithValue(db)],
    );

    addTearDown(() {
      container.dispose();
      db.close();
    });

    const uuid = Uuid();
    final now = DateTime.now();
    final boardRepo = container.read(boardRepositoryProvider);
    final taskRepo = container.read(taskRepositoryProvider);
    final colRepo = container.read(columnRepositoryProvider);

    // Create Monday board WITH a task.
    final mondayBoardId = uuid.v4();
    await boardRepo.create(Board(
      id: mondayBoardId,
      name: 'Week of Mar 16',
      type: BoardType.weekly,
      weekStart: DateTime(2026, 3, 16),
      createdAt: now,
      updatedAt: now,
    ));
    for (final col in weeklyColumnDefs()) {
      await colRepo.create(BoardColumn(
        id: uuid.v4(),
        boardId: mondayBoardId,
        label: col.label,
        position: col.position,
        type: col.type,
      ));
    }
    await taskRepo.create(Task(
      id: uuid.v4(),
      boardId: mondayBoardId,
      title: 'Real task',
      position: 0,
      createdAt: now,
    ));

    // Create an EMPTY Sunday board (as if created by a previous
    // failed first-day switch attempt).
    final sundayBoardId = uuid.v4();
    await boardRepo.create(Board(
      id: sundayBoardId,
      name: 'Week of Mar 15',
      type: BoardType.weekly,
      weekStart: DateTime(2026, 3, 15),
      createdAt: now,
      updatedAt: now,
    ));
    for (final col in weeklyColumnDefs(firstDay: DateTime.sunday)) {
      await colRepo.create(BoardColumn(
        id: uuid.v4(),
        boardId: sundayBoardId,
        label: col.label,
        position: col.position,
        type: col.type,
      ));
    }

    // Query for Sunday week — should find the Monday board
    // (with tasks) instead of the empty Sunday board.
    final found = await boardRepo.getByWeekStart(DateTime(2026, 3, 15));
    expect(found, isNotNull);
    expect(found!.id, mondayBoardId,
        reason: 'Must prefer the board WITH tasks');

    final tasks = await taskRepo.getByBoard(found.id);
    expect(tasks.length, 1);
    expect(tasks.first.title, 'Real task');
  });
}
