import 'dart:convert';

import 'package:altekamerer/features/settings/calendar_display_controller.dart';
import 'package:altekamerer/features/settings/calendar_display_preferences.dart';
import 'package:altekamerer/features/settings/locale_controller.dart';
import 'package:altekamerer/features/settings/locale_preferences.dart';
import 'package:altekamerer/features/settings/reminder_preferences.dart';
import 'package:altekamerer/features/settings/settings_backup.dart';
import 'package:altekamerer/features/settings/settings_backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeLocalePreferences localePreferences;
  late _FakeReminderPreferences reminderPreferences;
  late _FakeCalendarDisplayPreferences calendarPreferences;
  late LocaleController localeController;
  late CalendarDisplayController calendarController;
  late SettingsBackupService service;

  setUp(() {
    localePreferences = _FakeLocalePreferences(AppLocalePreference.swedish);
    reminderPreferences = _FakeReminderPreferences(const [
      Duration(hours: 5),
      Duration(hours: 1),
    ]);
    calendarPreferences = _FakeCalendarDisplayPreferences(
      const CalendarDisplaySettings(
        dateFormat: CalendarDateFormat.numeric,
        timeFormat: CalendarTimeFormat.twelveHour,
        showWeekday: true,
      ),
    );

    localeController = LocaleController(localePreferences);
    calendarController = CalendarDisplayController(calendarPreferences);

    service = SettingsBackupService(
      localePreferences: localePreferences,
      reminderPreferences: reminderPreferences,
      calendarDisplayPreferences: calendarPreferences,
      localeController: localeController,
      calendarDisplayController: calendarController,
    );
  });

  test('export contains all supported current settings', () async {
    final encoded = await service.exportSettings();
    final json = jsonDecode(encoded) as Map<String, dynamic>;
    final settings = json['settings'] as Map<String, dynamic>;

    expect(json['schemaVersion'], settingsBackupSchemaVersion);
    expect(settings['language'], 'sv');
    expect(settings['reminders'], {
      'offsetMinutes': [300, 60],
    });
    expect(settings['calendarDisplay'], {
      'dateFormat': 'numeric',
      'timeFormat': '12-hour',
      'showWeekday': true,
    });
  });

  test('partial import preserves settings that are absent', () async {
    final backup = service.validateImport('''
{
  "schemaVersion": 1,
  "settings": {
    "language": "en",
    "calendarDisplay": {
      "showWeekday": false
    }
  }
}
''');

    await service.importSettings(backup);

    expect(
      await localePreferences.getLocalePreference(),
      AppLocalePreference.english,
    );
    expect(await reminderPreferences.getReminderOffsets(), const [
      Duration(hours: 5),
      Duration(hours: 1),
    ]);

    final calendar = await calendarPreferences.getSettings();
    expect(calendar.dateFormat, CalendarDateFormat.numeric);
    expect(calendar.timeFormat, CalendarTimeFormat.twelveHour);
    expect(calendar.showWeekday, isFalse);
  });

  test('successful import refreshes running controllers', () async {
    await localeController.load();
    await calendarController.load();

    expect(localeController.preference, AppLocalePreference.swedish);
    expect(calendarController.settings.dateFormat, CalendarDateFormat.numeric);

    final backup = service.validateImport('''
{
  "schemaVersion": 1,
  "settings": {
    "language": "en",
    "calendarDisplay": {
      "dateFormat": "written",
      "timeFormat": "24-hour",
      "showWeekday": false
    }
  }
}
''');

    await service.importSettings(backup);

    expect(localeController.preference, AppLocalePreference.english);
    expect(calendarController.settings.dateFormat, CalendarDateFormat.written);
    expect(
      calendarController.settings.timeFormat,
      CalendarTimeFormat.twentyFourHour,
    );
    expect(calendarController.settings.showWeekday, isFalse);
  });

  test('invalid source is rejected before any settings are written', () {
    expect(
      () => service.validateImport('''
{
  "schemaVersion": 1,
  "settings": {
    "language": "invalid"
  }
}
'''),
      throwsA(isA<SettingsBackupFormatException>()),
    );

    expect(localePreferences.writeCount, 0);
    expect(reminderPreferences.writeCount, 0);
    expect(calendarPreferences.writeCount, 0);
  });

  test('failed import attempts to restore previous settings', () async {
    reminderPreferences.failNextWrite = true;

    const backup = SettingsBackup(
      locale: AppLocalePreference.english,
      reminderOffsets: [Duration(minutes: 30)],
      calendarDisplay: SettingsBackupCalendarDisplay(
        dateFormat: CalendarDateFormat.written,
        timeFormat: CalendarTimeFormat.twentyFourHour,
        showWeekday: false,
      ),
    );

    await expectLater(
      service.importSettings(backup),
      throwsA(isA<StateError>()),
    );

    expect(
      await localePreferences.getLocalePreference(),
      AppLocalePreference.swedish,
    );
    expect(await reminderPreferences.getReminderOffsets(), const [
      Duration(hours: 5),
      Duration(hours: 1),
    ]);

    final calendar = await calendarPreferences.getSettings();
    expect(calendar.dateFormat, CalendarDateFormat.numeric);
    expect(calendar.timeFormat, CalendarTimeFormat.twelveHour);
    expect(calendar.showWeekday, isTrue);

    expect(localePreferences.writeCount, 2);
    expect(reminderPreferences.writeCount, 2);
    expect(calendarPreferences.writeCount, 1);
  });
}

class _FakeLocalePreferences implements LocalePreferences {
  _FakeLocalePreferences(this.value);

  AppLocalePreference value;
  int writeCount = 0;

  @override
  Future<AppLocalePreference> getLocalePreference() async => value;

  @override
  Future<void> setLocalePreference(AppLocalePreference preference) async {
    writeCount++;
    value = preference;
  }
}

class _FakeReminderPreferences implements ReminderPreferences {
  _FakeReminderPreferences(List<Duration> value)
    : value = List<Duration>.of(value);

  List<Duration> value;
  int writeCount = 0;
  bool failNextWrite = false;

  @override
  Future<List<Duration>> getReminderOffsets() async {
    return List<Duration>.of(value);
  }

  @override
  Future<void> setReminderOffsets(List<Duration> offsets) async {
    writeCount++;

    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('Injected reminder write failure.');
    }

    value = List<Duration>.of(offsets);
  }
}

class _FakeCalendarDisplayPreferences implements CalendarDisplayPreferences {
  _FakeCalendarDisplayPreferences(this.value);

  CalendarDisplaySettings value;
  int writeCount = 0;

  @override
  Future<CalendarDisplaySettings> getSettings() async => value;

  @override
  Future<void> setSettings(CalendarDisplaySettings settings) async {
    writeCount++;
    value = settings;
  }
}
