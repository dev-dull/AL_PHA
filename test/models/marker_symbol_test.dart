import 'package:flutter_test/flutter_test.dart';
import 'package:planyr/features/marker/domain/marker_symbol.dart';

void main() {
  group('MarkerSymbol', () {
    test('cycleStart should be dot', () {
      expect(MarkerSymbol.cycleStart, MarkerSymbol.dot);
    });

    test('tap cycle should follow empty -> dot -> slash -> x -> empty', () {
      // empty -> dot (handled by cycleStart)
      expect(MarkerSymbol.cycleStart, MarkerSymbol.dot);

      // dot -> slash
      expect(MarkerSymbol.dot.nextInCycle, MarkerSymbol.slash);

      // slash -> x
      expect(MarkerSymbol.slash.nextInCycle, MarkerSymbol.x);

      // x -> empty (null)
      expect(MarkerSymbol.x.nextInCycle, isNull);
    });

    test('special symbols should exit to empty', () {
      expect(MarkerSymbol.migratedForward.nextInCycle, isNull);
      expect(MarkerSymbol.doneEarly.nextInCycle, isNull);
      expect(MarkerSymbol.event.nextInCycle, isNull);
    });

    test('displayChar should return correct characters', () {
      expect(MarkerSymbol.dot.displayChar, '•');
      expect(MarkerSymbol.slash.displayChar, '/');
      expect(MarkerSymbol.x.displayChar, '✓');
      expect(MarkerSymbol.migratedForward.displayChar, '>');
      expect(MarkerSymbol.doneEarly.displayChar, '<');
      expect(MarkerSymbol.event.displayChar, '○');
    });

    test('all symbols should have a display name', () {
      for (final symbol in MarkerSymbol.values) {
        expect(symbol.displayName, isNotEmpty);
      }
    });
  });
}
