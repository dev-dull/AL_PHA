import 'package:flutter_test/flutter_test.dart';
import 'package:alpha/shared/week_utils.dart';

void main() {
  group('startOfWeek (Monday start)', () {
    test('returns Monday for a Monday', () {
      final monday = DateTime(2026, 3, 16); // Monday
      expect(startOfWeek(monday), DateTime(2026, 3, 16));
    });

    test('returns Monday for a Wednesday', () {
      final wed = DateTime(2026, 3, 18); // Wednesday
      expect(startOfWeek(wed), DateTime(2026, 3, 16));
    });

    test('returns Monday for a Sunday', () {
      final sun = DateTime(2026, 3, 22); // Sunday
      expect(startOfWeek(sun), DateTime(2026, 3, 16));
    });

    test('strips time component', () {
      final wedWithTime = DateTime(2026, 3, 18, 14, 30, 45);
      final result = startOfWeek(wedWithTime);
      expect(result, DateTime(2026, 3, 16));
      expect(result.hour, 0);
      expect(result.minute, 0);
    });
  });

  group('startOfWeek (Sunday start)', () {
    test('returns Sunday for a Sunday', () {
      final sun = DateTime(2026, 3, 22); // Sunday
      expect(
        startOfWeek(sun, firstDay: DateTime.sunday),
        DateTime(2026, 3, 22),
      );
    });

    test('returns Sunday for a Wednesday', () {
      final wed = DateTime(2026, 3, 18); // Wednesday
      expect(
        startOfWeek(wed, firstDay: DateTime.sunday),
        DateTime(2026, 3, 15),
      );
    });

    test('returns Sunday for a Saturday', () {
      final sat = DateTime(2026, 3, 21); // Saturday
      expect(
        startOfWeek(sat, firstDay: DateTime.sunday),
        DateTime(2026, 3, 15),
      );
    });
  });

  group('mondayOfWeek alias', () {
    test('delegates to startOfWeek with Monday', () {
      final wed = DateTime(2026, 3, 18);
      expect(mondayOfWeek(wed), startOfWeek(wed));
    });
  });

  group('weekBoardName', () {
    test('formats correctly', () {
      final monday = DateTime(2026, 3, 16);
      expect(weekBoardName(monday), 'Week of Mar 16');
    });
  });

  group('page index mapping', () {
    test('center index maps to current week', () {
      final ws = weekFromPageIndex(weekPageCenter);
      expect(ws, startOfWeek(DateTime.now()));
    });

    test('center + 1 maps to next week', () {
      final next = weekFromPageIndex(weekPageCenter + 1);
      final current = startOfWeek(DateTime.now());
      expect(next.difference(current).inDays, 7);
    });

    test('pageIndexFromWeek is inverse of weekFromPageIndex', () {
      final monday = DateTime(2026, 3, 16);
      final index = pageIndexFromWeek(monday);
      final result = weekFromPageIndex(index);
      expect(result, monday);
    });
  });
}
