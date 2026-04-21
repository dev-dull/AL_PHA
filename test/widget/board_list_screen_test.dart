import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:planyr/features/board/domain/board_type.dart';
import 'package:planyr/features/board/presentation/board_list_screen.dart';

import '../helpers/helpers.dart';

void main() {
  group('BoardListScreen', () {
    testWidgets('shows empty state when no boards exist', (tester) async {
      await tester.pumpApp(const BoardListScreen());
      await tester.pumpAndSettle();

      expect(find.text('No boards yet'), findsOneWidget);
      expect(find.text('Create your first board'), findsOneWidget);
    });

    testWidgets('shows board cards when boards exist', (tester) async {
      final container = await tester.pumpApp(const BoardListScreen());

      await seedBoard(
        container,
        board: makeBoard(
          id: 'b1',
          name: 'Week of March 16',
          type: BoardType.weekly,
        ),
      );
      await seedBoard(
        container,
        board: makeBoard(id: 'b2', name: 'GTD Board', type: BoardType.custom),
      );
      await tester.pumpAndSettle();

      expect(find.text('Week of March 16'), findsOneWidget);
      expect(find.text('GTD Board'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);
    });

    testWidgets('FAB is present', (tester) async {
      await tester.pumpApp(const BoardListScreen());
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('long-press opens options sheet', (tester) async {
      final container = await tester.pumpApp(const BoardListScreen());

      await seedBoard(
        container,
        board: makeBoard(id: 'b1', name: 'My Board'),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.text('My Board'));
      await tester.pumpAndSettle();

      expect(find.text('Archive'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('archive removes board from list', (tester) async {
      final container = await tester.pumpApp(const BoardListScreen());

      await seedBoard(
        container,
        board: makeBoard(id: 'b1', name: 'Archiveable Board'),
      );
      await tester.pumpAndSettle();

      // Long-press to open options
      await tester.longPress(find.text('Archiveable Board'));
      await tester.pumpAndSettle();

      // Tap archive
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();

      // Board should be gone (archived boards not shown)
      expect(find.text('Archiveable Board'), findsNothing);
      expect(find.text('No boards yet'), findsOneWidget);
    });

    testWidgets('delete with confirmation removes board', (tester) async {
      final container = await tester.pumpApp(const BoardListScreen());

      await seedBoard(
        container,
        board: makeBoard(id: 'b1', name: 'Deletable Board'),
      );
      await tester.pumpAndSettle();

      // Long-press to open options
      await tester.longPress(find.text('Deletable Board'));
      await tester.pumpAndSettle();

      // Tap delete
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Confirm in dialog
      expect(find.text('Delete board?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Deletable Board'), findsNothing);
    });
  });
}
