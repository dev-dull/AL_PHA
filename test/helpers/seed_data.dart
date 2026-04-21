import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:planyr/features/board/domain/board.dart';
import 'package:planyr/features/board/providers/board_providers.dart';
import 'package:planyr/features/column/domain/board_column.dart';
import 'package:planyr/features/column/providers/column_providers.dart';
import 'package:planyr/features/marker/domain/marker.dart';
import 'package:planyr/features/task/domain/task.dart';
import 'package:planyr/features/task/providers/task_providers.dart';
import 'package:planyr/shared/providers.dart';

Future<Board> seedBoard(
  ProviderContainer container, {
  required Board board,
}) async {
  return container.read(boardActionsProvider).create(board);
}

Future<Task> seedTask(ProviderContainer container, {required Task task}) async {
  return container.read(taskActionsProvider).create(task);
}

Future<BoardColumn> seedColumn(
  ProviderContainer container, {
  required BoardColumn column,
}) async {
  return container.read(columnActionsProvider).create(column);
}

Future<Marker> seedMarker(
  ProviderContainer container, {
  required Marker marker,
}) async {
  final repo = container.read(markerRepositoryProvider);
  await repo.set(marker);
  return marker;
}
