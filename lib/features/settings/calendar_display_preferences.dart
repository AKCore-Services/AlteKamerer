// -----------------------------------------------------------------------------
// calendar_display_preferences.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Defines calendar date and time display options and their
//   persistent representation.
//
// -----------------------------------------------------------------------------

import 'package:shared_preferences/shared_preferences.dart';

/// Supported calendar date formats.
///
/// Unrecognized stored values fall back to [CalendarDateFormat.compact].
enum CalendarDateFormat {
  compact('compact'),
  numeric('numeric'),
  written('written');

  const CalendarDateFormat(this.storageValue);

  final String storageValue;

  static CalendarDateFormat fromStorage(String? value) {
    return switch (value) {
      'numeric' => CalendarDateFormat.numeric,
      'written' => CalendarDateFormat.written,
      _ => CalendarDateFormat.compact,
    };
  }
}

/// Supported clock formats for calendar event times.
///
/// Unrecognized stored values fall back to
/// [CalendarTimeFormat.twentyFourHour].
enum CalendarTimeFormat {
  twentyFourHour('24-hour'),
  twelveHour('12-hour');

  const CalendarTimeFormat(this.storageValue);

  final String storageValue;

  static CalendarTimeFormat fromStorage(String? value) {
    return switch (value) {
      '12-hour' => CalendarTimeFormat.twelveHour,
      _ => CalendarTimeFormat.twentyFourHour,
    };
  }
}

/// Groups the member's preferred calendar display options.
///
/// Defaults to compact dates, a 24-hour clock, and hidden weekday names.
class CalendarDisplaySettings {
  const CalendarDisplaySettings({
    this.dateFormat = CalendarDateFormat.compact,
    this.timeFormat = CalendarTimeFormat.twentyFourHour,
    this.showWeekday = false,
  });

  final CalendarDateFormat dateFormat;
  final CalendarTimeFormat timeFormat;
  final bool showWeekday;

  CalendarDisplaySettings copyWith({
    CalendarDateFormat? dateFormat,
    CalendarTimeFormat? timeFormat,
    bool? showWeekday,
  }) {
    return CalendarDisplaySettings(
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
      showWeekday: showWeekday ?? this.showWeekday,
    );
  }
}

/// Contract for loading and persisting calendar display settings.
abstract interface class CalendarDisplayPreferences {
  Future<CalendarDisplaySettings> getSettings();

  Future<void> setSettings(CalendarDisplaySettings settings);
}

/// Persists calendar display settings using shared preferences.
///
/// Each option has its own storage key. Missing or unrecognized format
/// values use the defaults defined by [CalendarDisplaySettings].
class SharedPreferencesCalendarDisplayPreferences
    implements CalendarDisplayPreferences {
  SharedPreferencesCalendarDisplayPreferences(this._preferences);

  static const _dateFormatKey = 'calendar_date_format';
  static const _timeFormatKey = 'calendar_time_format';
  static const _showWeekdayKey = 'calendar_show_weekday';

  final SharedPreferences _preferences;

  @override
  Future<CalendarDisplaySettings> getSettings() async {
    return CalendarDisplaySettings(
      dateFormat: CalendarDateFormat.fromStorage(
        _preferences.getString(_dateFormatKey),
      ),
      timeFormat: CalendarTimeFormat.fromStorage(
        _preferences.getString(_timeFormatKey),
      ),
      showWeekday: _preferences.getBool(_showWeekdayKey) ?? false,
    );
  }

  @override
  Future<void> setSettings(CalendarDisplaySettings settings) async {
    await _preferences.setString(
      _dateFormatKey,
      settings.dateFormat.storageValue,
    );
    await _preferences.setString(
      _timeFormatKey,
      settings.timeFormat.storageValue,
    );
    await _preferences.setBool(_showWeekdayKey, settings.showWeekday);
  }
}
