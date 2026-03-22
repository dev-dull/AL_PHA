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
  Future<Board?> getByWeekStart(DateTime weekStart) async {
    // Collect all non-archived weekly boards within 1 day of the
    // target (covers Monday↔Sunday shift). Then pick the best one.
    final query = _db.select(_db.boards)
      ..where(
        (b) =>
            b.type.equals(BoardType.weekly.name) &
            b.archived.equals(false),
      );
    final rows = await query.get();
    final targetMs = weekStart.millisecondsSinceEpoch;
    const oneDay = 24 * 60 * 60 * 1000;

    final candidates = <BoardRow>[];
    for (final row in rows) {
      final ws = row.weekStart;
      if (ws == null) continue;
      if ((ws.millisecondsSinceEpoch - targetMs).abs() <= oneDay) {
        candidates.add(row);
      }
    }

    if (candidates.isEmpty) return null;
    if (candidates.length == 1) return _boardDataToBoard(candidates.first);

    // Multiple boards within 1 day (e.g. an empty Sunday board and
    // a Monday board with tasks from before a first-day switch).
    // Prefer the one that has tasks.
    for (final row in candidates) {
      final taskQuery = _db.select(_db.tasks)
        ..where((t) => t.boardId.equals(row.id))
        ..limit(1);
      final hasTask = await taskQuery.getSingleOrNull();
      if (hasTask != null) return _boardDataToBoard(row);
    }
    // All empty — return the exact match or first candidate.
    final exact = candidates.where(
      (r) => r.weekStart?.millisecondsSinceEpoch == targetMs,
    );
    return _boardDataToBoard(
      exact.isNotEmpty ? exact.first : candidates.first,
    );
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
