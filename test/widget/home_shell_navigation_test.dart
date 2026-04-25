import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:planyr/app/home_shell.dart';

import '../helpers/helpers.dart';

void main() {
  testWidgets(
    'tapping a day in monthly view navigates to that week in planner',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(700, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = createTestContainer();
      await tester.pumpWithContainer(const HomeShell(), container);
      await tester.pumpAndSettle();

      // Switch to Month Overview.
      await tester.tap(find.text('Month Overview'));
      await tester.pumpAndSettle();
      expect(find.text('15'), findsOneWidget,
          reason: 'monthly grid should render');

      // Tap day 15.
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();

      // We should now be on the Planner view, showing the week
      // containing the 15th. Look for "Week of" in the title.
      expect(find.textContaining('Week of'), findsOneWidget,
          reason: 'should switch to planner view with a week title');
    },
  );
}
