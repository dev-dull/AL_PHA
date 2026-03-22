import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:alpha/features/board/domain/board.dart';
import 'package:alpha/features/board/domain/board_type.dart';
import 'package:alpha/features/column/domain/board_column.dart';
import 'package:alpha/features/column/domain/weekly_columns.dart';
import 'package:alpha/features/preferences/domain/app_preferences.dart';
import 'package:alpha/features/preferences/providers/preferences_providers.dart';
import 'package:alpha/features/task/domain/task.dart';
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
    expect(sunday, DateTime(2026, 3, 15));

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
    final db = AlphaDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [alphaDatabaseProvider.overrideWithValue(db)],
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

  test('prefers board with tasks and cleans up empty duplicate',
      () async {
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
    // and delete the empty Sunday board.
    final found = await boardRepo.getByWeekStart(DateTime(2026, 3, 15));
    expect(found, isNotNull);
    expect(found!.id, mondayId);

    // Empty board should be cleaned up.
    final all = await boardRepo.listAll();
    expect(all.length, 1);
    expect(all.first.id, mondayId);
  });

  test('new board created with Sunday columns when no board exists',
      () async {
    final db = AlphaDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [alphaDatabaseProvider.overrideWithValue(db)],
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
}
