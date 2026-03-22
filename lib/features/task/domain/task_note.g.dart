// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_note.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TaskNote _$TaskNoteFromJson(Map<String, dynamic> json) => _TaskNote(
  id: json['id'] as String,
  taskId: json['taskId'] as String,
  content: json['content'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$TaskNoteToJson(_TaskNote instance) => <String, dynamic>{
  'id': instance.id,
  'taskId': instance.taskId,
  'content': instance.content,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};
