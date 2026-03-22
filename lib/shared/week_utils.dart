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

/// Human-readable board name for a week, e.g. "Week of Mar 17".
String weekBoardName(DateTime weekStart) {
  return 'Week of ${DateFormat.MMMd().format(weekStart)}';
}
