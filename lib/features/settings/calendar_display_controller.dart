// -----------------------------------------------------------------------------
// calendar_display_controller.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Coordinates the calendar's date and time display preferences
//   and notifies the UI when persisted settings change.
//
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';

import '../fika/fika_section.dart';
import 'calendar_display_preferences.dart';

/// Exposes the calendar display settings used by the UI.
///
/// Loads settings from [CalendarDisplayPreferences] and persists changes
/// before updating the observable state.
class CalendarDisplayController extends ChangeNotifier {
  CalendarDisplayController(this._preferences);

  final CalendarDisplayPreferences _preferences;

  CalendarDisplaySettings _settings = const CalendarDisplaySettings();

  CalendarDisplaySettings get settings => _settings;

  /// Loads persisted display settings and notifies listeners.
  ///
  /// If loading fails, the current in-memory settings remain unchanged.
  Future<void> load() async {
    _settings = await _preferences.getSettings();
    notifyListeners();
  }

  Future<void> setDateFormat(CalendarDateFormat format) async {
    await _update(_settings.copyWith(dateFormat: format));
  }

  Future<void> setTimeFormat(CalendarTimeFormat format) async {
    await _update(_settings.copyWith(timeFormat: format));
  }

  Future<void> setShowWeekday(bool showWeekday) async {
    await _update(_settings.copyWith(showWeekday: showWeekday));
  }

  Future<void> setFikaVisibility(FikaVisibility visibility) async {
    await _update(_settings.copyWith(fikaVisibility: visibility));
  }

  Future<void> setFikaEmoji(FikaSection section, String value) async {
    final emojis = Map<FikaSection, String>.from(_settings.fikaEmojis);
    final normalized = value.trim();

    emojis[section] = normalized.isEmpty
        ? defaultFikaEmojis[section]!
        : normalized;

    await _update(_settings.copyWith(fikaEmojis: emojis));
  }

  Future<void> resetFikaEmojis() async {
    await _update(
      _settings.copyWith(
        fikaEmojis: Map<FikaSection, String>.from(defaultFikaEmojis),
      ),
    );
  }

  Future<void> _update(CalendarDisplaySettings settings) async {
    await _preferences.setSettings(settings);
    _settings = settings;
    notifyListeners();
  }
}
