import 'package:drift/drift.dart';
import 'package:alpha/shared/database.dart';
import 'package:alpha/features/board/domain/board.dart';
import 'package:alpha/features/board/domain/board_type.dart';

class BoardRepository {
  final AlphaDatabase _db;

  BoardRepository(this._db);

  Board _boardDataToBoard(dynamic row) {
    return Board(
      id: row.id as String,
      name: row.name as String,
      type: BoardType.values.byName(row.type as String),
      createdAt: row.createdAt as DateTime,
      updatedAt: row.updatedAt as DateTime,
      archived: row.archived as bool,
      weekStart: row.weekStart as DateTime?,
    );
  }

  Future<Board> create(Board board) async {
    await _db
        .into(_db.boards)
        .insert(
          BoardsCompanion.insert(
            id: board.id,
            name: board.name,
            type: board.type.name,
            createdAt: board.createdAt,
            updatedAt: board.updatedAt,
            archived: Value(board.archived),
            weekStart: Value(board.weekStart),
          ),
        );
    return board;
  }

  /// Looks up a weekly board that overlaps the week starting at
  /// [weekStart].
  ///
  /// First tries an exact match. If none is found, scans all
  /// non-archived weekly boards for one whose stored weekStart
  /// is within 6 days of the requested date. This handles boards
  /// created under a different first-day-of-week preference.
  /// Finds a weekly board that covers the same calendar week as
  /// [weekStart]. Handles boards created under a different
  /// first-day-of-week convention by checking ±1 day.
  Future<Board?> getByWeekStart(DateTime weekStart) async {
    final exact = await getByPeriodStart(weekStart, BoardType.weekly);

    final dayBefore = DateTime(
      weekStart.year, weekStart.month, weekStart.day - 1);
    final dayAfter = DateTime(
      weekStart.year, weekStart.month, weekStart.day + 1);
    final neighbor =
        await getByPeriodStart(dayBefore, BoardType.weekly) ??
        await getByPeriodStart(dayAfter, BoardType.weekly);

    if (exact == null) return neighbor;
    if (neighbor == null) return exact;

    // Both exist (duplicate from a previous first-day switch).
    // Prefer whichever has tasks; delete the empty duplicate.
    final exactQuery = _db.select(_db.tasks)
      ..where((t) => t.boardId.equals(exact.id));
    final neighborQuery = _db.select(_db.tasks)
      ..where((t) => t.boardId.equals(neighbor.id));
    final exactCount = (await exactQuery.get()).length;
    final neighborCount = (await neighborQuery.get()).length;

    if (exactCount >= neighborCount) {
      await _deleteBoardCascade(neighbor.id);
      return exact;
    } else {
      await _deleteBoardCascade(exact.id);
      return neighbor;
    }
  }

  /// Removes a board and all its columns, markers, and tasks.
  Future<void> _deleteBoardCascade(String boardId) async {
    await (_db.delete(_db.markers)
          ..where((m) => m.boardId.equals(boardId)))
        .go();
    await (_db.delete(_db.tasks)
          ..where((t) => t.boardId.equals(boardId)))
        .go();
    await (_db.delete(_db.boardColumns)
          ..where((c) => c.boardId.equals(boardId)))
        .go();
    await (_db.delete(_db.boards)
          ..where((b) => b.id.equals(boardId)))
        .go();
  }

  Future<Board?> getByPeriodStart(
    DateTime periodStart,
    BoardType type,
  ) async {
    final query = _db.select(_db.boards)
      ..where(
        (b) =>
            b.weekStart.equals(periodStart) &
            b.type.equals(type.name) &
            b.archived.equals(false),
      );
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return _boardDataToBoard(row);
  }

  Future<Board?> getById(String id) async {
    final query = _db.select(_db.boards)..where((b) => b.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return _boardDataToBoard(row);
  }

  Future<List<Board>> listAll({bool includeArchived = false}) async {
    final query = _db.select(_db.boards);
    if (!includeArchived) {
      query.where((b) => b.archived.equals(false));
    }
    final rows = await query.get();
    return rows.map((r) => _boardDataToBoard(r)).toList();
  }

  Future<Board> update(Board board) async {
    await (_db.update(_db.boards)..where((b) => b.id.equals(board.id))).write(
      BoardsCompanion(
        name: Value(board.name),
        type: Value(board.type.name),
        updatedAt: Value(board.updatedAt),
        archived: Value(board.archived),
      ),
    );
    return board;
  }

  Future<void> archive(String id) async {
    await (_db.update(_db.boards)..where((b) => b.id.equals(id))).write(
      BoardsCompanion(
        archived: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> delete(String id) async {
    await (_db.delete(_db.boards)..where((b) => b.id.equals(id))).go();
  }

  Stream<List<Board>> watchAll({bool includeArchived = false}) {
    final query = _db.select(_db.boards);
    if (!includeArchived) {
      query.where((b) => b.archived.equals(false));
    }
    return query.watch().map(
      (rows) => rows.map((r) => _boardDataToBoard(r)).toList(),
    );
  }
}
