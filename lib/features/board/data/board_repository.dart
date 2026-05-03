import 'package:drift/drift.dart';
import 'package:planyr/features/sync/data/tombstone_repository.dart';
import 'package:planyr/shared/database.dart';
import 'package:planyr/features/board/domain/board.dart';
import 'package:planyr/features/board/domain/board_type.dart';

class BoardRepository {
  final PlanyrDatabase _db;
  final TombstoneRepository? _tombstones;

  BoardRepository(this._db, [this._tombstones]);

  Board _boardDataToBoard(dynamic row) {
    final rawWeekStart = row.weekStart as DateTime?;
    return Board(
      id: row.id as String,
      name: row.name as String,
      type: BoardType.values.byName(row.type as String),
      createdAt: row.createdAt as DateTime,
      updatedAt: row.updatedAt as DateTime,
      archived: row.archived as bool,
      // Drift reads DateTime as local — re-stamp as UTC so the
      // weekStart contract (always UTC midnight, #56) survives the
      // round-trip. Same absolute instant, just `isUtc=true`.
      weekStart: rawWeekStart?.toUtc(),
    );
  }

  /// Normalizes a [DateTime] to UTC midnight of its calendar date.
  /// Anything passed as a board's weekStart goes through this so the
  /// stored value is TZ-stable: lookup from a different timezone
  /// still finds the same board (issue #56).
  static DateTime? _normalizeWeekStart(DateTime? d) {
    if (d == null) return null;
    return DateTime.utc(d.year, d.month, d.day);
  }

  Future<Board> create(Board board) async {
    final normalized = _normalizeWeekStart(board.weekStart);
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
            weekStart: Value(normalized),
          ),
        );
    return board.copyWith(weekStart: normalized);
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
    // Normalize to UTC midnight before any equality lookup so
    // callers passing a local DateTime still find the canonical row.
    final ws = _normalizeWeekStart(weekStart)!;
    final exact = await getByPeriodStart(ws, BoardType.weekly);

    final dayBefore = DateTime.utc(ws.year, ws.month, ws.day - 1);
    final dayAfter = DateTime.utc(ws.year, ws.month, ws.day + 1);
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
  /// Tombstones every row so the cloud propagates the deletes.
  Future<void> _deleteBoardCascade(String boardId) async {
    final tombs = _tombstones;
    if (tombs != null) {
      for (final m in await (_db.select(_db.markers)
            ..where((m) => m.boardId.equals(boardId)))
          .get()) {
        await tombs.record('markers', m.id);
      }
      for (final t in await (_db.select(_db.tasks)
            ..where((t) => t.boardId.equals(boardId)))
          .get()) {
        await tombs.record('tasks', t.id);
      }
      for (final c in await (_db.select(_db.boardColumns)
            ..where((c) => c.boardId.equals(boardId)))
          .get()) {
        await tombs.record('board_columns', c.id);
      }
    }
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
    await tombs?.record('boards', boardId);
  }

  Future<Board?> getByPeriodStart(
    DateTime periodStart,
    BoardType type,
  ) async {
    // Stored weekStart is always UTC midnight (#56). Normalize the
    // lookup key the same way so callers passing a local DateTime
    // still match.
    final ws = _normalizeWeekStart(periodStart)!;
    final query = _db.select(_db.boards)
      ..where(
        (b) =>
            b.weekStart.equals(ws) &
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
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> delete(String id) async {
    await (_db.delete(_db.boards)..where((b) => b.id.equals(id))).go();
    await _tombstones?.record('boards', id);
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
