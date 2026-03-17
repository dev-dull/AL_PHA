// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'board_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BoardTemplate _$BoardTemplateFromJson(Map<String, dynamic> json) =>
    _BoardTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      boardType: $enumDecode(_$BoardTypeEnumMap, json['boardType']),
      columns: (json['columns'] as List<dynamic>)
          .map((e) => TemplateColumn.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BoardTemplateToJson(_BoardTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'boardType': _$BoardTypeEnumMap[instance.boardType]!,
      'columns': instance.columns,
    };

const _$BoardTypeEnumMap = {
  BoardType.daily: 'daily',
  BoardType.weekly: 'weekly',
  BoardType.monthly: 'monthly',
  BoardType.yearly: 'yearly',
  BoardType.custom: 'custom',
};

_TemplateColumn _$TemplateColumnFromJson(Map<String, dynamic> json) =>
    _TemplateColumn(
      label: json['label'] as String,
      position: (json['position'] as num).toInt(),
      type:
          $enumDecodeNullable(_$ColumnTypeEnumMap, json['type']) ??
          ColumnType.custom,
    );

Map<String, dynamic> _$TemplateColumnToJson(_TemplateColumn instance) =>
    <String, dynamic>{
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
