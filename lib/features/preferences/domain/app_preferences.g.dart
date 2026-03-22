// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppPreferences _$AppPreferencesFromJson(Map<String, dynamic> json) =>
    _AppPreferences(
      fontFamily: json['fontFamily'] as String? ?? 'PatrickHand',
      themeModeIndex: (json['themeModeIndex'] as num?)?.toInt() ?? 0,
      firstDayOfWeek:
          (json['firstDayOfWeek'] as num?)?.toInt() ?? DateTime.monday,
    );

Map<String, dynamic> _$AppPreferencesToJson(_AppPreferences instance) =>
    <String, dynamic>{
      'fontFamily': instance.fontFamily,
      'themeModeIndex': instance.themeModeIndex,
      'firstDayOfWeek': instance.firstDayOfWeek,
    };
