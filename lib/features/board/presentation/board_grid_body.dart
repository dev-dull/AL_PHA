import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:alpha/design_system/widgets/dot_grid_background.dart';
import 'package:alpha/features/column/domain/board_column.dart';
import 'package:alpha/features/column/providers/column_providers.dart';
import 'package:alpha/features/marker/presentation/marker_cell.dart';
import 'package:alpha/features/marker/providers/marker_providers.dart';
import 'package:alpha/features/task/domain/task.dart';
import 'package:alpha/features/task/domain/task_sort.dart';
import 'package:alpha/features/task/domain/task_state.dart';
import 'package:alpha/features/task/presentation/task_detail_sheet.dart';
import 'package:alpha/features/task/providers/task_providers.dart';

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

  Future<void> _completeTask(Task task) async {
    final previousState = task.state;
    await ref.read(taskActionsProvider).complete(task.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${task.title}" completed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => _restoreTaskState(task, previousState),
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
          onPressed: () => _restoreTaskState(task, previousState),
        ),
      ),
    );
  }

  Future<void> _restoreTaskState(Task task, TaskState previousState) async {
    final updated = task.copyWith(state: previousState, completedAt: null);
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
  // Sort menu (exposed for parent widgets to include in AppBar)
  // ----------------------------------------------------------

  /// Builds the sort popup menu button for use in an AppBar.
  PopupMenuButton<TaskSortMode> buildSortButton(BuildContext context) {
    return PopupMenuButton<TaskSortMode>(
      icon: const Icon(Icons.sort),
      tooltip: 'Sort tasks',
      onSelected: (mode) => setState(() => _sortMode = mode),
      itemBuilder: (_) => [
        for (final mode in TaskSortMode.values)
          PopupMenuItem(
            value: mode,
            child: Row(
              children: [
                if (_sortMode == mode)
                  Icon(
                    Icons.check,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  )
                else
                  const SizedBox(width: 18),
                const SizedBox(width: 8),
                Text(mode.displayName),
              ],
            ),
          ),
      ],
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
    final markerColumnsWidth = columns.length * MarkerCell.cellSize;

    final sortedTasks = sortTasks(
      tasks,
      _sortMode,
      getPosition: (t) => t.position,
      getCreatedAt: (t) => t.createdAt,
      getDeadline: (t) => t.deadline,
      getTitle: (t) => t.title,
      getPriority: (t) => t.priority,
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
                const Expanded(child: HeaderCorner()),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Expanded(
            child: sortedTasks.isEmpty
                ? _buildEmptyState(context)
                : _buildTaskList(sortedTasks, columns, markerColumnsWidth),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(
    List<Task> tasks,
    List<BoardColumn> columns,
    double markerColumnsWidth,
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
          onComplete: () => _completeTask(task),
          onCancel: () => _cancelTask(task),
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

/// Header label for the task name column.
class HeaderCorner extends StatelessWidget {
  const HeaderCorner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Tasks',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
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
  final VoidCallback onComplete;
  final VoidCallback onCancel;
  final VoidCallback onTap;

  const BoardRow({
    super.key,
    required this.boardId,
    required this.task,
    required this.columns,
    required this.index,
    this.canReorder = true,
    required this.onComplete,
    required this.onCancel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCancelled = task.state == TaskState.cancelled;
    final theme = Theme.of(context);

    Widget row = GestureDetector(
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
                onEventTap: task.isEvent ? onTap : null,
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
                            .withValues(alpha: isCancelled ? 0.4 : 0.7),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          decoration: isCancelled
                              ? TextDecoration.lineThrough
                              : null,
                          color: isCancelled
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
                                .withValues(alpha: isCancelled ? 0.3 : 0.5),
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

    if (isCancelled) return row;

    return Dismissible(
      key: ValueKey('dismiss_${task.id}'),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        color: Colors.green,
        child: const Icon(Icons.check, color: Colors.white),
      ),
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
        return false;
      },
      child: row,
    );
  }
}
