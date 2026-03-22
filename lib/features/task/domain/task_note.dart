import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_note.freezed.dart';
part 'task_note.g.dart';

@freezed
abstract class TaskNote with _$TaskNote {
  const factory TaskNote({
    required String id,
    required String taskId,
    required String content,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _TaskNote;

  factory TaskNote.fromJson(Map<String, dynamic> json) =>
      _$TaskNoteFromJson(json);
}
