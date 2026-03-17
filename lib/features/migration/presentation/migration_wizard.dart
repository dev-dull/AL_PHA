import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:alpha/features/board/domain/board.dart';
import 'package:alpha/features/board/domain/board_type.dart';
import 'package:alpha/features/board/providers/board_providers.dart';
import 'package:alpha/features/column/domain/board_column.dart';
import 'package:alpha/features/column/domain/column_type.dart';
import 'package:alpha/features/column/providers/column_providers.dart';
import 'package:alpha/features/marker/domain/marker.dart';
import 'package:alpha/features/marker/domain/marker_symbol.dart';
import 'package:alpha/features/task/domain/task.dart';
import 'package:alpha/features/task/domain/task_state.dart';
import 'package:alpha/features/task/providers/task_providers.dart';
import 'package:alpha/shared/providers.dart';

/// Returns true if the board's time period has ended and
/// migration should be suggested.
bool isBoardPeriodEnded(Board board) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final created = board.createdAt;

  switch (board.type) {
    case BoardType.daily:
      final boardDay = DateTime(created.year, created.month, created.day);
      return today.isAfter(boardDay);

    case BoardType.weekly:
      // Find the Sunday of the board's creation week.
      final createdWeekday = created.weekday; // 1=Mon, 7=Sun
      final sunday = DateTime(
        created.year,
        created.month,
        created.day,
      ).add(Duration(days: 7 - createdWeekday));
      return today.isAfter(sunday);

    case BoardType.monthly:
      final lastDay = DateTime(
        created.year,
        created.month + 1,
        0, // day 0 of next month = last day of this month
      );
      return today.isAfter(lastDay);

    case BoardType.yearly:
      final lastDay = DateTime(created.year, 12, 31);
      return today.isAfter(lastDay);

    case BoardType.custom:
      return false;
  }
}

/// A migration banner shown at the top of [BoardDetailScreen]
/// when the board's period has ended.
class MigrationBanner extends StatelessWidget {
  final VoidCallback onMigrate;

  const MigrationBanner({super.key, required this.onMigrate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MaterialBanner(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      content: Text(
        'This period has ended. Migrate incomplete tasks?',
        style: theme.textTheme.bodyMedium,
      ),
      leading: Icon(Icons.move_down_rounded, color: theme.colorScheme.primary),
      actions: [
        FilledButton.tonal(onPressed: onMigrate, child: const Text('Migrate')),
      ],
    );
  }
}

/// Shows the migration wizard as a full-screen dialog.
Future<void> showMigrationWizard(
  BuildContext context, {
  required String sourceBoardId,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => _MigrationWizard(sourceBoardId: sourceBoardId),
    ),
  );
}

/// Returns the name for the next week's board, e.g. "Week of Mar 23".
String _nextWeekBoardName() {
  final now = DateTime.now();
  // Next Monday.
  final nextMonday = now.add(Duration(days: 8 - now.weekday));
  return 'Week of ${DateFormat.MMMd().format(nextMonday)}';
}

class _MigrationWizard extends ConsumerStatefulWidget {
  final String sourceBoardId;

  const _MigrationWizard({required this.sourceBoardId});

  @override
  ConsumerState<_MigrationWizard> createState() => _MigrationWizardState();
}

class _MigrationWizardState extends ConsumerState<_MigrationWizard> {
  static const _uuid = Uuid();

  int _step = 0; // 0=tasks, 1=confirm
  Set<String> _selectedTaskIds = {};
  List<Task> _migratableTasks = [];
  bool _isExecuting = false;

  /// The fixed weekly columns: M T W T F S S >
  static const _weeklyColumns = [
    (label: 'M', position: 0, type: ColumnType.date),
    (label: 'T', position: 1, type: ColumnType.date),
    (label: 'W', position: 2, type: ColumnType.date),
    (label: 'T', position: 3, type: ColumnType.date),
    (label: 'F', position: 4, type: ColumnType.date),
    (label: 'S', position: 5, type: ColumnType.date),
    (label: 'S', position: 6, type: ColumnType.date),
    (label: '>', position: 7, type: ColumnType.custom),
  ];

  @override
  void initState() {
    super.initState();
    // Pre-load migratable tasks immediately.
    Future.microtask(_loadMigratableTasks);
  }

  void _loadMigratableTasks() {
    final tasksAsync = ref.read(taskListProvider(widget.sourceBoardId));
    final tasks = tasksAsync.valueOrNull ?? [];
    final migratable = tasks.where((t) {
      return t.state == TaskState.open || t.state == TaskState.inProgress;
    }).toList();

    setState(() {
      _migratableTasks = migratable;
      _selectedTaskIds = migratable.map((t) => t.id).toSet();
    });
  }

