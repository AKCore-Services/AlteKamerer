// -----------------------------------------------------------------------------
// locale_controller.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Coordinates the selected application language and exposes
//   the locale used by the root Flutter application.
//
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import 'locale_preferences.dart';

/// Manages the application's persisted language preference.
///
/// Exposes a Flutter [Locale] for an explicit language selection, or null
/// when the application should follow the device's system language.
class LocaleController extends ChangeNotifier {
  LocaleController(this._preferences);

  final LocalePreferences _preferences;

  AppLocalePreference _preference = AppLocalePreference.system;

  AppLocalePreference get preference => _preference;

  /// Returns the explicitly selected locale, or null for system language.
  Locale? get locale {
    return switch (_preference) {
      AppLocalePreference.system => null,
      AppLocalePreference.swedish => const Locale('sv'),
      AppLocalePreference.english => const Locale('en'),
    };
  }

  /// Loads the persisted language preference and notifies listeners.
  ///
  /// If loading fails, the current in-memory preference is preserved.
  Future<void> load() async {
    _preference = await _preferences.getLocalePreference();
    notifyListeners();
  }

  /// Persists [preference] before updating the observable language.
  ///
  /// Does nothing when the preference is unchanged. A storage failure
  /// leaves the current preference unchanged and propagates to the caller.
  Future<void> setPreference(AppLocalePreference preference) async {
    if (_preference == preference) {
      return;
    }

    await _preferences.setLocalePreference(preference);
    _preference = preference;
    notifyListeners();
  }
}
