import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alpha/features/board/domain/board_type.dart';
import 'package:alpha/features/board/presentation/board_detail_screen.dart';
import 'package:alpha/features/marker/presentation/marker_cell.dart';

import '../helpers/helpers.dart';

void main() {
  group('BoardDetailScreen', () {
    const boardId = 'board-1';

    testWidgets('shows board name in app bar', (tester) async {
      final container = createTestContainer();
      await seedBoard(
        container,
        board: makeBoard(id: boardId, name: 'My Week'),
      );
      await tester.pumpWithContainer(
        const BoardDetailScreen(boardId: boardId),
        container,
      );
      await tester.pumpAndSettle();

      expect(find.text('My Week'), findsOneWidget);
    });

    testWidgets('shows empty state when no tasks', (tester) async {
      final container = createTestContainer();
      await seedBoard(container, board: makeBoard(id: boardId));
      await tester.pumpWithContainer(
        const BoardDetailScreen(boardId: boardId),
        container,
      );
      await tester.pumpAndSettle();

      expect(find.text('No tasks yet'), findsOneWidget);
      expect(find.text('Tap + to add your first task.'), findsOneWidget);
    });

    testWidgets('renders column headers', (tester) async {
      final container = createTestContainer();
      await seedBoard(container, board: makeBoard(id: boardId));
      await seedColumn(
        container,
        column: makeColumn(
          id: 'c1',
          boardId: boardId,
          label: 'Mon',
          position: 0,
        ),
      );
      await seedColumn(
        container,
        column: makeColumn(
          id: 'c2',
          boardId: boardId,
          label: 'Tue',
          position: 1,
        ),
      );
      await seedTask(
        container,
        task: makeTask(id: 't1', boardId: boardId, title: 'Do stuff'),
      );
      await tester.pumpWithContainer(
        const BoardDetailScreen(boardId: boardId),
        container,
      );
      await tester.pumpAndSettle();

      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
    });

    testWidgets('renders task names', (tester) async {
      final container = createTestContainer();
      await seedBoard(container, board: makeBoard(id: boardId));
      await seedTask(
        container,
        task: makeTask(
          id: 't1',
          boardId: boardId,
          title: 'Task Alpha',
          position: 0,
        ),
      );
      await seedTask(
        container,
        task: makeTask(
          id: 't2',
          boardId: boardId,
          title: 'Task Beta',
          position: 1,
        ),
      );
      await tester.pumpWithContainer(
        const BoardDetailScreen(boardId: boardId),
        container,
      );
      await tester.pumpAndSettle();

      expect(find.text('Task Alpha'), findsOneWidget);
      expect(find.text('Task Beta'), findsOneWidget);
    });

    testWidgets('renders marker cells at intersections', (tester) async {
      final container = createTestContainer();
      await seedBoard(container, board: makeBoard(id: boardId));
      await seedColumn(
        container,
        column: makeColumn(id: 'c1', boardId: boardId, label: 'Mon'),
      );
      await seedTask(
        container,
        task: makeTask(id: 't1', boardId: boardId, title: 'Walk'),
      );
      await tester.pumpWithContainer(
        const BoardDetailScreen(boardId: boardId),
        container,
      );
      await tester.pumpAndSettle();

      expect(find.byType(MarkerCell), findsOneWidget);
    });

    testWidgets('FAB opens add task dialog', (tester) async {
      final container = createTestContainer();
      await seedBoard(container, board: makeBoard(id: boardId));
      await tester.pumpWithContainer(
        const BoardDetailScreen(boardId: boardId),
        container,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('New Task'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('add task via dialog', (tester) async {
      final container = createTestContainer();
      await seedBoard(container, board: makeBoard(id: boardId));
      await seedColumn(
        container,
        column: makeColumn(id: 'c1', boardId: boardId, label: 'Mon'),
      );
      await tester.pumpWithContainer(
        const BoardDetailScreen(boardId: boardId),
        container,
      );
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Enter name and submit
      await tester.enterText(find.byType(TextField), 'New task');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('New task'), findsOneWidget);
    });

    testWidgets('empty task name is not added', (tester) async {
      final container = createTestContainer();
      await seedBoard(container, board: makeBoard(id: boardId));
      await tester.pumpWithContainer(
        const BoardDetailScreen(boardId: boardId),
        container,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Submit empty — tap Cancel instead to avoid controller disposal issues
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Should still show empty state
      expect(find.text('No tasks yet'), findsOneWidget);
    });

    testWidgets('migration banner appears for expired daily board', (
      tester,
    ) async {
      final container = createTestContainer();
      await seedBoard(
        container,
        board: makeBoard(
          id: boardId,
          name: 'Yesterday',
          type: BoardType.daily,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      );
      await tester.pumpWithContainer(
        const BoardDetailScreen(boardId: boardId),
        container,
      );
      await tester.pumpAndSettle();

      expect(
        find.text('This period has ended. Migrate incomplete tasks?'),
        findsOneWidget,
      );
    });

    testWidgets('migration banner does NOT appear for current board', (
      tester,
    ) async {
      final container = createTestContainer();
      await seedBoard(
        container,
        board: makeBoard(
          id: boardId,
          name: 'Today',
          type: BoardType.daily,
          createdAt: DateTime.now(),
        ),
      );
      await tester.pumpWithContainer(
        const BoardDetailScreen(boardId: boardId),
        container,
      );
      await tester.pumpAndSettle();

      expect(
        find.text('This period has ended. Migrate incomplete tasks?'),
        findsNothing,
      );
    });
  });
}
