import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:alpha/features/board/providers/board_providers.dart';
import 'package:alpha/features/column/domain/board_column.dart';
import 'package:alpha/features/column/providers/column_providers.dart';
import 'package:alpha/features/marker/presentation/marker_cell.dart';
import 'package:alpha/features/marker/providers/marker_providers.dart';
import 'package:alpha/features/migration/presentation/migration_wizard.dart';
import 'package:alpha/features/task/domain/task.dart';
import 'package:alpha/features/task/domain/task_state.dart';
import 'package:alpha/features/task/presentation/task_detail_sheet.dart';
import 'package:alpha/features/task/providers/task_providers.dart';

/// The core screen of AlPHA: a 2D matrix with tasks as rows,
/// columns (dates/contexts) as headers, and tappable markers
/// at each intersection.
class BoardDetailScreen extends ConsumerStatefulWidget {
  final String boardId;

  const BoardDetailScreen({super.key, required this.boardId});

  @override
  ConsumerState<BoardDetailScreen> createState() =>
      _BoardDetailScreenState();
}

class _BoardDetailScreenState
    extends ConsumerState<BoardDetailScreen> {
  static const _uuid = Uuid();

  /// Width of the fixed task-name column.
  static const double _taskColumnWidth = 140;

  /// Height of each row (matches MarkerCell.cellSize).
  static const double _rowHeight = MarkerCell.cellSize;

  /// Height of the column header row.
  static const double _headerHeight = 44;

  /// Vertical scroll controllers kept in sync.
  final _taskScrollController = ScrollController();
  final _gridScrollController = ScrollController();

  /// Whether we are currently syncing scroll positions.
  bool _isSyncingScroll = false;

  @override
  void initState() {
    super.initState();
    _taskScrollController.addListener(_syncTaskToGrid);
    _gridScrollController.addListener(_syncGridToTask);
  }

  @override
  void dispose() {
    _taskScrollController
      ..removeListener(_syncTaskToGrid)
      ..dispose();
    _gridScrollController
      ..removeListener(_syncGridToTask)
      ..dispose();
    super.dispose();
  }

  void _syncTaskToGrid() {
    if (_isSyncingScroll) return;
    _isSyncingScroll = true;
    _gridScrollController.jumpTo(_taskScrollController.offset);
    _isSyncingScroll = false;
  }

  void _syncGridToTask() {
    if (_isSyncingScroll) return;
    _isSyncingScroll = true;
    _taskScrollController.jumpTo(_gridScrollController.offset);
    _isSyncingScroll = false;
  }

  // ----------------------------------------------------------
  // Task actions
  // ----------------------------------------------------------

  Future<void> _completeTask(Task task) async {
    final previousState = task.state;
    await ref.read(taskActionsProvider).complete(task.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${task.title}" completed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => _restoreTaskState(
            task,
            previousState,
          ),
        ),
      ),
    );
  }

  Future<void> _cancelTask(Task task) async {
    final previousState = task.state;
    await ref.read(taskActionsProvider).cancel(task.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${task.title}" cancelled'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => _restoreTaskState(
            task,
            previousState,
          ),
        ),
      ),
    );
  }

  Future<void> _restoreTaskState(
    Task task,
    TaskState previousState,
  ) async {
    final updated = task.copyWith(
      state: previousState,
      completedAt: null,
    );
    await ref.read(taskActionsProvider).update(updated);
  }

  void _openTaskDetailSheet(Task task) {
    TaskDetailSheet.show(
      context: context,
      task: task,
      onSave: (updated) async {
        await ref.read(taskActionsProvider).update(updated);
      },
      onDelete: () async {
        await ref.read(taskActionsProvider).delete(task.id);
      },
    );
  }

  Future<void> _onReorder(
    List<Task> tasks,
    int oldIndex,
    int newIndex,
  ) async {
    // ReorderableListView passes newIndex that accounts for
    // removal, so adjust when moving downward.
    if (newIndex > oldIndex) newIndex--;

    final reordered = List<Task>.from(tasks);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);

    final ids = reordered.map((t) => t.id).toList();
    await ref
        .read(taskActionsProvider)
        .reorder(widget.boardId, ids);
  }

  // ----------------------------------------------------------
  // Build
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final boardAsync = ref.watch(boardProvider(widget.boardId));
    final tasksAsync =
        ref.watch(taskListProvider(widget.boardId));
    final columnsAsync =
        ref.watch(columnListProvider(widget.boardId));
    // Pre-warm the markers map so MarkerCell reads are instant.
    ref.watch(markersByBoardProvider(widget.boardId));

    final boardName = boardAsync.when(
      data: (b) => b?.name ?? 'Board',
      loading: () => 'Loading...',
      error: (_, _) => 'Board',
    );

    final board = boardAsync.valueOrNull;
    final showBanner =
        board != null && isBoardPeriodEnded(board);

    return Scaffold(
      appBar: AppBar(
        title: Text(boardName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'migrate') {
                showMigrationWizard(
                  context,
                  sourceBoardId: widget.boardId,
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'migrate',
                child: Text('Migrate tasks...'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (showBanner)
            MigrationBanner(
              onMigrate: () => showMigrationWizard(
                context,
                sourceBoardId: widget.boardId,
              ),
            ),
          Expanded(
            child: tasksAsync.when(
              data: (tasks) => columnsAsync.when(
                data: (columns) =>
                    _buildGrid(context, tasks, columns),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (e, st) =>
                    Center(child: Text('Error: $e')),
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (e, st) =>
                  Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        tooltip: 'Add task',
        child: const Icon(Icons.add),
      ),
    );
  }

  // ----------------------------------------------------------
  // Grid
  // ----------------------------------------------------------

  Widget _buildGrid(
    BuildContext context,
    List<Task> tasks,
    List<BoardColumn> columns,
  ) {
    if (tasks.isEmpty && columns.isEmpty) {
      return _buildEmptyState(context);
    }

    final theme = Theme.of(context);

    // The grid is split into a fixed left task column and a
    // horizontally scrollable right marker area. Both share
    // synchronised vertical scroll controllers.
    return Column(
      children: [
        // ---------- Header row ----------
        SizedBox(
          height: _headerHeight,
          child: Row(
            children: [
              // Top-left corner (task column header).
              const _HeaderCorner(width: _taskColumnWidth),
              // Column headers scroll horizontally.
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: columns
                        .map((col) => _ColumnHeader(column: col))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: theme.dividerColor),
        // ---------- Body rows ----------
        Expanded(
          child: tasks.isEmpty
              ? _buildEmptyState(context)
              : Row(
                  children: [
                    // Fixed task name column (scrolls
                    // vertically only) with reorder support.
                    SizedBox(
                      width: _taskColumnWidth,
                      child: _buildTaskColumn(tasks),
                    ),
                    VerticalDivider(
                      width: 1,
                      color: theme.dividerColor,
                    ),
                    // Scrollable marker grid (scrolls both
                    // horizontally and vertically).
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: columns.length *
                              MarkerCell.cellSize,
                          child: ListView.builder(
                            controller: _gridScrollController,
                            itemCount: tasks.length,
                            itemExtent: _rowHeight,
                            itemBuilder: (_, i) => _MarkerRow(
                              boardId: widget.boardId,
                              task: tasks[i],
                              columns: columns,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // Task column with reorder + swipe
  // ----------------------------------------------------------

  Widget _buildTaskColumn(List<Task> tasks) {
    return ReorderableListView.builder(
      scrollController: _taskScrollController,
      itemCount: tasks.length,
      buildDefaultDragHandles: false,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Material(
            elevation: 4,
            child: child,
          ),
          child: child,
        );
      },
      onReorder: (oldIndex, newIndex) =>
          _onReorder(tasks, oldIndex, newIndex),
      itemBuilder: (context, i) {
        final task = tasks[i];
        return _SwipeableTaskCell(
          key: ValueKey(task.id),
          task: task,
          index: i,
          onComplete: () => _completeTask(task),
          onCancel: () => _cancelTask(task),
          onTap: () => _openTaskDetailSheet(task),
        );
      },
    );
  }

  // ----------------------------------------------------------
  // Empty state
  // ----------------------------------------------------------

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
              color: theme.colorScheme.onSurface.withValues(
                alpha: 0.3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first task.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface
                    .withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // Add Task dialog
  // ----------------------------------------------------------

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
          decoration: const InputDecoration(
            hintText: 'Task title',
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(ctx).pop(controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (title == null || title.trim().isEmpty) return;

    final tasks = ref.read(taskListProvider(widget.boardId));
    final currentCount = tasks.valueOrNull?.length ?? 0;

    await ref.read(taskActionsProvider).create(
          Task(
            id: _uuid.v4(),
            boardId: widget.boardId,
            title: title.trim(),
            position: currentCount,
            createdAt: DateTime.now(),
          ),
        );
  }
}

// ============================================================
// Private sub-widgets
// ============================================================

/// Top-left corner cell above the task column.
class _HeaderCorner extends StatelessWidget {
  final double width;

  const _HeaderCorner({required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Tasks',
            style:
                Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
          ),
        ),
      ),
    );
  }
}

/// A single column header label.
class _ColumnHeader extends StatelessWidget {
  final BoardColumn column;

  const _ColumnHeader({required this.column});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MarkerCell.cellSize,
      child: Center(
        child: Text(
          column.label,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style:
              Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
        ),
      ),
    );
  }
}

/// A task name cell wrapped with [Dismissible] for swipe
/// gestures, a [GestureDetector] for tap-to-edit, and a
/// [ReorderableDragStartListener] for drag-to-reorder.
class _SwipeableTaskCell extends StatelessWidget {
  final Task task;
  final int index;
  final VoidCallback onComplete;
  final VoidCallback onCancel;
  final VoidCallback onTap;

  const _SwipeableTaskCell({
    super.key,
    required this.task,
    required this.index,
    required this.onComplete,
    required this.onCancel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTerminal = task.state.isTerminal;
    final theme = Theme.of(context);

    Widget cell = GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: MarkerCell.cellSize,
        child: Row(
          children: [
            // Drag handle for reorder
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.drag_indicator,
                  size: 16,
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.3),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 4,
                  right: 8,
                ),
                child: Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    decoration: isTerminal
                        ? TextDecoration.lineThrough
                        : null,
                    color: isTerminal
                        ? theme.colorScheme.onSurface
                            .withValues(alpha: 0.4)
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Terminal tasks cannot be swiped.
    if (isTerminal) return cell;

    return Dismissible(
      key: ValueKey('dismiss_${task.id}'),
      // Swipe right to complete.
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        color: Colors.green,
        child: const Icon(Icons.check, color: Colors.white),
      ),
      // Swipe left to cancel.
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.close, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onComplete();
        } else {
          onCancel();
        }
        // Return false so the widget is not removed from the
        // tree — the provider stream will rebuild the list.
        return false;
      },
      child: cell,
    );
  }
}

/// A horizontal row of MarkerCells for a single task.
class _MarkerRow extends StatelessWidget {
  final String boardId;
  final Task task;
  final List<BoardColumn> columns;

  const _MarkerRow({
    required this.boardId,
    required this.task,
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: columns
          .map(
            (col) => MarkerCell(
              boardId: boardId,
              taskId: task.id,
              columnId: col.id,
            ),
          )
          .toList(),
    );
  }
}
