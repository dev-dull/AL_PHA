import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alpha/features/column/presentation/column_manager_sheet.dart';

import '../helpers/helpers.dart';

void main() {
  group('ColumnManagerSheet', () {
    const boardId = 'board-1';

    testWidgets('shows empty state when no columns', (tester) async {
      final container = await tester.pumpApp(
        const ColumnManagerSheet(boardId: boardId),
      );

      await seedBoard(container, board: makeBoard(id: boardId));
      await tester.pumpAndSettle();

      expect(find.text('No columns yet. Add one below.'), findsOneWidget);
    });

    testWidgets('shows column list', (tester) async {
      final container = await tester.pumpApp(
        const ColumnManagerSheet(boardId: boardId),
      );

      await seedBoard(container, board: makeBoard(id: boardId));
      await seedColumn(
        container,
        column: makeColumn(
          id: 'c1',
          boardId: boardId,
          label: 'Monday',
          position: 0,
        ),
      );
      await seedColumn(
        container,
        column: makeColumn(
          id: 'c2',
          boardId: boardId,
          label: 'Tuesday',
          position: 1,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Monday'), findsOneWidget);
      expect(find.text('Tuesday'), findsOneWidget);
    });

    testWidgets('add column via text field and button', (tester) async {
      final container = await tester.pumpApp(
        const ColumnManagerSheet(boardId: boardId),
      );

      await seedBoard(container, board: makeBoard(id: boardId));
      await tester.pumpAndSettle();

      // Type new column label
      await tester.enterText(
        find.widgetWithText(TextField, 'New column label'),
        'Wednesday',
      );
      await tester.pumpAndSettle();

      // Tap Add
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('Wednesday'), findsOneWidget);
    });

    testWidgets('empty label is not added', (tester) async {
      final container = await tester.pumpApp(
        const ColumnManagerSheet(boardId: boardId),
      );

      await seedBoard(container, board: makeBoard(id: boardId));
      await tester.pumpAndSettle();

      // Tap Add without entering text
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('No columns yet. Add one below.'), findsOneWidget);
    });

    testWidgets('manage columns title is shown', (tester) async {
      await tester.pumpApp(const ColumnManagerSheet(boardId: boardId));
      await tester.pumpAndSettle();

      expect(find.text('Manage Columns'), findsOneWidget);
    });
  });
}
