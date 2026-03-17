import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:alpha/features/column/domain/column_type.dart';
import 'package:alpha/features/marker/domain/marker.dart';
import 'package:alpha/features/marker/domain/marker_symbol.dart';
import 'package:alpha/shared/providers.dart';

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
  /// When cycling to X, auto-fills `<` on later scheduled days.
  /// When cycling away from X, reverts `<` back to dots.
  Future<void> cycleMarker({
    required String boardId,
    required String taskId,
    required String columnId,
  }) async {
    final repo = _ref.read(markerRepositoryProvider);
    final existing = await repo.get(taskId, columnId);

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
  Future<void> setMarker({
    required String boardId,
    required String taskId,
    required String columnId,
    required MarkerSymbol? symbol,
  }) async {
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

  /// Auto-fills `>` (migrated) on past day columns where a task
  /// still has a dot (scheduled but not acted on).
  /// Call this when opening a board to catch up missed days.
  Future<void> autoFillMissedDays({required String boardId}) async {
    final boardRepo = _ref.read(boardRepositoryProvider);
    final columnRepo = _ref.read(columnRepositoryProvider);
    final markerRepo = _ref.read(markerRepositoryProvider);

    final board = await boardRepo.getById(boardId);
    if (board == null) return;

    final columns = await columnRepo.getByBoard(boardId);
    final dayColumns = columns.where((c) => c.type == ColumnType.date);
    if (dayColumns.isEmpty) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Determine which day columns are in the past.
    // Column positions 0–6 map to Mon–Sun.
    // Compare the board's week to the current week.
    final boardCreatedAt = board.createdAt;
    final boardMonday = boardCreatedAt.subtract(
      Duration(days: boardCreatedAt.weekday - 1),
    );
    final boardWeekStart = DateTime(
      boardMonday.year,
      boardMonday.month,
      boardMonday.day,
    );
    final currentMonday = today.subtract(Duration(days: today.weekday - 1));

    Iterable<dynamic> pastDayColumns;
    if (boardWeekStart.isBefore(currentMonday)) {
      // Past week: all day columns are past.
      pastDayColumns = dayColumns;
    } else if (boardWeekStart == currentMonday) {
      // Current week: columns before today are past.
      // position 0=Mon → weekday 1, so past if position < (weekday - 1).
      pastDayColumns = dayColumns.where((c) => c.position < (now.weekday - 1));
    } else {
      // Future week: nothing is past.
      return;
    }

    if (pastDayColumns.isEmpty) return;

    final allMarkers = await markerRepo.getByBoard(boardId);
    for (final col in pastDayColumns) {
      final dotsInCol = allMarkers.where(
        (m) => m.columnId == col.id && m.symbol == MarkerSymbol.dot,
      );
      for (final marker in dotsInCol) {
        await markerRepo.set(
          marker.copyWith(symbol: MarkerSymbol.migratedForward, updatedAt: now),
        );
      }
    }
  }
}
