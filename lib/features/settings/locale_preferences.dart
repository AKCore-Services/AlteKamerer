// -----------------------------------------------------------------------------
// locale_preferences.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Defines the supported language preferences and their
//   persistent storage representation.
//
// -----------------------------------------------------------------------------

import 'package:shared_preferences/shared_preferences.dart';

/// Application language selection, including the device default.
///
/// Unknown stored values fall back to [AppLocalePreference.system].
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

/// Contract for loading and saving the application language.
abstract interface class LocalePreferences {
  Future<AppLocalePreference> getLocalePreference();

  Future<void> setLocalePreference(AppLocalePreference preference);
}

/// Stores the language preference using shared preferences.
///
/// An absent or unrecognized stored value selects the system language.
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
