import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_preferences.freezed.dart';
part 'app_preferences.g.dart';

@freezed
abstract class AppPreferences with _$AppPreferences {
  const factory AppPreferences({
    /// Font family name, or null for system default.
    @Default('PatrickHand') String? fontFamily,

    /// 0 = system, 1 = light, 2 = dark.
    @Default(0) int themeModeIndex,

    /// First day of the week: 1 = Monday, 7 = Sunday.
    @Default(DateTime.monday) int firstDayOfWeek,
  }) = _AppPreferences;

  const AppPreferences._();

  ThemeMode get themeMode {
    switch (themeModeIndex) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  factory AppPreferences.fromJson(Map<String, dynamic> json) =>
      _$AppPreferencesFromJson(json);
}
