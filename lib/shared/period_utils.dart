import 'package:intl/intl.dart';

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

/// Display name for a monthly view, e.g. "Mar 2026".
String monthBoardName(DateTime monthStart) {
  return DateFormat.yMMM().format(monthStart);
}

/// Number of days in the given month.
int daysInMonth(DateTime monthStart) {
  return DateTime(monthStart.year, monthStart.month + 1, 0).day;
}

/// Grid offset for the first day of the month, relative to [firstDay].
int firstWeekdayOffset(DateTime monthStart, {int firstDay = DateTime.monday}) {
  final wd = DateTime(monthStart.year, monthStart.month, 1).weekday;
  return (wd - firstDay + 7) % 7;
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

/// Display name for a yearly view, e.g. "2026".
String yearBoardName(DateTime yearStart) {
  return '${yearStart.year}';
}
