import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:planyr/features/board/domain/board.dart';
import 'package:planyr/features/board/domain/board_type.dart';
import 'package:planyr/features/column/domain/board_column.dart';
import 'package:planyr/features/column/domain/column_type.dart';
import 'package:planyr/features/column/domain/weekly_columns.dart';
import 'package:planyr/features/marker/domain/marker_symbol.dart';
import 'package:planyr/features/marker/providers/marker_providers.dart';
import 'package:planyr/features/task/domain/task.dart';
import 'package:planyr/shared/database.dart';
import 'package:planyr/shared/providers.dart';
import 'package:planyr/shared/week_utils.dart';

/// Regression: when the user opens the editor on a non-recurring
/// task and ticks an additional day in the "Scheduled Days"
/// picker, that day must get a marker on save. The board's
/// onScheduledDaysChanged callback fires for non-recurring tasks
/// and reconciles markers against the picker (the picker IS the
/// source of truth for non-recurring; recurring tasks have their
/// markers driven by the rrule).
///
/// The earlier fix that stopped destructive marker erasure also
/// removed this legitimate "ticking adds a marker" path; this
/// test exercises the restored behavior via the actions layer
/// the callback uses internally.
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

  Future<(String boardId, List<BoardColumn> columns)> createBoard() async {
    final boardId = uuid.v4();
    final now = DateTime.now().toUtc();
    await container.read(boardRepositoryProvider).create(Board(
          id: boardId,
          name: weekBoardName(DateTime(2026, 5, 11)),
          type: BoardType.weekly,
          weekStart: DateTime(2026, 5, 11),
          createdAt: now,
          updatedAt: now,
        ));
    final cols = <BoardColumn>[];
    for (final def in weeklyColumnDefs()) {
      final col = BoardColumn(
        id: uuid.v4(),
        boardId: boardId,
        label: def.label,
        position: def.position,
        type: def.type,
      );
      await container.read(columnRepositoryProvider).create(col);
      cols.add(col);
    }
    return (boardId, cols);
  }

  /// Mirrors `_syncMarkersForPicker` in board_grid_body.dart —
  /// reconciles markers on day columns to match the picker's
  /// `days` set. Kept as a local helper so the test exercises the
  /// same actions layer the widget callback uses.
  Future<void> reconcileMarkers(
    String boardId,
    String taskId,
    bool isEvent,
    List<BoardColumn> columns,
    Set<int> days,
  ) async {
    final markerActions = container.read(markerActionsProvider);
    final markerRepo = container.read(markerRepositoryProvider);
    final sym = MarkerSymbol.defaultFor(isEvent: isEvent);
    for (final col in columns) {
      if (col.type != ColumnType.date) continue;
      final existing = await markerRepo.get(taskId, col.id);
      final shouldHave = days.contains(col.position);
      if (shouldHave && existing == null) {
        await markerActions.setMarker(
          boardId: boardId,
          taskId: taskId,
          columnId: col.id,
          symbol: sym,
        );
      } else if (!shouldHave &&
          existing != null &&
          (existing.symbol == MarkerSymbol.event ||
              existing.symbol == MarkerSymbol.dot)) {
        await markerActions.setMarker(
          boardId: boardId,
          taskId: taskId,
          columnId: col.id,
          symbol: null,
        );
      }
    }
  }

  test('ticking a new day in the picker adds a marker for that '
      'day, leaving existing markers in place', () async {
    final (boardId, columns) = await createBoard();
    final taskRepo = container.read(taskRepositoryProvider);
    final markerActions = container.read(markerActionsProvider);
    final markerRepo = container.read(markerRepositoryProvider);

    final taskId = uuid.v4();
    await taskRepo.create(Task(
      id: taskId,
      boardId: boardId,
      title: 'Ship the thing',
      position: 0,
      createdAt: DateTime.now().toUtc(),
    ));
    // Existing dot on Monday (position 0).
    final monCol = columns.firstWhere((c) => c.position == 0);
    await markerActions.setMarker(
      boardId: boardId,
      taskId: taskId,
      columnId: monCol.id,
      symbol: MarkerSymbol.dot,
    );

    // User ticks Wed (position 2) in the picker → save fires
    // onScheduledDaysChanged({0, 2}).
    await reconcileMarkers(boardId, taskId, false, columns, {0, 2});

    final wedCol = columns.firstWhere((c) => c.position == 2);
    expect(await markerRepo.get(taskId, monCol.id), isNotNull,
        reason: 'Existing Monday marker must survive');
    expect(await markerRepo.get(taskId, wedCol.id), isNotNull,
        reason: 'Newly ticked Wednesday must get a marker');
  });

  test('un-ticking a day in the picker removes that day\'s marker',
      () async {
    final (boardId, columns) = await createBoard();
    final taskRepo = container.read(taskRepositoryProvider);
    final markerActions = container.read(markerActionsProvider);
    final markerRepo = container.read(markerRepositoryProvider);

    final taskId = uuid.v4();
    await taskRepo.create(Task(
      id: taskId,
      boardId: boardId,
      title: 'Edit homelab 3 video',
      position: 0,
      createdAt: DateTime.now().toUtc(),
    ));
    // Existing dots on Mon and Fri.
    final monCol = columns.firstWhere((c) => c.position == 0);
    final friCol = columns.firstWhere((c) => c.position == 4);
    for (final col in [monCol, friCol]) {
      await markerActions.setMarker(
        boardId: boardId,
        taskId: taskId,
        columnId: col.id,
        symbol: MarkerSymbol.dot,
      );
    }

    // User un-ticks Fri → picker becomes {0}.
    await reconcileMarkers(boardId, taskId, false, columns, {0});

    expect(await markerRepo.get(taskId, monCol.id), isNotNull);
    expect(await markerRepo.get(taskId, friCol.id), isNull,
        reason: 'Un-ticked Friday marker must be removed');
  });

  test('checkmark and other non-dot symbols are NOT cleared by '
      'a picker un-tick (auto-fill state must survive)', () async {
    // Important constraint: the picker only owns dot/event
    // markers. A user-placed checkmark, slash, or migrated >
    // marker has independent meaning and shouldn't be wiped.
    final (boardId, columns) = await createBoard();
    final taskRepo = container.read(taskRepositoryProvider);
    final markerActions = container.read(markerActionsProvider);
    final markerRepo = container.read(markerRepositoryProvider);

    final taskId = uuid.v4();
    await taskRepo.create(Task(
      id: taskId,
      boardId: boardId,
      title: 'Took meds',
      position: 0,
      createdAt: DateTime.now().toUtc(),
    ));
    // A checkmark (done) — explicitly NOT a dot.
    final monCol = columns.firstWhere((c) => c.position == 0);
    await markerActions.setMarker(
      boardId: boardId,
      taskId: taskId,
      columnId: monCol.id,
      symbol: MarkerSymbol.x,
    );

    // Picker is empty → reconcile.
    await reconcileMarkers(boardId, taskId, false, columns, const {});

    final still = await markerRepo.get(taskId, monCol.id);
    expect(still?.symbol, MarkerSymbol.x,
        reason: 'A done/checkmark must not be cleared by the picker');
  });
}
