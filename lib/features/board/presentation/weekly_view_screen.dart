import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alpha/features/board/data/data_export.dart';
import 'package:alpha/features/board/presentation/board_grid_body.dart';
import 'package:alpha/features/board/presentation/marker_legend_dialog.dart';
import 'package:alpha/features/board/providers/weekly_board_provider.dart';
import 'package:alpha/features/marker/providers/marker_providers.dart';
import 'package:alpha/features/preferences/domain/app_preferences.dart';
import 'package:alpha/features/auth/providers/auth_providers.dart';
import 'package:alpha/features/preferences/providers/preferences_providers.dart';
import 'package:alpha/features/sync/domain/sync_status.dart';
import 'package:alpha/features/sync/providers/sync_providers.dart';
import 'package:alpha/shared/providers.dart';
import 'package:alpha/shared/week_utils.dart';

/// The primary weekly view: auto-creates boards per week and
/// navigates between weeks via chevron buttons.
class WeeklyViewScreen extends ConsumerStatefulWidget {
  final DateTime? initialWeekStart;

  const WeeklyViewScreen({super.key, this.initialWeekStart});

  @override
  ConsumerState<WeeklyViewScreen> createState() => _WeeklyViewScreenState();
}

class _WeeklyViewScreenState extends ConsumerState<WeeklyViewScreen> {
  late DateTime _currentWeekStart;

  static const _seenLegendKey = 'alpha_seen_legend';

  @override
  void initState() {
    super.initState();
    final firstDay =
        ref.read(preferencesProvider).firstDayOfWeek;
    _currentWeekStart = widget.initialWeekStart ??
        startOfWeek(DateTime.now(), firstDay: firstDay);
    _showLegendOnFirstLaunch();
  }

  /// Recalculates the displayed week when the first-day
  /// preference changes (e.g. from settings screen).
  void _onPrefsChanged(AppPreferences? prev, AppPreferences next) {
    if (prev?.firstDayOfWeek == next.firstDayOfWeek) return;
    final midWeek = _currentWeekStart.add(const Duration(days: 3));
    setState(() {
      _currentWeekStart =
          startOfWeek(midWeek, firstDay: next.firstDayOfWeek);
    });
  }

  Future<void> _showLegendOnFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_seenLegendKey) == true) return;
    await prefs.setBool(_seenLegendKey, true);
    if (!mounted) return;
    showMarkerLegend(context);
  }

  /// Runs auto-fill on the board being left, then navigates.
  Future<void> _changeWeek(DateTime newWeekStart) async {
    final oldWeekStart = _currentWeekStart;

    // Run auto-fill on the board being navigated away from
    // so any new dots on past days get migrated.
    final oldBoardId = ref
        .read(weeklyBoardProvider(oldWeekStart))
        .valueOrNull;
    if (oldBoardId != null) {
      await ref
          .read(markerActionsProvider)
          .autoFillMissedDays(boardId: oldBoardId);
    }

    if (mounted) {
      setState(() => _currentWeekStart = newWeekStart);
    }
  }

  void _goToPreviousWeek() {
    final m = _currentWeekStart;
    _changeWeek(DateTime(m.year, m.month, m.day - 7));
  }

  void _goToNextWeek() {
    final m = _currentWeekStart;
    _changeWeek(DateTime(m.year, m.month, m.day + 7));
  }

  void _goToToday() {
    final firstDay =
        ref.read(preferencesProvider).firstDayOfWeek;
    _changeWeek(startOfWeek(DateTime.now(), firstDay: firstDay));
  }

  Future<void> _exportData() async {
    final db = ref.read(alphaDatabaseProvider);
    final path = await exportDataAsJson(db);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported to $path')),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(preferencesProvider, _onPrefsChanged);
    final firstDay =
        ref.watch(preferencesProvider).firstDayOfWeek;
    final title = weekBoardName(_currentWeekStart);
    final isCurrentWeek = _currentWeekStart ==
        startOfWeek(DateTime.now(), firstDay: firstDay);

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: isCurrentWeek ? null : _goToToday,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title),
              if (ref.watch(authProvider).user != null)
                _SyncIndicator(),
            ],
          ),
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'export') _exportData();
              if (value == 'help') showMarkerLegend(context);
              if (value == 'settings') context.pushNamed('preferences');
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: Text('Settings'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'help',
                child: ListTile(
                  leading: Icon(Icons.help_outline),
                  title: Text('How It Works'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export Data'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _WeekPage(key: ValueKey(_currentWeekStart), weekStart: _currentWeekStart),
    );
  }
}

/// A single week page that resolves the board ID and shows
/// the board grid.
class _WeekPage extends ConsumerWidget {
  final DateTime weekStart;

  const _WeekPage({super.key, required this.weekStart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardIdAsync = ref.watch(weeklyBoardProvider(weekStart));

    return boardIdAsync.when(
      data: (boardId) =>
          BoardGridBody(key: ValueKey(boardId), boardId: boardId),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}

class _SyncIndicator extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncProvider);
    final theme = Theme.of(context);

    final icon = switch (sync.status) {
      SyncState.idle => Icons.cloud_off_outlined,
      SyncState.syncing => Icons.cloud_sync_outlined,
      SyncState.synced => Icons.cloud_done_outlined,
      SyncState.error => Icons.cloud_off,
    };

    final color = switch (sync.status) {
      SyncState.error => theme.colorScheme.error,
      SyncState.synced => theme.colorScheme.onSurface.withValues(alpha: 0.3),
      SyncState.syncing => theme.colorScheme.primary,
      SyncState.idle => theme.colorScheme.onSurface.withValues(alpha: 0.2),
    };

    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Icon(icon, size: 14, color: color),
    );
  }
}
