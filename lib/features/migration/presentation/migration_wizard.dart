import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'package:alpha/features/board/domain/board.dart';
import 'package:alpha/features/board/domain/board_type.dart';
import 'package:alpha/features/board/providers/board_providers.dart';
import 'package:alpha/features/column/domain/board_column.dart';
import 'package:alpha/features/column/providers/column_providers.dart';
import 'package:alpha/features/marker/domain/marker.dart';
import 'package:alpha/features/marker/domain/marker_symbol.dart';
import 'package:alpha/features/task/domain/task.dart';
import 'package:alpha/features/task/domain/task_state.dart';
import 'package:alpha/features/task/providers/task_providers.dart';
import 'package:alpha/features/template/data/templates.dart';
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
      // Last day of the board's creation month.
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
      // Custom boards never auto-detect.
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

class _MigrationWizard extends ConsumerStatefulWidget {
  final String sourceBoardId;

  const _MigrationWizard({required this.sourceBoardId});

  @override
  ConsumerState<_MigrationWizard> createState() => _MigrationWizardState();
}

class _MigrationWizardState extends ConsumerState<_MigrationWizard> {
  static const _uuid = Uuid();

  int _step = 0; // 0=target, 1=tasks, 2=confirm
  String? _targetBoardId;
  String? _targetBoardName;
  Set<String> _selectedTaskIds = {};
  List<Task> _migratableTasks = [];
  bool _isExecuting = false;

  // For inline board creation.
  bool _creatingNewBoard = false;
  final _newBoardNameController = TextEditingController();
  int _selectedTemplateIndex = 0;

