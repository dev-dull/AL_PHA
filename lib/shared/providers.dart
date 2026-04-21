import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:planyr/shared/database.dart';
import 'package:planyr/features/board/data/board_repository.dart';
import 'package:planyr/features/task/data/task_repository.dart';
import 'package:planyr/features/column/data/column_repository.dart';
import 'package:planyr/features/marker/data/marker_repository.dart';
import 'package:planyr/features/series/data/series_repository.dart';
import 'package:planyr/features/series/data/series_tag_repository.dart';
import 'package:planyr/features/tag/data/tag_repository.dart';
import 'package:planyr/features/sync/data/change_tracker.dart';
import 'package:planyr/features/sync/data/sync_meta_repository.dart';
import 'package:planyr/features/tag/data/task_tag_repository.dart';
import 'package:planyr/features/task/data/task_note_repository.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
PlanyrDatabase planyrDatabase(PlanyrDatabaseRef ref) {
  throw UnimplementedError(
    'planyrDatabaseProvider must be overridden in ProviderScope',
  );
}

@Riverpod(keepAlive: true)
BoardRepository boardRepository(BoardRepositoryRef ref) {
  final db = ref.watch(planyrDatabaseProvider);
  return BoardRepository(db);
}

@Riverpod(keepAlive: true)
TaskRepository taskRepository(TaskRepositoryRef ref) {
  final db = ref.watch(planyrDatabaseProvider);
  return TaskRepository(db);
}

@Riverpod(keepAlive: true)
ColumnRepository columnRepository(ColumnRepositoryRef ref) {
  final db = ref.watch(planyrDatabaseProvider);
  return ColumnRepository(db);
}

@Riverpod(keepAlive: true)
MarkerRepository markerRepository(MarkerRepositoryRef ref) {
  final db = ref.watch(planyrDatabaseProvider);
  return MarkerRepository(db);
}

@Riverpod(keepAlive: true)
TaskNoteRepository taskNoteRepository(TaskNoteRepositoryRef ref) {
  final db = ref.watch(planyrDatabaseProvider);
  return TaskNoteRepository(db);
}

@Riverpod(keepAlive: true)
SeriesRepository seriesRepository(SeriesRepositoryRef ref) {
  final db = ref.watch(planyrDatabaseProvider);
  return SeriesRepository(db);
}

@Riverpod(keepAlive: true)
SeriesTagRepository seriesTagRepository(SeriesTagRepositoryRef ref) {
  final db = ref.watch(planyrDatabaseProvider);
  return SeriesTagRepository(db);
}

@Riverpod(keepAlive: true)
TagRepository tagRepository(TagRepositoryRef ref) {
  final db = ref.watch(planyrDatabaseProvider);
  return TagRepository(db);
}

@Riverpod(keepAlive: true)
TaskTagRepository taskTagRepository(TaskTagRepositoryRef ref) {
  final db = ref.watch(planyrDatabaseProvider);
  return TaskTagRepository(db);
}

@Riverpod(keepAlive: true)
SyncMetaRepository syncMetaRepository(SyncMetaRepositoryRef ref) {
  final db = ref.watch(planyrDatabaseProvider);
  return SyncMetaRepository(db);
}

@Riverpod(keepAlive: true)
ChangeTracker changeTracker(ChangeTrackerRef ref) {
  final db = ref.watch(planyrDatabaseProvider);
  return ChangeTracker(db);
}
