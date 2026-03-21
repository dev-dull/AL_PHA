import 'package:flutter_test/flutter_test.dart';
import 'package:alpha/features/board/domain/board_type.dart';

void main() {
  group('BoardType', () {
    test('all types should have display names', () {
      for (final type in BoardType.values) {
        expect(type.displayName, isNotEmpty);
      }
    });

    test('should have exactly 5 types', () {
      expect(BoardType.values.length, 5);
    });
  });
}
