import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:planyr/app/theme.dart';
import 'package:planyr/design_system/widgets/dot_grid_background.dart';
import 'package:planyr/features/column/domain/board_column.dart';
import 'package:planyr/features/column/domain/column_type.dart';
import 'package:planyr/features/column/domain/weekly_columns.dart';
import 'package:planyr/features/column/providers/column_providers.dart';
import 'package:planyr/features/marker/domain/marker.dart';
import 'package:planyr/features/series/domain/board_item.dart';
import 'package:planyr/features/series/domain/recurring_series.dart';
import 'package:planyr/features/series/providers/series_providers.dart';
import 'package:planyr/features/tag/domain/tag.dart';
import 'package:planyr/features/tag/domain/tag_palette.dart';
import 'package:planyr/features/tag/presentation/tag_badge.dart';
import 'package:planyr/features/tag/providers/tag_providers.dart';
import 'package:planyr/features/marker/domain/marker_symbol.dart';
import 'package:planyr/features/marker/presentation/marker_cell.dart';
import 'package:planyr/features/marker/providers/marker_providers.dart';
import 'package:planyr/features/task/domain/recurrence.dart';
import 'package:planyr/features/task/domain/task.dart';
import 'package:planyr/shared/providers.dart';
import 'package:planyr/features/board/providers/board_providers.dart';
import 'package:planyr/features/auth/providers/auth_providers.dart';
import 'package:planyr/features/sync/providers/sync_providers.dart';
import 'package:planyr/features/task/domain/task_sort.dart';
import 'package:planyr/features/task/domain/task_state.dart';
import 'package:planyr/features/task/presentation/task_detail_sheet.dart';
import 'package:planyr/features/preferences/providers/preferences_providers.dart';
import 'package:planyr/features/task/providers/task_providers.dart';
import 'package:planyr/shared/week_utils.dart';

/// Convert a stored UTC "HH:mm" string to local time for display.
String _utcTimeToLocal(String utcTime) {
  final parts = utcTime.split(':');
  if (parts.length != 2) return utcTime;
  final now = DateTime.now();
  final utcDt = DateTime.utc(
    now.year, now.month, now.day,
    int.parse(parts[0]), int.parse(parts[1]),
  );
  final local = utcDt.toLocal();
  final h = local.hour;
  final m = local.minute;
  final amPm = h >= 12 ? 'PM' : 'AM';
  final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
  return '$h12:${m.toString().padLeft(2, '0')} $amPm';
}

/// The board grid body: column headers + task rows with markers.
/// Used by both [BoardDetailScreen] and [WeeklyViewScreen].
class BoardGridBody extends ConsumerStatefulWidget {
  final String boardId;

  const BoardGridBody({super.key, required this.boardId});

  @override
  ConsumerState<BoardGridBody> createState() => _BoardGridBodyState();
}

class _BoardGridBodyState extends ConsumerState<BoardGridBody> {
  static const _uuid = Uuid();
  static const double _headerHeight = 44;

  TaskSortMode _sortMode = TaskSortMode.manual;

