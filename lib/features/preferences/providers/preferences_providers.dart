import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:alpha/features/preferences/data/preferences_repository.dart';
import 'package:alpha/features/preferences/domain/app_preferences.dart';

part 'preferences_providers.g.dart';

@Riverpod(keepAlive: true)
class Preferences extends _$Preferences {
  @override
  AppPreferences build() => const AppPreferences();

  Future<void> init() async {
    state = await PreferencesRepository().load();
  }

  Future<void> update(AppPreferences prefs) async {
    await PreferencesRepository().save(prefs);
    state = prefs;
  }
}
