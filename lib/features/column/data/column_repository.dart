import 'package:drift/drift.dart';
import 'package:planyr/shared/database.dart';
import 'package:planyr/features/column/domain/board_column.dart';
import 'package:planyr/features/column/domain/column_type.dart';

class ColumnRepository {
  final PlanyrDatabase _db;

  ColumnRepository(this._db);

  BoardColumn _rowToColumn(dynamic row) {
    return BoardColumn(
      id: row.id as String,
      boardId: row.boardId as String,
      label: row.label as String,
      position: row.position as int,
      type: ColumnType.values.byName(row.type as String),
    );
  }

  Future<BoardColumn> create(BoardColumn column) async {
    await _db
        .into(_db.boardColumns)
        .insert(
          BoardColumnsCompanion.insert(
            id: column.id,
            boardId: column.boardId,
            label: column.label,
            position: column.position,
            type: Value(column.type.name),
          ),
        );
    return column;
  }

  Future<List<BoardColumn>> getByBoard(String boardId) async {
    final query = _db.select(_db.boardColumns)
      ..where((c) => c.boardId.equals(boardId))
      ..orderBy([(c) => OrderingTerm.asc(c.position)]);
    return (await query.get()).map((r) => _rowToColumn(r)).toList();
  }

  Future<BoardColumn> update(BoardColumn column) async {
    await (_db.update(
      _db.boardColumns,
    )..where((c) => c.id.equals(column.id))).write(
      BoardColumnsCompanion(
        label: Value(column.label),
        position: Value(column.position),
        type: Value(column.type.name),
      ),
    );
    return column;
  }

  Future<void> reorder(String boardId, List<String> columnIds) async {
    await _db.transaction(() async {
      for (var i = 0; i < columnIds.length; i++) {
        await (_db.update(_db.boardColumns)
              ..where((c) => c.id.equals(columnIds[i])))
            .write(BoardColumnsCompanion(position: Value(i)));
      }
    });
  }

  Future<void> delete(String id) async {
    await (_db.delete(_db.boardColumns)..where((c) => c.id.equals(id))).go();
  }

  Future<int> getNextPosition(String boardId) async {
    final query = _db.select(_db.boardColumns)
      ..where((c) => c.boardId.equals(boardId))
      ..orderBy([(c) => OrderingTerm.desc(c.position)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return (row?.position ?? -1) + 1;
  }

  Stream<List<BoardColumn>> watchByBoard(String boardId) {
    final query = _db.select(_db.boardColumns)
      ..where((c) => c.boardId.equals(boardId))
      ..orderBy([(c) => OrderingTerm.asc(c.position)]);
    return query.watch().map(
      (rows) => rows.map((r) => _rowToColumn(r)).toList(),
    );
  }
}
