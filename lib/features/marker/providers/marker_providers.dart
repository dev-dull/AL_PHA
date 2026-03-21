import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:alpha/features/board/providers/weekly_board_provider.dart';
import 'package:alpha/features/column/domain/column_type.dart';
import 'package:alpha/features/marker/domain/marker.dart';
import 'package:alpha/features/marker/domain/marker_symbol.dart';
import 'package:alpha/features/task/domain/task.dart';
import 'package:alpha/features/task/domain/task_state.dart';
import 'package:alpha/features/task/providers/task_providers.dart';
import 'package:alpha/shared/providers.dart';
import 'package:alpha/shared/week_utils.dart';

part 'marker_providers.g.dart';

@riverpod
Stream<Map<String, Marker>> markersByBoard(
  MarkersByBoardRef ref,
  String boardId,
) {
  final repo = ref.watch(markerRepositoryProvider);
  return repo.watchByBoard(boardId).map((markers) {
    return {for (final m in markers) '${m.taskId}_${m.columnId}': m};
  });
}

@riverpod
Marker? marker(MarkerRef ref, String taskId, String columnId) {
  // Find the boardId from the marker repository is not possible
  // without knowing it. Instead, we return null as a fallback —
  // callers should use markerFromBoard for efficiency.
  return null;
}

/// Derived provider for a single cell marker, keyed off the
/// board-level markers map for granular rebuilds.
@riverpod
Marker? markerFromBoard(
  MarkerFromBoardRef ref,
  String boardId,
  String taskId,
  String columnId,
) {
  final markersAsync = ref.watch(markersByBoardProvider(boardId));
  return markersAsync.whenOrNull(
    data: (markers) => markers['${taskId}_$columnId'],
  );
}

/// Helper class for marker mutations. Access via ref.read.
@riverpod
MarkerActions markerActions(MarkerActionsRef ref) {
  return MarkerActions(ref);
}

class MarkerActions {
  final MarkerActionsRef _ref;
  static const _uuid = Uuid();

  MarkerActions(this._ref);

  /// Cycles a marker: empty → DOT → SLASH → X → empty.
  /// Migration column: empty → > → empty.
  /// When cycling to X, auto-fills `<` on later scheduled days.
  /// When cycling away from X, reverts `<` back to dots.
  Future<void> cycleMarker({
    required String boardId,
    required String taskId,
    required String columnId,
  }) async {
    final repo = _ref.read(markerRepositoryProvider);
    final existing = await repo.get(taskId, columnId);

    // Migration column only allows > toggle.
    if (await _isMigrationColumn(boardId, columnId)) {
      if (existing == null) {
        await repo.set(
          Marker(
            id: _uuid.v4(),
            taskId: taskId,
            columnId: columnId,
            boardId: boardId,
            symbol: MarkerSymbol.migratedForward,
            updatedAt: DateTime.now(),
          ),
        );
        await _migrateTaskToNextWeek(boardId: boardId, taskId: taskId);
      } else {
        await repo.remove(taskId, columnId);
      }
      return;
    }

    if (existing == null) {
      // Empty -> DOT
      await repo.set(
        Marker(
          id: _uuid.v4(),
          taskId: taskId,
          columnId: columnId,
          boardId: boardId,
          symbol: MarkerSymbol.cycleStart,
          updatedAt: DateTime.now(),
        ),
      );
    } else {
      final wasX = existing.symbol == MarkerSymbol.x;
      final next = existing.symbol.nextInCycle;
      if (next == null) {
        // Back to empty
        await repo.remove(taskId, columnId);
      } else {
        await repo.set(
          existing.copyWith(symbol: next, updatedAt: DateTime.now()),
        );
        if (next == MarkerSymbol.x) {
          await _autoFillDoneEarly(
            boardId: boardId,
            taskId: taskId,
            completedColumnId: columnId,
          );
        }
      }
      // If we just left X, revert any < back to dots.
      if (wasX) {
        await _revertDoneEarly(
          boardId: boardId,
          taskId: taskId,
          changedColumnId: columnId,
        );
      }
    }
  }