  @override
  void dispose() {
    _newBoardNameController.dispose();
    super.dispose();
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
      body: _buildStep(context),
    );
  }

  Widget _buildStep(BuildContext context) {
    switch (_step) {
      case 0:
        return _buildTargetSelection(context);
      case 1:
        return _buildTaskSelection(context);
      case 2:
        return _buildConfirmation(context);
      default:
        return const SizedBox.shrink();
    }
  }

  // --------------------------------------------------------
  // Step 1: Target board selection
  // --------------------------------------------------------

  Widget _buildTargetSelection(BuildContext context) {
    if (_creatingNewBoard) {
      return _buildNewBoardForm(context);
    }

    final boardsAsync = ref.watch(boardListProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepHeader(
          step: 1,
          title: 'Select target board',
          subtitle: 'Choose which board to migrate tasks to.',
        ),
        const SizedBox(height: 8),
        // Create new board option.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() => _creatingNewBoard = true);
            },
            icon: const Icon(Icons.add),
            label: const Text('Create new board'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
        const Divider(height: 24),
        Expanded(
          child: boardsAsync.when(
            data: (boards) {
              final available = boards
                  .where((b) => b.id != widget.sourceBoardId && !b.archived)
                  .toList();
              if (available.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No other boards available. '
                      'Create a new board to migrate to.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: available.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final board = available[i];
                  final isSelected = _targetBoardId == board.id;
                  return ListTile(
                    title: Text(board.name),
                    subtitle: Text(board.type.displayName),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: theme.colorScheme.primary,
                          )
                        : null,
                    selected: isSelected,
                    onTap: () {
                      setState(() {
                        _targetBoardId = board.id;
                        _targetBoardName = board.name;
                      });
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
        _BottomBar(
          onNext: _targetBoardId != null ? _goToTaskSelection : null,
          onBack: null,
          nextLabel: 'Next',
        ),
      ],
    );
  }

  // --------------------------------------------------------
  // Inline board creation
  // --------------------------------------------------------

  Widget _buildNewBoardForm(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepHeader(
          step: 1,
          title: 'Create new board',
          subtitle: 'Set up a board to migrate tasks to.',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _newBoardNameController,
                decoration: const InputDecoration(
                  labelText: 'Board name',
                  hintText: 'e.g. Week of March 23',
                ),
                textCapitalization: TextCapitalization.sentences,
                autofocus: true,
              ),
              const SizedBox(height: 24),
              Text('Template', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              RadioGroup<int>(
                groupValue: _selectedTemplateIndex,
                onChanged: (v) {
                  setState(() => _selectedTemplateIndex = v ?? 0);
                },
                child: Column(
                  children: List.generate(defaultTemplates.length, (i) {
                    final t = defaultTemplates[i];
                    return RadioListTile<int>(
                      title: Text(t.name),
                      subtitle: Text(t.description),
                      value: i,
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        _BottomBar(
          onBack: () {
            setState(() => _creatingNewBoard = false);
          },
          onNext: _createNewBoardAndProceed,
          nextLabel: 'Create & Continue',
        ),
      ],
    );
  }

  Future<void> _createNewBoardAndProceed() async {
    final name = _newBoardNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a board name')),
      );
      return;
    }

    final template = defaultTemplates[_selectedTemplateIndex];
    final now = DateTime.now();
    final boardId = _uuid.v4();

    final board = Board(
      id: boardId,
      name: name,
      type: template.boardType,
      createdAt: now,
      updatedAt: now,
    );

    await ref.read(boardActionsProvider).create(board);

    final columnActions = ref.read(columnActionsProvider);
    for (final col in template.columns) {
      await columnActions.create(
        BoardColumn(
          id: _uuid.v4(),
          boardId: boardId,
          label: col.label,
          position: col.position,
          type: col.type,
        ),
      );
    }

    setState(() {
      _targetBoardId = boardId;
      _targetBoardName = name;
      _creatingNewBoard = false;
    });

    _goToTaskSelection();
  }

  // --------------------------------------------------------
  // Step 2: Task selection
  // --------------------------------------------------------

  void _goToTaskSelection() {
    final tasksAsync = ref.read(taskListProvider(widget.sourceBoardId));
    final tasks = tasksAsync.valueOrNull ?? [];
    final migratable = tasks.where((t) {
      return t.state == TaskState.open || t.state == TaskState.inProgress;
    }).toList();

    setState(() {
      _migratableTasks = migratable;
      _selectedTaskIds = migratable.map((t) => t.id).toSet();
      _step = 1;
    });
  }

  Widget _buildTaskSelection(BuildContext context) {
    final theme = Theme.of(context);
    final selectedCount = _selectedTaskIds.length;
    final totalCount = _migratableTasks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(
          step: 2,
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
          onBack: () => setState(() => _step = 0),
          onNext: _selectedTaskIds.isNotEmpty
              ? () => setState(() => _step = 2)
              : null,
          nextLabel: 'Next',
        ),
      ],
    );
  }

  // --------------------------------------------------------
  // Step 3: Confirmation
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepHeader(
          step: 3,
          title: 'Confirm migration',
          subtitle: 'Review and confirm.',
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Migrate $count '
                          '${count == 1 ? 'task' : 'tasks'}',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
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
                                  Text(_targetBoardName ?? ''),
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
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
              ],
            ),
          ),
        ),
        _BottomBar(
          onBack: _isExecuting ? null : () => setState(() => _step = 1),
          onNext: _isExecuting ? null : _executeMigration,
          nextLabel: 'Confirm',
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
      final targetBoardId = _targetBoardId!;

      // Get the next position in the target board.
      final targetTasksAsync = ref.read(taskListProvider(targetBoardId));
      final existingTargetTasks = targetTasksAsync.valueOrNull ?? [];
      var nextPosition = existingTargetTasks.length;

      for (final task in _migratableTasks) {
        if (!_selectedTaskIds.contains(task.id)) {
          continue;
        }

        // 1. Mark source task as MIGRATED.
        await taskActions.update(task.copyWith(state: TaskState.migrated));

        // 2. Create MIGRATED markers on all source
        //    board columns for this task.
        for (final col in sourceColumns) {
          await markerRepo.set(
            Marker(
              id: _uuid.v4(),
              taskId: task.id,
              columnId: col.id,
              boardId: widget.sourceBoardId,
              symbol: MarkerSymbol.migrated,
              updatedAt: DateTime.now(),
            ),
          );
        }

        // 3. Create a new OPEN task on the target
        //    board, copying relevant fields.
        final newTaskId = _uuid.v4();
        await taskActions.create(
          Task(
            id: newTaskId,
            boardId: targetBoardId,
            title: task.title,
            description: task.description,
            priority: task.priority,
            position: nextPosition,
            createdAt: DateTime.now(),
            deadline: task.deadline,
            migratedFromBoardId: widget.sourceBoardId,
            migratedFromTaskId: task.id,
          ),
        );

        nextPosition++;
      }

      if (!mounted) return;

      // 4. Show success SnackBar.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Migrated ${_selectedTaskIds.length} '
            '${_selectedTaskIds.length == 1 ? 'task' : 'tasks'} '
            'to ${_targetBoardName ?? 'target board'}',
          ),
        ),
      );

      // 5. Navigate to the target board.
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
  final String title;
  final String subtitle;

  const _StepHeader({
    required this.step,
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
            'Step $step of 3',
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
