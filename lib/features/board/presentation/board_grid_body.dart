import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:alpha/design_system/widgets/dot_grid_background.dart';
import 'package:alpha/features/column/domain/board_column.dart';
import 'package:alpha/features/column/domain/column_type.dart';
import 'package:alpha/features/column/domain/weekly_columns.dart';
import 'package:alpha/features/column/providers/column_providers.dart';
import 'package:alpha/features/marker/domain/marker.dart';
import 'package:alpha/features/marker/domain/marker_symbol.dart';
import 'package:alpha/features/marker/presentation/marker_cell.dart';
import 'package:alpha/features/marker/providers/marker_providers.dart';
import 'package:alpha/features/task/domain/recurrence.dart';
import 'package:alpha/features/task/domain/task.dart';
import 'package:alpha/shared/providers.dart';
import 'package:alpha/features/board/providers/board_providers.dart';
import 'package:alpha/features/task/domain/task_sort.dart';
import 'package:alpha/features/task/domain/task_state.dart';
import 'package:alpha/features/task/presentation/task_detail_sheet.dart';
import 'package:alpha/features/preferences/providers/preferences_providers.dart';
import 'package:alpha/features/task/providers/task_providers.dart';
import 'package:alpha/shared/week_utils.dart';

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

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final actions = ref.read(markerActionsProvider);
      // Pull recurring events from the previous week.
      await actions.populateRecurringEvents(boardId: widget.boardId);
      // Auto-fill missed days and migrate incomplete tasks.
      await actions.autoFillMissedDays(boardId: widget.boardId);
    });
  }

  // ----------------------------------------------------------
  // Task actions
  // ----------------------------------------------------------

  void _openTaskDetailSheet(Task task) {
    // Collect which day-column positions have markers for this task.
    final markersAsync =
        ref.read(markersByBoardProvider(widget.boardId));
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

    TaskDetailSheet.show(
      context: context,
      task: task,
      markerPositions: markerPositions,
      onSave: (updated) async {
        await ref.read(taskActionsProvider).update(updated);
        if (updated.isRecurring || updated.isEvent) {
          await _syncRecurrenceMarkers(updated);
        }
      },
      onDelete: () async {
        await ref.read(taskActionsProvider).delete(task.id);
      },
      onWontDo: task.state.isTerminal
          ? null
          : () async {
              await ref.read(taskActionsProvider).wontDo(task.id);
            },
      onReopen: (task.state == TaskState.wontDo ||
              task.state == TaskState.cancelled)
          ? () async {
              await ref.read(taskActionsProvider).reopen(task.id);
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
    final sym =
        task.isEvent ? MarkerSymbol.event : MarkerSymbol.dot;

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
            createdAt: DateTime.now(),
          ),
        );
  }

  // ----------------------------------------------------------
  // Build
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(taskListProvider(widget.boardId));
    final columnsAsync = ref.watch(columnListProvider(widget.boardId));
    ref.watch(markersByBoardProvider(widget.boardId));

    return Stack(
      children: [
        tasksAsync.when(
          data: (tasks) => columnsAsync.when(
            data: (columns) => _buildGrid(context, tasks, columns),
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
    final firstDay =
        ref.watch(preferencesProvider).firstDayOfWeek;
    final boardAsync = ref.watch(boardProvider(widget.boardId));
    final board = boardAsync.valueOrNull;
    if (board == null) return {};
    final weekStart = board.weekStart ??
        startOfWeek(board.createdAt, firstDay: firstDay);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentWeekStart =
        startOfWeek(today, firstDay: firstDay);
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
          (m.symbol == MarkerSymbol.dot ||
              m.symbol == MarkerSymbol.event)) {
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
    final firstDay =
        ref.watch(preferencesProvider).firstDayOfWeek;
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
    final shift = (boardFirstDay - firstDay + 7) % 7;

    final dateColumns = columns
        .where((c) => c.type == ColumnType.date)
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    final nonDateColumns = columns
        .where((c) => c.type != ColumnType.date)
        .toList();

    if (dateColumns.length != 7) return columns;

    // Build the preferred label order.
    final labels =
        weeklyColumnDefs(firstDay: firstDay)
            .where((d) => d.type == ColumnType.date)
            .map((d) => d.label)
            .toList();

    // Rotate: new visual position i gets data from
    // old position (i + shift) % 7.
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

    return [...reordered, ...nonDateColumns];
  }

  Widget _buildGrid(
    BuildContext context,
    List<Task> tasks,
    List<BoardColumn> columns,
  ) {
    if (tasks.isEmpty && columns.isEmpty) {
      return _buildEmptyState(context);
    }

    // Reorder columns if the board's first-day differs from the
    // user's preference (e.g. Mon-start board with Sun preference).
    columns = _reorderColumns(columns);

    final theme = Theme.of(context);
    final markerColumnsWidth = columns.length * MarkerCell.cellSize;

    final markersAsync =
        ref.watch(markersByBoardProvider(widget.boardId));
    final markers = markersAsync.valueOrNull ?? {};

    final sortedTasks = sortTasks(
      tasks,
      _sortMode,
      getPosition: (t) => t.position,
      getCreatedAt: (t) => t.createdAt,
      getDeadline: (t) => t.deadline,
      getTitle: (t) => t.title,
      getPriority: (t) => t.priority,
      getNextDotPosition: (t) =>
          _nextDotPosition(t.id, columns, markers),
    );

    return DotGridBackground(
      child: Column(
        children: [
          SizedBox(
            height: _headerHeight,
            child: Row(
              children: [
                ...columns.map((col) => ColumnHeader(column: col)),
                VerticalDivider(width: 1, color: theme.dividerColor),
                Expanded(child: _SortableHeaderCorner(
                  sortMode: _sortMode,
                  onSortChanged: (mode) =>
                      setState(() => _sortMode = mode),
                )),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Expanded(
            child: sortedTasks.isEmpty
                ? _buildEmptyState(context)
                : _buildTaskList(
                    sortedTasks,
                    columns,
                    markerColumnsWidth,
                    _computePastDayPositions(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(
    List<Task> tasks,
    List<BoardColumn> columns,
    double markerColumnsWidth,
    Set<int> pastDayPositions,
  ) {
    final canReorder = _sortMode == TaskSortMode.manual;

    return ReorderableListView.builder(
      itemCount: tasks.length,
      buildDefaultDragHandles: false,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Material(elevation: 4, child: child),
          child: child,
        );
      },
      onReorder: canReorder
          ? (oldIndex, newIndex) => _onReorder(tasks, oldIndex, newIndex)
          : (_, _) {},
      itemBuilder: (context, i) {
        final task = tasks[i];
        return BoardRow(
          key: ValueKey(task.id),
          boardId: widget.boardId,
          task: task,
          columns: columns,
          index: i,
          canReorder: canReorder,
          pastDayPositions: pastDayPositions,
          onTap: () => _openTaskDetailSheet(task),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.grid_on_rounded,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first task.',
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
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        children: [
          Text(
            'Tasks',
            style: theme.textTheme.labelLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          PopupMenuButton<TaskSortMode>(
            icon: Icon(
              Icons.sort,
              size: 18,
              color: theme.colorScheme.onSurface
                  .withValues(alpha: 0.5),
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
        ],
      ),
    );
  }
}

/// A single day-column header label (e.g. "M", "T", ">").
class ColumnHeader extends StatelessWidget {
  final BoardColumn column;

  const ColumnHeader({super.key, required this.column});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MarkerCell.cellSize,
      child: Center(
        child: Text(
          column.label,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// A full board row: marker cells on the left, task name on
/// the right with drag-to-reorder and swipe gestures.
class BoardRow extends StatelessWidget {
  final String boardId;
  final Task task;
  final List<BoardColumn> columns;
  final int index;
  final bool canReorder;
  final Set<int> pastDayPositions;
  final VoidCallback onTap;

  const BoardRow({
    super.key,
    required this.boardId,
    required this.task,
    required this.columns,
    required this.index,
    this.canReorder = true,
    this.pastDayPositions = const {},
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isStrikethrough = task.state == TaskState.cancelled ||
        task.state == TaskState.wontDo;
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
                isPastDay: col.type == ColumnType.date &&
                    pastDayPositions.contains(col.position),
                isLocked: task.state == TaskState.wontDo ||
                    task.state == TaskState.cancelled,
                isRecurring: task.isRecurring,
                onEventTap: (task.isEvent || task.isRecurring)
                    ? onTap
                    : null,
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 4, right: 8),
                child: Row(
                  children: [
                    if (task.isEvent) ...[
                      Icon(
                        Icons.event,
                        size: 14,
                        color: theme.colorScheme.primary
                            .withValues(alpha: isStrikethrough ? 0.4 : 0.7),
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
                              ? theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4)
                              : null,
                        ),
                      ),
                    ),
                    if (task.isEvent && task.scheduledTime != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          task.scheduledTime!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: isStrikethrough ? 0.3 : 0.5),
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
