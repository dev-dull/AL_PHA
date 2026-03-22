import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:alpha/features/board/domain/board_type.dart';
import 'package:alpha/features/column/domain/column_type.dart';
import 'package:alpha/features/marker/domain/marker_symbol.dart';
import 'package:alpha/features/preferences/providers/preferences_providers.dart';
import 'package:alpha/shared/providers.dart';
import 'package:alpha/shared/week_utils.dart';

part 'day_summary_provider.g.dart';

/// Summary of task activity for a single day.
class DaySummary {
  final int completed; // x or doneEarly
  final int missed; // migratedForward
  final int inProgress; // slash
  final int scheduled; // dot
  final int events; // event

  const DaySummary({
    this.completed = 0,
    this.missed = 0,
    this.inProgress = 0,
    this.scheduled = 0,
    this.events = 0,
  });

  int get total => completed + missed + inProgress + scheduled;
  bool get isEmpty => total == 0;

  double get completionRate =>
      total == 0 ? 0 : (completed / total).clamp(0.0, 1.0);
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
    final board = await boardRepo.getByPeriodStart(
      weekStart,
      BoardType.weekly,
    );

    if (board != null) {
      final columns = await columnRepo.getByBoard(board.id);
      final markers = await markerRepo.getByBoard(board.id);

      for (final col in columns) {
        if (col.type != ColumnType.date) continue;

        final date = weekStart.add(Duration(days: col.position));
        if (date.isBefore(rangeStart) || !date.isBefore(rangeEnd)) continue;

        final dayKey = DateTime(date.year, date.month, date.day);
        var completed = 0;
        var missed = 0;
        var inProgress = 0;
        var scheduled = 0;
        var events = 0;

        for (final m in markers) {
          if (m.columnId != col.id) continue;
          // Count all task markers (including migrated tasks).
          switch (m.symbol) {
            case MarkerSymbol.x:
            case MarkerSymbol.doneEarly:
              completed++;
            case MarkerSymbol.migratedForward:
              missed++;
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
          missed: missed,
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
