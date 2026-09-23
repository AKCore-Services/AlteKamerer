import 'package:flutter/material.dart';

import 'locale_preferences.dart';

class LocaleController extends ChangeNotifier {
  LocaleController(this._preferences);

  final LocalePreferences _preferences;

  AppLocalePreference _preference = AppLocalePreference.system;

  AppLocalePreference get preference => _preference;

  Locale? get locale {
    return switch (_preference) {
      AppLocalePreference.system => null,
      AppLocalePreference.swedish => const Locale('sv'),
      AppLocalePreference.english => const Locale('en'),
    };
  }

  Future<void> load() async {
    _preference = await _preferences.getLocalePreference();
    notifyListeners();
  }

  Future<void> setPreference(AppLocalePreference preference) async {
    if (_preference == preference) {
      return;
    }

    await _preferences.setLocalePreference(preference);
    _preference = preference;
    notifyListeners();
  }
}
