import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alpha/features/board/presentation/board_grid_body.dart';
import 'package:alpha/features/board/providers/weekly_board_provider.dart';
import 'package:alpha/shared/week_utils.dart';

/// The primary weekly view: auto-creates boards per week and
/// supports swiping between weeks.
class WeeklyViewScreen extends ConsumerStatefulWidget {
  const WeeklyViewScreen({super.key});

  @override
  ConsumerState<WeeklyViewScreen> createState() => _WeeklyViewScreenState();
}

class _WeeklyViewScreenState extends ConsumerState<WeeklyViewScreen> {
  late final PageController _pageController;
  late DateTime _currentMonday;

  @override
  void initState() {
    super.initState();
    _currentMonday = mondayOfWeek(DateTime.now());
    _pageController = PageController(initialPage: weekPageCenter);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToToday() {
    final todayPage = pageIndexFromMonday(mondayOfWeek(DateTime.now()));
    _goToPage(todayPage);
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
            onPressed: () {
              final current = _pageController.page?.round() ?? weekPageCenter;
              _goToPage(current - 1);
            },
          ),
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'This week',
            onPressed: isCurrentWeek ? null : _goToToday,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next week',
            onPressed: () {
              final current = _pageController.page?.round() ?? weekPageCenter;
              _goToPage(current + 1);
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentMonday = mondayFromPageIndex(index);
          });
        },
        itemBuilder: (context, index) {
          final monday = mondayFromPageIndex(index);
          return _WeekPage(key: ValueKey(monday), monday: monday);
        },
      ),
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
