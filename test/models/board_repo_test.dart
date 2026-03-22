import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alpha/features/board/data/board_repository.dart';
import 'package:alpha/features/board/domain/board.dart';
import 'package:alpha/features/board/domain/board_type.dart';
import 'package:alpha/shared/database.dart';

void main() {
  late AlphaDatabase db;
  late BoardRepository repo;

  setUp(() {
    db = AlphaDatabase.forTesting(NativeDatabase.memory());
    repo = BoardRepository(db);
  });

  tearDown(() => db.close());

  test('getByPeriodStart finds exact match', () async {
    final monday = DateTime(2026, 3, 16);
    await repo.create(Board(
      id: 'b1',
      name: 'Week of Mar 16',
      type: BoardType.weekly,
      weekStart: monday,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    final found = await repo.getByPeriodStart(monday, BoardType.weekly);
    expect(found, isNotNull);
    expect(found!.id, 'b1');
  });

  test('getByPeriodStart finds board with DateTime(y,m,d+1)', () async {
    final monday = DateTime(2026, 3, 16);
    await repo.create(Board(
      id: 'b1',
      name: 'Week of Mar 16',
      type: BoardType.weekly,
      weekStart: monday,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // Query with DateTime(2026, 3, 15 + 1) which should equal
    // DateTime(2026, 3, 16).
    final dayAfterSunday = DateTime(2026, 3, 15 + 1);
    expect(monday, dayAfterSunday);

    final found = await repo.getByPeriodStart(
      dayAfterSunday,
      BoardType.weekly,
    );
    expect(found, isNotNull, reason: 'DateTime(2026,3,16) should match');
    expect(found!.id, 'b1');
  });

  test('getByWeekStart fallback finds ±1 day board', () async {
    final monday = DateTime(2026, 3, 16);
    await repo.create(Board(
      id: 'b1',
      name: 'Week of Mar 16',
      type: BoardType.weekly,
      weekStart: monday,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // Query for Sunday (1 day before Monday).
    final sunday = DateTime(2026, 3, 15);
    final found = await repo.getByWeekStart(sunday);
    expect(found, isNotNull,
        reason: 'Should find Monday board via ±1 day fallback');
    expect(found!.id, 'b1');
  });

  test('raw DB roundtrip preserves DateTime', () async {
    final monday = DateTime(2026, 3, 16);
    await repo.create(Board(
      id: 'b1',
      name: 'test',
      type: BoardType.weekly,
      weekStart: monday,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    final board = await repo.getById('b1');
    expect(board, isNotNull);
    expect(board!.weekStart, monday);
    expect(board.weekStart?.millisecondsSinceEpoch,
        monday.millisecondsSinceEpoch);
  });
}
