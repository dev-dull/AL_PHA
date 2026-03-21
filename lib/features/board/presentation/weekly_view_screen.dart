import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alpha/features/board/presentation/board_grid_body.dart';
import 'package:alpha/features/board/providers/weekly_board_provider.dart';
import 'package:alpha/features/marker/providers/marker_providers.dart';
import 'package:alpha/shared/week_utils.dart';

/// The primary weekly view: auto-creates boards per week and
/// navigates between weeks via chevron buttons.
class WeeklyViewScreen extends ConsumerStatefulWidget {
  const WeeklyViewScreen({super.key});

  @override
  ConsumerState<WeeklyViewScreen> createState() => _WeeklyViewScreenState();
}

class _WeeklyViewScreenState extends ConsumerState<WeeklyViewScreen> {
  late DateTime _currentMonday;

  @override
  void initState() {
    super.initState();
    _currentMonday = mondayOfWeek(DateTime.now());
  }

  /// Runs auto-fill on the board being left, then navigates.
  Future<void> _changeWeek(DateTime newMonday) async {
    final oldMonday = _currentMonday;

    // Run auto-fill on the board being navigated away from
    // so any new dots on past days get migrated.
    final oldBoardId = ref
        .read(weeklyBoardProvider(oldMonday))
        .valueOrNull;
    if (oldBoardId != null) {
      await ref
          .read(markerActionsProvider)
          .autoFillMissedDays(boardId: oldBoardId);
    }

    if (mounted) {
      setState(() => _currentMonday = newMonday);
    }
  }

  void _goToPreviousWeek() {
    _changeWeek(_currentMonday.subtract(const Duration(days: 7)));
  }

  void _goToNextWeek() {
    _changeWeek(_currentMonday.add(const Duration(days: 7)));
  }

  void _goToToday() {
    _changeWeek(mondayOfWeek(DateTime.now()));
  }

  @override
  Widget build(BuildContext context) {
    final title = weekBoardName(_currentMonday);
    final isCurrentWeek = _currentMonday == mondayOfWeek(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: isCurrentWeek ? null : _goToToday,
          child: Text(title),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous week',
            onPressed: _goToPreviousWeek,
          ),
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'This week',
            onPressed: isCurrentWeek ? null : _goToToday,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next week',
            onPressed: _goToNextWeek,
          ),
        ],
      ),
      body: _WeekPage(key: ValueKey(_currentMonday), monday: _currentMonday),
    );
  }
}

/// A single week page that resolves the board ID and shows
/// the board grid.
class _WeekPage extends ConsumerWidget {
  final DateTime monday;

  const _WeekPage({super.key, required this.monday});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardIdAsync = ref.watch(weeklyBoardProvider(monday));

    return boardIdAsync.when(
      data: (boardId) =>
          BoardGridBody(key: ValueKey(boardId), boardId: boardId),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}
