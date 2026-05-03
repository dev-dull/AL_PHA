import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:planyr/features/board/data/board_repository.dart';
import 'package:planyr/features/board/domain/board.dart';
import 'package:planyr/features/board/domain/board_type.dart';
import 'package:planyr/shared/database.dart';

void main() {
  late PlanyrDatabase db;
  late BoardRepository repo;

  setUp(() {
    db = PlanyrDatabase.forTesting(NativeDatabase.memory());
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

  test('lookup is TZ-stable: storing with one offset and looking up '
      'with another still finds the board (#56)', () async {
    // Simulates the user travel scenario from #56. Pre-fix, a board
    // created in Pacific had its weekStart stored as the local-
    // midnight epoch; the same calendar Monday computed in Eastern
    // produced a different epoch and lookup missed entirely. With
    // UTC-midnight normalization, both representations of the same
    // calendar Monday hit the same stored row.
    await repo.create(Board(
      id: 'b1',
      name: 'Week of Mar 16',
      type: BoardType.weekly,
      // "Pacific Mon midnight" — naive local DateTime that on
      // travel day would have been interpreted with a different
      // offset.
      weekStart: DateTime(2026, 3, 16),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // Lookup expressed as UTC midnight directly.
    final viaUtc =
        await repo.getByWeekStart(DateTime.utc(2026, 3, 16));
    expect(viaUtc?.id, 'b1');

    // Lookup expressed as local midnight — the most common
    // accidental call shape from a `DateTime.now()`-derived
    // computation. Repo normalizes both to UTC and matches.
    final viaLocal =
        await repo.getByWeekStart(DateTime(2026, 3, 16));
    expect(viaLocal?.id, 'b1');
  });

  test('raw DB roundtrip normalizes weekStart to UTC midnight (#56)',
      () async {
    // Pass a TZ-naive local DateTime; the repository normalizes
    // it to UTC midnight of the same calendar date so the stored
    // value is TZ-stable across travel. The corresponding UTC
    // instant is what comes back on read.
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
    expect(board!.weekStart, DateTime.utc(2026, 3, 16));
    expect(board.weekStart!.isUtc, isTrue,
        reason: 'Stored weekStart must be UTC for TZ-stable lookup');
  });
}
