// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Task _$TaskFromJson(Map<String, dynamic> json) => _Task(
  id: json['id'] as String,
  boardId: json['boardId'] as String,
  title: json['title'] as String,
  description: json['description'] as String? ?? '',
  state:
      $enumDecodeNullable(_$TaskStateEnumMap, json['state']) ?? TaskState.open,
  priority: (json['priority'] as num?)?.toInt() ?? 0,
  position: (json['position'] as num).toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
  deadline: json['deadline'] == null
      ? null
      : DateTime.parse(json['deadline'] as String),
  migratedFromBoardId: json['migratedFromBoardId'] as String?,
  migratedFromTaskId: json['migratedFromTaskId'] as String?,
);

Map<String, dynamic> _$TaskToJson(_Task instance) => <String, dynamic>{
  'id': instance.id,
  'boardId': instance.boardId,
  'title': instance.title,
  'description': instance.description,
  'state': _$TaskStateEnumMap[instance.state]!,
  'priority': instance.priority,
  'position': instance.position,
  'createdAt': instance.createdAt.toIso8601String(),
  'completedAt': instance.completedAt?.toIso8601String(),
  'deadline': instance.deadline?.toIso8601String(),
  'migratedFromBoardId': instance.migratedFromBoardId,
  'migratedFromTaskId': instance.migratedFromTaskId,
};

const _$TaskStateEnumMap = {
  TaskState.open: 'open',
  TaskState.inProgress: 'inProgress',
  TaskState.complete: 'complete',
  TaskState.migrated: 'migrated',
  TaskState.cancelled: 'cancelled',
};
