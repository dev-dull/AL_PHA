import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:alpha/features/board/domain/board.dart';
import 'package:alpha/shared/providers.dart';

part 'board_providers.g.dart';

@riverpod
Stream<List<Board>> boardList(BoardListRef ref) {
  final repo = ref.watch(boardRepositoryProvider);
  return repo.watchAll();
}

@riverpod
Future<Board?> board(BoardRef ref, String boardId) async {
  final repo = ref.watch(boardRepositoryProvider);
  return repo.getById(boardId);
}

/// Helper class for board mutations. Access via ref.read.
@riverpod
BoardActions boardActions(BoardActionsRef ref) {
  return BoardActions(ref);
}

class BoardActions {
  final BoardActionsRef _ref;

  BoardActions(this._ref);

  Future<Board> create(Board board) async {
    final repo = _ref.read(boardRepositoryProvider);
    return repo.create(board);
  }

  Future<void> archive(String id) async {
    final repo = _ref.read(boardRepositoryProvider);
    await repo.archive(id);
  }

  Future<void> delete(String id) async {
    final repo = _ref.read(boardRepositoryProvider);
    await repo.delete(id);
  }
}
