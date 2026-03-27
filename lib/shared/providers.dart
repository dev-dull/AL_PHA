import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:alpha/shared/database.dart';
import 'package:alpha/features/board/data/board_repository.dart';
import 'package:alpha/features/task/data/task_repository.dart';
import 'package:alpha/features/column/data/column_repository.dart';
import 'package:alpha/features/marker/data/marker_repository.dart';
import 'package:alpha/features/tag/data/tag_repository.dart';
import 'package:alpha/features/tag/data/task_tag_repository.dart';
import 'package:alpha/features/task/data/task_note_repository.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
AlphaDatabase alphaDatabase(AlphaDatabaseRef ref) {
  throw UnimplementedError(
    'alphaDatabaseProvider must be overridden in ProviderScope',
  );
}

@Riverpod(keepAlive: true)
BoardRepository boardRepository(BoardRepositoryRef ref) {
  final db = ref.watch(alphaDatabaseProvider);
  return BoardRepository(db);
}

@Riverpod(keepAlive: true)
TaskRepository taskRepository(TaskRepositoryRef ref) {
  final db = ref.watch(alphaDatabaseProvider);
  return TaskRepository(db);
}

@Riverpod(keepAlive: true)
ColumnRepository columnRepository(ColumnRepositoryRef ref) {
  final db = ref.watch(alphaDatabaseProvider);
  return ColumnRepository(db);
}

@Riverpod(keepAlive: true)
MarkerRepository markerRepository(MarkerRepositoryRef ref) {
  final db = ref.watch(alphaDatabaseProvider);
  return MarkerRepository(db);
}

@Riverpod(keepAlive: true)
TaskNoteRepository taskNoteRepository(TaskNoteRepositoryRef ref) {
  final db = ref.watch(alphaDatabaseProvider);
  return TaskNoteRepository(db);
}

@Riverpod(keepAlive: true)
TagRepository tagRepository(TagRepositoryRef ref) {
  final db = ref.watch(alphaDatabaseProvider);
  return TagRepository(db);
}

@Riverpod(keepAlive: true)
TaskTagRepository taskTagRepository(TaskTagRepositoryRef ref) {
  final db = ref.watch(alphaDatabaseProvider);
  return TaskTagRepository(db);
}
