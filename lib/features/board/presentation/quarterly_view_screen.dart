import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alpha/features/board/presentation/board_grid_body.dart';
import 'package:alpha/features/board/providers/period_board_provider.dart';
import 'package:alpha/features/marker/providers/marker_providers.dart';
import 'package:alpha/shared/period_utils.dart';

class QuarterlyViewScreen extends ConsumerStatefulWidget {
  const QuarterlyViewScreen({super.key});

  @override
  ConsumerState<QuarterlyViewScreen> createState() =>
      _QuarterlyViewScreenState();
}

class _QuarterlyViewScreenState
    extends ConsumerState<QuarterlyViewScreen> {
  late DateTime _currentQuarterStart;

  @override
  void initState() {
    super.initState();
    _currentQuarterStart = firstOfQuarter(DateTime.now());
  }

  Future<void> _changeQuarter(DateTime newQuarterStart) async {
    final oldStart = _currentQuarterStart;
    final oldBoardId = ref
        .read(quarterlyBoardProvider(oldStart))
        .valueOrNull;
    if (oldBoardId != null) {
      await ref
          .read(markerActionsProvider)
          .autoFillMissedDays(boardId: oldBoardId);
    }
    if (mounted) setState(() => _currentQuarterStart = newQuarterStart);
  }

  void _goPrevious() =>
      _changeQuarter(previousQuarter(_currentQuarterStart));
  void _goNext() =>
      _changeQuarter(nextQuarter(_currentQuarterStart));

  void _goToCurrent() =>
      _changeQuarter(firstOfQuarter(DateTime.now()));

  @override
  Widget build(BuildContext context) {
    final title = quarterBoardName(_currentQuarterStart);
    final isCurrent =
        _currentQuarterStart == firstOfQuarter(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: isCurrent ? null : _goToCurrent,
          child: Text(title),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous quarter',
            onPressed: _goPrevious,
          ),
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'This quarter',
            onPressed: isCurrent ? null : _goToCurrent,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next quarter',
            onPressed: _goNext,
          ),
        ],
      ),
      body: _QuarterPage(
        key: ValueKey(_currentQuarterStart),
        quarterStart: _currentQuarterStart,
      ),
    );
  }
}

class _QuarterPage extends ConsumerWidget {
  final DateTime quarterStart;

  const _QuarterPage({super.key, required this.quarterStart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardIdAsync =
        ref.watch(quarterlyBoardProvider(quarterStart));

    return boardIdAsync.when(
      data: (boardId) =>
          BoardGridBody(key: ValueKey(boardId), boardId: boardId),
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}
