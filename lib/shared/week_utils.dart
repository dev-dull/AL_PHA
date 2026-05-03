import 'package:intl/intl.dart';

/// Returns the start-of-week for the week containing [date], as a
/// **UTC midnight** of that calendar Monday (or first-day-of-week).
///
/// Returning UTC midnight makes the value TZ-stable: the same
/// calendar Monday produces the same epoch regardless of the host's
/// current timezone. That matters for [date] persistence (Drift
/// stores DateTime as epoch — local-midnight values shift by the
/// host TZ offset and mismatch on lookup after travel) and for
/// cross-device sync (the cloud receives a stable instant rather
/// than each device's local interpretation of "Monday midnight").
///
/// [date] is interpreted via its own field accessors — local fields
/// for a local DateTime, UTC fields for a UTC DateTime. The user's
/// perceived calendar date drives the result either way.
///
/// [firstDay] is the first day of the week: 1 = Monday (ISO
/// default), 7 = Sunday.
DateTime startOfWeek(DateTime date, {int firstDay = DateTime.monday}) {
  // Walk the calendar in plain DateTime arithmetic first (handles
  // negative-day rollover across month/year), then re-stamp the
  // result as UTC midnight of that final Y/M/D.
  final d = DateTime(date.year, date.month, date.day);
  final diff = (d.weekday - firstDay + 7) % 7;
  final monday = DateTime(d.year, d.month, d.day - diff);
  return DateTime.utc(monday.year, monday.month, monday.day);
}

/// Human-readable board name for a week, e.g. "Week of Mar 17".
String weekBoardName(DateTime weekStart) {
  return 'Week of ${DateFormat.MMMd().format(weekStart)}';
}
