import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:planyr/features/board/domain/board.dart';
import 'package:planyr/features/board/domain/board_type.dart';
import 'package:planyr/features/board/providers/day_summary_provider.dart';
import 'package:planyr/features/column/domain/board_column.dart';
import 'package:planyr/features/column/domain/weekly_columns.dart';
import 'package:planyr/features/marker/domain/marker.dart';
import 'package:planyr/features/marker/domain/marker_symbol.dart';
import 'package:planyr/features/task/domain/task.dart';
import 'package:planyr/shared/database.dart';
import 'package:planyr/shared/providers.dart';
import 'package:planyr/shared/week_utils.dart';

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

  Future<String> createWeeklyBoard(DateTime weekStart) async {
    final boardRepo = container.read(boardRepositoryProvider);
    final colRepo = container.read(columnRepositoryProvider);
    final boardId = uuid.v4();
    final now = DateTime.now();
    await boardRepo.create(Board(
      id: boardId,
      name: weekBoardName(weekStart),
      type: BoardType.weekly,
      weekStart: weekStart,
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
    return boardId;
  }

  test('day summaries count markers correctly', () async {
    final monday = DateTime(2026, 3, 23);
    final boardId = await createWeeklyBoard(monday);

    final taskRepo = container.read(taskRepositoryProvider);
    final markerRepo = container.read(markerRepositoryProvider);
    final colRepo = container.read(columnRepositoryProvider);

    // Create a task with markers: dot on Mon, slash on Tue, x on Wed.
    final task = Task(
      id: uuid.v4(),
      boardId: boardId,
      title: 'Test task',
      position: 0,
      createdAt: DateTime.now(),
    );
    await taskRepo.create(task);

    final columns = await colRepo.getByBoard(boardId);
    final monCol = columns.firstWhere((c) => c.position == 0);
    final tueCol = columns.firstWhere((c) => c.position == 1);
    final wedCol = columns.firstWhere((c) => c.position == 2);

    await markerRepo.set(Marker(
      id: uuid.v4(), taskId: task.id, columnId: monCol.id,
      boardId: boardId, symbol: MarkerSymbol.dot,
      updatedAt: DateTime.now(),
    ));
    await markerRepo.set(Marker(
      id: uuid.v4(), taskId: task.id, columnId: tueCol.id,
      boardId: boardId, symbol: MarkerSymbol.slash,
      updatedAt: DateTime.now(),
    ));
    await markerRepo.set(Marker(
      id: uuid.v4(), taskId: task.id, columnId: wedCol.id,
      boardId: boardId, symbol: MarkerSymbol.x,
      updatedAt: DateTime.now(),
    ));

    // Query the day summaries for this week.
    final result = await container.read(
      daySummariesProvider(monday, DateTime(2026, 3, 30)).future,
    );

    // Monday should have 1 scheduled.
    final monSummary = result[DateTime(2026, 3, 23)];
    expect(monSummary, isNotNull, reason: 'Monday should have a summary');
    expect(monSummary!.scheduled, 1);
    expect(monSummary.completed, 0);

    // Tuesday should have 1 inProgress with partial credit.
    final tueSummary = result[DateTime(2026, 3, 24)];
    expect(tueSummary, isNotNull, reason: 'Tuesday should have a summary');
    expect(tueSummary!.inProgress, 1);
    // Slash gets 0.5 weight: 0.5 / 1 = 0.5 (yellow/amber, not red).
    expect(tueSummary.completionRate, 0.5);

    // Wednesday should have 1 completed.
    final wedSummary = result[DateTime(2026, 3, 25)];
    expect(wedSummary, isNotNull, reason: 'Wednesday should have a summary');
    expect(wedSummary!.completed, 1);

    // Completion rate: 1 completed out of 1 total per day.
    expect(wedSummary.completionRate, 1.0);
  });

  test('day summaries use board weekStart not query weekStart',
      () async {
    // Create a board for Monday March 23.
    final monday = DateTime(2026, 3, 23);
    final boardId = await createWeeklyBoard(monday);

    final taskRepo = container.read(taskRepositoryProvider);
    final markerRepo = container.read(markerRepositoryProvider);
    final colRepo = container.read(columnRepositoryProvider);

    final task = Task(
      id: uuid.v4(),
      boardId: boardId,
      title: 'Test',
      position: 0,
      createdAt: DateTime.now(),
    );
    await taskRepo.create(task);

    // Put a dot on position 0 (Monday).
    final columns = await colRepo.getByBoard(boardId);
    final monCol = columns.firstWhere((c) => c.position == 0);
    await markerRepo.set(Marker(
      id: uuid.v4(), taskId: task.id, columnId: monCol.id,
      boardId: boardId, symbol: MarkerSymbol.x,
      updatedAt: DateTime.now(),
    ));

    // Query for March — the provider computes startOfWeek(March 1).
    // March 1, 2026 is a Sunday, so startOfWeek = Feb 23 (Monday).
    // The board for March 23 should be found and position 0 should
    // map to Monday March 23, not to the query's weekStart.
    final result = await container.read(
      daySummariesProvider(
        DateTime(2026, 3, 1),
        DateTime(2026, 4, 1),
      ).future,
    );

    // The marker should appear on March 23 (Monday).
    final march23 = result[DateTime(2026, 3, 23)];
    expect(march23, isNotNull,
        reason: 'March 23 should have data');
    expect(march23!.completed, 1);

    // March 22 (Sunday, position 6 of previous week) should NOT
    // have the data.
    final march22 = result[DateTime(2026, 3, 22)];
    final has22 = march22 != null && march22.completed > 0;
    expect(has22, isFalse,
        reason: 'March 22 should NOT have the completed marker');
  });

  test('deferred (>) markers count separately from completed/missed',
      () async {
    // Regression: > used to count as "missed" and turn the day red
    // even though the task was carried forward (likely completed on
    // a later board). It should now count as `deferred` and not
    // contribute to the day's actionable activity.
    final monday = DateTime(2026, 3, 23);
    final boardId = await createWeeklyBoard(monday);

    final taskRepo = container.read(taskRepositoryProvider);
    final markerRepo = container.read(markerRepositoryProvider);
    final colRepo = container.read(columnRepositoryProvider);

    final task = Task(
      id: uuid.v4(), boardId: boardId,
      title: 'Test', position: 0, createdAt: DateTime.now(),
    );
    await taskRepo.create(task);
    final columns = await colRepo.getByBoard(boardId);

    // Put > on Tuesday (auto-migrated, task done on next week).
    final tueCol = columns.firstWhere((c) => c.position == 1);
    await markerRepo.set(Marker(
      id: uuid.v4(), taskId: task.id, columnId: tueCol.id,
      boardId: boardId, symbol: MarkerSymbol.migratedForward,
      updatedAt: DateTime.now(),
    ));

    final result = await container.read(
      daySummariesProvider(monday, DateTime(2026, 3, 30)).future,
    );

    final tue = result[DateTime(2026, 3, 24)];
    expect(tue, isNotNull);
    expect(tue!.deferred, 1, reason: 'should record the > marker');
    expect(tue.completed, 0);
    expect(tue.scheduled, 0);
    expect(tue.inProgress, 0);
    // Completion rate excludes deferred — no actionable basis.
    expect(tue.completionRate, 0);
  });

  test('day summaries correct when board found via ±1 day fallback',
      () async {
    // Board stored with Monday weekStart, but query uses Sunday.
    final monday = DateTime(2026, 3, 23);
    final boardId = await createWeeklyBoard(monday);

    final taskRepo = container.read(taskRepositoryProvider);
    final markerRepo = container.read(markerRepositoryProvider);
    final colRepo = container.read(columnRepositoryProvider);

    final task = Task(
      id: uuid.v4(),
      boardId: boardId,
      title: 'Test',
      position: 0,
      createdAt: DateTime.now(),
    );
    await taskRepo.create(task);

    // Dot on position 0 (Monday in the board's column layout).
    final columns = await colRepo.getByBoard(boardId);
    final monCol = columns.firstWhere((c) => c.position == 0);
    await markerRepo.set(Marker(
      id: uuid.v4(), taskId: task.id, columnId: monCol.id,
      boardId: boardId, symbol: MarkerSymbol.x,
      updatedAt: DateTime.now(),
    ));

    // Query with Sunday weekStart (March 22). The ±1 fallback
    // finds the Monday board. Position 0 should map to Monday
    // March 23 (board.weekStart + 0), NOT Sunday March 22.
    final sunday = DateTime(2026, 3, 22);
    final result = await container.read(
      daySummariesProvider(sunday, DateTime(2026, 3, 29)).future,
    );

    // March 23 (Monday) should have the completed marker.
    final march23 = result[DateTime(2026, 3, 23)];
    expect(march23, isNotNull,
        reason: 'March 23 should have data');
    expect(march23!.completed, 1,
        reason: 'Position 0 = Monday = March 23');

    // March 22 (Sunday) should NOT have the marker.
    final march22 = result[DateTime(2026, 3, 22)];
    final wrongMapping = march22 != null && march22.completed > 0;
    expect(wrongMapping, isFalse,
        reason: 'Position 0 must NOT map to Sunday March 22');
  });
}
