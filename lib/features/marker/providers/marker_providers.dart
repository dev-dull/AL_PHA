import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:alpha/features/marker/domain/marker.dart';
import 'package:alpha/features/marker/domain/marker_symbol.dart';
import 'package:alpha/shared/providers.dart';

part 'marker_providers.g.dart';

@riverpod
Stream<Map<String, Marker>> markersByBoard(
  MarkersByBoardRef ref,
  String boardId,
) {
  final repo = ref.watch(markerRepositoryProvider);
  return repo.watchByBoard(boardId).map((markers) {
    return {
      for (final m in markers) '${m.taskId}_${m.columnId}': m,
    };
  });
}

@riverpod
Marker? marker(MarkerRef ref, String taskId, String columnId) {
  // Find the boardId from the marker repository is not possible
  // without knowing it. Instead, we return null as a fallback —
  // callers should use markerFromBoard for efficiency.
  return null;
}

/// Derived provider for a single cell marker, keyed off the
/// board-level markers map for granular rebuilds.
@riverpod
Marker? markerFromBoard(
  MarkerFromBoardRef ref,
  String boardId,
  String taskId,
  String columnId,
) {
  final markersAsync = ref.watch(markersByBoardProvider(boardId));
  return markersAsync.whenOrNull(
    data: (markers) => markers['${taskId}_$columnId'],
  );
}

/// Helper class for marker mutations. Access via ref.read.
@riverpod
MarkerActions markerActions(MarkerActionsRef ref) {
  return MarkerActions(ref);
}

class MarkerActions {
  final MarkerActionsRef _ref;
  static const _uuid = Uuid();

  MarkerActions(this._ref);

  /// Cycles a marker: empty -> DOT -> CIRCLE -> X -> empty.
  Future<void> cycleMarker({
    required String boardId,
    required String taskId,
    required String columnId,
  }) async {
    final repo = _ref.read(markerRepositoryProvider);
    final existing = await repo.get(taskId, columnId);

    if (existing == null) {
      // Empty -> DOT
      await repo.set(Marker(
        id: _uuid.v4(),
        taskId: taskId,
        columnId: columnId,
        boardId: boardId,
        symbol: MarkerSymbol.cycleStart,
        updatedAt: DateTime.now(),
      ));
    } else {
      final next = existing.symbol.nextInCycle;
      if (next == null) {
        // Back to empty
        await repo.remove(taskId, columnId);
      } else {
        await repo.set(existing.copyWith(
          symbol: next,
          updatedAt: DateTime.now(),
        ));
      }
    }
  }
}
