import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alpha/features/board/presentation/board_grid_body.dart';
import 'package:alpha/features/board/providers/period_board_provider.dart';
import 'package:alpha/features/marker/providers/marker_providers.dart';
import 'package:alpha/shared/period_utils.dart';

class YearlyViewScreen extends ConsumerStatefulWidget {
  const YearlyViewScreen({super.key});

  @override
  ConsumerState<YearlyViewScreen> createState() =>
      _YearlyViewScreenState();
}

class _YearlyViewScreenState extends ConsumerState<YearlyViewScreen> {
  late DateTime _currentYearStart;

  @override
  void initState() {
    super.initState();
    _currentYearStart = firstOfYear(DateTime.now());
  }

  Future<void> _changeYear(DateTime newYearStart) async {
    final oldStart = _currentYearStart;
    final oldBoardId = ref
        .read(yearlyBoardProvider(oldStart))
        .valueOrNull;
    if (oldBoardId != null) {
      await ref
          .read(markerActionsProvider)
          .autoFillMissedDays(boardId: oldBoardId);
    }
    if (mounted) setState(() => _currentYearStart = newYearStart);
  }

  void _goPrevious() =>
      _changeYear(previousYear(_currentYearStart));
  void _goNext() => _changeYear(nextYear(_currentYearStart));

  void _goToCurrent() =>
      _changeYear(firstOfYear(DateTime.now()));

  @override
  Widget build(BuildContext context) {
    final title = yearBoardName(_currentYearStart);
    final isCurrent =
        _currentYearStart == firstOfYear(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: isCurrent ? null : _goToCurrent,
          child: Text(title),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous year',
            onPressed: _goPrevious,
          ),
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'This year',
            onPressed: isCurrent ? null : _goToCurrent,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next year',
            onPressed: _goNext,
          ),
        ],
      ),
      body: _YearPage(
        key: ValueKey(_currentYearStart),
        yearStart: _currentYearStart,
      ),
    );
  }
}

class _YearPage extends ConsumerWidget {
  final DateTime yearStart;

  const _YearPage({super.key, required this.yearStart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardIdAsync = ref.watch(yearlyBoardProvider(yearStart));

    return boardIdAsync.when(
      data: (boardId) =>
          BoardGridBody(key: ValueKey(boardId), boardId: boardId),
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}
