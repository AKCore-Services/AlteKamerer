import 'package:altekamerer/features/settings/calendar_display_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults preserve current calendar presentation', () async {
    final preferences = SharedPreferencesCalendarDisplayPreferences(
      await SharedPreferences.getInstance(),
    );

    final settings = await preferences.getSettings();

    expect(settings.dateFormat, CalendarDateFormat.compact);
    expect(settings.timeFormat, CalendarTimeFormat.twentyFourHour);
    expect(settings.showWeekday, isFalse);
  });

  test('persists calendar display settings', () async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final preferences = SharedPreferencesCalendarDisplayPreferences(
      sharedPreferences,
    );

    await preferences.setSettings(
      const CalendarDisplaySettings(
        dateFormat: CalendarDateFormat.written,
        timeFormat: CalendarTimeFormat.twelveHour,
        showWeekday: true,
      ),
    );

    final reloaded = SharedPreferencesCalendarDisplayPreferences(
      sharedPreferences,
    );
    final settings = await reloaded.getSettings();

    expect(settings.dateFormat, CalendarDateFormat.written);
    expect(settings.timeFormat, CalendarTimeFormat.twelveHour);
    expect(settings.showWeekday, isTrue);
  });

  test('unknown stored enum values fall back to defaults', () async {
    SharedPreferences.setMockInitialValues({
      'calendar_date_format': 'unknown',
      'calendar_time_format': 'unknown',
    });

    final preferences = SharedPreferencesCalendarDisplayPreferences(
      await SharedPreferences.getInstance(),
    );

    final settings = await preferences.getSettings();

    expect(settings.dateFormat, CalendarDateFormat.compact);
    expect(settings.timeFormat, CalendarTimeFormat.twentyFourHour);
  });
}
