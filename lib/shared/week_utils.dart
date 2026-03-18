import 'package:intl/intl.dart';

/// Returns Monday 00:00:00 of the week containing [date].
DateTime mondayOfWeek(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  return d.subtract(Duration(days: d.weekday - 1));
}

/// Human-readable board name for a week, e.g. "Week of Mar 17".
String weekBoardName(DateTime monday) {
  return 'Week of ${DateFormat.MMMd().format(monday)}';
}

/// Center index for the virtual PageView.
const int weekPageCenter = 5200;

/// Maps a PageView page index to the Monday of that week.
DateTime mondayFromPageIndex(int index) {
  final today = DateTime.now();
  final currentMonday = mondayOfWeek(today);
  final offset = index - weekPageCenter;
  return currentMonday.add(Duration(days: offset * 7));
}

/// Maps a Monday back to a PageView index.
int pageIndexFromMonday(DateTime monday) {
  final currentMonday = mondayOfWeek(DateTime.now());
  final diff = monday.difference(currentMonday).inDays;
  return weekPageCenter + (diff ~/ 7);
}
