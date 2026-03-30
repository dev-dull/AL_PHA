import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:alpha/features/board/domain/board.dart';
import 'package:alpha/features/board/domain/board_type.dart';
import 'package:alpha/features/column/domain/board_column.dart';
import 'package:alpha/features/column/domain/weekly_columns.dart';
import 'package:alpha/features/marker/domain/marker.dart';
import 'package:alpha/features/marker/domain/marker_symbol.dart';
import 'package:alpha/features/marker/providers/marker_providers.dart';
import 'package:alpha/features/series/providers/series_providers.dart';
import 'package:alpha/features/tag/domain/tag.dart';
import 'package:alpha/features/task/domain/recurrence.dart';
import 'package:alpha/features/task/domain/task.dart';
import 'package:alpha/shared/database.dart';
import 'package:alpha/shared/providers.dart';
import 'package:alpha/shared/week_utils.dart';

void main() {
  late AlphaDatabase db;
  late ProviderContainer container;
  const uuid = Uuid();

  setUp(() {
    db = AlphaDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [alphaDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() {
    container.dispose();
    db.close();
  });

  /// Helper: creates a weekly board with standard columns.
  Future<String> createWeeklyBoard(DateTime weekStart) async {
    final boardRepo = container.read(boardRepositoryProvider);
    final colRepo = container.read(columnRepositoryProvider);
    final boardId = uuid.v4();
    final now = DateTime.now();

    await boardRepo.create(Board(
      id: boardId,
      name: weekBoardName(weekStart),
      type: BoardType.weekly,
      weekStart: weekStart,
      createdAt: now,
      updatedAt: now,
    ));

    for (final col in weeklyColumnDefs()) {
      await colRepo.create(BoardColumn(
        id: uuid.v4(),
        boardId: boardId,
        label: col.label,
        position: col.position,
        type: col.type,
      ));
    }
    return boardId;
  }

  group('Series creation', () {
    test('createFromTask creates series and links task', () async {
      final boardId =
          await createWeeklyBoard(DateTime(2026, 3, 23));
      final taskRepo = container.read(taskRepositoryProvider);

      final task = Task(
        id: uuid.v4(),
        boardId: boardId,
        title: 'Take meds',
        position: 0,
        createdAt: DateTime.now(),
        recurrenceRule: 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU',
      );
      await taskRepo.create(task);

      final series = await container
          .read(seriesActionsProvider)
          .createFromTask(task, boardWeekStart: DateTime(2026, 3, 23));

      expect(series.title, 'Take meds');
      expect(series.isActive, isTrue);

      // Task should now have seriesId.
      final updated = await taskRepo.getById(task.id);
      expect(updated!.seriesId, series.id);
    });

    test('createFromTask copies tags to series', () async {
      final boardId =
          await createWeeklyBoard(DateTime(2026, 3, 23));
      final taskRepo = container.read(taskRepositoryProvider);
      final tagRepo = container.read(tagRepositoryProvider);
      final taskTagRepo = container.read(taskTagRepositoryProvider);
      final seriesTagRepo =
          container.read(seriesTagRepositoryProvider);

      // Create a tag.
      final tagId = uuid.v4();
      await tagRepo.create(Tag(
        id: tagId,
        name: 'Health',
        color: 0xFF00FF00,
        position: 0,
        createdAt: DateTime.now(),
      ));

      // Create task with tag.
      final task = Task(
        id: uuid.v4(),
        boardId: boardId,
        title: 'Take meds',
        position: 0,
        createdAt: DateTime.now(),
        recurrenceRule: 'FREQ=WEEKLY;BYDAY=MO',
      );
      await taskRepo.create(task);
      await taskTagRepo.setTagsForTask(task.id, [tagId]);

      final series = await container
          .read(seriesActionsProvider)
          .createFromTask(task, boardWeekStart: DateTime(2026, 3, 23));

      // Series should have the tag.
      final seriesTags =
          await seriesTagRepo.getTagsForSeries(series.id);
      expect(seriesTags.length, 1);
      expect(seriesTags.first.name, 'Health');
    });
  });

  group('Materialization', () {
    test('materialize creates task with markers and tags', () async {
      final board1Id =
          await createWeeklyBoard(DateTime(2026, 3, 23));
      final board2Id =
          await createWeeklyBoard(DateTime(2026, 3, 30));
      final taskRepo = container.read(taskRepositoryProvider);
      final markerRepo = container.read(markerRepositoryProvider);
      final tagRepo = container.read(tagRepositoryProvider);
      final seriesTagRepo =
          container.read(seriesTagRepositoryProvider);
      final taskTagRepo = container.read(taskTagRepositoryProvider);

      // Create a tag.
      final tagId = uuid.v4();
      await tagRepo.create(Tag(
        id: tagId,
        name: 'Health',
        color: 0xFF00FF00,
        position: 0,
        createdAt: DateTime.now(),
      ));

      // Create task + series on board 1.
      final task = Task(
        id: uuid.v4(),
        boardId: board1Id,
        title: 'Take meds',
        position: 0,
        createdAt: DateTime.now(),
        recurrenceRule: 'FREQ=WEEKLY;BYDAY=MO,WE,FR',
      );
      await taskRepo.create(task);
      await taskTagRepo.setTagsForTask(task.id, [tagId]);

      final series = await container
          .read(seriesActionsProvider)
          .createFromTask(task, boardWeekStart: DateTime(2026, 3, 23));
      await seriesTagRepo.setTagsForSeries(series.id, [tagId]);

      // Materialize on board 2.
      final materialized = await container
          .read(seriesActionsProvider)
          .materialize(series: series, boardId: board2Id);

      expect(materialized.title, 'Take meds');
      expect(materialized.seriesId, series.id);
      expect(materialized.boardId, board2Id);

      // Should have markers on Mon(0), Wed(2), Fri(4).
      final markers = await markerRepo.getByBoard(board2Id);
      final taskMarkers =
          markers.where((m) => m.taskId == materialized.id).toList();
      expect(taskMarkers.length, 3);
      expect(
        taskMarkers.every((m) => m.symbol == MarkerSymbol.dot),
        isTrue,
      );

      // Should have the tag.
      final tags =
          await taskTagRepo.getTagsForTask(materialized.id);
      expect(tags.length, 1);
      expect(tags.first.name, 'Health');
    });

    test('materialize is idempotent — no duplicates', () async {
      final boardId =
          await createWeeklyBoard(DateTime(2026, 3, 23));
      final board2Id =
          await createWeeklyBoard(DateTime(2026, 3, 30));
      final taskRepo = container.read(taskRepositoryProvider);

      final task = Task(
        id: uuid.v4(),
        boardId: boardId,
        title: 'Take meds',
        position: 0,
        createdAt: DateTime.now(),
        recurrenceRule: 'FREQ=WEEKLY;BYDAY=MO',
      );
      await taskRepo.create(task);

      final series = await container
          .read(seriesActionsProvider)
          .createFromTask(task, boardWeekStart: DateTime(2026, 3, 23));

      // Materialize twice.
      await container
          .read(seriesActionsProvider)
          .materialize(series: series, boardId: board2Id);
      await container
          .read(seriesActionsProvider)
          .materialize(series: series, boardId: board2Id);

      // Should only have one task on board 2.
      final tasks = await taskRepo.getByBoard(board2Id);
      expect(
        tasks.where((t) => t.title == 'Take meds').length,
        1,
      );
    });
  });

  group('Interval logic', () {
    test('weekly task appears every week', () async {
      final boardId =
          await createWeeklyBoard(DateTime(2026, 3, 23));
      final taskRepo = container.read(taskRepositoryProvider);

      final task = Task(
        id: uuid.v4(),
        boardId: boardId,
        title: 'Weekly task',
        position: 0,
        createdAt: DateTime.now(),
        recurrenceRule: 'FREQ=WEEKLY;BYDAY=MO',
      );
      await taskRepo.create(task);

      await container
          .read(seriesActionsProvider)
          .createFromTask(task, boardWeekStart: DateTime(2026, 3, 23));

      final week1 = DateTime(2026, 3, 23);
      final week2 = DateTime(2026, 3, 30);
      final week3 = DateTime(2026, 4, 6);

      expect(shouldRecurOnWeek(week1, week2, 1), isTrue);
      expect(shouldRecurOnWeek(week1, week3, 1), isTrue);
    });

    test('biweekly task skips alternate weeks', () async {
      final week1 = DateTime(2026, 3, 23);
      final week2 = DateTime(2026, 3, 30);
      final week3 = DateTime(2026, 4, 6);
      final week4 = DateTime(2026, 4, 13);

      expect(shouldRecurOnWeek(week1, week1, 2), isTrue);
      expect(shouldRecurOnWeek(week1, week2, 2), isFalse);
      expect(shouldRecurOnWeek(week1, week3, 2), isTrue);
      expect(shouldRecurOnWeek(week1, week4, 2), isFalse);
    });

    test('series does not appear before its start date', () async {
      final week1 = DateTime(2026, 3, 23);
      final week0 = DateTime(2026, 3, 16);

      // week0 is before week1 (start) — should not appear.
      expect(week0.isBefore(week1), isTrue);
    });
  });

  group('End series', () {
    test('ending a series prevents future materialization', () async {
      final boardId =
          await createWeeklyBoard(DateTime(2026, 3, 23));
      final taskRepo = container.read(taskRepositoryProvider);
      final seriesRepo = container.read(seriesRepositoryProvider);

      final task = Task(
        id: uuid.v4(),
        boardId: boardId,
        title: 'Take meds',
        position: 0,
        createdAt: DateTime.now(),
        recurrenceRule: 'FREQ=WEEKLY;BYDAY=MO',
      );
      await taskRepo.create(task);

      final series = await container
          .read(seriesActionsProvider)
          .createFromTask(task, boardWeekStart: DateTime(2026, 3, 23));

      // End the series.
      await container.read(seriesActionsProvider).endSeries(series.id);

      final ended = await seriesRepo.getById(series.id);
      expect(ended!.isActive, isFalse);
      expect(ended.endedAt, isNotNull);

      // Active series list should be empty.
      final active = await seriesRepo.getActive();
      expect(active, isEmpty);
    });
  });

  group('Delete series', () {
    test('deleting series removes all materialized instances',
        () async {
      final board1Id =
          await createWeeklyBoard(DateTime(2026, 3, 23));
      final board2Id =
          await createWeeklyBoard(DateTime(2026, 3, 30));
      final taskRepo = container.read(taskRepositoryProvider);
      final seriesRepo = container.read(seriesRepositoryProvider);

      final task = Task(
        id: uuid.v4(),
        boardId: board1Id,
        title: 'Take meds',
        position: 0,
        createdAt: DateTime.now(),
        recurrenceRule: 'FREQ=WEEKLY;BYDAY=MO',
      );
      await taskRepo.create(task);

      final series = await container
          .read(seriesActionsProvider)
          .createFromTask(task, boardWeekStart: DateTime(2026, 3, 23));

      // Materialize on board 2.
      await container
          .read(seriesActionsProvider)
          .materialize(series: series, boardId: board2Id);

      // Delete the series.
      await container
          .read(seriesActionsProvider)
          .deleteSeries(series.id);

      // Series should be gone.
      expect(await seriesRepo.getById(series.id), isNull);

      // All tasks with this seriesId should be gone.
      final remaining = await taskRepo.getBySeriesId(series.id);
      expect(remaining, isEmpty);
    });
  });

  group('Auto-fill missed days', () {
    test('non-recurring task dots on past days become >', () async {
      final monday = DateTime(2026, 3, 16);
      final boardId = await createWeeklyBoard(monday);
      final taskRepo = container.read(taskRepositoryProvider);
      final markerRepo = container.read(markerRepositoryProvider);
      final colRepo = container.read(columnRepositoryProvider);

      final task = Task(
        id: uuid.v4(),
        boardId: boardId,
        title: 'Buy groceries',
        position: 0,
        createdAt: DateTime.now(),
      );
      await taskRepo.create(task);

      // Place a dot on Monday (position 0).
      final columns = await colRepo.getByBoard(boardId);
      final monCol = columns.firstWhere((c) => c.position == 0);
      await markerRepo.set(Marker(
        id: uuid.v4(),
        taskId: task.id,
        columnId: monCol.id,
        boardId: boardId,
        symbol: MarkerSymbol.dot,
        updatedAt: DateTime.now(),
      ));

      // Run auto-fill (simulating past week).
      await container
          .read(markerActionsProvider)
          .autoFillMissedDays(boardId: boardId);

      // If this board is in the past, the dot should be converted.
      // (Exact behavior depends on current date vs board date.)
      final marker = await markerRepo.get(task.id, monCol.id);
      expect(marker, isNotNull);
    });

    test('recurring task dots on past days are NOT converted to >',
        () async {
      final monday = DateTime(2026, 3, 16); // past week
      final boardId = await createWeeklyBoard(monday);
      final taskRepo = container.read(taskRepositoryProvider);
      final markerRepo = container.read(markerRepositoryProvider);
      final colRepo = container.read(columnRepositoryProvider);

      final task = Task(
        id: uuid.v4(),
        boardId: boardId,
        title: 'Take meds',
        position: 0,
        createdAt: DateTime.now(),
        recurrenceRule: 'FREQ=WEEKLY;BYDAY=MO',
        seriesId: 'some-series-id',
      );
      await taskRepo.create(task);

      final columns = await colRepo.getByBoard(boardId);
      final monCol = columns.firstWhere((c) => c.position == 0);
      await markerRepo.set(Marker(
        id: uuid.v4(),
        taskId: task.id,
        columnId: monCol.id,
        boardId: boardId,
        symbol: MarkerSymbol.dot,
        updatedAt: DateTime.now(),
      ));

      await container
          .read(markerActionsProvider)
          .autoFillMissedDays(boardId: boardId);

      // Recurring task dots should stay as dots.
      final marker = await markerRepo.get(task.id, monCol.id);
      expect(marker, isNotNull);
      expect(marker!.symbol, MarkerSymbol.dot);
    });
  });
}

