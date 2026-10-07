import 'package:altekamerer/features/fika/fika_section.dart';
import 'package:altekamerer/features/settings/calendar_display_controller.dart';
import 'package:altekamerer/features/settings/calendar_display_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads persisted settings', () async {
    final preferences = _FakeCalendarDisplayPreferences(
      const CalendarDisplaySettings(
        dateFormat: CalendarDateFormat.numeric,
        timeFormat: CalendarTimeFormat.twelveHour,
        showWeekday: true,
        fikaVisibility: FikaVisibility.mySection,
      ),
    );
    final controller = CalendarDisplayController(preferences);

    await controller.load();

    expect(controller.settings.dateFormat, CalendarDateFormat.numeric);
    expect(controller.settings.timeFormat, CalendarTimeFormat.twelveHour);
    expect(controller.settings.showWeekday, isTrue);
    expect(controller.settings.fikaVisibility, FikaVisibility.mySection);
  });

  test('changes persist and notify listeners', () async {
    final preferences = _FakeCalendarDisplayPreferences(
      const CalendarDisplaySettings(),
    );
    final controller = CalendarDisplayController(preferences);
    await controller.load();

    var notifications = 0;
    controller.addListener(() {
      notifications++;
    });

    await controller.setDateFormat(CalendarDateFormat.written);
    await controller.setTimeFormat(CalendarTimeFormat.twelveHour);
    await controller.setShowWeekday(true);
    await controller.setFikaVisibility(FikaVisibility.all);
    await controller.setFikaEmoji(FikaSection.sax, '⭐');

    expect(preferences.settings.dateFormat, CalendarDateFormat.written);
    expect(preferences.settings.timeFormat, CalendarTimeFormat.twelveHour);
    expect(preferences.settings.showWeekday, isTrue);
    expect(preferences.settings.fikaVisibility, FikaVisibility.all);
    expect(preferences.settings.fikaEmojiFor(FikaSection.sax), '⭐');
    expect(notifications, 5);
  });

  test('empty fika emoji restores that section default', () async {
    final preferences = _FakeCalendarDisplayPreferences(
      const CalendarDisplaySettings(),
    );
    final controller = CalendarDisplayController(preferences);
    await controller.load();

    await controller.setFikaEmoji(FikaSection.sax, '⭐');
    await controller.setFikaEmoji(FikaSection.sax, '   ');

    expect(
      controller.settings.fikaEmojiFor(FikaSection.sax),
      defaultFikaEmojis[FikaSection.sax],
    );
  });

  test(
    'reset restores all fika emoji defaults without changing visibility',
    () async {
      final preferences = _FakeCalendarDisplayPreferences(
        const CalendarDisplaySettings(fikaVisibility: FikaVisibility.mySection),
      );
      final controller = CalendarDisplayController(preferences);
      await controller.load();

      await controller.setFikaEmoji(FikaSection.sax, '⭐');
      await controller.setFikaEmoji(FikaSection.trumpet, 'T');
      await controller.resetFikaEmojis();

      expect(controller.settings.fikaEmojis, defaultFikaEmojis);
      expect(controller.settings.fikaVisibility, FikaVisibility.mySection);
    },
  );
}

class _FakeCalendarDisplayPreferences implements CalendarDisplayPreferences {
  _FakeCalendarDisplayPreferences(this.settings);

  CalendarDisplaySettings settings;

  @override
  Future<CalendarDisplaySettings> getSettings() async => settings;

  @override
  Future<void> setSettings(CalendarDisplaySettings settings) async {
    this.settings = settings;
  }
}
