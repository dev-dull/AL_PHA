import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:alpha/features/board/presentation/board_create_screen.dart';

import '../helpers/helpers.dart';

void main() {
  group('BoardCreateScreen', () {
    testWidgets('renders form with pre-populated name field', (tester) async {
      await tester.pumpApp(const BoardCreateScreen());
      await tester.pumpAndSettle();

      expect(find.text('Create Board'), findsOneWidget);
      expect(find.text('Board name'), findsOneWidget);

      // Name should be pre-populated with "Week of {current date}"
      final now = DateTime.now();
      final formatted = DateFormat('MMMM d').format(now);
      expect(find.text('Week of $formatted'), findsOneWidget);
    });

    testWidgets('Create button exists', (tester) async {
      await tester.pumpApp(const BoardCreateScreen());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Create'), findsOneWidget);
    });

    testWidgets('does not show template selection', (tester) async {
      await tester.pumpApp(const BoardCreateScreen());
      await tester.pumpAndSettle();

      expect(find.text('Choose a template'), findsNothing);
    });

    testWidgets('shows validation error when name is empty', (tester) async {
      await tester.pumpApp(const BoardCreateScreen());
      await tester.pumpAndSettle();

      // Clear the pre-populated name
      final textField = find.byType(TextFormField);
      await tester.enterText(textField, '');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a board name'), findsOneWidget);
    });
  });
}
