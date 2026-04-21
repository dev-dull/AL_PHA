import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:planyr/features/column/domain/board_column.dart';
import 'package:planyr/features/column/providers/column_providers.dart';

/// Bottom sheet for managing board columns: add, rename, reorder,
/// and delete.
class ColumnManagerSheet extends ConsumerStatefulWidget {
  final String boardId;

  const ColumnManagerSheet({super.key, required this.boardId});

  /// Show the column manager as a modal bottom sheet.
  static Future<void> show({
    required BuildContext context,
    required String boardId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ColumnManagerSheet(boardId: boardId),
    );
  }

  @override
  ConsumerState<ColumnManagerSheet> createState() => _ColumnManagerSheetState();
}

class _ColumnManagerSheetState extends ConsumerState<ColumnManagerSheet> {
  static const _uuid = Uuid();

  final _addController = TextEditingController();

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------
  // Actions
  // --------------------------------------------------------

  Future<void> _addColumn() async {
    final label = _addController.text.trim();
    if (label.isEmpty) return;

    final columns = ref.read(columnListProvider(widget.boardId)).valueOrNull;
    final position = columns?.length ?? 0;

    await ref
        .read(columnActionsProvider)
        .create(
          BoardColumn(
            id: _uuid.v4(),
            boardId: widget.boardId,
            label: label,
            position: position,
          ),
        );

    _addController.clear();
  }

  Future<void> _renameColumn(BoardColumn column) async {
    final controller = TextEditingController(text: column.label);

    final newLabel = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Column'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Column label'),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (newLabel == null || newLabel.trim().isEmpty) return;
    if (newLabel.trim() == column.label) return;

    await ref
        .read(columnActionsProvider)
        .update(column.copyWith(label: newLabel.trim()));
  }

  Future<void> _deleteColumn(BoardColumn column) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Column'),
        content: Text(
          'Delete "${column.label}"? All markers in this '
          'column will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(columnActionsProvider).delete(column.id);
    }
  }

  Future<void> _onReorder(
    List<BoardColumn> columns,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) newIndex--;

    final reordered = List<BoardColumn>.from(columns);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);

    final ids = reordered.map((c) => c.id).toList();
    await ref.read(columnActionsProvider).reorder(widget.boardId, ids);
  }

  // --------------------------------------------------------
  // Build
  // --------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final columnsAsync = ref.watch(columnListProvider(widget.boardId));

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 32,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Text(
            'Manage Columns',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Column list
          Flexible(
            child: columnsAsync.when(
              data: (columns) => columns.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No columns yet. Add one below.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ),
                    )
                  : _buildColumnList(columns),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('Error: $e')),
              ),
            ),
          ),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),

          // Add column row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _addController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'New column label',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _addColumn(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _addColumn, child: const Text('Add')),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildColumnList(List<BoardColumn> columns) {
    final theme = Theme.of(context);

    return ReorderableListView.builder(
      shrinkWrap: true,
      itemCount: columns.length,
      buildDefaultDragHandles: false,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Material(elevation: 4, child: child),
          child: child,
        );
      },
      onReorder: (oldIndex, newIndex) =>
          _onReorder(columns, oldIndex, newIndex),
      itemBuilder: (context, i) {
        final column = columns[i];
        return Dismissible(
          key: ValueKey(column.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            color: theme.colorScheme.error,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            await _deleteColumn(column);
            // Always return false; deletion is handled
            // by the provider stream.
            return false;
          },
          child: ListTile(
            leading: ReorderableDragStartListener(
              index: i,
              child: Icon(
                Icons.drag_handle,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            title: Text(column.label),
            subtitle: Text(
              column.type.displayName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Rename',
              onPressed: () => _renameColumn(column),
            ),
            onTap: () => _renameColumn(column),
          ),
        );
      },
    );
  }
}
