// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_series.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RecurringSeries _$RecurringSeriesFromJson(Map<String, dynamic> json) =>
    _RecurringSeries(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      recurrenceRule: json['recurrenceRule'] as String,
      isEvent: json['isEvent'] as bool? ?? false,
      scheduledTime: json['scheduledTime'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      endedAt: json['endedAt'] == null
          ? null
          : DateTime.parse(json['endedAt'] as String),
    );

Map<String, dynamic> _$RecurringSeriesToJson(_RecurringSeries instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'priority': instance.priority,
      'recurrenceRule': instance.recurrenceRule,
      'isEvent': instance.isEvent,
      'scheduledTime': instance.scheduledTime,
      'createdAt': instance.createdAt.toIso8601String(),
      'endedAt': instance.endedAt?.toIso8601String(),
    };
