// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'board.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Board _$BoardFromJson(Map<String, dynamic> json) => _Board(
  id: json['id'] as String,
  name: json['name'] as String,
  type: $enumDecode(_$BoardTypeEnumMap, json['type']),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  archived: json['archived'] as bool? ?? false,
);

Map<String, dynamic> _$BoardToJson(_Board instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'type': _$BoardTypeEnumMap[instance.type]!,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'archived': instance.archived,
};

const _$BoardTypeEnumMap = {
  BoardType.daily: 'daily',
  BoardType.weekly: 'weekly',
  BoardType.monthly: 'monthly',
  BoardType.yearly: 'yearly',
  BoardType.custom: 'custom',
};
