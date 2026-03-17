import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alpha/features/board/domain/board.dart';
import 'package:alpha/features/board/providers/board_providers.dart';
import 'package:alpha/features/column/domain/board_column.dart';
import 'package:alpha/features/column/providers/column_providers.dart';
import 'package:alpha/features/marker/domain/marker.dart';
import 'package:alpha/features/task/domain/task.dart';
import 'package:alpha/features/task/providers/task_providers.dart';
import 'package:alpha/shared/providers.dart';

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
