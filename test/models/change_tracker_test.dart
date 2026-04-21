import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:planyr/features/board/domain/board.dart';
import 'package:planyr/features/board/domain/board_type.dart';
import 'package:planyr/features/column/domain/board_column.dart';
import 'package:planyr/features/column/domain/weekly_columns.dart';
import 'package:planyr/features/marker/domain/marker.dart';
import 'package:planyr/features/marker/domain/marker_symbol.dart';
import 'package:planyr/features/sync/data/change_tracker.dart';
import 'package:planyr/features/sync/data/sync_meta_repository.dart';
import 'package:planyr/features/task/domain/task.dart';
import 'package:planyr/shared/database.dart';
import 'package:planyr/shared/providers.dart';
import 'package:planyr/shared/week_utils.dart';

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

  /// Helper: creates a board with columns and returns the board ID.
  Future<String> createBoard(DateTime weekStart) async {
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

  group('SyncMeta', () {
    test('stores and retrieves device_id', () async {
      final meta = SyncMetaRepository(db);
      expect(await meta.getDeviceId(), isNull);

      await meta.setDeviceId('test-device-123');
      expect(await meta.getDeviceId(), 'test-device-123');
    });

    test('stores and retrieves last sync time', () async {
      final meta = SyncMetaRepository(db);
      expect(await meta.getLastSyncTime(), isNull);

      final now = DateTime.utc(2026, 4, 1, 12, 0);
      await meta.setLastSyncTime(now);
      final retrieved = await meta.getLastSyncTime();
      expect(retrieved, isNotNull);
      expect(retrieved!.toUtc(), now);
    });

    test('overwrites existing values', () async {
      final meta = SyncMetaRepository(db);
      await meta.setDeviceId('old');
      await meta.setDeviceId('new');
      expect(await meta.getDeviceId(), 'new');
    });
  });

  group('ChangeTracker', () {
    test('returns empty list when no data exists', () async {
      final tracker = ChangeTracker(db);
      final changes = await tracker.getChangesSince(null);
      expect(changes, isEmpty);
    });

    test('detects new board', () async {
      final boardId = await createBoard(DateTime(2026, 3, 30));
      final tracker = ChangeTracker(db);
      final changes = await tracker.getChangesSince(null);

      final boardChanges =
          changes.where((c) => c.table == 'boards').toList();
      expect(boardChanges.length, 1);
      expect(boardChanges.first.id, boardId);
    });

    test('detects new task', () async {
      final boardId = await createBoard(DateTime(2026, 3, 30));
      final taskRepo = container.read(taskRepositoryProvider);

      await taskRepo.create(Task(
        id: uuid.v4(),
        boardId: boardId,
        title: 'Test task',
        position: 0,
        createdAt: DateTime.now(),
      ));

      final tracker = ChangeTracker(db);
      final changes = await tracker.getChangesSince(null);

      final taskChanges =
          changes.where((c) => c.table == 'tasks').toList();
      expect(taskChanges.length, 1);
      expect(taskChanges.first.data['title'], 'Test task');
    });

    test('detects updated task', () async {
      final boardId = await createBoard(DateTime(2026, 3, 30));
      final taskRepo = container.read(taskRepositoryProvider);
      final taskId = uuid.v4();

      // Create task with a timestamp 10 seconds in the past
      // so that the sync point falls between create and update.
      // Drift stores DateTime as epoch seconds, so we need
      // at least 1 second of separation.
      final pastTime = DateTime.now()
          .subtract(const Duration(seconds: 10));
      await db.customStatement(
        'INSERT INTO tasks (id, board_id, title, description, '
        'state, priority, position, created_at, updated_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          taskId, boardId, 'Original', '', 'open', 0, 0,
          pastTime.millisecondsSinceEpoch ~/ 1000,
          pastTime.millisecondsSinceEpoch ~/ 1000,
        ],
      );

      // Sync time: 5 seconds ago (between past create and now).
      final syncTime = DateTime.now()
          .subtract(const Duration(seconds: 5));

      // Update sets updatedAt to DateTime.now() in the repo.
      await taskRepo.update(Task(
        id: taskId,
        boardId: boardId,
        title: 'Updated',
        position: 0,
        createdAt: pastTime,
      ));

      final tracker = ChangeTracker(db);
      final changes = await tracker.getChangesSince(syncTime);

      final taskChanges =
          changes.where((c) => c.table == 'tasks').toList();
      expect(taskChanges.length, 1);
      expect(taskChanges.first.data['title'], 'Updated');
    });

    test('does not return tasks unchanged since last sync', () async {
      final boardId = await createBoard(DateTime(2026, 3, 30));
      final taskRepo = container.read(taskRepositoryProvider);

      await taskRepo.create(Task(
        id: uuid.v4(),
        boardId: boardId,
        title: 'Old task',
        position: 0,
        createdAt: DateTime.now(),
      ));

      // Sync happens now — everything is synced.
      await Future.delayed(const Duration(milliseconds: 10));
      final syncTime = DateTime.now();

      final tracker = ChangeTracker(db);
      final changes = await tracker.getChangesSince(syncTime);

      final taskChanges =
          changes.where((c) => c.table == 'tasks').toList();
      expect(taskChanges, isEmpty,
          reason: 'Task created before sync time should not appear');
    });

    test('detects new markers', () async {
      final boardId = await createBoard(DateTime(2026, 3, 30));
      final taskRepo = container.read(taskRepositoryProvider);
      final markerRepo = container.read(markerRepositoryProvider);
      final colRepo = container.read(columnRepositoryProvider);

      final taskId = uuid.v4();
      await taskRepo.create(Task(
        id: taskId,
        boardId: boardId,
        title: 'With marker',
        position: 0,
        createdAt: DateTime.now(),
      ));

      final cols = await colRepo.getByBoard(boardId);
      await markerRepo.set(Marker(
        id: uuid.v4(),
        taskId: taskId,
        columnId: cols.first.id,
        boardId: boardId,
        symbol: MarkerSymbol.dot,
        updatedAt: DateTime.now(),
      ));

      final tracker = ChangeTracker(db);
      final changes = await tracker.getChangesSince(null);

      final markerChanges =
          changes.where((c) => c.table == 'markers').toList();
      expect(markerChanges.length, 1);
      expect(markerChanges.first.data['symbol'], 'dot');
    });

    test('returns changes in dependency order', () async {
      final boardId = await createBoard(DateTime(2026, 3, 30));
      final taskRepo = container.read(taskRepositoryProvider);

      await taskRepo.create(Task(
        id: uuid.v4(),
        boardId: boardId,
        title: 'Task',
        position: 0,
        createdAt: DateTime.now(),
      ));

      final tracker = ChangeTracker(db);
      final changes = await tracker.getChangesSince(null);

      final tables = changes.map((c) => c.table).toList();
      // Tags before boards, boards before board_columns,
      // board_columns before tasks.
      final boardIdx = tables.indexOf('boards');
      final colIdx = tables.indexOf('board_columns');
      final taskIdx = tables.indexOf('tasks');

      expect(boardIdx, lessThan(colIdx),
          reason: 'Boards must come before board_columns');
      expect(colIdx, lessThan(taskIdx),
          reason: 'Board columns must come before tasks');
    });

    test('includes board columns when board is modified', () async {
      await createBoard(DateTime(2026, 3, 30));

      final tracker = ChangeTracker(db);
      final changes = await tracker.getChangesSince(null);

      final colChanges =
          changes.where((c) => c.table == 'board_columns').toList();
      expect(colChanges.length, 8,
          reason: '7 day columns + 1 migration column');
    });

    test('toJson produces server-compatible format', () async {
      final boardId = await createBoard(DateTime(2026, 3, 30));
      final taskRepo = container.read(taskRepositoryProvider);
      final taskId = uuid.v4();

      await taskRepo.create(Task(
        id: taskId,
        boardId: boardId,
        title: 'JSON test',
        position: 0,
        createdAt: DateTime.now(),
      ));

      final tracker = ChangeTracker(db);
      final changes = await tracker.getChangesSince(null);
      final taskChange =
          changes.firstWhere((c) => c.table == 'tasks');

      final json = taskChange.toJson();
      expect(json['table'], 'tasks');
      expect(json['id'], taskId);
      expect(json['data'], isA<Map>());
      expect(json['updated_at'], isA<String>());
      expect(json['deleted'], false);
    });
  });
}
