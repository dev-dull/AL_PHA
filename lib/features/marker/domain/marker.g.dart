// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'marker.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Marker _$MarkerFromJson(Map<String, dynamic> json) => _Marker(
  id: json['id'] as String,
  taskId: json['taskId'] as String,
  columnId: json['columnId'] as String,
  boardId: json['boardId'] as String,
  symbol: $enumDecode(_$MarkerSymbolEnumMap, json['symbol']),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$MarkerToJson(_Marker instance) => <String, dynamic>{
  'id': instance.id,
  'taskId': instance.taskId,
  'columnId': instance.columnId,
  'boardId': instance.boardId,
  'symbol': _$MarkerSymbolEnumMap[instance.symbol]!,
  'updatedAt': instance.updatedAt.toIso8601String(),
};

const _$MarkerSymbolEnumMap = {
  MarkerSymbol.dot: 'dot',
  MarkerSymbol.slash: 'slash',
  MarkerSymbol.x: 'x',
  MarkerSymbol.migratedForward: 'migratedForward',
  MarkerSymbol.doneEarly: 'doneEarly',
  MarkerSymbol.event: 'event',
};
