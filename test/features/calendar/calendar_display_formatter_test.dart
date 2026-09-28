import 'package:altekamerer/features/calendar/calendar_display_formatter.dart';
import 'package:altekamerer/features/settings/calendar_display_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  const formatter = CalendarDisplayFormatter();

  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('sv');
  });

  test('compact date preserves existing presentation', () {
    expect(
      formatter.formatDate(
        '2026-09-15',
        locale: 'sv',
        settings: const CalendarDisplaySettings(),
      ),
      '15/09',
    );
  });

  test('numeric dates are locale aware', () {
    const settings = CalendarDisplaySettings(
      dateFormat: CalendarDateFormat.numeric,
    );

    expect(
      formatter.formatDate('2026-09-15', locale: 'sv', settings: settings),
      '2026-09-15',
    );
    expect(
      formatter.formatDate('2026-09-15', locale: 'en', settings: settings),
      '9/15/2026',
    );
  });

  test('weekday abbreviations are localized', () {
    const settings = CalendarDisplaySettings(showWeekday: true);

    expect(
      formatter.formatDate('2026-09-15', locale: 'sv', settings: settings),
      'tis 15/09',
    );
    expect(
      formatter.formatDate('2026-09-15', locale: 'en', settings: settings),
      'Tue 15/09',
    );
  });

  test('24-hour and 12-hour times are formatted', () {
    expect(
      formatter.formatTime(
        '18:30',
        locale: 'en',
        settings: const CalendarDisplaySettings(),
      ),
      '18:30',
    );
    expect(
      formatter.formatTime(
        '18:30',
        locale: 'en',
        settings: const CalendarDisplaySettings(
          timeFormat: CalendarTimeFormat.twelveHour,
        ),
      ),
      '6:30 PM',
    );
    expect(
      formatter.formatTime(
        '18:30',
        locale: 'sv',
        settings: const CalendarDisplaySettings(
          timeFormat: CalendarTimeFormat.twelveHour,
        ),
      ),
      '6:30 em',
    );
  });

  test('invalid date and time values are preserved', () {
    const settings = CalendarDisplaySettings();

    expect(
      formatter.formatDate('not-a-date', locale: 'en', settings: settings),
      'not-a-date',
    );
    expect(
      formatter.formatTime('not-a-time', locale: 'en', settings: settings),
      'not-a-time',
    );
  });
}
