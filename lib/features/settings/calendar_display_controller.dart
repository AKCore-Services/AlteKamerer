import 'package:flutter/foundation.dart';

import 'calendar_display_preferences.dart';

class CalendarDisplayController extends ChangeNotifier {
  CalendarDisplayController(this._preferences);

  final CalendarDisplayPreferences _preferences;

  CalendarDisplaySettings _settings = const CalendarDisplaySettings();

  CalendarDisplaySettings get settings => _settings;

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

  Future<void> _update(CalendarDisplaySettings settings) async {
    await _preferences.setSettings(settings);
    _settings = settings;
    notifyListeners();
  }
}