  /// Sets a marker to a specific symbol (used by the picker).
  /// Handles auto-fill `<` and revert logic.
  /// Migration column only accepts [MarkerSymbol.migratedForward]
  /// or null (clear).
  Future<void> setMarker({
    required String boardId,
    required String taskId,
    required String columnId,
    required MarkerSymbol? symbol,
  }) async {
    // Enforce migration column constraint.
    if (symbol != null &&
        symbol != MarkerSymbol.migratedForward &&
        await _isMigrationColumn(boardId, columnId)) {
      return;
    }

    final repo = _ref.read(markerRepositoryProvider);
    final existing = await repo.get(taskId, columnId);
    final wasX = existing?.symbol == MarkerSymbol.x;

    if (symbol == null) {
      await repo.remove(taskId, columnId);
    } else if (existing != null) {
      await repo.set(
        existing.copyWith(symbol: symbol, updatedAt: DateTime.now()),
      );
    } else {
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

    if (symbol == MarkerSymbol.x) {
      await _autoFillDoneEarly(
        boardId: boardId,
        taskId: taskId,
        completedColumnId: columnId,
      );
    } else if (wasX) {
      await _revertDoneEarly(
        boardId: boardId,
        taskId: taskId,
        changedColumnId: columnId,
      );
    }

    // If > was set on the migration column, migrate the task.
    if (symbol == MarkerSymbol.migratedForward &&
        await _isMigrationColumn(boardId, columnId)) {
      await _migrateTaskToNextWeek(boardId: boardId, taskId: taskId);
    }
  }

  /// When a task is marked X on a day, any dots on later day
  /// columns become `<` (done early).
  Future<void> _autoFillDoneEarly({
    required String boardId,
    required String taskId,
    required String completedColumnId,
  }) async {
    final columnRepo = _ref.read(columnRepositoryProvider);
    final markerRepo = _ref.read(markerRepositoryProvider);

    final columns = await columnRepo.getByBoard(boardId);
    final completedCol = columns.firstWhere((c) => c.id == completedColumnId);

    // Only auto-fill day columns after the completed one.
    final laterDayColumns = columns.where(
      (c) => c.position > completedCol.position && c.type == ColumnType.date,
    );

    final now = DateTime.now();
    for (final col in laterDayColumns) {
      final marker = await markerRepo.get(taskId, col.id);
      if (marker != null && marker.symbol == MarkerSymbol.dot) {
        await markerRepo.set(
          marker.copyWith(symbol: MarkerSymbol.doneEarly, updatedAt: now),
        );
      }
    }
  }

  /// When a marker leaves X, any `<` (done early) on later day
  /// columns revert back to dots.
  Future<void> _revertDoneEarly({
    required String boardId,
    required String taskId,
    required String changedColumnId,
  }) async {
    final columnRepo = _ref.read(columnRepositoryProvider);
    final markerRepo = _ref.read(markerRepositoryProvider);

    final columns = await columnRepo.getByBoard(boardId);
    final changedCol = columns.firstWhere((c) => c.id == changedColumnId);

    final laterDayColumns = columns.where(
      (c) => c.position > changedCol.position && c.type == ColumnType.date,
    );

    final now = DateTime.now();
    for (final col in laterDayColumns) {
      final marker = await markerRepo.get(taskId, col.id);
      if (marker != null && marker.symbol == MarkerSymbol.doneEarly) {
        await markerRepo.set(
          marker.copyWith(symbol: MarkerSymbol.dot, updatedAt: now),
        );
      }
    }
  }

  /// Returns true if the column is a migration column (not a day).
  Future<bool> _isMigrationColumn(String boardId, String columnId) async {
    final columnRepo = _ref.read(columnRepositoryProvider);
    final columns = await columnRepo.getByBoard(boardId);
    final col = columns.firstWhere((c) => c.id == columnId);
    return col.type != ColumnType.date;
  }

  /// Migrates a single task to the next week's board.
  /// Copies the task's day-of-week dot schedule to the new board.
  Future<void> _migrateTaskToNextWeek({
    required String boardId,
    required String taskId,
  }) async {
    final taskRepo = _ref.read(taskRepositoryProvider);
    final markerRepo = _ref.read(markerRepositoryProvider);
    final columnRepo = _ref.read(columnRepositoryProvider);
    final boardRepo = _ref.read(boardRepositoryProvider);

    final task = await taskRepo.getById(taskId);
    if (task == null) return;
    // Only migrate open or in-progress tasks.
    if (task.state != TaskState.open &&
        task.state != TaskState.inProgress) {
      return;
    }

    // Determine the next week's Monday from the board's weekStart.
    final board = await boardRepo.getById(boardId);
    if (board == null) return;
    final boardMonday = board.weekStart ?? mondayOfWeek(board.createdAt);
    final nextMonday = boardMonday.add(const Duration(days: 7));

    final targetBoardId = await _ref.read(
      weeklyBoardProvider(nextMonday).future,
    );

    // Check if already migrated to this target.
    final targetTasks = await taskRepo.getByBoard(targetBoardId);
    final alreadyMigrated = targetTasks.any(
      (t) =>
          t.migratedFromBoardId == boardId &&
          t.migratedFromTaskId == taskId,
    );
    if (alreadyMigrated) return;

    // Collect dot positions from source board.
    final sourceColumns = await columnRepo.getByBoard(boardId);
    final sourceMarkers = await markerRepo.getByBoard(boardId);
    final dotPositions = <int>{};
    for (final col in sourceColumns) {
      if (col.type != ColumnType.date) continue;
      final hasDot = sourceMarkers.any(
        (m) =>
            m.taskId == taskId &&
            m.columnId == col.id &&
            (m.symbol == MarkerSymbol.dot ||
                m.symbol == MarkerSymbol.migratedForward),
      );
      if (hasDot) dotPositions.add(col.position);
    }

    final now = DateTime.now();

    // Create on target board.
    final newTaskId = _uuid.v4();
    await taskRepo.create(
      Task(
        id: newTaskId,
        boardId: targetBoardId,
        title: task.title,
        description: task.description,
        priority: task.priority,
        position: targetTasks.length,
        createdAt: now,
        deadline: task.deadline,
        migratedFromBoardId: boardId,
        migratedFromTaskId: task.id,
      ),
    );

    // Copy dot schedule to target board.
    if (dotPositions.isNotEmpty) {
      final targetColumns = await columnRepo.getByBoard(targetBoardId);
      for (final targetCol in targetColumns) {
        if (targetCol.type == ColumnType.date &&
            dotPositions.contains(targetCol.position)) {
          await markerRepo.set(
            Marker(
              id: _uuid.v4(),
              taskId: newTaskId,
              columnId: targetCol.id,
              boardId: targetBoardId,
              symbol: MarkerSymbol.dot,
              updatedAt: now,
            ),
          );
        }
      }
    }

    // Invalidate target board providers.
    _ref.invalidate(taskListProvider(targetBoardId));
    _ref.invalidate(markersByBoardProvider(targetBoardId));
  }

  /// Auto-fills `>` (migrated) on past day columns where a task
  /// still has a dot (scheduled but not acted on).
  /// Also marks the migration column and creates the task on
  /// the current week's board.
  /// Call this when opening a board to catch up missed days.
  Future<void> autoFillMissedDays({required String boardId}) async {
    final boardRepo = _ref.read(boardRepositoryProvider);
    final columnRepo = _ref.read(columnRepositoryProvider);
    final markerRepo = _ref.read(markerRepositoryProvider);
    final taskRepo = _ref.read(taskRepositoryProvider);

    final board = await boardRepo.getById(boardId);
    if (board == null) return;

    final columns = await columnRepo.getByBoard(boardId);
    final dayColumns = columns.where((c) => c.type == ColumnType.date);
    if (dayColumns.isEmpty) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Determine which day columns are in the past.
    final boardWeekStart = board.weekStart ??
        DateTime(
          board.createdAt.year,
          board.createdAt.month,
          board.createdAt.day,
        ).subtract(Duration(days: board.createdAt.weekday - 1));
    final currentMonday = mondayOfWeek(today);

    Iterable<dynamic> pastDayColumns;
    if (boardWeekStart.isBefore(currentMonday)) {
      // Past week: all day columns are past.
      pastDayColumns = dayColumns;
    } else if (boardWeekStart == currentMonday) {
      // Current week: columns before today are past.
      pastDayColumns = dayColumns.where((c) => c.position < (now.weekday - 1));
    } else {
      // Future week: nothing is past.
      return;
    }

    if (pastDayColumns.isEmpty) return;

    final allMarkers = await markerRepo.getByBoard(boardId);
    // Track which tasks had dots converted to > (need migration),
    // and which day-of-week positions had dots (to carry over).
    final migratedTaskIds = <String>{};
    final taskDotPositions = <String, Set<int>>{};

    for (final col in pastDayColumns) {
      final dotsInCol = allMarkers.where(
        (m) => m.columnId == col.id && m.symbol == MarkerSymbol.dot,
      );
      for (final marker in dotsInCol) {
        await markerRepo.set(
          marker.copyWith(symbol: MarkerSymbol.migratedForward, updatedAt: now),
        );
        migratedTaskIds.add(marker.taskId);
        taskDotPositions
            .putIfAbsent(marker.taskId, () => {})
            .add(col.position);
      }
    }

    if (migratedTaskIds.isEmpty) return;

    // Re-read markers after converting dots to >.
    final updatedMarkers = await markerRepo.getByBoard(boardId);

    // Determine which future day columns remain (current week only).
    final futureDayColumns = dayColumns.where(
      (c) => c.position >= (now.weekday - 1),
    );

    // For each affected task, check if it has any remaining dots
    // on future day columns. If not, it needs full migration.
    final tasksToMigrate = <String>{};
    for (final taskId in migratedTaskIds) {
      final hasFutureDot = futureDayColumns.any((col) {
        return updatedMarkers.any(
          (m) =>
              m.taskId == taskId &&
              m.columnId == col.id &&
              m.symbol == MarkerSymbol.dot,
        );
      });
      if (!hasFutureDot) {
        tasksToMigrate.add(taskId);
      }
    }

    if (tasksToMigrate.isEmpty) return;

    // Mark the migration column (>) for tasks with no future dots.
    final migrationCol = columns
        .where((c) => c.type != ColumnType.date)
        .firstOrNull;
    if (migrationCol != null) {
      for (final taskId in tasksToMigrate) {
        final existing = await markerRepo.get(taskId, migrationCol.id);
        if (existing == null) {
          await markerRepo.set(
            Marker(
              id: _uuid.v4(),
              taskId: taskId,
              columnId: migrationCol.id,
              boardId: boardId,
              symbol: MarkerSymbol.migratedForward,
              updatedAt: now,
            ),
          );
        }
      }
    }

    // Determine target week: next week if current week, else current.
    final isPastWeek = boardWeekStart.isBefore(currentMonday);
    final targetMonday = isPastWeek
        ? currentMonday
        : currentMonday.add(const Duration(days: 7));

    final targetBoardId = await _ref.read(
      weeklyBoardProvider(targetMonday).future,
    );

    // Get existing tasks on the target board to check for dupes
    // and compute next position.
    final targetTasks = await taskRepo.getByBoard(targetBoardId);
    final existingMigrationSources = targetTasks
        .where((t) => t.migratedFromBoardId == boardId)
        .map((t) => t.migratedFromTaskId)
        .toSet();
    var nextPosition = targetTasks.length;
    var didMigrate = false;

    for (final taskId in tasksToMigrate) {
      // Skip if already migrated to target board.
      if (existingMigrationSources.contains(taskId)) continue;

      final task = await taskRepo.getById(taskId);
      if (task == null) continue;
      // Only migrate open or in-progress tasks.
      if (task.state != TaskState.open &&
          task.state != TaskState.inProgress) {
        continue;
      }

      // Create on target board.
      final newTaskId = _uuid.v4();
      await taskRepo.create(
        Task(
          id: newTaskId,
          boardId: targetBoardId,
          title: task.title,
          description: task.description,
          priority: task.priority,
          position: nextPosition,
          createdAt: now,
          deadline: task.deadline,
          migratedFromBoardId: boardId,
          migratedFromTaskId: task.id,
        ),
      );
      nextPosition++;
      didMigrate = true;

      // Carry over day-of-week dots to the target board.
      final positions = taskDotPositions[taskId];
      if (positions != null && positions.isNotEmpty) {
        final targetColumns = await columnRepo.getByBoard(targetBoardId);
        for (final targetCol in targetColumns) {
          if (targetCol.type == ColumnType.date &&
              positions.contains(targetCol.position)) {
            await markerRepo.set(
              Marker(
                id: _uuid.v4(),
                taskId: newTaskId,
                columnId: targetCol.id,
                boardId: targetBoardId,
                symbol: MarkerSymbol.dot,
                updatedAt: now,
              ),
            );
          }
        }
      }
    }

    // Invalidate target board providers so they pick up new data
    // immediately when navigated to.
    if (didMigrate) {
      _ref.invalidate(taskListProvider(targetBoardId));
      _ref.invalidate(markersByBoardProvider(targetBoardId));
    }
  }
}