  // --------------------------------------------------------
  // Build
  // --------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Migrate Tasks'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _step == 0
          ? _buildTaskSelection(context)
          : _buildConfirmation(context),
    );
  }

  // --------------------------------------------------------
  // Step 1: Task selection
  // --------------------------------------------------------

  Widget _buildTaskSelection(BuildContext context) {
    final theme = Theme.of(context);
    final selectedCount = _selectedTaskIds.length;
    final totalCount = _migratableTasks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(
          step: 1,
          totalSteps: 2,
          title: 'Select tasks to migrate',
          subtitle: '$selectedCount of $totalCount tasks selected',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedTaskIds = _migratableTasks
                        .map((t) => t.id)
                        .toSet();
                  });
                },
                child: const Text('Select All'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  setState(() => _selectedTaskIds = {});
                },
                child: const Text('Deselect All'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _migratableTasks.isEmpty
              ? Center(
                  child: Text(
                    'No incomplete tasks to migrate.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _migratableTasks.length,
                  itemBuilder: (_, i) {
                    final task = _migratableTasks[i];
                    final isSelected = _selectedTaskIds.contains(task.id);
                    return CheckboxListTile(
                      title: Text(task.title),
                      subtitle: Text(task.state.displayName),
                      value: isSelected,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selectedTaskIds.add(task.id);
                          } else {
                            _selectedTaskIds.remove(task.id);
                          }
                        });
                      },
                    );
                  },
                ),
        ),
        _BottomBar(
          onBack: null,
          onNext: _selectedTaskIds.isNotEmpty
              ? () => setState(() => _step = 1)
              : null,
          nextLabel: 'Next',
        ),
      ],
    );
  }

  // --------------------------------------------------------
  // Step 2: Confirmation
  // --------------------------------------------------------

  Widget _buildConfirmation(BuildContext context) {
    final boardAsync = ref.watch(boardProvider(widget.sourceBoardId));
    final sourceName = boardAsync.when(
      data: (b) => b?.name ?? 'Source Board',
      loading: () => 'Loading...',
      error: (_, _) => 'Source Board',
    );

    final theme = Theme.of(context);
    final count = _selectedTaskIds.length;
    final targetName = _nextWeekBoardName();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepHeader(
          step: 2,
          totalSteps: 2,
          title: 'Confirm migration',
          subtitle:
              'A new weekly board will be created and selected tasks moved.',
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Migrate $count '
                      '${count == 1 ? 'task' : 'tasks'}',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'From',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(sourceName),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'To',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(targetName),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text('Tasks:', style: theme.textTheme.labelMedium),
                    const SizedBox(height: 4),
                    ..._migratableTasks
                        .where((t) => _selectedTaskIds.contains(t.id))
                        .map(
                          (t) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.arrow_right,
                                  size: 16,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Expanded(child: Text(t.title)),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
        _BottomBar(
          onBack: _isExecuting ? null : () => setState(() => _step = 0),
          onNext: _isExecuting ? null : _executeMigration,
          nextLabel: 'Migrate',
          isLoading: _isExecuting,
        ),
      ],
    );
  }

  // --------------------------------------------------------
  // Execute migration
  // --------------------------------------------------------

  Future<void> _executeMigration() async {
    setState(() => _isExecuting = true);

    try {
      final taskActions = ref.read(taskActionsProvider);
      final markerRepo = ref.read(markerRepositoryProvider);
      final columnsAsync = ref.read(columnListProvider(widget.sourceBoardId));
      final sourceColumns = columnsAsync.valueOrNull ?? [];

      // Create a new weekly board for next week.
      final now = DateTime.now();
      final nextMonday = now.add(Duration(days: 8 - now.weekday));
      final targetBoardId = _uuid.v4();
      final targetName = _nextWeekBoardName();

      final board = Board(
        id: targetBoardId,
        name: targetName,
        type: BoardType.weekly,
        createdAt: DateTime(nextMonday.year, nextMonday.month, nextMonday.day),
        updatedAt: now,
      );

      await ref.read(boardActionsProvider).create(board);

      final columnActions = ref.read(columnActionsProvider);
      for (final col in _weeklyColumns) {
        await columnActions.create(
          BoardColumn(
            id: _uuid.v4(),
            boardId: targetBoardId,
            label: col.label,
            position: col.position,
            type: col.type,
          ),
        );
      }

      // Migrate selected tasks.
      var nextPosition = 0;
      for (final task in _migratableTasks) {
        if (!_selectedTaskIds.contains(task.id)) continue;

        // 1. Mark source task as MIGRATED.
        await taskActions.update(task.copyWith(state: TaskState.migrated));

        // 2. Mark source columns with > for this task.
        for (final col in sourceColumns) {
          await markerRepo.set(
            Marker(
              id: _uuid.v4(),
              taskId: task.id,
              columnId: col.id,
              boardId: widget.sourceBoardId,
              symbol: MarkerSymbol.migratedForward,
              updatedAt: now,
            ),
          );
        }

        // 3. Create a new task on the target board.
        await taskActions.create(
          Task(
            id: _uuid.v4(),
            boardId: targetBoardId,
            title: task.title,
            description: task.description,
            priority: task.priority,
            position: nextPosition,
            createdAt: now,
            deadline: task.deadline,
            migratedFromBoardId: widget.sourceBoardId,
            migratedFromTaskId: task.id,
          ),
        );

        nextPosition++;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Migrated ${_selectedTaskIds.length} '
            '${_selectedTaskIds.length == 1 ? 'task' : 'tasks'} '
            'to $targetName',
          ),
        ),
      );

      Navigator.of(context).pop();
      context.goNamed('boardDetail', pathParameters: {'id': targetBoardId});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Migration failed: $e')));
      setState(() => _isExecuting = false);
    }
  }
}

// ==============================================================
// Private helper widgets
// ==============================================================

class _StepHeader extends StatelessWidget {
  final int step;
  final int totalSteps;
  final String title;
  final String subtitle;

  const _StepHeader({
    required this.step,
    required this.totalSteps,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step $step of $totalSteps',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final String nextLabel;
  final bool isLoading;

  const _BottomBar({
    required this.onBack,
    required this.onNext,
    required this.nextLabel,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (onBack != null)
              OutlinedButton(onPressed: onBack, child: const Text('Back')),
            const Spacer(),
            FilledButton(
              onPressed: onNext,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(nextLabel),
            ),
          ],
        ),
      ),
    );
  }
}
