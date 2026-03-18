import 'package:flutter_test/flutter_test.dart';
import 'package:alpha/shared/week_utils.dart';

void main() {
  group('mondayOfWeek', () {
    test('returns Monday for a Monday', () {
      final monday = DateTime(2026, 3, 16); // Monday
      expect(mondayOfWeek(monday), DateTime(2026, 3, 16));
    });

    test('returns Monday for a Wednesday', () {
      final wed = DateTime(2026, 3, 18); // Wednesday
      expect(mondayOfWeek(wed), DateTime(2026, 3, 16));
    });

    test('returns Monday for a Sunday', () {
      final sun = DateTime(2026, 3, 22); // Sunday
      expect(mondayOfWeek(sun), DateTime(2026, 3, 16));
    });

    test('strips time component', () {
      final wedWithTime = DateTime(2026, 3, 18, 14, 30, 45);
      final result = mondayOfWeek(wedWithTime);
      expect(result, DateTime(2026, 3, 16));
      expect(result.hour, 0);
      expect(result.minute, 0);
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
      final monday = mondayFromPageIndex(weekPageCenter);
      expect(monday, mondayOfWeek(DateTime.now()));
    });

    test('center + 1 maps to next week', () {
      final nextMonday = mondayFromPageIndex(weekPageCenter + 1);
      final currentMonday = mondayOfWeek(DateTime.now());
      expect(nextMonday.difference(currentMonday).inDays, 7);
    });

    test('pageIndexFromMonday is inverse of mondayFromPageIndex', () {
      final monday = DateTime(2026, 3, 16);
      final index = pageIndexFromMonday(monday);
      final result = mondayFromPageIndex(index);
      expect(result, monday);
    });
  });
}
