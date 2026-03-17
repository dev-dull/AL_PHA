// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'board_column.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BoardColumn _$BoardColumnFromJson(Map<String, dynamic> json) => _BoardColumn(
  id: json['id'] as String,
  boardId: json['boardId'] as String,
  label: json['label'] as String,
  position: (json['position'] as num).toInt(),
  type:
      $enumDecodeNullable(_$ColumnTypeEnumMap, json['type']) ??
      ColumnType.custom,
);

Map<String, dynamic> _$BoardColumnToJson(_BoardColumn instance) =>
    <String, dynamic>{
      'id': instance.id,
      'boardId': instance.boardId,
      'label': instance.label,
      'position': instance.position,
      'type': _$ColumnTypeEnumMap[instance.type]!,
    };

const _$ColumnTypeEnumMap = {
  ColumnType.date: 'date',
  ColumnType.context: 'context',
  ColumnType.priority: 'priority',
  ColumnType.custom: 'custom',
};
