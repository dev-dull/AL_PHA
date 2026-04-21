import 'package:uuid/uuid.dart';
import 'package:planyr/features/board/domain/board.dart';
import 'package:planyr/features/board/domain/board_type.dart';
import 'package:planyr/features/column/domain/board_column.dart';
import 'package:planyr/features/column/domain/column_type.dart';
import 'package:planyr/features/marker/domain/marker.dart';
import 'package:planyr/features/marker/domain/marker_symbol.dart';
import 'package:planyr/features/task/domain/task.dart';
import 'package:planyr/features/task/domain/task_state.dart';

const _uuid = Uuid();

final _now = DateTime(2026, 3, 16, 12, 0);

Board makeBoard({
  String? id,
  String? name,
  BoardType type = BoardType.weekly,
  DateTime? createdAt,
  DateTime? updatedAt,
  bool archived = false,
}) {
  return Board(
    id: id ?? _uuid.v4(),
    name: name ?? 'Test Board',
    type: type,
    createdAt: createdAt ?? _now,
    updatedAt: updatedAt ?? _now,
    archived: archived,
  );
}

Task makeTask({
  String? id,
  String? boardId,
  String? title,
  String description = '',
  TaskState state = TaskState.open,
  int priority = 0,
  int position = 0,
  DateTime? createdAt,
  DateTime? completedAt,
  DateTime? deadline,
  String? migratedFromBoardId,
  String? migratedFromTaskId,
}) {
  return Task(
    id: id ?? _uuid.v4(),
    boardId: boardId ?? 'board-1',
    title: title ?? 'Test Task',
    description: description,
    state: state,
    priority: priority,
    position: position,
    createdAt: createdAt ?? _now,
    completedAt: completedAt,
    deadline: deadline,
    migratedFromBoardId: migratedFromBoardId,
    migratedFromTaskId: migratedFromTaskId,
  );
}

BoardColumn makeColumn({
  String? id,
  String? boardId,
  String? label,
  int position = 0,
  ColumnType type = ColumnType.custom,
}) {
  return BoardColumn(
    id: id ?? _uuid.v4(),
    boardId: boardId ?? 'board-1',
    label: label ?? 'Col ${position + 1}',
    position: position,
    type: type,
  );
}

Marker makeMarker({
  String? id,
  String? taskId,
  String? columnId,
  String? boardId,
  MarkerSymbol symbol = MarkerSymbol.dot,
  DateTime? updatedAt,
}) {
  return Marker(
    id: id ?? _uuid.v4(),
    taskId: taskId ?? 'task-1',
    columnId: columnId ?? 'col-1',
    boardId: boardId ?? 'board-1',
    symbol: symbol,
    updatedAt: updatedAt ?? _now,
  );
}
