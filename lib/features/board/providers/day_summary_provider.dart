import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:planyr/features/column/domain/column_type.dart';
import 'package:planyr/features/marker/domain/marker_symbol.dart';
import 'package:planyr/features/preferences/providers/preferences_providers.dart';
import 'package:planyr/shared/providers.dart';
import 'package:planyr/shared/week_utils.dart';

part 'day_summary_provider.g.dart';

/// Summary of task activity for a single day.
class DaySummary {
  final int completed; // x or doneEarly
  final int deferred; // migratedForward — task pushed to later, not abandoned
  final int inProgress; // slash
  final int scheduled; // dot
  final int events; // event

  const DaySummary({
    this.completed = 0,
    this.deferred = 0,
    this.inProgress = 0,
    this.scheduled = 0,
    this.events = 0,
  });

  int get total =>
      completed + deferred + inProgress + scheduled;
  bool get isEmpty => total == 0;

  /// Completion rate from 0.0 to 1.0. Counts completed fully and
  /// in-progress at half credit. Deferred (>) markers are excluded
  /// because the task is being carried forward, not abandoned —
  /// counting them would unfairly tank the rate.
  double get completionRate {
    final actionable = completed + inProgress + scheduled;
    if (actionable == 0) return 0;
    final score = completed + (inProgress * 0.5);
    return (score / actionable).clamp(0.0, 1.0);
  }
}

/// Loads day summaries for all days in a date range by reading
/// weekly board data. Returns a map of date → DaySummary.
@riverpod
Future<Map<DateTime, DaySummary>> daySummaries(
  DaySummariesRef ref,
  DateTime rangeStart,
  DateTime rangeEnd,
) async {
  final boardRepo = ref.read(boardRepositoryProvider);
  final columnRepo = ref.read(columnRepositoryProvider);
  final markerRepo = ref.read(markerRepositoryProvider);

  final result = <DateTime, DaySummary>{};

  final firstDay = ref.read(preferencesProvider).firstDayOfWeek;

  // Find all week starts that overlap with the date range.
  var weekStart = startOfWeek(rangeStart, firstDay: firstDay);
  while (weekStart.isBefore(rangeEnd)) {
    final board = await boardRepo.getByWeekStart(weekStart);

    if (board != null) {
      final columns = await columnRepo.getByBoard(board.id);
      final markers = await markerRepo.getByBoard(board.id);

      for (final col in columns) {
        if (col.type != ColumnType.date) continue;

        final date = weekStart.add(Duration(days: col.position));
        if (date.isBefore(rangeStart) || !date.isBefore(rangeEnd)) continue;

        final dayKey = DateTime(date.year, date.month, date.day);
        var completed = 0;
        var deferred = 0;
        var inProgress = 0;
        var scheduled = 0;
        var events = 0;

        for (final m in markers) {
          if (m.columnId != col.id) continue;
          switch (m.symbol) {
            case MarkerSymbol.x:
            case MarkerSymbol.doneEarly:
              completed++;
            case MarkerSymbol.migratedForward:
              deferred++;
            case MarkerSymbol.slash:
              inProgress++;
            case MarkerSymbol.dot:
              scheduled++;
            case MarkerSymbol.event:
              events++;
          }
        }

        result[dayKey] = DaySummary(
          completed: completed,
          deferred: deferred,
          inProgress: inProgress,
          scheduled: scheduled,
          events: events,
        );
      }
    }

    // Use calendar arithmetic instead of Duration to avoid DST shifts.
    weekStart = DateTime(weekStart.year, weekStart.month, weekStart.day + 7);
  }

  return result;
}
