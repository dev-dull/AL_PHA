import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:alpha/features/column/domain/board_column.dart';
import 'package:alpha/shared/providers.dart';

part 'column_providers.g.dart';

@riverpod
Stream<List<BoardColumn>> columnList(ColumnListRef ref, String boardId) {
  final repo = ref.watch(columnRepositoryProvider);
  return repo.watchByBoard(boardId);
}

/// Helper class for column mutations. Access via ref.read.
@riverpod
ColumnActions columnActions(ColumnActionsRef ref) {
  return ColumnActions(ref);
}

class ColumnActions {
  final ColumnActionsRef _ref;

  ColumnActions(this._ref);

  Future<BoardColumn> create(BoardColumn column) async {
    final repo = _ref.read(columnRepositoryProvider);
    return repo.create(column);
  }

  Future<BoardColumn> update(BoardColumn column) async {
    final repo = _ref.read(columnRepositoryProvider);
    return repo.update(column);
  }

  Future<void> reorder(String boardId, List<String> columnIds) async {
    final repo = _ref.read(columnRepositoryProvider);
    await repo.reorder(boardId, columnIds);
  }

  Future<void> delete(String id) async {
    final repo = _ref.read(columnRepositoryProvider);
    await repo.delete(id);
  }
}
