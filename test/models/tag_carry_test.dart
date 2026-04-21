import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:planyr/features/board/domain/board.dart';
import 'package:planyr/features/board/domain/board_type.dart';
import 'package:planyr/features/column/domain/board_column.dart';
import 'package:planyr/features/column/domain/weekly_columns.dart';
import 'package:planyr/features/series/providers/series_providers.dart';
import 'package:planyr/features/tag/domain/tag.dart';
import 'package:planyr/features/task/domain/task.dart';
import 'package:planyr/shared/database.dart';
import 'package:planyr/shared/providers.dart';
import 'package:planyr/shared/week_utils.dart';

/// Reproduces the exact user flow:
/// 1. Create task "Take meds"
/// 2. Set dots on days
/// 3. Edit → set weekly repeat
/// 4. Edit → add tag "Not dead yet"
/// 5. Navigate to next week
/// 6. Verify the tag appears on the materialized task
void main() {
  late PlanyrDatabase db;
  late ProviderContainer container;
  const uuid = Uuid();

  setUp(() {
    db = PlanyrDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [planyrDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() {
    container.dispose();
    db.close();
  });

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

  test('full user flow: create task → tag → recurring → next week has tag',
      () async {
    final board1Id = await createWeeklyBoard(DateTime(2026, 3, 23));
    final board2Id = await createWeeklyBoard(DateTime(2026, 3, 30));

    final taskRepo = container.read(taskRepositoryProvider);
    final tagRepo = container.read(tagRepositoryProvider);
    final taskTagRepo = container.read(taskTagRepositoryProvider);
    final seriesTagRepo = container.read(seriesTagRepositoryProvider);
    final seriesActions = container.read(seriesActionsProvider);

    // 1. Create tag.
    final tagId = uuid.v4();
    await tagRepo.create(Tag(
      id: tagId,
      name: 'Not dead yet',
      color: 0xFF00FF00,
      position: 0,
      createdAt: DateTime.now(),
    ));

    // 2. Create task (not yet recurring).
    final taskId = uuid.v4();
    final task = Task(
      id: taskId,
      boardId: board1Id,
      title: 'Take meds',
      position: 0,
      createdAt: DateTime.now(),
    );
    await taskRepo.create(task);

    // 3. Make it recurring (simulates onSave).
    final updated = task.copyWith(
      recurrenceRule: 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU',
    );
    await taskRepo.update(updated);

    // 4. createFromTask (simulates onSave detecting isRecurring).
    final series = await seriesActions.createFromTask(
      updated,
      boardWeekStart: DateTime(2026, 3, 23),
    );

    // 5. Set tags (simulates onTagsChanged AFTER onSave).
    await taskTagRepo.setTagsForTask(taskId, [tagId]);

    // 6. Re-read task to get seriesId (simulates onTagsChanged logic).
    final reloaded = await taskRepo.getById(taskId);
    expect(reloaded!.seriesId, isNotNull,
        reason: 'Task must have seriesId after createFromTask');

    // 7. Sync tags to series (simulates onTagsChanged).
    await seriesTagRepo.setTagsForSeries(reloaded.seriesId!, [tagId]);

    // Verify series tags are set.
    final sTags = await seriesTagRepo.getTagsForSeries(series.id);
    expect(sTags.length, 1, reason: 'Series must have the tag');

    // 8. Materialize on next week (simulates _materializeVirtualInstances).
    final mat = await seriesActions.materialize(
      series: series,
      boardId: board2Id,
    );

    // 9. Check the materialized task has the tag.
    final matTags = await taskTagRepo.getTagsForTask(mat.id);
    expect(matTags.length, 1,
        reason: 'Materialized task on next week MUST have the tag');
    expect(matTags.first.name, 'Not dead yet');
  });

  test('materialize on board where task already exists without tags',
      () async {
    final board1Id = await createWeeklyBoard(DateTime(2026, 3, 23));
    final board2Id = await createWeeklyBoard(DateTime(2026, 3, 30));

    final taskRepo = container.read(taskRepositoryProvider);
    final tagRepo = container.read(tagRepositoryProvider);
    final taskTagRepo = container.read(taskTagRepositoryProvider);
    final seriesTagRepo = container.read(seriesTagRepositoryProvider);
    final seriesActions = container.read(seriesActionsProvider);

    // Create tag + series.
    final tagId = uuid.v4();
    await tagRepo.create(Tag(
      id: tagId,
      name: 'Health',
      color: 0xFF0000FF,
      position: 0,
      createdAt: DateTime.now(),
    ));

    final task = Task(
      id: uuid.v4(),
      boardId: board1Id,
      title: 'Take meds',
      position: 0,
      createdAt: DateTime.now(),
      recurrenceRule: 'FREQ=WEEKLY;BYDAY=MO',
    );
    await taskRepo.create(task);
    await taskTagRepo.setTagsForTask(task.id, [tagId]);

    final series = await seriesActions.createFromTask(
      task,
      boardWeekStart: DateTime(2026, 3, 23),
    );
    await seriesTagRepo.setTagsForSeries(series.id, [tagId]);

    // Pre-create a task on board2 WITH seriesId but WITHOUT tags
    // (simulates the bug where materialize's safety check
    // returns early).
    final existingTask = Task(
      id: uuid.v4(),
      boardId: board2Id,
      title: 'Take meds',
      position: 0,
      createdAt: DateTime.now(),
      recurrenceRule: 'FREQ=WEEKLY;BYDAY=MO',
      seriesId: series.id,
    );
    await taskRepo.create(existingTask);

    // Now call materialize — it should detect the existing task
    // and STILL ensure it has tags.
    final mat = await seriesActions.materialize(
      series: series,
      boardId: board2Id,
    );

    expect(mat.id, existingTask.id,
        reason: 'Should return the existing task');

    // THIS IS THE BUG: the existing task has no tags.
    final matTags = await taskTagRepo.getTagsForTask(mat.id);
    expect(matTags.length, 1,
        reason: 'Even pre-existing task should get series tags');
  });
}
