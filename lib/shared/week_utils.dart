import 'package:intl/intl.dart';

/// Returns the start-of-week (midnight) for the week containing [date].
///
/// [firstDay] is the first day of the week: 1 = Monday (ISO default),
/// 7 = Sunday. Uses calendar arithmetic to avoid DST issues.
DateTime startOfWeek(DateTime date, {int firstDay = DateTime.monday}) {
  final d = DateTime(date.year, date.month, date.day);
  final diff = (d.weekday - firstDay + 7) % 7;
  return DateTime(d.year, d.month, d.day - diff);
}

/// Convenience alias — returns Monday of the week containing [date].
DateTime mondayOfWeek(DateTime date) => startOfWeek(date);

/// Human-readable board name for a week, e.g. "Week of Mar 17".
String weekBoardName(DateTime weekStart) {
  return 'Week of ${DateFormat.MMMd().format(weekStart)}';
}

/// Center index for the virtual PageView.
const int weekPageCenter = 5200;

/// Maps a PageView page index to the start-of-week date.
DateTime weekFromPageIndex(int index, {int firstDay = DateTime.monday}) {
  final today = DateTime.now();
  final current = startOfWeek(today, firstDay: firstDay);
  return DateTime(current.year, current.month, current.day + (index - weekPageCenter) * 7);
}

/// Maps a week start date back to a PageView index.
int pageIndexFromWeek(DateTime weekStart, {int firstDay = DateTime.monday}) {
  final current = startOfWeek(DateTime.now(), firstDay: firstDay);
  final diff = weekStart.difference(current).inDays;
  return weekPageCenter + (diff ~/ 7);
}
