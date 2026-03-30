import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:alpha/features/column/domain/column_type.dart';
import 'package:alpha/features/marker/domain/marker.dart';
import 'package:alpha/features/marker/domain/marker_symbol.dart';
import 'package:alpha/features/series/domain/recurring_series.dart';
import 'package:alpha/features/task/domain/recurrence.dart';
import 'package:alpha/features/task/domain/task.dart';
import 'package:alpha/shared/providers.dart';

part 'series_providers.g.dart';

@riverpod
Stream<List<RecurringSeries>> activeSeries(ActiveSeriesRef ref) {
  return ref.watch(seriesRepositoryProvider).watchActive();
}

@riverpod
SeriesActions seriesActions(SeriesActionsRef ref) =>
    SeriesActions(ref);

class SeriesActions {
  final SeriesActionsRef _ref;
  static const _uuid = Uuid();

  SeriesActions(this._ref);

  /// Creates a new recurring series from a task's properties.
  /// [boardWeekStart] anchors the interval calculation — the
  /// series will appear on weeks that are a multiple of the
  /// interval away from this date.
  Future<RecurringSeries> createFromTask(
    Task task, {
    DateTime? boardWeekStart,
  }) async {
    final repo = _ref.read(seriesRepositoryProvider);
    final series = RecurringSeries(
      id: _uuid.v4(),
      title: task.title,
      description: task.description,
      priority: task.priority,
      recurrenceRule: task.recurrenceRule!,
      isEvent: task.isEvent,
      scheduledTime: task.scheduledTime,
      createdAt: boardWeekStart ?? DateTime.now(),
    );
    await repo.create(series);

    // Copy task tags to series tags.
    final taskTagRepo = _ref.read(taskTagRepositoryProvider);
    final seriesTagRepo = _ref.read(seriesTagRepositoryProvider);
    final tags = await taskTagRepo.getTagsForTask(task.id);
    if (tags.isNotEmpty) {
      await seriesTagRepo.setTagsForSeries(
        series.id,
        tags.map((t) => t.id).toList(),
      );
    }

    // Link the task to the series.
    final taskRepo = _ref.read(taskRepositoryProvider);
    await taskRepo.update(task.copyWith(seriesId: series.id));

    return series;
  }

  /// Materializes a virtual series instance as a real Task on
  /// the given board. Returns the new or existing Task.
  Future<Task> materialize({
    required RecurringSeries series,
    required String boardId,
  }) async {
    final taskRepo = _ref.read(taskRepositoryProvider);

    // Safety check: don't create a duplicate if already materialized.
    final existing = await taskRepo.getByBoard(boardId);
    final alreadyExists = existing.any(
      (t) => t.seriesId == series.id || t.title == series.title,
    );
    if (alreadyExists) {
      return existing.firstWhere(
        (t) => t.seriesId == series.id || t.title == series.title,
      );
    }

    final markerRepo = _ref.read(markerRepositoryProvider);
    final columnRepo = _ref.read(columnRepositoryProvider);
    final taskTagRepo = _ref.read(taskTagRepositoryProvider);
    final seriesTagRepo = _ref.read(seriesTagRepositoryProvider);

    final existingTasks = await taskRepo.getByBoard(boardId);
    final taskId = _uuid.v4();
    final now = DateTime.now();

    final task = Task(
      id: taskId,
      boardId: boardId,
      title: series.title,
      description: series.description,
      priority: series.priority,
      position: existingTasks.length,
      createdAt: now,
      isEvent: series.isEvent,
      scheduledTime: series.scheduledTime,
      recurrenceRule: series.recurrenceRule,
      seriesId: series.id,
    );

    await taskRepo.create(task);

    // Place markers on scheduled days.
    final (_, days) = parseRRule(series.recurrenceRule);
    if (days.isNotEmpty) {
      final columns = await columnRepo.getByBoard(boardId);
      final sym = series.isEvent
          ? MarkerSymbol.event
          : MarkerSymbol.dot;
      for (final col in columns) {
        if (col.type == ColumnType.date &&
            days.contains(col.position)) {
          await markerRepo.set(
            Marker(
              id: _uuid.v4(),
              taskId: taskId,
              columnId: col.id,
              boardId: boardId,
              symbol: sym,
              updatedAt: now,
            ),
          );
        }
      }
    }

    // Copy series tags to task tags.
    final seriesTags =
        await seriesTagRepo.getTagsForSeries(series.id);
    if (seriesTags.isNotEmpty) {
      await taskTagRepo.setTagsForTask(
        taskId,
        seriesTags.map((t) => t.id).toList(),
      );
    }

    return task;
  }

  /// Updates the series definition. All future virtual instances
  /// automatically reflect the change.
  Future<void> updateSeries(RecurringSeries updated,
      {List<String>? tagIds}) async {
    final repo = _ref.read(seriesRepositoryProvider);
    await repo.update(updated);
    if (tagIds != null) {
      final seriesTagRepo = _ref.read(seriesTagRepositoryProvider);
      await seriesTagRepo.setTagsForSeries(updated.id, tagIds);
    }
  }

  /// Ends the series — no new virtual instances will be generated.
  Future<void> endSeries(String seriesId) async {
    await _ref.read(seriesRepositoryProvider).end(seriesId);
  }

  /// Deletes the series and all materialized instances.
  Future<void> deleteSeries(String seriesId) async {
    final taskRepo = _ref.read(taskRepositoryProvider);
    final noteRepo = _ref.read(taskNoteRepositoryProvider);
    final taskTagRepo = _ref.read(taskTagRepositoryProvider);

    // Delete all materialized instances.
    final instances = await taskRepo.getBySeriesId(seriesId);
    for (final inst in instances) {
      await noteRepo.deleteByTask(inst.id);
      await taskTagRepo.deleteByTask(inst.id);
      await taskRepo.delete(inst.id);
    }

    // Delete the series itself.
    await _ref.read(seriesRepositoryProvider).delete(seriesId);
  }
}
