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
}
