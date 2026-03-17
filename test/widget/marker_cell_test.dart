import 'dart:ui';
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

      // No symbol character should be visible
      for (final symbol in MarkerSymbol.values) {
        expect(
          find.text(symbol.displayChar),
          findsNothing,
          reason: 'Should not show ${symbol.displayChar}',
        );
      }
    });

    testWidgets('renders display character when marker exists', (tester) async {
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

      expect(find.text('•'), findsOneWidget);
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

      expect(find.text('•'), findsOneWidget);
    });

    testWidgets('tap cycles dot to slash to x to empty', (tester) async {
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

      // dot -> slash
      await tester.tap(find.byType(MarkerCell));
      await tester.pumpAndSettle();
      expect(find.text('/'), findsOneWidget);

      // slash -> x
      await tester.tap(find.byType(MarkerCell));
      await tester.pumpAndSettle();
      expect(find.text('X'), findsOneWidget);

      // x -> empty
      await tester.tap(find.byType(MarkerCell));
      await tester.pumpAndSettle();

      for (final symbol in MarkerSymbol.values) {
        expect(find.text(symbol.displayChar), findsNothing);
      }
    });

    testWidgets('long-press opens picker sheet', (tester) async {
      // Increase surface size to avoid overflow in the picker sheet
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
        column: makeColumn(id: colId, boardId: boardId, type: ColumnType.date),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.byType(MarkerCell));
      await tester.pumpAndSettle();

      expect(find.text('Set Marker'), findsOneWidget);
      expect(find.text('Scheduled'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Migrated'), findsOneWidget);
      expect(find.text('Done Early'), findsOneWidget);
      expect(find.text('Event'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
    });

    testWidgets('selecting symbol from picker sets marker', (tester) async {
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
        column: makeColumn(id: colId, boardId: boardId, type: ColumnType.date),
      );
      await tester.pumpAndSettle();

      // Long-press to open picker
      await tester.longPress(find.byType(MarkerCell));
      await tester.pumpAndSettle();

      // Select Event
      await tester.tap(find.text('Event'));
      await tester.pumpAndSettle();

      expect(find.text('○'), findsOneWidget);
    });
  });
}
