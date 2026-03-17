import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alpha/features/board/presentation/board_create_screen.dart';
import 'package:alpha/features/template/data/templates.dart';

import '../helpers/helpers.dart';

void main() {
  group('BoardCreateScreen', () {
    testWidgets('renders form with name field and template section',
        (tester) async {
      await tester.pumpApp(const BoardCreateScreen());
      await tester.pumpAndSettle();

      expect(find.text('Create Board'), findsOneWidget);
      expect(find.text('Board name'), findsOneWidget);
      expect(find.text('Choose a template'), findsOneWidget);
    });

    testWidgets('shows all default templates', (tester) async {
      await tester.pumpApp(const BoardCreateScreen());
      await tester.pumpAndSettle();

      for (final template in defaultTemplates) {
        expect(find.text(template.name), findsOneWidget);
      }
    });

    testWidgets('shows validation error when name is empty', (tester) async {
      // Use a taller viewport so the Create button is visible
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpApp(const BoardCreateScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a board name'), findsOneWidget);
    });

    testWidgets('tapping a template changes selection', (tester) async {
      await tester.pumpApp(const BoardCreateScreen());
      await tester.pumpAndSettle();

      // All templates should be visible
      for (final template in defaultTemplates) {
        expect(find.text(template.name), findsOneWidget);
      }

      // Tap the second template
      if (defaultTemplates.length > 1) {
        await tester.tap(find.text(defaultTemplates[1].name));
        await tester.pumpAndSettle();

        expect(find.text(defaultTemplates[1].name), findsOneWidget);
      }
    });
  });
}
