import 'package:altekamerer/features/fika/fika_section.dart';
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
    expect(settings.fikaVisibility, FikaVisibility.dontShow);
    expect(settings.fikaEmojis, defaultFikaEmojis);
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
        fikaVisibility: FikaVisibility.all,
        fikaEmojis: {
          FikaSection.balett: 'A',
          FikaSection.flojt: 'B',
          FikaSection.klarinett: 'C',
          FikaSection.komp: 'D',
          FikaSection.sax: 'E',
          FikaSection.horn: 'F',
          FikaSection.grovbrass: 'G',
          FikaSection.trumpet: 'H',
        },
      ),
    );

    final reloaded = SharedPreferencesCalendarDisplayPreferences(
      sharedPreferences,
    );
    final settings = await reloaded.getSettings();

    expect(settings.dateFormat, CalendarDateFormat.written);
    expect(settings.timeFormat, CalendarTimeFormat.twelveHour);
    expect(settings.showWeekday, isTrue);
    expect(settings.fikaVisibility, FikaVisibility.all);
    expect(settings.fikaEmojis[FikaSection.balett], 'A');
    expect(settings.fikaEmojis[FikaSection.flojt], 'B');
    expect(settings.fikaEmojis[FikaSection.klarinett], 'C');
    expect(settings.fikaEmojis[FikaSection.komp], 'D');
    expect(settings.fikaEmojis[FikaSection.sax], 'E');
    expect(settings.fikaEmojis[FikaSection.horn], 'F');
    expect(settings.fikaEmojis[FikaSection.grovbrass], 'G');
    expect(settings.fikaEmojis[FikaSection.trumpet], 'H');
  });

  test('unknown stored enum values fall back to defaults', () async {
    SharedPreferences.setMockInitialValues({
      'calendar_date_format': 'unknown',
      'calendar_time_format': 'unknown',
      'calendar_fika_visibility': 'unknown',
    });

    final preferences = SharedPreferencesCalendarDisplayPreferences(
      await SharedPreferences.getInstance(),
    );

    final settings = await preferences.getSettings();

    expect(settings.dateFormat, CalendarDateFormat.compact);
    expect(settings.timeFormat, CalendarTimeFormat.twentyFourHour);
    expect(settings.fikaVisibility, FikaVisibility.dontShow);
  });

  test('empty stored fika emoji falls back to app default', () async {
    SharedPreferences.setMockInitialValues({'calendar_fika_emoji_sax': '   '});

    final preferences = SharedPreferencesCalendarDisplayPreferences(
      await SharedPreferences.getInstance(),
    );

    final settings = await preferences.getSettings();

    expect(
      settings.fikaEmojiFor(FikaSection.sax),
      defaultFikaEmojis[FikaSection.sax],
    );
  });
}
