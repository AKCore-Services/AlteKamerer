import 'dart:convert';

import 'package:altekamerer/features/settings/calendar_display_preferences.dart';
import 'package:altekamerer/features/settings/locale_preferences.dart';
import 'package:altekamerer/features/settings/settings_backup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const codec = SettingsBackupCodec();

  test('encodes and decodes all supported settings', () {
    const backup = SettingsBackup(
      locale: AppLocalePreference.swedish,
      reminderOffsets: [Duration(hours: 5), Duration(hours: 1)],
      calendarDisplay: SettingsBackupCalendarDisplay(
        dateFormat: CalendarDateFormat.written,
        timeFormat: CalendarTimeFormat.twelveHour,
        showWeekday: true,
      ),
    );

    final encoded = codec.encode(backup);
    final decoded = codec.decode(encoded);

    expect(decoded.locale, AppLocalePreference.swedish);
    expect(decoded.reminderOffsets, const [
      Duration(hours: 5),
      Duration(hours: 1),
    ]);
    expect(decoded.calendarDisplay?.dateFormat, CalendarDateFormat.written);
    expect(decoded.calendarDisplay?.timeFormat, CalendarTimeFormat.twelveHour);
    expect(decoded.calendarDisplay?.showWeekday, isTrue);

    final json = jsonDecode(encoded) as Map<String, dynamic>;
    expect(json['schemaVersion'], settingsBackupSchemaVersion);
  });

  test('missing settings remain absent', () {
    final backup = codec.decode('''
{
  "schemaVersion": 1,
  "settings": {}
}
''');

    expect(backup.locale, isNull);
    expect(backup.reminderOffsets, isNull);
    expect(backup.calendarDisplay, isNull);
  });

  test('partial calendar settings preserve absent fields', () {
    final backup = codec.decode('''
{
  "schemaVersion": 1,
  "settings": {
    "calendarDisplay": {
      "showWeekday": true
    }
  }
}
''');

    expect(backup.calendarDisplay, isNotNull);
    expect(backup.calendarDisplay?.dateFormat, isNull);
    expect(backup.calendarDisplay?.timeFormat, isNull);
    expect(backup.calendarDisplay?.showWeekday, isTrue);

    final encoded = jsonDecode(codec.encode(backup)) as Map<String, dynamic>;
    final settings = encoded['settings'] as Map<String, dynamic>;
    final calendar = settings['calendarDisplay'] as Map<String, dynamic>;

    expect(calendar, {'showWeekday': true});
  });

  test('unknown fields are ignored', () {
    final backup = codec.decode('''
{
  "schemaVersion": 1,
  "futureTopLevelField": "ignored",
  "settings": {
    "futureSetting": {
      "enabled": true
    },
    "language": "en",
    "calendarDisplay": {
      "dateFormat": "numeric",
      "futureCalendarField": 123
    }
  }
}
''');

    expect(backup.locale, AppLocalePreference.english);
    expect(backup.calendarDisplay?.dateFormat, CalendarDateFormat.numeric);
    expect(backup.calendarDisplay?.timeFormat, isNull);
    expect(backup.calendarDisplay?.showWeekday, isNull);
  });

  test('malformed JSON is rejected', () {
    expect(
      () => codec.decode('{not-json'),
      throwsA(isA<SettingsBackupFormatException>()),
    );
  });

  test('non-object JSON is rejected', () {
    expect(
      () => codec.decode('[]'),
      throwsA(isA<SettingsBackupFormatException>()),
    );
  });

  test('missing schema version is rejected', () {
    expect(
      () => codec.decode('{"settings": {}}'),
      throwsA(isA<SettingsBackupFormatException>()),
    );
  });

  test('unsupported schema version is rejected', () {
    expect(
      () => codec.decode('{"schemaVersion": 2, "settings": {}}'),
      throwsA(
        isA<SettingsBackupUnsupportedVersionException>().having(
          (error) => error.version,
          'version',
          2,
        ),
      ),
    );
  });

  test('invalid known language is rejected', () {
    expect(
      () => codec.decode('''
{
  "schemaVersion": 1,
  "settings": {
    "language": "de"
  }
}
'''),
      throwsA(isA<SettingsBackupFormatException>()),
    );
  });

  test('invalid calendar values are rejected', () {
    expect(
      () => codec.decode('''
{
  "schemaVersion": 1,
  "settings": {
    "calendarDisplay": {
      "dateFormat": "future-format"
    }
  }
}
'''),
      throwsA(isA<SettingsBackupFormatException>()),
    );

    expect(
      () => codec.decode('''
{
  "schemaVersion": 1,
  "settings": {
    "calendarDisplay": {
      "showWeekday": "yes"
    }
  }
}
'''),
      throwsA(isA<SettingsBackupFormatException>()),
    );
  });

  test('invalid reminder offsets are rejected', () {
    for (final value in ['0', '-1', '"60"', '1.5']) {
      expect(
        () => codec.decode('''
{
  "schemaVersion": 1,
  "settings": {
    "reminders": {
      "offsetMinutes": [$value]
    }
  }
}
'''),
        throwsA(isA<SettingsBackupFormatException>()),
        reason: 'Expected $value to be rejected.',
      );
    }
  });

  test('duplicate reminder offsets are rejected', () {
    expect(
      () => codec.decode('''
{
  "schemaVersion": 1,
  "settings": {
    "reminders": {
      "offsetMinutes": [300, 60, 60]
    }
  }
}
'''),
      throwsA(isA<SettingsBackupFormatException>()),
    );
  });

  test('encoded backup contains no unrelated or sensitive fields', () {
    final encoded = codec.encode(
      const SettingsBackup(
        locale: AppLocalePreference.english,
        reminderOffsets: [Duration(minutes: 60)],
        calendarDisplay: SettingsBackupCalendarDisplay(
          dateFormat: CalendarDateFormat.compact,
          timeFormat: CalendarTimeFormat.twentyFourHour,
          showWeekday: false,
        ),
      ),
    );

    final json = jsonDecode(encoded) as Map<String, dynamic>;

    expect(json.keys, unorderedEquals(['schemaVersion', 'settings']));

    final settings = json['settings'] as Map<String, dynamic>;
    expect(
      settings.keys,
      unorderedEquals(['language', 'reminders', 'calendarDisplay']),
    );

    final lower = encoded.toLowerCase();
    expect(lower, isNot(contains('password')));
    expect(lower, isNot(contains('token')));
    expect(lower, isNot(contains('session')));
    expect(lower, isNot(contains('credential')));
  });
}
