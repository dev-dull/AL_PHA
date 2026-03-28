/// Recurrence frequency options for events.
enum RecurrenceFrequency {
  none,
  daily,
  weekly,
  biweekly,
  monthly,
  yearly;

  String get displayName {
    switch (this) {
      case RecurrenceFrequency.none:
        return 'None';
      case RecurrenceFrequency.daily:
        return 'Daily';
      case RecurrenceFrequency.weekly:
        return 'Weekly';
      case RecurrenceFrequency.biweekly:
        return 'Every 2 weeks';
      case RecurrenceFrequency.monthly:
        return 'Monthly';
      case RecurrenceFrequency.yearly:
        return 'Yearly';
    }
  }
}

/// iCal day abbreviations: MO, TU, WE, TH, FR, SA, SU.
const _icalDays = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

/// Day labels for the UI.
const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Builds an RRULE string from frequency and selected days.
/// [days] is a set of weekday indices (0=Mon .. 6=Sun).
String? buildRRule(RecurrenceFrequency freq, Set<int> days) {
  if (freq == RecurrenceFrequency.none) return null;

  final parts = <String>[];

  switch (freq) {
    case RecurrenceFrequency.daily:
      parts.add('FREQ=DAILY');
    case RecurrenceFrequency.weekly:
      parts.add('FREQ=WEEKLY');
    case RecurrenceFrequency.biweekly:
      parts.add('FREQ=WEEKLY');
      parts.add('INTERVAL=2');
    case RecurrenceFrequency.monthly:
      parts.add('FREQ=MONTHLY');
    case RecurrenceFrequency.yearly:
      parts.add('FREQ=YEARLY');
    case RecurrenceFrequency.none:
      return null;
  }

  if (days.isNotEmpty &&
      (freq == RecurrenceFrequency.weekly ||
          freq == RecurrenceFrequency.biweekly)) {
    final sorted = days.toList()..sort();
    parts.add('BYDAY=${sorted.map((d) => _icalDays[d]).join(',')}');
  }

  return parts.join(';');
}

/// Parses an RRULE string to extract frequency and days.
(RecurrenceFrequency, Set<int>) parseRRule(String? rrule) {
  if (rrule == null || rrule.isEmpty) {
    return (RecurrenceFrequency.none, <int>{});
  }

  final params = <String, String>{};
  for (final part in rrule.split(';')) {
    final eq = part.indexOf('=');
    if (eq > 0) {
      params[part.substring(0, eq)] = part.substring(eq + 1);
    }
  }

  var freq = RecurrenceFrequency.none;
  final interval = int.tryParse(params['INTERVAL'] ?? '') ?? 1;

  switch (params['FREQ']) {
    case 'DAILY':
      freq = RecurrenceFrequency.daily;
    case 'WEEKLY':
      freq = interval >= 2
          ? RecurrenceFrequency.biweekly
          : RecurrenceFrequency.weekly;
    case 'MONTHLY':
      freq = RecurrenceFrequency.monthly;
    case 'YEARLY':
      freq = RecurrenceFrequency.yearly;
  }

  final days = <int>{};
  final byday = params['BYDAY'];
  if (byday != null) {
    for (final d in byday.split(',')) {
      final trimmed = d.trim();
      final idx = _icalDays.indexOf(trimmed);
      if (idx >= 0) days.add(idx);
    }
  }

  return (freq, days);
}

/// Builds a BYDAY-only string (no FREQ) to preserve scheduled days
/// when recurrence is removed. Returns `null` if [days] is empty.
String? buildByDayOnly(Set<int> days) {
  if (days.isEmpty) return null;
  final sorted = days.toList()..sort();
  return 'BYDAY=${sorted.map((d) => _icalDays[d]).join(',')}';
}

/// Given an RRULE, returns the set of weekday column positions
/// (0=Mon .. 6=Sun) that should have markers.
Set<int> scheduledDaysFromRRule(String? rrule) {
  if (rrule == null) return {};
  final (_, days) = parseRRule(rrule);
  return days;
}

/// Returns the INTERVAL from an RRULE (defaults to 1).
int rruleInterval(String? rrule) {
  if (rrule == null) return 1;
  final match = RegExp(r'INTERVAL=(\d+)').firstMatch(rrule);
  return match != null ? (int.tryParse(match.group(1)!) ?? 1) : 1;
}

/// Whether a recurring task should appear on [targetWeekStart]
/// given its source board's [sourceWeekStart] and RRULE interval.
/// For INTERVAL=1 (weekly), always true.
/// For INTERVAL=2 (biweekly), true every other week.
bool shouldRecurOnWeek(
  DateTime sourceWeekStart,
  DateTime targetWeekStart,
  int interval,
) {
  if (interval <= 1) return true;
  final daysDiff =
      targetWeekStart.difference(sourceWeekStart).inDays.abs();
  final weeksDiff = (daysDiff / 7).round();
  return weeksDiff % interval == 0;
}