  /// Tag IDs to filter by. Empty means no filter (show all).
  /// Contains a special '_none' value when filtering to untagged.
  final Set<String> _tagFilter = {};
  static const _untaggedFilter = '_none';

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final actions = ref.read(markerActionsProvider);
      // Auto-fill missed days and migrate incomplete tasks.
      await actions.autoFillMissedDays(boardId: widget.boardId);
      // Sweep stale > markers left behind by pre-fix auto-migration:
      // for any task that's now done in this week, convert past >
      // to <. Idempotent.
      await actions.backfillCompletedMigrations(
        boardId: widget.boardId,
      );
      // Auto-materialize virtual series instances so all rows
      // are real tasks with full interactivity (drag, markers).
      await _materializeVirtualInstances();
    });
  }

  /// Creates real task rows for any active series that should
  /// appear on this board but don't have a materialized instance.
  Future<void> _materializeVirtualInstances() async {
    // Read the board directly from the DB — the boardProvider
    // FutureProvider may not have resolved yet in initState.
    final boardRepo = ref.read(boardRepositoryProvider);
    final boardData = await boardRepo.getById(widget.boardId);
    if (boardData == null) return;
    final weekStart = boardData.weekStart;
    if (weekStart == null) return;

    final firstDay = ref.read(preferencesProvider).firstDayOfWeek;
    final seriesRepo = ref.read(seriesRepositoryProvider);
    final taskRepo = ref.read(taskRepositoryProvider);
    // Read directly from the DB (not the stream provider cache)
    // because the providers may not have emitted yet.
    final allSeries = await seriesRepo.getActive();
    final tasks = await taskRepo.getByBoard(widget.boardId);

    final materializedSeriesIds = <String>{};
    final existingTitles = <String>{};
    for (final t in tasks) {
      if (t.seriesId != null) materializedSeriesIds.add(t.seriesId!);
      existingTitles.add(t.title);
    }

    final seriesActions = ref.read(seriesActionsProvider);

    for (final series in allSeries) {
      if (materializedSeriesIds.contains(series.id)) continue;
      if (existingTitles.contains(series.title)) continue;

      final sourceWeekStart = startOfWeek(series.createdAt, firstDay: firstDay);
      if (weekStart.isBefore(sourceWeekStart)) continue;

      final interval = rruleInterval(series.recurrenceRule);
      if (!shouldRecurOnWeek(sourceWeekStart, weekStart, interval)) {
        continue;
      }

      await seriesActions.materialize(series: series, boardId: widget.boardId);
      existingTitles.add(series.title);
    }
  }

  // ----------------------------------------------------------
  // Task actions
  // ----------------------------------------------------------

  void _openTaskDetailSheet(Task task) {
    // Collect which day-column positions have markers for this task.
    final markersAsync = ref.read(markersByBoardProvider(widget.boardId));
    final allMarkers = markersAsync.valueOrNull ?? {};
    final columnsAsync = ref.read(columnListProvider(widget.boardId));
    final columns = columnsAsync.valueOrNull ?? [];
    final markerPositions = <int>{};
    for (final col in columns) {
      if (col.type != ColumnType.date) continue;
      final key = '${task.id}_${col.id}';
      if (allMarkers.containsKey(key)) {
        markerPositions.add(col.position);
      }
    }

    // Use watch data (already loaded) rather than read (may be loading).
    final allTags = ref.read(tagListProvider).valueOrNull ?? [];
    final taskTagsMap =
        ref.read(tagsByBoardProvider(widget.boardId)).valueOrNull ?? {};
    final taskTags = taskTagsMap[task.id] ?? [];

    TaskDetailSheet.show(
      context: context,
      task: task,
      markerPositions: markerPositions,
      availableTags: allTags,
      currentTags: taskTags,
      onTagsChanged: (tagIds) async {
        // Always update the task's own tags.
        await ref
            .read(tagActionsProvider)
            .setTagsForTask(task.id, tagIds);
        // Re-read the task to get the latest seriesId (it may
        // have been set by createFromTask after the sheet opened).
        final currentTask = await ref
            .read(taskRepositoryProvider)
            .getById(task.id);
        final sid = currentTask?.seriesId;
        if (sid != null) {
          final seriesTagRepo =
              ref.read(seriesTagRepositoryProvider);
          await seriesTagRepo.setTagsForSeries(sid, tagIds);
        }
      },
      onSave: (updated) async {
        await ref.read(taskActionsProvider).update(updated);
        if (updated.isRecurring && updated.seriesId == null) {
          final boardData = ref.read(boardProvider(widget.boardId)).valueOrNull;
          await ref
              .read(seriesActionsProvider)
              .createFromTask(updated, boardWeekStart: boardData?.weekStart);
        }
        if (updated.recurrenceRule != null) {
          await _syncRecurrenceMarkers(updated);
        }
        if (ref.read(authProvider).user != null) {
          ref.read(syncProvider.notifier).scheduleSyncAfterWrite();
        }
      },
      onSaveAll: (updated) async {
        if (task.seriesId != null) {
          // Update the series definition so future virtual
          // instances reflect the change.
          final seriesRepo = ref.read(seriesRepositoryProvider);
          final series = await seriesRepo.getById(task.seriesId!);
          if (series != null) {
            await ref
                .read(seriesActionsProvider)
                .updateSeries(
                  series.copyWith(
                    title: updated.title,
                    description: updated.description,
                    priority: updated.priority,
                    isEvent: updated.isEvent,
                    scheduledTime: updated.scheduledTime,
                    recurrenceRule:
                        updated.recurrenceRule ?? series.recurrenceRule,
                  ),
                );
          }
        }
        // Also update this materialized instance.
        await ref.read(taskActionsProvider).update(updated);
        if (updated.isRecurring || updated.isEvent) {
          await _syncRecurrenceMarkers(updated);
        }
        if (ref.read(authProvider).user != null) {
          ref.read(syncProvider.notifier).scheduleSyncAfterWrite();
        }
      },
      onDelete: () async {
        await ref.read(taskActionsProvider).delete(task.id);
        if (ref.read(authProvider).user != null) {
          ref.read(syncProvider.notifier).scheduleSyncAfterWrite();
        }
      },
      onDeleteAll: () async {
        if (task.seriesId != null) {
          await ref.read(seriesActionsProvider).deleteSeries(task.seriesId!);
        } else {
          await ref.read(taskActionsProvider).delete(task.id);
        }
        if (ref.read(authProvider).user != null) {
          ref.read(syncProvider.notifier).scheduleSyncAfterWrite();
        }
      },
      onWontDo: task.state.isTerminal
          ? null
          : () async {
              final cols = columns;
              final migCol = cols
                  .where((c) => c.type != ColumnType.date)
                  .firstOrNull;
              if (migCol != null) {
                final markerRepo = ref.read(markerRepositoryProvider);
                final migMarker = await markerRepo.get(task.id, migCol.id);
                if (migMarker != null) {
                  await ref
                      .read(markerActionsProvider)
                      .cycleMarker(
                        boardId: widget.boardId,
                        taskId: task.id,
                        columnId: migCol.id,
                      );
                }
              }
              await ref.read(taskActionsProvider).wontDo(task.id);
              if (ref.read(authProvider).user != null) {
          ref.read(syncProvider.notifier).scheduleSyncAfterWrite();
        }
            },
      onReopen:
          (task.state == TaskState.wontDo || task.state == TaskState.cancelled)
          ? () async {
              await ref.read(taskActionsProvider).reopen(task.id);
              if (ref.read(authProvider).user != null) {
          ref.read(syncProvider.notifier).scheduleSyncAfterWrite();
        }
            }
          : null,
    );
  }

  /// Syncs markers on day columns to match the task's scheduled
  /// days (derived from its recurrence rule). Uses event markers
  /// for events and dot markers for recurring tasks.
  Future<void> _syncRecurrenceMarkers(Task task) async {
    final columnsAsync = ref.read(columnListProvider(widget.boardId));
    final columns = columnsAsync.valueOrNull;
    if (columns == null) return;

    final (_, days) = parseRRule(task.recurrenceRule);
    final markerActions = ref.read(markerActionsProvider);
    final markerRepo = ref.read(markerRepositoryProvider);
    final sym = MarkerSymbol.defaultFor(isEvent: task.isEvent);

    for (final col in columns) {
      if (col.type != ColumnType.date) continue;

      final existing = await markerRepo.get(task.id, col.id);
      final shouldHaveMarker = days.contains(col.position);

      if (shouldHaveMarker && existing == null) {
        await markerActions.setMarker(
          boardId: widget.boardId,
          taskId: task.id,
          columnId: col.id,
          symbol: sym,
        );
      } else if (!shouldHaveMarker &&
          existing != null &&
          (existing.symbol == MarkerSymbol.event ||
              existing.symbol == MarkerSymbol.dot)) {
        await markerActions.setMarker(
          boardId: widget.boardId,
          taskId: task.id,
          columnId: col.id,
          symbol: null,
        );
      }
    }
  }

  Future<void> _onReorder(List<Task> tasks, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;

    final reordered = List<Task>.from(tasks);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);

    final ids = reordered.map((t) => t.id).toList();
    await ref.read(taskActionsProvider).reorder(widget.boardId, ids);
  }

  Future<void> _showAddTaskDialog(BuildContext context) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Task'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Task title'),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    Future.delayed(const Duration(milliseconds: 300), controller.dispose);

    if (title == null || title.trim().isEmpty) return;

    final tasks = ref.read(taskListProvider(widget.boardId));
    final currentCount = tasks.valueOrNull?.length ?? 0;

    await ref
        .read(taskActionsProvider)
        .create(
          Task(
            id: _uuid.v4(),
            boardId: widget.boardId,
            title: title.trim(),
            position: currentCount,
            createdAt: DateTime.now().toUtc(),
          ),
        );
    if (ref.read(authProvider).user != null) {
          ref.read(syncProvider.notifier).scheduleSyncAfterWrite();
        }
  }

  // ----------------------------------------------------------
  // Build
  // ----------------------------------------------------------

  /// Computes the board's weekStart for virtual instance checks.
  DateTime? _boardWeekStart() {
    final firstDay = ref.read(preferencesProvider).firstDayOfWeek;
    final boardAsync = ref.read(boardProvider(widget.boardId));
    final board = boardAsync.valueOrNull;
    if (board == null) return null;
    return board.weekStart ?? startOfWeek(board.createdAt, firstDay: firstDay);
  }

  /// Merges real tasks with virtual instances from active series.
  List<BoardItem> _mergeItems(
    List<Task> tasks,
    List<RecurringSeries> allSeries,
  ) {
    final weekStart = _boardWeekStart();
    final items = <BoardItem>[for (final t in tasks) RealTask(t)];

    if (weekStart == null || allSeries.isEmpty) return items;

    // Track which series are already represented on this board
    // (by seriesId or by matching title for race-condition safety).
    final materializedSeriesIds = <String>{};
    final existingTitles = <String>{};
    for (final t in tasks) {
      if (t.seriesId != null) {
        materializedSeriesIds.add(t.seriesId!);
      }
      existingTitles.add(t.title);
    }

    for (final series in allSeries) {
      // Skip if already materialized on this board (by seriesId
      // or by title match for tasks not yet linked).
      if (materializedSeriesIds.contains(series.id)) continue;
      if (existingTitles.contains(series.title)) continue;

      // Check if this series should appear this week.
      final interval = rruleInterval(series.recurrenceRule);
      final firstDay = ref.read(preferencesProvider).firstDayOfWeek;
      final sourceWeekStart = startOfWeek(series.createdAt, firstDay: firstDay);
      // Don't show on weeks before the series was created.
      if (weekStart.isBefore(sourceWeekStart)) continue;
      if (!shouldRecurOnWeek(sourceWeekStart, weekStart, interval)) {
        continue;
      }

      final (_, days) = parseRRule(series.recurrenceRule);

      items.add(VirtualTask(series: series, scheduledDays: days));
    }

    return items;
  }

  /// Materializes a virtual task and then runs [action] with the
  /// newly created real task.
  Future<void> _materializeAndAct(
    RecurringSeries series,
    Future<void> Function(Task task) action,
  ) async {
    final task = await ref
        .read(seriesActionsProvider)
        .materialize(series: series, boardId: widget.boardId);
    await action(task);
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(taskListProvider(widget.boardId));
    final columnsAsync = ref.watch(columnListProvider(widget.boardId));
    final seriesAsync = ref.watch(activeSeriesProvider);
    ref.watch(markersByBoardProvider(widget.boardId));
    ref.watch(tagListProvider); // keep subscribed so data is ready
    final tagsMap =
        ref.watch(tagsByBoardProvider(widget.boardId)).valueOrNull ?? {};

    final activeSeries = seriesAsync.valueOrNull ?? [];

    return Stack(
      children: [
        tasksAsync.when(
          data: (tasks) => columnsAsync.when(
            data: (columns) {
              final items = _mergeItems(tasks, activeSeries);
              return _buildGrid(context, items, columns, tagsMap);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton.small(
                heroTag: 'addEvent',
                onPressed: () => context.pushNamed(
                  'eventCreate',
                  pathParameters: {'id': widget.boardId},
                ),
                tooltip: 'Add event',
                child: const Icon(Icons.event),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'addTask',
                onPressed: () => _showAddTaskDialog(context),
                tooltip: 'Add task',
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // Grid
  // ----------------------------------------------------------

  Set<int> _computePastDayPositions() {
    final firstDay = ref.watch(preferencesProvider).firstDayOfWeek;
    final boardAsync = ref.watch(boardProvider(widget.boardId));
    final board = boardAsync.valueOrNull;
    if (board == null) return {};
    final weekStart =
        board.weekStart ?? startOfWeek(board.createdAt, firstDay: firstDay);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentWeekStart = startOfWeek(today, firstDay: firstDay);
    if (weekStart.isBefore(currentWeekStart)) {
      // Past week — all day positions are past.
      return {0, 1, 2, 3, 4, 5, 6};
    } else if (weekStart == currentWeekStart) {
      // Current week — positions before today's offset.
      final todayOffset = (now.weekday - firstDay + 7) % 7;
      return {for (var i = 0; i < todayOffset; i++) i};
    }
    return {};
  }

  /// Returns the lowest date-column position that has a dot or
  /// event marker for [taskId], or null if none.
  int? _nextDotPosition(
    String taskId,
    List<BoardColumn> columns,
    Map<String, Marker> markers,
  ) {
    int? best;
    for (final col in columns) {
      if (col.type != ColumnType.date) continue;
      final m = markers['${taskId}_${col.id}'];
      if (m != null &&
          (m.symbol == MarkerSymbol.dot || m.symbol == MarkerSymbol.event)) {
        if (best == null || col.position < best) {
          best = col.position;
        }
      }
    }
    return best;
  }

  /// Reorders and relabels columns so they display with the
  /// preferred first-day-of-week, even if the board was created
  /// with a different convention.
  List<BoardColumn> _reorderColumns(List<BoardColumn> columns) {
    final firstDay = ref.watch(preferencesProvider).firstDayOfWeek;
    final boardAsync = ref.watch(boardProvider(widget.boardId));
    final board = boardAsync.valueOrNull;
    if (board == null) return columns;

    // Detect the board's original first day from its weekStart.
    final ws = board.weekStart;
    if (ws == null) return columns;
    final boardFirstDay = ws.weekday; // 1=Mon, 7=Sun

    if (boardFirstDay == firstDay) return columns;

    // Compute how many positions to rotate. E.g. Monday(1)→Sunday(7):
    // Sunday is at position 6 in a Monday-start board, so rotate by 6.
    final shift = (firstDay - boardFirstDay + 7) % 7;

    final dateColumns = columns.where((c) => c.type == ColumnType.date).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    final nonDateColumns = columns
        .where((c) => c.type != ColumnType.date)
        .toList();

    if (dateColumns.length != 7) return columns;

    // Build the preferred label order.
    final labels = weeklyColumnDefs(
      firstDay: firstDay,
    ).where((d) => d.type == ColumnType.date).map((d) => d.label).toList();

    // Rotate: new visual position i gets data from
    // old position (i + shift) % 7.
    final reordered = <BoardColumn>[];
    for (var i = 0; i < 7; i++) {
      final srcIdx = (i + shift) % 7;
      final src = dateColumns[srcIdx];
      reordered.add(
        BoardColumn(
          id: src.id,
          boardId: src.boardId,
          label: labels[i],
          position: src.position,
          type: src.type,
        ),
      );
    }

    return [...reordered, ...nonDateColumns];
  }

  Widget _buildGrid(
    BuildContext context,
    List<BoardItem> items,
    List<BoardColumn> columns,
    Map<String, List<Tag>> tagsMap,
  ) {
    if (items.isEmpty && columns.isEmpty) {
      return _buildEmptyState(context);
    }

    // Reorder columns if the board's first-day differs from the
    // user's preference (e.g. Mon-start board with Sun preference).
    columns = _reorderColumns(columns);

    final theme = Theme.of(context);
    final markerColumnsWidth = columns.length * MarkerCell.cellSize;

    final markersAsync = ref.watch(markersByBoardProvider(widget.boardId));
    final markers = markersAsync.valueOrNull ?? {};

    // Sort only real tasks; virtual tasks go at the end.
    final realItems = items.whereType<RealTask>().toList();
    final virtualItems = items.whereType<VirtualTask>().toList();

    final sortedReal = sortTasks(
      realItems.map((r) => r.task).toList(),
      _sortMode,
      getPosition: (t) => t.position,
      getCreatedAt: (t) => t.createdAt,
      getDeadline: (t) => t.deadline,
      getTitle: (t) => t.title,
      getPriority: (t) => t.priority,
      getNextDotPosition: (t) => _nextDotPosition(t.id, columns, markers),
    );

    final sortedItems = <BoardItem>[
      for (final t in sortedReal) RealTask(t),
      ...virtualItems,
    ];

    // Apply tag filter.
    final filteredItems = _tagFilter.isEmpty
        ? sortedItems
        : sortedItems.where((item) {
            if (item is VirtualTask) {
              final vTags = item.tags;
              if (_tagFilter.contains(_untaggedFilter)) {
                return vTags.isEmpty;
              }
              final vTagIds = vTags.map((t) => t.id).toSet();
              return _tagFilter.every(vTagIds.contains);
            }
            final taskTags = tagsMap[item.displayId] ?? [];
            if (_tagFilter.contains(_untaggedFilter)) {
              return taskTags.isEmpty;
            }
            final taskTagIds = taskTags.map((t) => t.id).toSet();
            return _tagFilter.every(taskTagIds.contains);
          }).toList();

    // Minimum width: marker columns + divider + task name area.
    final minWidth = markerColumnsWidth + 1 + 120;

    return DotGridBackground(
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final useScroll = constraints.maxWidth < minWidth;
                final contentWidth = useScroll
                    ? minWidth
                    : constraints.maxWidth;

                Widget content = SizedBox(
                  width: contentWidth,
                  child: Column(
                    children: [
                      SizedBox(
                        height: _headerHeight,
                        child: Row(
                          children: [
                            ...columns.asMap().entries.map((e) {
                              final i = e.key;
                              final col = e.value;
                              DateTime? date;
                              if (col.type == ColumnType.date) {
                                final ws = _boardWeekStart();
                                if (ws != null) {
                                  final firstDay = ref.read(
                                    preferencesProvider,
                                  ).firstDayOfWeek;
                                  final displayStart = startOfWeek(
                                    ws,
                                    firstDay: firstDay,
                                  );
                                  date = DateTime(
                                    displayStart.year,
                                    displayStart.month,
                                    displayStart.day + i,
                                  );
                                }
                              }
                              return ColumnHeader(
                                column: col,
                                date: date,
                              );
                            }),
                            VerticalDivider(
                              width: 1,
                              color: theme.dividerColor,
                            ),
                            Expanded(
                              child: _SortableHeaderCorner(
                                sortMode: _sortMode,
                                onSortChanged: (mode) =>
                                    setState(() => _sortMode = mode),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: theme.dividerColor),
                      Expanded(
                        child: filteredItems.isEmpty
                            ? _buildEmptyState(
                                context,
                                filtered: _tagFilter.isNotEmpty,
                              )
                            : _buildItemList(
                                filteredItems,
                                columns,
                                markerColumnsWidth,
                                _computePastDayPositions(),
                                tagsMap,
                              ),
                      ),
                    ],
                  ),
                );

                if (useScroll) {
                  content = SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: content,
                  );
                }

                return content;
              },
            ),
          ),
          _buildTagLegend(theme),
        ],
      ),
    );
  }

  Widget _buildItemList(
    List<BoardItem> items,
    List<BoardColumn> columns,
    double markerColumnsWidth,
    Set<int> pastDayPositions,
    Map<String, List<Tag>> tagsMap,
  ) {
    final canReorder = _sortMode == TaskSortMode.manual;

    // Extract real tasks for reorder callback.
    final realTasks = items.whereType<RealTask>().map((r) => r.task).toList();

    return ReorderableListView.builder(
      itemCount: items.length,
      buildDefaultDragHandles: false,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Material(elevation: 4, child: child),
          child: child,
        );
      },
      onReorder: canReorder
          ? (oldIndex, newIndex) => _onReorder(realTasks, oldIndex, newIndex)
          : (_, _) {},
      itemBuilder: (context, i) {
        final item = items[i];
        if (item is VirtualTask) {
          return VirtualBoardRow(
            key: ValueKey(item.displayId),
            boardId: widget.boardId,
            virtualTask: item,
            columns: columns,
            pastDayPositions: pastDayPositions,
            onTap: () => _materializeAndAct(
              item.series,
              (task) async => _openTaskDetailSheet(task),
            ),
          );
        }
        final task = (item as RealTask).task;
        return BoardRow(
          key: ValueKey(task.id),
          boardId: widget.boardId,
          task: task,
          columns: columns,
          index: i,
          canReorder: canReorder,
          pastDayPositions: pastDayPositions,
          tags: tagsMap[task.id] ?? const [],
          onTap: () => _openTaskDetailSheet(task),
        );
      },
    );
  }

  Widget _buildTagLegend(ThemeData theme) {
    final tags = ref.watch(tagListProvider).valueOrNull ?? [];
    if (tags.isEmpty) return const SizedBox.shrink();

    final isFiltering = _tagFilter.isNotEmpty;

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // "Untagged" filter chip.
          _TagFilterChip(
            label: 'Untagged',
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            selected: _tagFilter.contains(_untaggedFilter),
            onTap: () => setState(() {
              if (_tagFilter.contains(_untaggedFilter)) {
                _tagFilter.remove(_untaggedFilter);
              } else {
                // Untagged is exclusive — clear other filters.
                _tagFilter
                  ..clear()
                  ..add(_untaggedFilter);
              }
            }),
          ),
          const SizedBox(width: 8),
          // Tag chips.
          for (final tag in tags) ...[
            _TagFilterChip(
              label: tag.name,
              color: TagPalette.colorFromValue(tag.color),
              selected: _tagFilter.contains(tag.id),
              onTap: () => setState(() {
                _tagFilter.remove(_untaggedFilter);
                if (_tagFilter.contains(tag.id)) {
                  _tagFilter.remove(tag.id);
                } else if (_tagFilter.length < 4) {
                  _tagFilter.add(tag.id);
                }
              }),
            ),
            const SizedBox(width: 8),
          ],
          // Clear filter button.
          if (isFiltering)
            GestureDetector(
              onTap: () => setState(() => _tagFilter.clear()),
              child: Center(
                child: Text(
                  'Clear',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {bool filtered = false}) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              filtered ? Icons.filter_list_off : Icons.grid_on_rounded,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              filtered ? 'No matching tasks' : 'No tasks yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              filtered
                  ? 'Clear the tag filter below to see all tasks.'
                  : 'Tap + to add your first task.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Shared sub-widgets
// ============================================================

/// Header with "Tasks" label and sort popup menu.
class _SortableHeaderCorner extends StatelessWidget {
  final TaskSortMode sortMode;
  final ValueChanged<TaskSortMode> onSortChanged;

  const _SortableHeaderCorner({
    required this.sortMode,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Tasks',
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 28,
            height: 28,
            child: PopupMenuButton<TaskSortMode>(
              iconSize: 16,
              icon: Icon(
                Icons.sort,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              tooltip: 'Sort tasks',
              padding: EdgeInsets.zero,
              onSelected: onSortChanged,
              itemBuilder: (_) => [
                for (final mode in TaskSortMode.values)
                  PopupMenuItem(
                    value: mode,
                    child: Row(
                      children: [
                        if (sortMode == mode)
                          Icon(
                            Icons.check,
                            size: 18,
                            color: theme.colorScheme.primary,
                          )
                        else
                          const SizedBox(width: 18),
                        const SizedBox(width: 8),
                        Text(mode.displayName),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A single day-column header label (e.g. "M", "T", ">").
/// When [date] is provided, the day of the month is shown
/// below the weekday letter.
class ColumnHeader extends StatelessWidget {
  final BoardColumn column;
  final DateTime? date;

  const ColumnHeader({super.key, required this.column, this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelSmall
        ?.copyWith(fontWeight: FontWeight.w600);

    if (date != null && column.type == ColumnType.date) {
      return SizedBox(
        width: MarkerCell.cellSize,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              column.label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: labelStyle,
            ),
            Text(
              '${date!.day}',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: theme.colorScheme.onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: MarkerCell.cellSize,
      child: Center(
        child: Text(
          column.label,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: labelStyle,
        ),
      ),
    );
  }
}

/// A full board row: marker cells on the left, task name on
/// the right with drag-to-reorder and swipe gestures.
class _TagFilterChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TagFilterChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: selected ? color.withValues(alpha: 0.2) : Colors.transparent,
            border: Border.all(
              color: selected
                  ? color
                  : theme.colorScheme.onSurface.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected
                      ? color
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BoardRow extends StatelessWidget {
  final String boardId;
  final Task task;
  final List<BoardColumn> columns;
  final int index;
  final bool canReorder;
  final Set<int> pastDayPositions;
  final List<Tag> tags;
  final VoidCallback onTap;

  const BoardRow({
    super.key,
    required this.boardId,
    required this.task,
    required this.columns,
    required this.index,
    this.canReorder = true,
    this.pastDayPositions = const {},
    this.tags = const [],
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isStrikethrough =
        task.state == TaskState.cancelled || task.state == TaskState.wontDo;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: MarkerCell.cellSize,
        child: Row(
          children: [
            ...columns.map(
              (col) => MarkerCell(
                boardId: boardId,
                taskId: task.id,
                columnId: col.id,
                columnType: col.type,
                isEvent: task.isEvent,
                isPastDay:
                    col.type == ColumnType.date &&
                    pastDayPositions.contains(col.position),
                isLocked:
                    task.state == TaskState.wontDo ||
                    task.state == TaskState.cancelled,
                isRecurring: task.isRecurring,
                seriesId: task.seriesId,
                onEventTap: (task.isEvent || task.isRecurring) ? onTap : null,
              ),
            ),
            VerticalDivider(width: 1, color: theme.dividerColor),
            if (canReorder)
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.drag_indicator,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              )
            else
              const SizedBox(width: 8),
            if (tags.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: TagBadge(tags: tags),
              ),
            ],
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 4, right: 8),
                child: Row(
                  children: [
                    if (task.isEvent) ...[
                      Icon(
                        Icons.event,
                        size: 14,
                        color: theme.colorScheme.primary.withValues(
                          alpha: isStrikethrough ? 0.4 : 0.7,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          decoration: isStrikethrough
                              ? TextDecoration.lineThrough
                              : null,
                          color: isStrikethrough
                              ? theme.colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                )
                              : null,
                        ),
                      ),
                    ),
                    if (task.isEvent && task.scheduledTime != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          _utcTimeToLocal(task.scheduledTime!),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: isStrikethrough ? 0.3 : 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A board row for a virtual (not yet materialized) recurring
/// series instance. Shown at reduced opacity with computed markers.
class VirtualBoardRow extends ConsumerWidget {
  final String boardId;
  final VirtualTask virtualTask;
  final List<BoardColumn> columns;
  final Set<int> pastDayPositions;
  final VoidCallback onTap;

  const VirtualBoardRow({
    super.key,
    required this.boardId,
    required this.virtualTask,
    required this.columns,
    this.pastDayPositions = const {},
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final series = virtualTask.series;
    final days = virtualTask.scheduledDays;
    final sym = MarkerSymbol.defaultFor(isEvent: series.isEvent);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: MarkerCell.cellSize,
        child: Row(
          children: [
            // Marker cells: show computed symbols on scheduled
            // days, migration column shows autorenew/event icon.
            ...columns.map((col) {
              if (col.type != ColumnType.date) {
                // Migration column — show recurring icon.
                final iconColor = brightness == Brightness.dark
                    ? const Color(0xFFA09A94)
                    : const Color(0xFF6B6560);
                return SizedBox(
                  width: MarkerCell.cellSize,
                  height: MarkerCell.cellSize,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: onTap,
                      child: Center(
                        child: Icon(
                          series.isEvent ? Icons.event_repeat : Icons.autorenew,
                          size: 18,
                          color: iconColor,
                        ),
                      ),
                    ),
                  ),
                );
              }
              // Day column — show marker if scheduled.
              final hasMarker = days.contains(col.position);
              final color = hasMarker
                  ? PlanyrTheme.markerColor(sym, brightness)
                  : null;
              return SizedBox(
                width: MarkerCell.cellSize,
                height: MarkerCell.cellSize,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: onTap,
                    child: Center(
                      child: hasMarker
                          ? MarkerCell.buildMarkerWidget(sym, color)
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              );
            }),
            VerticalDivider(width: 1, color: theme.dividerColor),
            const SizedBox(width: 8),
            if (virtualTask.tags.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: TagBadge(tags: virtualTask.tags),
              ),
            ],
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 4, right: 8),
                child: Row(
                  children: [
                    if (series.isEvent) ...[
                      Icon(
                        Icons.event,
                        size: 14,
                        color: theme.colorScheme.primary.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        series.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    if (series.isEvent && series.scheduledTime != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          _utcTimeToLocal(series.scheduledTime!),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
