import 'package:shared_preferences/shared_preferences.dart';
import 'package:alpha/features/preferences/domain/app_preferences.dart';

class PreferencesRepository {
  static const _fontKey = 'pref_font_family';
  static const _themeKey = 'pref_theme_mode';
  static const _firstDayKey = 'pref_first_day_of_week';

  Future<AppPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppPreferences(
      fontFamily: prefs.getString(_fontKey) ?? 'PatrickHand',
      themeModeIndex: prefs.getInt(_themeKey) ?? 0,
      firstDayOfWeek: prefs.getInt(_firstDayKey) ?? DateTime.monday,
    );
  }

  Future<void> save(AppPreferences settings) async {
    final prefs = await SharedPreferences.getInstance();
    if (settings.fontFamily != null) {
      await prefs.setString(_fontKey, settings.fontFamily!);
    } else {
      await prefs.remove(_fontKey);
    }
    await prefs.setInt(_themeKey, settings.themeModeIndex);
    await prefs.setInt(_firstDayKey, settings.firstDayOfWeek);
  }
}
