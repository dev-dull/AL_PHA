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
///
/// [days] is a set of weekday indices (0=Mon .. 6=Sun). Used as
/// `BYDAY` for `weekly` / `biweekly` / (optionally) `daily`.
///
/// Monthly and yearly anchor on a day-of-month / month+day:
///
/// - For **monthly**, [anchorDates] is preferred — pass every date
///   the rule should fire on and the encoder will emit
///   `BYMONTHDAY=N1,N2,…` (deduped, sorted). [anchorDate] is the
///   single-anchor shorthand and stays for backward compat.
/// - For **yearly**, [anchorDate] is used (the first entry of
///   [anchorDates] if [anchorDate] is null) to emit `BYMONTH=M`
///   plus `BYMONTHDAY=N`. Multi-anchor yearly isn't supported yet.
///
/// Omitting both falls back to the materialization layer deriving
/// the anchor from the series' `createdAt`.
String? buildRRule(
  RecurrenceFrequency freq,
  Set<int> days, {
  DateTime? anchorDate,
  List<DateTime>? anchorDates,
}) {
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
      // Multi-anchor: BYMONTHDAY=13,15 (deduped + sorted). Falls
      // back to a single anchorDate, then to nothing (the
      // materializer infers from createdAt).
      final dates = <DateTime>[
        ...?anchorDates,
        ?anchorDate,
      ];
      if (dates.isNotEmpty) {
        final monthDays = (dates.map((d) => d.day).toSet().toList()
          ..sort())
            .join(',');
        parts.add('BYMONTHDAY=$monthDays');
      }
    case RecurrenceFrequency.yearly:
      parts.add('FREQ=YEARLY');
      // Yearly stays single-anchor for now (multi-anchor yearly is
      // legal in iCal but rare).
      final d = anchorDate ?? anchorDates?.firstOrNull;
      if (d != null) {
        parts.add('BYMONTH=${d.month}');
        parts.add('BYMONTHDAY=${d.day}');
      }
    case RecurrenceFrequency.none:
      return null;
  }

  if (days.isNotEmpty &&
      (freq == RecurrenceFrequency.weekly ||
          freq == RecurrenceFrequency.biweekly ||
          freq == RecurrenceFrequency.daily)) {
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

/// Parse every value out of `BYMONTHDAY=<n[,n2,…]>`. iCal lets a
/// single rule fire on multiple days of the month — used for
/// monthly tasks the user wants on more than one day (e.g.
/// `BYMONTHDAY=13,15` for "the 13th *and* 15th of every month").
/// Returns `[]` if the rule is null or has no `BYMONTHDAY`.
List<int> rruleByMonthDays(String? rrule) {
  if (rrule == null) return const [];
  final m = RegExp(r'BYMONTHDAY=([\d,]+)').firstMatch(rrule);
  if (m == null) return const [];
  return m
      .group(1)!
      .split(',')
      .map(int.tryParse)
      .whereType<int>()
      .toList();
}

/// Parse the *first* `BYMONTHDAY` value from an RRULE. Returns
/// `null` if absent. Convenience for callers that don't yet handle
/// multi-anchor monthly rules; new code should prefer
/// [rruleByMonthDays].
int? rruleByMonthDay(String? rrule) {
  final all = rruleByMonthDays(rrule);
  return all.isEmpty ? null : all.first;
}

/// Parse `BYMONTH=<n>` from an RRULE (1=Jan .. 12=Dec).
int? rruleByMonth(String? rrule) {
  if (rrule == null) return null;
  final m = RegExp(r'BYMONTH=(\d+)').firstMatch(rrule);
  return m != null ? int.tryParse(m.group(1)!) : null;
}

/// Returns a real [DateTime] for [year]/[month]/[day] (UTC), or
/// null if that day doesn't exist in that month (e.g. Feb 31).
/// Dart's `DateTime` silently overflows — so `DateTime.utc(2026,
/// 2, 31)` becomes Mar 3. We detect that by re-checking the
/// result. UTC keeps the day-difference math in [_datesInWeek]
/// independent of the host timezone.
DateTime? _dateIfValid(int year, int month, int day) {
  final dt = DateTime.utc(year, month, day);
  if (dt.month != ((month - 1) % 12) + 1 || dt.day != day) return null;
  return dt;
}

/// Day-of-week positions (0..6, relative to [firstDay]) on which a
/// recurring task should appear in the week starting [targetWeekStart].
///
/// - WEEKLY (and biweekly): the rule's `BYDAY` positions.
/// - DAILY: the rule's `BYDAY` if specified, otherwise all 7 days.
/// - MONTHLY: the day-of-month (from `BYMONTHDAY` or [sourceCreatedAt])
///   IF that day falls inside the target week.
/// - YEARLY: same as MONTHLY but additionally gated on month.
///
/// Empty set means "this series doesn't render on this week."
Set<int> scheduledDaysForWeek(
  String? rrule,
  DateTime targetWeekStart,
  DateTime sourceCreatedAt, {
  int firstDay = DateTime.monday,
}) {
  if (rrule == null || rrule.isEmpty) return {};
  final (freq, byDay) = parseRRule(rrule);

  switch (freq) {
    case RecurrenceFrequency.none:
      return {};
    case RecurrenceFrequency.weekly:
    case RecurrenceFrequency.biweekly:
      return byDay;
    case RecurrenceFrequency.daily:
      return byDay.isNotEmpty ? byDay : {0, 1, 2, 3, 4, 5, 6};
    case RecurrenceFrequency.monthly:
      // Multi-anchor: BYMONTHDAY can list several days
      // (e.g. 13,15). Try each across this week's month AND the
      // next so a week straddling a month boundary still matches.
      final monthDays = rruleByMonthDays(rrule);
      final daysOfMonth =
          monthDays.isNotEmpty ? monthDays : [sourceCreatedAt.day];
      final candidates = <DateTime?>[];
      for (final d in daysOfMonth) {
        candidates.add(
          _dateIfValid(targetWeekStart.year, targetWeekStart.month, d),
        );
        candidates.add(
          _dateIfValid(
              targetWeekStart.year, targetWeekStart.month + 1, d),
        );
      }
      return _datesInWeek(
        targetWeekStart, firstDay,
        candidates: candidates,
      );
    case RecurrenceFrequency.yearly:
      final month = rruleByMonth(rrule) ?? sourceCreatedAt.month;
      final day = rruleByMonthDay(rrule) ?? sourceCreatedAt.day;
      return _datesInWeek(
        targetWeekStart, firstDay,
        candidates: [
          // A week can also straddle Dec/Jan, so try both years.
          _dateIfValid(targetWeekStart.year, month, day),
          _dateIfValid(targetWeekStart.year + 1, month, day),
        ],
      );
  }
}

Set<int> _datesInWeek(
  DateTime targetWeekStart,
  int firstDay, {
  required List<DateTime?> candidates,
}) {
  // Pin both sides to a UTC date-at-midnight so the `inDays`
  // comparison ignores timezone offsets.
  final wsDay = DateTime.utc(
    targetWeekStart.year,
    targetWeekStart.month,
    targetWeekStart.day,
  );
  final out = <int>{};
  for (final c in candidates) {
    if (c == null) continue;
    final cDay = DateTime.utc(c.year, c.month, c.day);
    final daysFromStart = cDay.difference(wsDay).inDays;
    if (daysFromStart < 0 || daysFromStart >= 7) continue;
    out.add((c.weekday - firstDay + 7) % 7);
  }
  return out;
}

/// Whether a recurring task should appear on [targetWeekStart].
///
/// - DAILY / WEEKLY (interval=1): always true.
/// - WEEKLY with INTERVAL>1 (e.g. biweekly): every Nth week from
///   the source's week-start.
/// - MONTHLY / YEARLY: true iff the rule's anchor date falls inside
///   the target week (delegates to [scheduledDaysForWeek]).
bool shouldRecurOnWeek(
  DateTime sourceCreatedAt,
  DateTime targetWeekStart,
  String? rrule, {
  int firstDay = DateTime.monday,
}) {
  if (rrule == null || rrule.isEmpty) return false;
  final (freq, _) = parseRRule(rrule);
  switch (freq) {
    case RecurrenceFrequency.none:
      return false;
    case RecurrenceFrequency.daily:
      return true;
    case RecurrenceFrequency.weekly:
    case RecurrenceFrequency.biweekly:
      final interval = rruleInterval(rrule);
      if (interval <= 1) return true;
      final sourceWeekStart =
          _startOfWeek(sourceCreatedAt, firstDay);
      final daysDiff =
          targetWeekStart.difference(sourceWeekStart).inDays.abs();
      final weeksDiff = (daysDiff / 7).round();
      return weeksDiff % interval == 0;
    case RecurrenceFrequency.monthly:
    case RecurrenceFrequency.yearly:
      return scheduledDaysForWeek(
        rrule, targetWeekStart, sourceCreatedAt,
        firstDay: firstDay,
      ).isNotEmpty;
  }
}

/// Local copy of week_utils.startOfWeek so this module stays free
/// of cross-feature imports.
DateTime _startOfWeek(DateTime date, int firstDay) {
  final daysFromFirst = (date.weekday - firstDay + 7) % 7;
  final start = DateTime(date.year, date.month, date.day - daysFromFirst);
  return start;
}

/// Resolves the anchor date used to build a monthly / yearly RRULE.
///
/// Priority:
/// 1. **Existing rule** — if [recurrenceRule] already has BYMONTHDAY
///    (and BYMONTH for yearly), reconstruct that date. Editing a
///    recurring task's frequency shouldn't surprise the user by
///    moving the anchor.
/// 2. **Where the user dotted** — translate the lowest entry in
///    [markerPositions] through [boardWeekStart] into a real date.
///    "Dot Friday May 15, then make this monthly" should produce
///    `BYMONTHDAY=15`, not `BYMONTHDAY=<today>`.
/// 3. **Task creation date** — the conservative fallback.
DateTime resolveRecurrenceAnchor({
  required String? recurrenceRule,
  required DateTime createdAt,
  Set<int> markerPositions = const {},
  DateTime? boardWeekStart,
}) {
  final existingDay = rruleByMonthDay(recurrenceRule);
  if (existingDay != null) {
    final month = rruleByMonth(recurrenceRule) ?? createdAt.month;
    return DateTime.utc(createdAt.year, month, existingDay);
  }
  if (boardWeekStart != null && markerPositions.isNotEmpty) {
    final pos = markerPositions.reduce((a, b) => a < b ? a : b);
    return boardWeekStart.add(Duration(days: pos));
  }
  return createdAt;
}
