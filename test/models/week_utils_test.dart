import 'package:flutter_test/flutter_test.dart';
import 'package:planyr/shared/week_utils.dart';

void main() {
  group('startOfWeek (Monday start)', () {
    test('returns Monday for a Monday', () {
      final monday = DateTime.utc(2026, 3, 16);
      expect(startOfWeek(monday), DateTime.utc(2026, 3, 16));
    });

    test('returns Monday for a Wednesday', () {
      final wed = DateTime(2026, 3, 18);
      expect(startOfWeek(wed), DateTime.utc(2026, 3, 16));
    });

    test('returns Monday for a Sunday', () {
      final sun = DateTime.utc(2026, 3, 22);
      expect(startOfWeek(sun), DateTime.utc(2026, 3, 16));
    });

    test('strips time component', () {
      final wedWithTime = DateTime(2026, 3, 18, 14, 30, 45);
      final result = startOfWeek(wedWithTime);
      expect(result, DateTime.utc(2026, 3, 16));
      expect(result.hour, 0);
      expect(result.minute, 0);
    });
  });

  group('startOfWeek (Sunday start)', () {
    test('returns Sunday for a Sunday', () {
      final sun = DateTime.utc(2026, 3, 22);
      expect(
        startOfWeek(sun, firstDay: DateTime.sunday),
        DateTime.utc(2026, 3, 22),
      );
    });

    test('returns Sunday for a Wednesday', () {
      final wed = DateTime(2026, 3, 18);
      expect(
        startOfWeek(wed, firstDay: DateTime.sunday),
        DateTime.utc(2026, 3, 15),
      );
    });

    test('returns Sunday for a Saturday', () {
      final sat = DateTime(2026, 3, 21);
      expect(
        startOfWeek(sat, firstDay: DateTime.sunday),
        DateTime.utc(2026, 3, 15),
      );
    });
  });

  group('weekBoardName', () {
    test('formats correctly', () {
      final monday = DateTime.utc(2026, 3, 16);
      expect(weekBoardName(monday), 'Week of Mar 16');
    });
  });
}
