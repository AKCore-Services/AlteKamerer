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
      ),
    );
    final controller = CalendarDisplayController(preferences);

    await controller.load();

    expect(controller.settings.dateFormat, CalendarDateFormat.numeric);
    expect(controller.settings.timeFormat, CalendarTimeFormat.twelveHour);
    expect(controller.settings.showWeekday, isTrue);
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

    expect(preferences.settings.dateFormat, CalendarDateFormat.written);
    expect(preferences.settings.timeFormat, CalendarTimeFormat.twelveHour);
    expect(preferences.settings.showWeekday, isTrue);
    expect(notifications, 3);
  });
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
