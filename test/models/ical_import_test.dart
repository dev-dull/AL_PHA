import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'package:planyr/features/task/data/ical_import.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('parseICalString — TZID handling', () {
    late List<ParsedEvent> events;

    setUpAll(() {
      final ics = File('test/fixtures/event_with_tzid.ics')
          .readAsStringSync();
      events = parseICalString(ics);
    });

    test('TZID=America/New_York is converted to UTC, not host-local', () {
      // 12:15 EDT (UTC-4 on May 1, 2026) → 16:15 UTC. The bug we
      // fixed: enough_icalendar returns a naive 12:15, and a plain
      // .toUtc() interpreted that as host-local time, producing
      // wrong wall-clock hours that depend on where the user lives.
      final e = events.firstWhere((e) => e.title == 'Eastern lunch meeting');
      expect(e.scheduledTime, '16:15');
    });

    test('DTSTART with Z suffix is treated as UTC unchanged', () {
      // 19:30Z stays at 19:30 regardless of host TZ.
      final e = events.firstWhere((e) => e.title == 'UTC midday call');
      expect(e.scheduledTime, '19:30');
    });

    test('DTSTART without TZID and without Z stays floating-local', () {
      // No TZID → fall back to host-local interpretation. We can't
      // assert the resulting hour because tests run on whatever TZ
      // the runner is in; just confirm the event imports and gets
      // a non-null scheduledTime.
      final e = events.firstWhere((e) => e.title == 'Floating local time');
      expect(e.scheduledTime, isNotNull);
    });
  });

  group('parseICalString — X-WR-TIMEZONE fallback (#60)', () {
    late List<ParsedEvent> events;

    setUpAll(() {
      final ics =
          File('test/fixtures/event_with_x_wr_timezone.ics')
              .readAsStringSync();
      events = parseICalString(ics);
    });

    test('floating-local DTSTART picks up calendar-level '
        'X-WR-TIMEZONE as the source zone', () {
      // Pre-fix: 14:30 with no per-event TZID fell through to
      // host-local interpretation, so on a Pacific test runner the
      // user saw 21:30 UTC stored, displaying as 2:30 PM PDT
      // instead of the source's intended 14:30 EDT = 18:30 UTC.
      // Outlook / older Google exports routinely look like this.
      final e = events.firstWhere(
        (e) => e.title == 'Floating local with calendar-level TZ',
      );
      // 14:30 EDT (May 7 2026 → UTC-4) = 18:30 UTC, regardless of
      // host TZ.
      expect(e.scheduledTime, '18:30');
    });

    test('per-event TZID overrides calendar-level X-WR-TIMEZONE', () {
      // The calendar declares X-WR-TIMEZONE = America/New_York,
      // but this event's DTSTART explicitly says
      // TZID=Europe/London:20260507T100000. The per-event TZID
      // must win. 10:00 BST (London on May 7 = UTC+1) = 09:00 UTC.
      // (If we mis-applied the calendar zone instead, we'd compute
      // 14:00 UTC.)
      final e = events.firstWhere(
        (e) => e.title == 'Per-event TZID overrides calendar X-WR-TIMEZONE',
      );
      expect(e.scheduledTime, '09:00');
    });
  });
}
