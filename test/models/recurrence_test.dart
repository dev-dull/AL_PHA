import 'package:flutter_test/flutter_test.dart';

import 'package:planyr/features/task/domain/recurrence.dart';

void main() {
  // Helpers ------------------------------------------------------------
  // Mondays are convenient anchors because the codebase defaults to
  // firstDay = DateTime.monday.
  final mar23 = DateTime.utc(2026, 3, 23); // Monday
  final mar30 = DateTime.utc(2026, 3, 30);
  final apr6 = DateTime.utc(2026, 4, 6);
  final apr13 = DateTime.utc(2026, 4, 13);

  group('buildRRule', () {
    test('monthly with anchor encodes BYMONTHDAY', () {
      final r = buildRRule(
        RecurrenceFrequency.monthly,
        const {},
        anchorDate: DateTime.utc(2026, 4, 15),
      );
      expect(r, 'FREQ=MONTHLY;BYMONTHDAY=15');
    });

    test('monthly with anchorDates emits comma-joined BYMONTHDAY '
        '(deduped, sorted)', () {
      final r = buildRRule(
        RecurrenceFrequency.monthly,
        const {},
        anchorDates: [
          DateTime.utc(2026, 5, 15),
          DateTime.utc(2026, 5, 13),
          DateTime.utc(2026, 6, 15), // same day-of-month as first
        ],
      );
      expect(r, 'FREQ=MONTHLY;BYMONTHDAY=13,15');
    });

    test('monthly merges anchorDate into anchorDates dedupe', () {
      // anchorDate present alongside anchorDates: both contribute.
      final r = buildRRule(
        RecurrenceFrequency.monthly,
        const {},
        anchorDate: DateTime.utc(2026, 5, 22),
        anchorDates: [DateTime.utc(2026, 5, 15)],
      );
      expect(r, 'FREQ=MONTHLY;BYMONTHDAY=15,22');
    });

    test('yearly with anchor encodes BYMONTH and BYMONTHDAY', () {
      final r = buildRRule(
        RecurrenceFrequency.yearly,
        const {},
        anchorDate: DateTime.utc(2026, 1, 1),
      );
      expect(r, 'FREQ=YEARLY;BYMONTH=1;BYMONTHDAY=1');
    });

    test('daily with selected weekdays encodes BYDAY', () {
      final r = buildRRule(
        RecurrenceFrequency.daily,
        {0, 1, 2, 3, 4}, // Mon-Fri
      );
      expect(r, 'FREQ=DAILY;BYDAY=MO,TU,WE,TH,FR');
    });

    test('daily without weekday filter omits BYDAY', () {
      final r = buildRRule(RecurrenceFrequency.daily, const {});
      expect(r, 'FREQ=DAILY');
    });
  });

  group('rruleByMonthDays', () {
    test('returns empty list for null or rule without BYMONTHDAY', () {
      expect(rruleByMonthDays(null), isEmpty);
      expect(rruleByMonthDays('FREQ=MONTHLY'), isEmpty);
      expect(rruleByMonthDays('FREQ=DAILY;BYDAY=MO'), isEmpty);
    });

    test('parses a single value', () {
      expect(rruleByMonthDays('FREQ=MONTHLY;BYMONTHDAY=15'), [15]);
    });

    test('parses comma-separated values preserving rule order', () {
      expect(
        rruleByMonthDays('FREQ=MONTHLY;BYMONTHDAY=13,15'),
        [13, 15],
      );
    });
  });

  group('shouldRecurOnWeek — daily', () {
    test('appears every week regardless of source date', () {
      final source = DateTime.utc(2026, 1, 1);
      for (final wk in [mar23, mar30, apr6, apr13]) {
        expect(
          shouldRecurOnWeek(source, wk, 'FREQ=DAILY'),
          isTrue,
          reason: 'daily series should appear on $wk',
        );
      }
    });
  });

  group('shouldRecurOnWeek — monthly', () {
    test('appears only on weeks containing the anchor day-of-month', () {
      // Series anchor: 15th of every month.
      const rrule = 'FREQ=MONTHLY;BYMONTHDAY=15';
      final source = DateTime.utc(2026, 1, 15);
      // Apr 13 week (Apr 13–19): contains Apr 15 ✓
      expect(shouldRecurOnWeek(source, apr13, rrule), isTrue);
      // Apr 6 week (Apr 6–12): no 15th ✗
      expect(shouldRecurOnWeek(source, apr6, rrule), isFalse);
      // Mar 16 week (Mar 16–22): no 15th ✗
      expect(
        shouldRecurOnWeek(source, DateTime.utc(2026, 3, 16), rrule),
        isFalse,
      );
      // Mar 9 week (Mar 9–15): contains Mar 15 ✓
      expect(
        shouldRecurOnWeek(source, DateTime.utc(2026, 3, 9), rrule),
        isTrue,
      );
    });

    test('week spanning a month boundary picks up the day from '
        'either month', () {
      // Anchor day-of-month = 1.
      const rrule = 'FREQ=MONTHLY;BYMONTHDAY=1';
      final source = DateTime.utc(2026, 4, 1);
      // Apr 27 week (Apr 27–May 3): contains May 1 (next month) ✓
      expect(
        shouldRecurOnWeek(source, DateTime.utc(2026, 4, 27), rrule),
        isTrue,
      );
    });

    test('day-31 series skips months that don\'t have a 31st', () {
      const rrule = 'FREQ=MONTHLY;BYMONTHDAY=31';
      final source = DateTime.utc(2026, 1, 31);
      // Feb 23 week (Feb 23–Mar 1): Feb has no 31; Mar 31 isn't in
      // this week either ✗
      expect(
        shouldRecurOnWeek(source, DateTime.utc(2026, 2, 23), rrule),
        isFalse,
      );
      // Mar 30 week (Mar 30–Apr 5): contains Mar 31 ✓
      expect(
        shouldRecurOnWeek(source, DateTime.utc(2026, 3, 30), rrule),
        isTrue,
      );
    });

    test('falls back to source createdAt day-of-month when '
        'BYMONTHDAY is absent', () {
      const rrule = 'FREQ=MONTHLY';
      // source = the 7th — appears in weeks containing the 7th.
      final source = DateTime.utc(2026, 1, 7);
      expect(
        shouldRecurOnWeek(source, DateTime.utc(2026, 4, 6), rrule),
        isTrue, reason: 'Apr 6 week (Apr 6–12) contains the 7th',
      );
      expect(
        shouldRecurOnWeek(source, DateTime.utc(2026, 4, 13), rrule),
        isFalse, reason: 'Apr 13 week (Apr 13–19) does not',
      );
    });
  });

  group('shouldRecurOnWeek — yearly', () {
    test('appears only on weeks containing the anchor month/day', () {
      // Series anchor: Jan 1.
      const rrule = 'FREQ=YEARLY;BYMONTH=1;BYMONTHDAY=1';
      final source = DateTime.utc(2025, 1, 1);
      // Dec 29 2025 week (Dec 29–Jan 4 2026): contains Jan 1 ✓
      expect(
        shouldRecurOnWeek(source, DateTime.utc(2025, 12, 29), rrule),
        isTrue,
      );
      // A random week in March doesn't ✗
      expect(shouldRecurOnWeek(source, mar23, rrule), isFalse);
    });
  });

  group('resolveRecurrenceRuleForSave', () {
    test('plain non-recurring task with dots saves null, '
        'NOT a BYDAY-only rule (the user-reported tag-clears-dot '
        'regression)', () {
      // _scheduledDays is pre-filled from the task's markers so
      // the picker has the right initial state; saving must NOT
      // turn that into a BYDAY rule, otherwise the marker-sync
      // step sees a rule with no FREQ, computes "no scheduled
      // days," and erases every dot.
      final r = resolveRecurrenceRuleForSave(
        isEvent: false,
        recurrence: RecurrenceFrequency.none,
        scheduledDays: {2}, // dot on Wednesday
        existingRule: null,
      );
      expect(r, isNull);
    });

    test('post-End-Series task preserves BYDAY-only rule across '
        'unrelated edits', () {
      // End Series strips FREQ but keeps BYDAY for display.
      // Editing the task afterwards must not silently undo that.
      final r = resolveRecurrenceRuleForSave(
        isEvent: false,
        recurrence: RecurrenceFrequency.none,
        scheduledDays: {0, 2, 4}, // Mon/Wed/Fri
        existingRule: 'BYDAY=MO,WE,FR',
      );
      expect(r, 'BYDAY=MO,WE,FR');
    });

    test('weekly with FREQ uses buildRRule (full rule)', () {
      final r = resolveRecurrenceRuleForSave(
        isEvent: false,
        recurrence: RecurrenceFrequency.weekly,
        scheduledDays: {0, 4},
        existingRule: null,
      );
      expect(r, 'FREQ=WEEKLY;BYDAY=MO,FR');
    });

    test('event with no recurrence still emits null (one-time '
        'event)', () {
      final r = resolveRecurrenceRuleForSave(
        isEvent: true,
        recurrence: RecurrenceFrequency.none,
        scheduledDays: {3},
        existingRule: null,
      );
      // buildRRule returns null for freq=none regardless of
      // isEvent — a one-time event has no rrule by definition.
      expect(r, isNull);
    });
  });

  group('resolveRecurrenceAnchor', () {
    test('preserves existing BYMONTHDAY/BYMONTH when editing a '
        'recurring task', () {
      // User changes some other field on a "monthly on the 15th"
      // task. The anchor must stay on the 15th regardless of what
      // other inputs say.
      final anchor = resolveRecurrenceAnchor(
        recurrenceRule: 'FREQ=MONTHLY;BYMONTHDAY=15',
        createdAt: DateTime.utc(2026, 4, 29),
        markerPositions: {2}, // Wednesday — would resolve to 13 if used
        boardWeekStart: DateTime.utc(2026, 4, 13),
      );
      expect(anchor.day, 15);
    });

    test('yearly preserves both BYMONTH and BYMONTHDAY', () {
      final anchor = resolveRecurrenceAnchor(
        recurrenceRule: 'FREQ=YEARLY;BYMONTH=1;BYMONTHDAY=1',
        createdAt: DateTime.utc(2026, 4, 29),
      );
      expect(anchor.month, 1);
      expect(anchor.day, 1);
    });

    test('infers anchor from the lowest marker position when no '
        'rule exists yet (the user-reported bug)', () {
      // User adds a dot to Friday May 15 (position 4 on a Mon-start
      // board for week of May 11), then converts the task to
      // monthly. Anchor must be May 15, not today's date — otherwise
      // _syncRecurrenceMarkers will erase the marker.
      final anchor = resolveRecurrenceAnchor(
        recurrenceRule: null,
        createdAt: DateTime.utc(2026, 4, 29), // not used in this path
        markerPositions: {4},
        boardWeekStart: DateTime.utc(2026, 5, 11),
      );
      expect(anchor.year, 2026);
      expect(anchor.month, 5);
      expect(anchor.day, 15);
    });

    test('multiple markers: anchor on the earliest', () {
      // Dots on Wed (2) and Fri (4) → anchor uses Wed.
      final anchor = resolveRecurrenceAnchor(
        recurrenceRule: null,
        createdAt: DateTime.utc(2026, 4, 29),
        markerPositions: {4, 2},
        boardWeekStart: DateTime.utc(2026, 5, 11),
      );
      expect(anchor.day, 13); // May 11 + 2 days = May 13 (Wed)
    });

    test('falls back to createdAt with no markers and no rule', () {
      final created = DateTime.utc(2026, 4, 29);
      final anchor = resolveRecurrenceAnchor(
        recurrenceRule: null,
        createdAt: created,
      );
      expect(anchor, created);
    });

    test('falls back to createdAt when boardWeekStart is missing', () {
      // Markers without a board to translate them through can't
      // produce a date — fall back rather than guess.
      final created = DateTime.utc(2026, 4, 29);
      final anchor = resolveRecurrenceAnchor(
        recurrenceRule: null,
        createdAt: created,
        markerPositions: {4},
        boardWeekStart: null,
      );
      expect(anchor, created);
    });
  });

  group('scheduledDaysForWeek', () {
    test('weekly returns BYDAY positions', () {
      const rrule = 'FREQ=WEEKLY;BYDAY=MO,WE,FR';
      final source = mar23;
      expect(
        scheduledDaysForWeek(rrule, mar30, source),
        {0, 2, 4},
      );
    });

    test('daily without BYDAY returns all 7 weekday positions', () {
      const rrule = 'FREQ=DAILY';
      expect(
        scheduledDaysForWeek(rrule, mar30, mar23),
        {0, 1, 2, 3, 4, 5, 6},
      );
    });

    test('daily with BYDAY honors the filter', () {
      const rrule = 'FREQ=DAILY;BYDAY=MO,TU,WE,TH,FR';
      expect(
        scheduledDaysForWeek(rrule, mar30, mar23),
        {0, 1, 2, 3, 4},
      );
    });

    test('monthly returns the weekday position of the anchor in '
        'this week', () {
      // Anchor day-of-month = 15. Apr 15 2026 falls on Wednesday.
      const rrule = 'FREQ=MONTHLY;BYMONTHDAY=15';
      final apr13Mon = DateTime.utc(2026, 4, 13); // Monday
      expect(
        scheduledDaysForWeek(rrule, apr13Mon, mar23),
        {2}, // Wednesday position with firstDay=Monday
      );
    });

    test('monthly returns empty for a week that doesn\'t contain '
        'the anchor day', () {
      const rrule = 'FREQ=MONTHLY;BYMONTHDAY=15';
      final apr6Mon = DateTime.utc(2026, 4, 6);
      expect(scheduledDaysForWeek(rrule, apr6Mon, mar23), isEmpty);
    });

    test('monthly with multi-anchor BYMONTHDAY returns every '
        'matching weekday in the week', () {
      // BYMONTHDAY=13,15 on the week of May 11 2026 (Mon).
      // May 13 is Wednesday (pos 2), May 15 is Friday (pos 4).
      const rrule = 'FREQ=MONTHLY;BYMONTHDAY=13,15';
      final may11 = DateTime.utc(2026, 5, 11);
      expect(
        scheduledDaysForWeek(rrule, may11, DateTime.utc(2026, 1, 1)),
        {2, 4},
      );
    });

    test('monthly multi-anchor still gates on weeks that miss '
        'every anchor day', () {
      // Week of May 18 (Mon): May 18–24. Neither 13 nor 15 falls
      // here, so no positions.
      const rrule = 'FREQ=MONTHLY;BYMONTHDAY=13,15';
      final may18 = DateTime.utc(2026, 5, 18);
      expect(
        scheduledDaysForWeek(rrule, may18, DateTime.utc(2026, 1, 1)),
        isEmpty,
      );
    });

    test('monthly multi-anchor across a month boundary picks up '
        'days from either month', () {
      // BYMONTHDAY=1,30 on week of Apr 27 (Apr 27–May 3).
      // Apr 30 (Thu, pos 3) and May 1 (Fri, pos 4) both match.
      const rrule = 'FREQ=MONTHLY;BYMONTHDAY=1,30';
      final apr27 = DateTime.utc(2026, 4, 27);
      expect(
        scheduledDaysForWeek(rrule, apr27, DateTime.utc(2026, 1, 1)),
        {3, 4},
      );
    });

    test('yearly returns the weekday position only on the anchor week',
        () {
      // Anchor: Jan 1. Jan 1 2026 falls on Thursday.
      const rrule = 'FREQ=YEARLY;BYMONTH=1;BYMONTHDAY=1';
      final dec29 = DateTime.utc(2025, 12, 29); // Monday
      expect(
        scheduledDaysForWeek(rrule, dec29, DateTime.utc(2024, 1, 1)),
        {3}, // Thursday position with firstDay=Monday
      );
      // A different week → empty.
      expect(
        scheduledDaysForWeek(rrule, mar23, DateTime.utc(2024, 1, 1)),
        isEmpty,
      );
    });
  });
}
