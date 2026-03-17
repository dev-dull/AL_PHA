import 'package:flutter_test/flutter_test.dart';
import 'package:alpha/features/marker/domain/marker_symbol.dart';

void main() {
  group('MarkerSymbol', () {
    test('cycleStart should be dot', () {
      expect(MarkerSymbol.cycleStart, MarkerSymbol.dot);
    });

    test('tap cycle should follow empty -> dot -> circle -> x -> empty', () {
      // empty -> dot (handled by cycleStart)
      expect(MarkerSymbol.cycleStart, MarkerSymbol.dot);

      // dot -> circle
      expect(MarkerSymbol.dot.nextInCycle, MarkerSymbol.circle);

      // circle -> x
      expect(MarkerSymbol.circle.nextInCycle, MarkerSymbol.x);

      // x -> empty (null)
      expect(MarkerSymbol.x.nextInCycle, isNull);
    });

    test('special symbols should exit to empty', () {
      expect(MarkerSymbol.star.nextInCycle, isNull);
      expect(MarkerSymbol.tilde.nextInCycle, isNull);
      expect(MarkerSymbol.migrated.nextInCycle, isNull);
    });

    test('displayChar should return correct characters', () {
      expect(MarkerSymbol.dot.displayChar, '•');
      expect(MarkerSymbol.circle.displayChar, '○');
      expect(MarkerSymbol.x.displayChar, '✕');
      expect(MarkerSymbol.star.displayChar, '★');
      expect(MarkerSymbol.tilde.displayChar, '~');
      expect(MarkerSymbol.migrated.displayChar, '>');
    });

    test('all symbols should have a display name', () {
      for (final symbol in MarkerSymbol.values) {
        expect(symbol.displayName, isNotEmpty);
      }
    });
  });
}
