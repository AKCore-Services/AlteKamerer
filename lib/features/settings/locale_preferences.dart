import 'package:shared_preferences/shared_preferences.dart';

enum AppLocalePreference {
  system('system'),
  swedish('sv'),
  english('en');

  const AppLocalePreference(this.storageValue);

  final String storageValue;

  static AppLocalePreference fromStorage(String? value) {
    return switch (value) {
      'sv' => AppLocalePreference.swedish,
      'en' => AppLocalePreference.english,
      _ => AppLocalePreference.system,
    };
  }
}

abstract interface class LocalePreferences {
  Future<AppLocalePreference> getLocalePreference();

  Future<void> setLocalePreference(AppLocalePreference preference);
}

class SharedPreferencesLocalePreferences implements LocalePreferences {
  SharedPreferencesLocalePreferences(this._preferences);

  static const _localePreferenceKey = 'locale_preference';

  final SharedPreferences _preferences;

  @override
  Future<AppLocalePreference> getLocalePreference() async {
    return AppLocalePreference.fromStorage(
      _preferences.getString(_localePreferenceKey),
    );
  }

  @override
  Future<void> setLocalePreference(AppLocalePreference preference) async {
    await _preferences.setString(_localePreferenceKey, preference.storageValue);
  }
}
