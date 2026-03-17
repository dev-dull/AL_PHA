import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:alpha/features/task/domain/task_state.dart';

part 'task.freezed.dart';
part 'task.g.dart';

@freezed
abstract class Task with _$Task {
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
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
}
