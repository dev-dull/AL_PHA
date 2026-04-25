import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:planyr/features/board/presentation/monthly_view_screen.dart';

import '../helpers/helpers.dart';

void main() {
  testWidgets(
    'tapping anywhere inside a day cell box fires onDayTap',
    (tester) async {
      // Set a generous viewport so cells are large.
      await tester.binding.setSurfaceSize(const Size(700, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      DateTime? captured;
      final container = createTestContainer();
      await tester.pumpWithContainer(
        MonthlyViewScreen(onDayTap: (w) => captured = w),
        container,
      );
      await tester.pumpAndSettle();

      // Find the InkWell ancestor of day "15" — that's the actual
      // tappable region.
      final dayText = find.text('15');
      expect(dayText, findsOneWidget);
      final inkWell = find.ancestor(
        of: dayText,
        matching: find.byType(InkWell),
      );
      expect(inkWell, findsOneWidget);

      final cellRect = tester.getRect(inkWell);
      final textRect = tester.getRect(dayText);

      // Tap a corner of the cell — far from the text.
      await tester.tapAt(cellRect.topLeft.translate(4, 4));
      await tester.pumpAndSettle();

      // Print info for debugging if it fails.
      if (captured == null) {
        debugPrint('cell rect: $cellRect');
        debugPrint('text rect: $textRect');
      }
      expect(captured, isNotNull,
          reason: 'tapping in a cell corner should invoke onDayTap '
              '(cell: $cellRect, text: $textRect)');
    },
  );
}
