import 'package:drift/drift.dart';
import 'package:planyr/shared/database.dart';
import 'package:planyr/features/marker/domain/marker.dart';
import 'package:planyr/features/marker/domain/marker_symbol.dart';

class MarkerRepository {
  final PlanyrDatabase _db;

  MarkerRepository(this._db);

  Marker _rowToMarker(dynamic row) {
    return Marker(
      id: row.id as String,
      taskId: row.taskId as String,
      columnId: row.columnId as String,
      boardId: row.boardId as String,
      symbol: MarkerSymbol.values.byName(row.symbol as String),
      updatedAt: row.updatedAt as DateTime,
    );
  }

  Future<Marker> set(Marker marker) async {
    await _db
        .into(_db.markers)
        .insertOnConflictUpdate(
          MarkersCompanion.insert(
            id: marker.id,
            taskId: marker.taskId,
            columnId: marker.columnId,
            boardId: marker.boardId,
            symbol: marker.symbol.name,
            updatedAt: marker.updatedAt,
          ),
        );
    return marker;
  }

  Future<void> remove(String taskId, String columnId) async {
    await (_db.delete(_db.markers)
          ..where((m) => m.taskId.equals(taskId) & m.columnId.equals(columnId)))
        .go();
  }

  Future<Marker?> get(String taskId, String columnId) async {
    final query = _db.select(_db.markers)
      ..where((m) => m.taskId.equals(taskId) & m.columnId.equals(columnId));
    final row = await query.getSingleOrNull();
    return row != null ? _rowToMarker(row) : null;
  }

  Future<List<Marker>> getByBoard(String boardId) async {
    final query = _db.select(_db.markers)
      ..where((m) => m.boardId.equals(boardId));
    return (await query.get()).map((r) => _rowToMarker(r)).toList();
  }

  Future<List<Marker>> getByTask(String taskId) async {
    final query = _db.select(_db.markers)
      ..where((m) => m.taskId.equals(taskId));
    return (await query.get()).map((r) => _rowToMarker(r)).toList();
  }

  Stream<List<Marker>> watchByBoard(String boardId) {
    final query = _db.select(_db.markers)
      ..where((m) => m.boardId.equals(boardId));
    return query.watch().map(
      (rows) => rows.map((r) => _rowToMarker(r)).toList(),
    );
  }
}
