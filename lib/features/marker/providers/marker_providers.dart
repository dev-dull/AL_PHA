import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:planyr/features/board/domain/board.dart';
import 'package:planyr/features/board/domain/board_type.dart';
import 'package:planyr/features/column/domain/board_column.dart';
import 'package:planyr/features/column/domain/column_type.dart';
import 'package:planyr/features/column/domain/weekly_columns.dart';
import 'package:planyr/features/marker/domain/marker.dart';
import 'package:planyr/features/marker/domain/marker_symbol.dart';
import 'package:planyr/features/task/domain/task.dart';
import 'package:planyr/features/task/domain/task_state.dart';
import 'package:planyr/features/auth/providers/auth_providers.dart';
import 'package:planyr/features/preferences/providers/preferences_providers.dart';
import 'package:planyr/features/sync/providers/sync_providers.dart';
import 'package:planyr/features/task/providers/task_providers.dart';
import 'package:planyr/shared/providers.dart';
import 'package:planyr/shared/week_utils.dart';

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

  void _scheduleSync() {
    try {
      final auth = _ref.read(authProvider);
      if (auth.user == null) return;
      _ref.read(syncProvider.notifier).scheduleSyncAfterWrite();
    } catch (_) {
      // Sync provider may not be initialized yet.
    }
  }

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
            updatedAt: DateTime.now().toUtc(),
          ),
        );
        await _migrateTaskToNextWeek(boardId: boardId, taskId: taskId);
      } else {
        await repo.remove(taskId, columnId);
        await _undoMigrateTask(boardId: boardId, taskId: taskId);
      }
      return;
    }

    if (existing == null) {
      await repo.set(
        Marker(
          id: _uuid.v4(),
          taskId: taskId,
          columnId: columnId,
          boardId: boardId,
          symbol: MarkerSymbol.cycleStart,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    } else {
      final wasX = existing.symbol == MarkerSymbol.x;
      final next = existing.symbol.nextInCycle;
      if (next == null) {
        await repo.remove(taskId, columnId);
      } else {
        await repo.set(
          existing.copyWith(symbol: next, updatedAt: DateTime.now().toUtc()),
        );
        if (next == MarkerSymbol.x) {
          await _autoFillDoneEarly(
            boardId: boardId,
            taskId: taskId,
            completedColumnId: columnId,
          );
        }
      }
      if (wasX) {
        await _revertDoneEarly(
          boardId: boardId,
          taskId: taskId,
          changedColumnId: columnId,
        );
      }
    }
    _scheduleSync();
  }

  /// Sets a marker to a specific symbol (used by the picker).
  Future<void> setMarker({
    required String boardId,
    required String taskId,
    required String columnId,
    required MarkerSymbol? symbol,
  }) async {
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
        existing.copyWith(symbol: symbol, updatedAt: DateTime.now().toUtc()),
      );
    } else {
      await repo.set(
        Marker(
          id: _uuid.v4(),
          taskId: taskId,
          columnId: columnId,
          boardId: boardId,
          symbol: symbol,
          updatedAt: DateTime.now().toUtc(),
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

    if (symbol == MarkerSymbol.migratedForward &&
        await _isMigrationColumn(boardId, columnId)) {
      await _migrateTaskToNextWeek(boardId: boardId, taskId: taskId);
    }
    _scheduleSync();
  }

  Future<void> _autoFillDoneEarly({
    required String boardId,
    required String taskId,
    required String completedColumnId,
  }) async {
    final columnRepo = _ref.read(columnRepositoryProvider);
    final markerRepo = _ref.read(markerRepositoryProvider);

    final columns = await columnRepo.getByBoard(boardId);
    final completedCol = columns.firstWhere((c) => c.id == completedColumnId);

    final dateColumns = columns.where((c) => c.type == ColumnType.date);
    final now = DateTime.now();

    // Forward: later scheduled days get < (done before scheduled day).
    for (final col in dateColumns.where(
      (c) => c.position > completedCol.position,
    )) {
      final marker = await markerRepo.get(taskId, col.id);
      if (marker != null && marker.symbol == MarkerSymbol.dot) {
        await markerRepo.set(
          marker.copyWith(symbol: MarkerSymbol.doneEarly, updatedAt: now),
        );
      }
    }

    // Backfill: earlier days that were auto-migrated (>) become <
    // ("done late"). Without this, completing a task later in the
    // week leaves stale > markers that the monthly view counts as
    // missed even though the task is now done.
    for (final col in dateColumns.where(
      (c) => c.position < completedCol.position,
    )) {
      final marker = await markerRepo.get(taskId, col.id);
      if (marker != null &&
          marker.symbol == MarkerSymbol.migratedForward) {
        await markerRepo.set(
          marker.copyWith(symbol: MarkerSymbol.doneEarly, updatedAt: now),
        );
      }
    }
  }

  Future<void> _revertDoneEarly({
    required String boardId,
    required String taskId,
    required String changedColumnId,
  }) async {
    final columnRepo = _ref.read(columnRepositoryProvider);
    final markerRepo = _ref.read(markerRepositoryProvider);

    final columns = await columnRepo.getByBoard(boardId);
    final changedCol = columns.firstWhere((c) => c.id == changedColumnId);
    final dateColumns = columns.where((c) => c.type == ColumnType.date);
    final now = DateTime.now();

    // Forward: < was originally a •, restore it.
    for (final col in dateColumns.where(
      (c) => c.position > changedCol.position,
    )) {
      final marker = await markerRepo.get(taskId, col.id);
      if (marker != null && marker.symbol == MarkerSymbol.doneEarly) {
        await markerRepo.set(
          marker.copyWith(symbol: MarkerSymbol.dot, updatedAt: now),
        );
      }
    }

    // Backward: < was originally a > (auto-migrated), restore it.
    for (final col in dateColumns.where(
      (c) => c.position < changedCol.position,
    )) {
      final marker = await markerRepo.get(taskId, col.id);
      if (marker != null && marker.symbol == MarkerSymbol.doneEarly) {
        await markerRepo.set(
          marker.copyWith(
            symbol: MarkerSymbol.migratedForward, updatedAt: now,
          ),
        );
      }
    }
  }

  /// Copies tag assignments from one task to another.
  Future<void> _copyTags(String sourceTaskId, String destTaskId) async {
    final tagRepo = _ref.read(taskTagRepositoryProvider);
    final tags = await tagRepo.getTagsForTask(sourceTaskId);
    if (tags.isNotEmpty) {
      await tagRepo.setTagsForTask(
        destTaskId,
        tags.map((t) => t.id).toList(),
      );
    }
  }

  Future<bool> _isMigrationColumn(String boardId, String columnId) async {
    final columnRepo = _ref.read(columnRepositoryProvider);
    final columns = await columnRepo.getByBoard(boardId);
    final col = columns.firstWhere((c) => c.id == columnId);
    return col.type != ColumnType.date;
  }

  /// Looks up or creates a weekly board for the given week start,
  /// bypassing the Riverpod provider to avoid caching issues.
  Future<String> _getOrCreateWeeklyBoard(DateTime weekStart) async {
    final boardRepo = _ref.read(boardRepositoryProvider);
    final existing = await boardRepo.getByWeekStart(weekStart);
    if (existing != null) return existing.id;

    final firstDay =
        _ref.read(preferencesProvider).firstDayOfWeek;
    final columnRepo = _ref.read(columnRepositoryProvider);
    final boardId = _uuid.v4();
    final now = DateTime.now().toUtc();

    await boardRepo.create(
      Board(
        id: boardId,
        name: weekBoardName(weekStart),
        type: BoardType.weekly,
        weekStart: weekStart,
        createdAt: now,
        updatedAt: now,
      ),
    );

    for (final col in weeklyColumnDefs(firstDay: firstDay)) {
      await columnRepo.create(
        BoardColumn(
          id: _uuid.v4(),
          boardId: boardId,
          label: col.label,
          position: col.position,
          type: col.type,
        ),
      );
    }

    return boardId;
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
    if (task.state == TaskState.wontDo ||
        task.state == TaskState.cancelled) {
      return;
    }

    final firstDay =
        _ref.read(preferencesProvider).firstDayOfWeek;
    final board = await boardRepo.getById(boardId);
    if (board == null) return;
    final boardWeekStart = board.weekStart ??
        startOfWeek(board.createdAt, firstDay: firstDay);
    final nextWeekStart = DateTime(
      boardWeekStart.year,
      boardWeekStart.month,
      boardWeekStart.day + 7,
    );

    final targetBoardId =
        await _getOrCreateWeeklyBoard(nextWeekStart);

    final targetTasks = await taskRepo.getByBoard(targetBoardId);
    final alreadyMigrated = targetTasks.any(
      (t) =>
          t.migratedFromBoardId == boardId &&
          t.migratedFromTaskId == taskId,
    );
    if (alreadyMigrated) return;

    final sourceColumns = await columnRepo.getByBoard(boardId);
    final sourceMarkers = await markerRepo.getByBoard(boardId);
    final dotPositions = <int>{};
    for (final col in sourceColumns) {
      if (col.type != ColumnType.date) continue;
      final hasMarker = sourceMarkers.any(
        (m) => m.taskId == taskId && m.columnId == col.id,
      );
      if (hasMarker) dotPositions.add(col.position);
    }

    final now = DateTime.now().toUtc();

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
        isEvent: task.isEvent,
        scheduledTime: task.scheduledTime,
        recurrenceRule: task.recurrenceRule,
        seriesId: task.seriesId,
      ),
    );
    await _copyTags(task.id, newTaskId);

    final markerSymbol =
        MarkerSymbol.defaultFor(isEvent: task.isEvent);

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
              symbol: markerSymbol,
              updatedAt: now,
            ),
          );
        }
      }
    }

    _ref.invalidate(taskListProvider(targetBoardId));
    _ref.invalidate(markersByBoardProvider(targetBoardId));
  }

  /// Removes a previously migrated task from the next week's board
  /// when the user toggles off the > marker.
  Future<void> _undoMigrateTask({
    required String boardId,
    required String taskId,
  }) async {
    final firstDay =
        _ref.read(preferencesProvider).firstDayOfWeek;
    final taskRepo = _ref.read(taskRepositoryProvider);
    final boardRepo = _ref.read(boardRepositoryProvider);

    final board = await boardRepo.getById(boardId);
    if (board == null) return;
    final boardWeekStart = board.weekStart ??
        startOfWeek(board.createdAt, firstDay: firstDay);
    final nextWeekStart = DateTime(
      boardWeekStart.year,
      boardWeekStart.month,
      boardWeekStart.day + 7,
    );

    final targetBoard =
        await boardRepo.getByWeekStart(nextWeekStart);
    if (targetBoard == null) return;

    final targetTasks = await taskRepo.getByBoard(targetBoard.id);
    final migrated = targetTasks.where(
      (t) =>
          t.migratedFromBoardId == boardId &&
          t.migratedFromTaskId == taskId,
    );

    for (final t in migrated) {
      final markerRepo = _ref.read(markerRepositoryProvider);
      final markers = await markerRepo.getByBoard(targetBoard.id);
      for (final m in markers.where((m) => m.taskId == t.id)) {
        await markerRepo.remove(m.taskId, m.columnId);
      }
      await taskRepo.delete(t.id);
    }

    if (migrated.isNotEmpty) {
      _ref.invalidate(taskListProvider(targetBoard.id));
      _ref.invalidate(markersByBoardProvider(targetBoard.id));
    }
  }

  /// Retroactively cleans up stale `>` markers on day cells for
  /// tasks that were eventually completed in the same week.
  ///
  /// Pre-fix, marking a task done after auto-migration left those
  /// past `>` markers behind, so the monthly view counted those
  /// days as "missed." This sweep runs `_autoFillDoneEarly` for
  /// every existing `x` marker on the board, which now also
  /// backfills past `>` to `<`. Idempotent — safe to call on every
  /// board open.
  Future<void> backfillCompletedMigrations({
    required String boardId,
  }) async {
    final markerRepo = _ref.read(markerRepositoryProvider);
    final markers = await markerRepo.getByBoard(boardId);
    final completedMarkers =
        markers.where((m) => m.symbol == MarkerSymbol.x).toList();
    for (final m in completedMarkers) {
      await _autoFillDoneEarly(
        boardId: boardId,
        taskId: m.taskId,
        completedColumnId: m.columnId,
      );
    }
  }

  /// Auto-fills `>` (migrated) on past day columns where a task
  /// still has a dot (scheduled but not acted on).
  /// Also marks the migration column and creates the task on
  /// the next week's board.
  Future<void> autoFillMissedDays({required String boardId}) async {
    final boardRepo = _ref.read(boardRepositoryProvider);
    final columnRepo = _ref.read(columnRepositoryProvider);
    final markerRepo = _ref.read(markerRepositoryProvider);
    final taskRepo = _ref.read(taskRepositoryProvider);

    final firstDay =
        _ref.read(preferencesProvider).firstDayOfWeek;
    final board = await boardRepo.getById(boardId);
    if (board == null) return;

    final columns = await columnRepo.getByBoard(boardId);
    final dayColumns = columns.where((c) => c.type == ColumnType.date);
    if (dayColumns.isEmpty) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final boardWeekStart = board.weekStart ??
        startOfWeek(board.createdAt, firstDay: firstDay);
    final currentWeekStart =
        startOfWeek(today, firstDay: firstDay);

    final todayOffset = (now.weekday - firstDay + 7) % 7;

    Iterable<dynamic> pastDayColumns;
    if (boardWeekStart.isBefore(currentWeekStart)) {
      pastDayColumns = dayColumns;
    } else if (boardWeekStart == currentWeekStart) {
      pastDayColumns =
          dayColumns.where((c) => c.position < todayOffset);
    } else {
      return;
    }

    if (pastDayColumns.isEmpty) return;

    final allMarkers = await markerRepo.getByBoard(boardId);
    final allTasks = await taskRepo.getByBoard(boardId);
    final migratedTaskIds = <String>{};
    final taskDotPositions = <String, Set<int>>{};

    for (final col in pastDayColumns) {
      // Only DOT markers migrate. Event markers (the open-circle ○
      // for scheduled events) are date-specific by spec and must
      // never auto-roll forward — see CLAUDE.md "one-time events
      // don't migrate." Filtering at the marker-symbol layer here
      // (instead of relying on a task-level skip below) means we
      // can't accidentally migrate an event marker even if its
      // parent task lookup returns null or has surprising fields
      // (#42).
      final dotsInCol = allMarkers.where(
        (m) =>
            m.columnId == col.id &&
            m.symbol == MarkerSymbol.dot,
      );
      for (final marker in dotsInCol) {
        final task = allTasks
            .where((t) => t.id == marker.taskId)
            .firstOrNull;
        // Defensive: an orphan marker (task missing from this
        // board, possibly migrated elsewhere) — skip rather than
        // converting to >. Migrating something we can't identify
        // is exactly the class of footgun that bit us in #62.
        if (task == null) continue;
        // Skip recurring tasks — the virtual instance system
        // handles their carry-forward automatically.
        if (task.isRecurring) continue;
        // Belt-and-braces: events would already be filtered at
        // the marker-symbol layer above, but the data path could
        // also reach here via a task that's `isEvent = true` with
        // a stray `dot` marker (legacy / corrupt data). Skip any
        // such case for the same "events don't migrate" rule.
        if (task.isEvent) continue;

        await markerRepo.set(
          marker.copyWith(
            symbol: MarkerSymbol.migratedForward,
            updatedAt: now,
          ),
        );
        migratedTaskIds.add(marker.taskId);
        taskDotPositions
            .putIfAbsent(marker.taskId, () => {})
            .add(col.position);
      }
    }

    final isPastWeek = boardWeekStart.isBefore(currentWeekStart);

    if (migratedTaskIds.isEmpty) return;

    final updatedMarkers = await markerRepo.getByBoard(boardId);

    final futureDayColumns = dayColumns.where(
      (c) => c.position >= todayOffset,
    );

    final tasksToMigrate = <String>{};
    for (final taskId in migratedTaskIds) {
      final hasFutureDot = futureDayColumns.any((col) {
        return updatedMarkers.any(
          (m) =>
              m.taskId == taskId &&
              m.columnId == col.id &&
              (m.symbol == MarkerSymbol.dot ||
                  m.symbol == MarkerSymbol.event),
        );
      });
      if (!hasFutureDot) {
        tasksToMigrate.add(taskId);
      }
    }

    // For a CURRENT-week board, "missed Tuesday, today is Wednesday"
    // doesn't mean "migrate to next week" — the user just wants the
    // task to roll forward to today. Add a fresh dot on today's
    // column for each task that had no later dot this week, then
    // bail out before the migration-column / next-week-duplicate
    // path that's only correct for past-week boards.
    if (!isPastWeek) {
      final todayCol = dayColumns
          .where((c) => c.position == todayOffset)
          .firstOrNull;
      if (todayCol == null) return;
      for (final taskId in tasksToMigrate) {
        final existing = await markerRepo.get(taskId, todayCol.id);
        if (existing != null) continue;
        final task =
            allTasks.where((t) => t.id == taskId).firstOrNull;
        if (task == null) continue;
        await markerRepo.set(
          Marker(
            id: _uuid.v4(),
            taskId: taskId,
            columnId: todayCol.id,
            boardId: boardId,
            symbol: MarkerSymbol.defaultFor(isEvent: task.isEvent),
            updatedAt: now,
          ),
        );
      }
      return;
    }

    // Past-week board only: mark the migration column for missed
    // tasks. (Mid-week catch-up never sets the migration column —
    // see the early return above.)
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

    final targetWeekStart = currentWeekStart;

    final targetBoardId =
        await _getOrCreateWeeklyBoard(targetWeekStart);

    final targetTasks = await taskRepo.getByBoard(targetBoardId);
    final existingMigrationSources = targetTasks
        .where((t) => t.migratedFromBoardId == boardId)
        .map((t) => t.migratedFromTaskId)
        .toSet();
    var nextPosition = targetTasks.length;
    var didMigrate = false;

    // Migrate missed non-recurring tasks. Recurring tasks are
    // handled by the virtual instance system.
    for (final taskId in tasksToMigrate) {
      if (existingMigrationSources.contains(taskId)) continue;

      final task = await taskRepo.getById(taskId);
      if (task == null) continue;
      if (task.isRecurring) continue;
      if (task.state != TaskState.open &&
          task.state != TaskState.inProgress) {
        continue;
      }

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
          isEvent: task.isEvent,
          scheduledTime: task.scheduledTime,
          recurrenceRule: task.recurrenceRule,
          seriesId: task.seriesId,
        ),
      );
      await _copyTags(task.id, newTaskId);
      nextPosition++;
      didMigrate = true;

      final markerSymbol =
          MarkerSymbol.defaultFor(isEvent: task.isEvent);
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
                symbol: markerSymbol,
                updatedAt: now,
              ),
            );
          }
        }
      }
    }

    if (didMigrate) {
      _ref.invalidate(taskListProvider(targetBoardId));
      _ref.invalidate(markersByBoardProvider(targetBoardId));
    }
  }

}
