import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:planyr/features/task/domain/task_state.dart';

part 'task.freezed.dart';
part 'task.g.dart';

@freezed
abstract class Task with _$Task {
  const Task._();

  const factory Task({
    required String id,
    required String boardId,
    required String title,
    @Default('') String description,
    @Default(TaskState.open) TaskState state,
    @Default(0) int priority,
    required int position,
    required DateTime createdAt,
    DateTime? completedAt,
    DateTime? deadline,
    String? migratedFromBoardId,
    String? migratedFromTaskId,
    @Default(false) bool isEvent,
    /// Stored as "HH:mm" (24-hour format), e.g. "14:30".
    String? scheduledTime,
    /// iCal RRULE string, e.g. "FREQ=WEEKLY;BYDAY=MO,WE,FR".
    String? recurrenceRule,
    /// Links this task to a RecurringSeries for virtual instance support.
    String? seriesId,
  }) = _Task;

  /// Whether this task has an active recurrence schedule.
  bool get isRecurring =>
      recurrenceRule != null && recurrenceRule!.contains('FREQ=');

  /// Whether this task is a materialized instance of a series.
  bool get isSeriesInstance => seriesId != null;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
}
