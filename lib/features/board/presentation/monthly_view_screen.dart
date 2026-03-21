import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alpha/features/board/presentation/board_grid_body.dart';
import 'package:alpha/features/board/providers/period_board_provider.dart';
import 'package:alpha/features/marker/providers/marker_providers.dart';
import 'package:alpha/shared/period_utils.dart';

class MonthlyViewScreen extends ConsumerStatefulWidget {
  const MonthlyViewScreen({super.key});

  @override
  ConsumerState<MonthlyViewScreen> createState() =>
      _MonthlyViewScreenState();
}

class _MonthlyViewScreenState extends ConsumerState<MonthlyViewScreen> {
  late DateTime _currentMonthStart;

  @override
  void initState() {
    super.initState();
    _currentMonthStart = firstOfMonth(DateTime.now());
  }

  Future<void> _changeMonth(DateTime newMonthStart) async {
    final oldStart = _currentMonthStart;
    final oldBoardId = ref
        .read(monthlyBoardProvider(oldStart))
        .valueOrNull;
    if (oldBoardId != null) {
      await ref
          .read(markerActionsProvider)
          .autoFillMissedDays(boardId: oldBoardId);
    }
    if (mounted) setState(() => _currentMonthStart = newMonthStart);
  }

  void _goPrevious() => _changeMonth(previousMonth(_currentMonthStart));
  void _goNext() => _changeMonth(nextMonth(_currentMonthStart));

  void _goToCurrent() =>
      _changeMonth(firstOfMonth(DateTime.now()));

  @override
  Widget build(BuildContext context) {
    final title = monthBoardName(_currentMonthStart);
    final isCurrent =
        _currentMonthStart == firstOfMonth(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: isCurrent ? null : _goToCurrent,
          child: Text(title),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous month',
            onPressed: _goPrevious,
          ),
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'This month',
            onPressed: isCurrent ? null : _goToCurrent,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next month',
            onPressed: _goNext,
          ),
        ],
      ),
      body: _MonthPage(
        key: ValueKey(_currentMonthStart),
        monthStart: _currentMonthStart,
      ),
    );
  }
}

class _MonthPage extends ConsumerWidget {
  final DateTime monthStart;

  const _MonthPage({super.key, required this.monthStart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardIdAsync = ref.watch(monthlyBoardProvider(monthStart));

    return boardIdAsync.when(
      data: (boardId) =>
          BoardGridBody(key: ValueKey(boardId), boardId: boardId),
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}
