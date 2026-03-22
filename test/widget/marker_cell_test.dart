import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alpha/features/column/domain/column_type.dart';
import 'package:alpha/features/marker/domain/marker_symbol.dart';
import 'package:alpha/features/marker/presentation/marker_cell.dart';

import '../helpers/helpers.dart';

void main() {
  group('MarkerCell', () {
    const boardId = 'board-1';
    const taskId = 'task-1';
    const colId = 'col-1';

    testWidgets('renders empty when no marker exists', (tester) async {
      final container = await tester.pumpApp(
        const MarkerCell(boardId: boardId, taskId: taskId, columnId: colId),
      );

      // Seed board, task, column (required for foreign keys) but no marker
      await seedBoard(container, board: makeBoard(id: boardId));
      await seedTask(
        container,
        task: makeTask(id: taskId, boardId: boardId),
      );
      await seedColumn(
        container,
        column: makeColumn(id: colId, boardId: boardId, type: ColumnType.date),
      );
      await tester.pumpAndSettle();

      // No marker text or symbols should be visible
      expect(find.text('/'), findsNothing);
      expect(find.text('X'), findsNothing);
      expect(find.text('>'), findsNothing);
      expect(find.text('<'), findsNothing);
    });

    testWidgets('renders marker when marker exists', (tester) async {
      final container = await tester.pumpApp(
        const MarkerCell(boardId: boardId, taskId: taskId, columnId: colId),
      );

      await seedBoard(container, board: makeBoard(id: boardId));
      await seedTask(
        container,
        task: makeTask(id: taskId, boardId: boardId),
      );
      await seedColumn(
        container,
        column: makeColumn(id: colId, boardId: boardId, type: ColumnType.date),
      );
      await seedMarker(
        container,
        marker: makeMarker(
          taskId: taskId,
          columnId: colId,
          boardId: boardId,
          symbol: MarkerSymbol.dot,
        ),
      );
      await tester.pumpAndSettle();

      // Dot renders as a painted widget — verify no text '•' but
      // the cell has content (the MarkerCell itself is present).
      expect(find.text('•'), findsNothing);
      expect(find.byType(MarkerCell), findsOneWidget);
    });

    testWidgets('tap cycles empty to dot', (tester) async {
      final container = await tester.pumpApp(
        const MarkerCell(boardId: boardId, taskId: taskId, columnId: colId),
      );

      await seedBoard(container, board: makeBoard(id: boardId));
      await seedTask(
        container,
        task: makeTask(id: taskId, boardId: boardId),
      );
      await seedColumn(
        container,
        column: makeColumn(id: colId, boardId: boardId, type: ColumnType.date),
      );
      await tester.pumpAndSettle();

      // Tap to cycle: empty -> dot
      await tester.tap(find.byType(MarkerCell));
      await tester.pumpAndSettle();

      // Dot renders as painted widget, not text
      expect(find.text('•'), findsNothing);
      expect(find.byType(MarkerCell), findsOneWidget);
    });

    testWidgets('tap on existing symbol opens radial menu', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = await tester.pumpApp(
        const MarkerCell(boardId: boardId, taskId: taskId, columnId: colId),
      );

      await seedBoard(container, board: makeBoard(id: boardId));
      await seedTask(
        container,
        task: makeTask(id: taskId, boardId: boardId),
      );
      await seedColumn(
        container,
        column: makeColumn(
          id: colId,
          boardId: boardId,
          type: ColumnType.date,
        ),
      );
      await seedMarker(
        container,
        marker: makeMarker(
          taskId: taskId,
          columnId: colId,
          boardId: boardId,
          symbol: MarkerSymbol.dot,
        ),
      );
      await tester.pumpAndSettle();

      // Tap existing dot — should open radial menu with all symbols
      await tester.tap(find.byType(MarkerCell));
      await tester.pumpAndSettle();

      // Radial menu shows manual-cycle symbols (plus clear ∅).
      // Dot and checkmark are painted, so only verify text items.
      expect(find.text('/'), findsWidgets); // slash
      expect(find.text('∅'), findsOneWidget); // clear
    });

    testWidgets('selecting symbol from radial menu sets marker', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = await tester.pumpApp(
        const MarkerCell(boardId: boardId, taskId: taskId, columnId: colId),
      );

      await seedBoard(container, board: makeBoard(id: boardId));
      await seedTask(
        container,
        task: makeTask(id: taskId, boardId: boardId),
      );
      await seedColumn(
        container,
        column: makeColumn(
          id: colId,
          boardId: boardId,
          type: ColumnType.date,
        ),
      );
      await seedMarker(
        container,
        marker: makeMarker(
          taskId: taskId,
          columnId: colId,
          boardId: boardId,
          symbol: MarkerSymbol.dot,
        ),
      );
      await tester.pumpAndSettle();

      // Tap to open radial menu
      await tester.tap(find.byType(MarkerCell));
      await tester.pumpAndSettle();

      // Tap the slash (/) symbol in the radial menu
      await tester.tap(find.text('/').last);
      await tester.pumpAndSettle();

      expect(find.text('/'), findsOneWidget);
    });

    testWidgets('clearing via radial menu removes marker', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Center the widget so radial menu items stay on screen.
      final container = await tester.pumpApp(
        const Center(
          child: MarkerCell(
            boardId: boardId,
            taskId: taskId,
            columnId: colId,
          ),
        ),
      );

      await seedBoard(container, board: makeBoard(id: boardId));
      await seedTask(
        container,
        task: makeTask(id: taskId, boardId: boardId),
      );
      await seedColumn(
        container,
        column: makeColumn(
          id: colId,
          boardId: boardId,
          type: ColumnType.date,
        ),
      );
      await seedMarker(
        container,
        marker: makeMarker(
          taskId: taskId,
          columnId: colId,
          boardId: boardId,
          symbol: MarkerSymbol.slash,
        ),
      );
      await tester.pumpAndSettle();

      // Tap to open radial menu
      await tester.tap(find.byType(MarkerCell));
      await tester.pumpAndSettle();

      // Tap clear (∅)
      await tester.tap(find.text('∅'));
      await tester.pumpAndSettle();

      // After menu dismisses, no symbol should remain in the cell
      expect(find.text('/'), findsNothing);
    });
  });
}
