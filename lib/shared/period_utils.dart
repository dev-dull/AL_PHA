import 'package:intl/intl.dart';
import 'package:alpha/features/board/domain/board_type.dart';

// ── Monthly ─────────────────────────────────────────────────

/// Returns the first day of the month containing [date].
DateTime firstOfMonth(DateTime date) {
  return DateTime(date.year, date.month);
}

/// Returns the first day of the next month after [monthStart].
DateTime nextMonth(DateTime monthStart) {
  return DateTime(monthStart.year, monthStart.month + 1);
}

/// Returns the first day of the previous month before [monthStart].
DateTime previousMonth(DateTime monthStart) {
  return DateTime(monthStart.year, monthStart.month - 1);
}

/// Display name for a monthly board, e.g. "Mar 2026".
String monthBoardName(DateTime monthStart) {
  return DateFormat.yMMM().format(monthStart);
}

/// Returns the ISO week-of-month (0-indexed) for a given day.
/// Week 0 = days 1–7, Week 1 = days 8–14, etc.
int weekOfMonth(DateTime date) {
  return (date.day - 1) ~/ 7;
}

/// Number of week slots in the given month (4 or 5).
int weeksInMonth(DateTime monthStart) {
  final lastDay = DateTime(monthStart.year, monthStart.month + 1, 0).day;
  return (lastDay / 7).ceil();
}

// ── Quarterly ───────────────────────────────────────────────

/// Returns the first day of the quarter containing [date].
/// Q1=Jan, Q2=Apr, Q3=Jul, Q4=Oct.
DateTime firstOfQuarter(DateTime date) {
  final qMonth = ((date.month - 1) ~/ 3) * 3 + 1;
  return DateTime(date.year, qMonth);
}

/// Returns the first day of the next quarter after [quarterStart].
DateTime nextQuarter(DateTime quarterStart) {
  return DateTime(quarterStart.year, quarterStart.month + 3);
}

/// Returns the first day of the previous quarter.
DateTime previousQuarter(DateTime quarterStart) {
  return DateTime(quarterStart.year, quarterStart.month - 3);
}

/// Display name for a quarterly board, e.g. "Q1 2026".
String quarterBoardName(DateTime quarterStart) {
  final q = ((quarterStart.month - 1) ~/ 3) + 1;
  return 'Q$q ${quarterStart.year}';
}

/// Returns which month within the quarter (0-indexed) for [date].
/// 0 = first month, 1 = second, 2 = third.
int monthOfQuarter(DateTime date) {
  return (date.month - 1) % 3;
}

// ── Yearly ──────────────────────────────────────────────────

/// Returns January 1 of the year containing [date].
DateTime firstOfYear(DateTime date) {
  return DateTime(date.year);
}

/// Returns January 1 of the next year.
DateTime nextYear(DateTime yearStart) {
  return DateTime(yearStart.year + 1);
}

/// Returns January 1 of the previous year.
DateTime previousYear(DateTime yearStart) {
  return DateTime(yearStart.year - 1);
}

/// Display name for a yearly board, e.g. "2026".
String yearBoardName(DateTime yearStart) {
  return '${yearStart.year}';
}

/// Returns which quarter (0-indexed) for [date].
int quarterOfYear(DateTime date) {
  return (date.month - 1) ~/ 3;
}

// ── Generic period helpers ──────────────────────────────────

/// Returns the start of the current period for the given [type].
DateTime currentPeriodStart(BoardType type, DateTime now) {
  switch (type) {
    case BoardType.monthly:
      return firstOfMonth(now);
    case BoardType.quarterly:
      return firstOfQuarter(now);
    case BoardType.yearly:
      return firstOfYear(now);
    default:
      throw ArgumentError('Unsupported board type: $type');
  }
}

/// Returns the start of the next period.
DateTime nextPeriodStart(BoardType type, DateTime periodStart) {
  switch (type) {
    case BoardType.monthly:
      return nextMonth(periodStart);
    case BoardType.quarterly:
      return nextQuarter(periodStart);
    case BoardType.yearly:
      return nextYear(periodStart);
    default:
      throw ArgumentError('Unsupported board type: $type');
  }
}

/// Returns the start of the previous period.
DateTime previousPeriodStart(BoardType type, DateTime periodStart) {
  switch (type) {
    case BoardType.monthly:
      return previousMonth(periodStart);
    case BoardType.quarterly:
      return previousQuarter(periodStart);
    case BoardType.yearly:
      return previousYear(periodStart);
    default:
      throw ArgumentError('Unsupported board type: $type');
  }
}

/// Display name for a period board.
String periodBoardName(BoardType type, DateTime periodStart) {
  switch (type) {
    case BoardType.monthly:
      return monthBoardName(periodStart);
    case BoardType.quarterly:
      return quarterBoardName(periodStart);
    case BoardType.yearly:
      return yearBoardName(periodStart);
    default:
      throw ArgumentError('Unsupported board type: $type');
  }
}

/// Returns which sub-period column index (0-indexed) the given
/// [date] falls into for a board of [type].
int currentSubPeriodIndex(BoardType type, DateTime date) {
  switch (type) {
    case BoardType.monthly:
      return weekOfMonth(date);
    case BoardType.quarterly:
      return monthOfQuarter(date);
    case BoardType.yearly:
      return quarterOfYear(date);
    default:
      throw ArgumentError('Unsupported board type: $type');
  }
}
