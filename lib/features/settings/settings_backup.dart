// -----------------------------------------------------------------------------
// settings_backup.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Defines the versioned JSON format used to export, validate,
//   and import application preferences.
//
// -----------------------------------------------------------------------------

import 'dart:convert';

import 'package:characters/characters.dart';

import '../fika/fika_section.dart';
import 'calendar_display_preferences.dart';
import 'locale_preferences.dart';

const settingsBackupSchemaVersion = 1;

/// Represents the preferences included in a settings backup.
///
/// Fields are optional so imports can update selected settings without
/// requiring every supported preference to be present.
class SettingsBackup {
  const SettingsBackup({
    this.locale,
    this.reminderOffsets,
    this.calendarDisplay,
  });

  final AppLocalePreference? locale;
  final List<Duration>? reminderOffsets;
  final SettingsBackupCalendarDisplay? calendarDisplay;
}

class SettingsBackupCalendarDisplay {
  const SettingsBackupCalendarDisplay({
    this.dateFormat,
    this.timeFormat,
    this.showWeekday,
    this.fikaVisibility,
    this.fikaEmojis,
  });

  final CalendarDateFormat? dateFormat;
  final CalendarTimeFormat? timeFormat;
  final bool? showWeekday;
  final FikaVisibility? fikaVisibility;
  final Map<FikaSection, String>? fikaEmojis;
}

/// Encodes and validates the versioned settings backup format.
///
/// Encodes supported preferences into JSON and rejects malformed documents
/// or unsupported schema versions before settings are applied.
class SettingsBackupCodec {
  const SettingsBackupCodec();

  /// Serializes [backup] using the current settings schema version.
  ///
  /// Omits absent preferences so partial backups can represent only
  /// the settings explicitly supplied by the caller.
  String encode(SettingsBackup backup) {
    final settings = <String, Object?>{};

    final locale = backup.locale;
    if (locale != null) {
      settings['language'] = locale.storageValue;
    }

    final reminderOffsets = backup.reminderOffsets;
    if (reminderOffsets != null) {
      settings['reminders'] = {
        'offsetMinutes': reminderOffsets
            .map((offset) => offset.inMinutes)
            .toList(),
      };
    }

    final calendarDisplay = backup.calendarDisplay;
    if (calendarDisplay != null) {
      settings['calendarDisplay'] = {
        if (calendarDisplay.dateFormat case final dateFormat?)
          'dateFormat': dateFormat.storageValue,
        if (calendarDisplay.timeFormat case final timeFormat?)
          'timeFormat': timeFormat.storageValue,
        'showWeekday': ?calendarDisplay.showWeekday,
        if (calendarDisplay.fikaVisibility case final fikaVisibility?)
          'fikaVisibility': fikaVisibility.storageValue,
        if (calendarDisplay.fikaEmojis case final fikaEmojis?)
          'fikaEmojis': {
            for (final entry in fikaEmojis.entries) entry.key.name: entry.value,
          },
      };
    }

    return const JsonEncoder.withIndent('  ').convert({
      'schemaVersion': settingsBackupSchemaVersion,
      'settings': settings,
    });
  }

  /// Validates and decodes a settings backup without applying it.
  ///
  /// Throws [SettingsBackupFormatException] for malformed input and
  /// [SettingsBackupUnsupportedVersionException] for incompatible versions.
  SettingsBackup decode(String source) {
    final Object? decoded;

    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw SettingsBackupFormatException('Invalid JSON.', error);
    }

    if (decoded is! Map<String, dynamic>) {
      throw const SettingsBackupFormatException(
        'The settings backup must contain a JSON object.',
      );
    }

    final schemaVersion = decoded['schemaVersion'];
    if (schemaVersion is! int) {
      throw const SettingsBackupFormatException(
        'The settings backup is missing a valid schema version.',
      );
    }

    if (schemaVersion != settingsBackupSchemaVersion) {
      throw SettingsBackupUnsupportedVersionException(schemaVersion);
    }

    final settings = decoded['settings'];
    if (settings is! Map<String, dynamic>) {
      throw const SettingsBackupFormatException(
        'The settings backup is missing a valid settings object.',
      );
    }

    return SettingsBackup(
      locale: _decodeLocale(settings),
      reminderOffsets: _decodeReminders(settings),
      calendarDisplay: _decodeCalendarDisplay(settings),
    );
  }

  AppLocalePreference? _decodeLocale(Map<String, dynamic> settings) {
    if (!settings.containsKey('language')) {
      return null;
    }

    final value = settings['language'];
    if (value is! String) {
      throw const SettingsBackupFormatException(
        'The language setting must be a string.',
      );
    }

    return switch (value) {
      'system' => AppLocalePreference.system,
      'sv' => AppLocalePreference.swedish,
      'en' => AppLocalePreference.english,
      _ => throw const SettingsBackupFormatException(
        'The language setting is not supported.',
      ),
    };
  }

  List<Duration>? _decodeReminders(Map<String, dynamic> settings) {
    if (!settings.containsKey('reminders')) {
      return null;
    }

    final reminders = settings['reminders'];
    if (reminders is! Map<String, dynamic>) {
      throw const SettingsBackupFormatException(
        'The reminders setting must be an object.',
      );
    }

    if (!reminders.containsKey('offsetMinutes')) {
      return null;
    }

    final values = reminders['offsetMinutes'];
    if (values is! List) {
      throw const SettingsBackupFormatException(
        'Reminder offsets must be a list.',
      );
    }

    final offsets = <Duration>[];
    final seenMinutes = <int>{};

    for (final value in values) {
      if (value is! int || value <= 0) {
        throw const SettingsBackupFormatException(
          'Reminder offsets must contain positive whole minutes.',
        );
      }

      if (!seenMinutes.add(value)) {
        throw const SettingsBackupFormatException(
          'Reminder offsets must not contain duplicates.',
        );
      }

      offsets.add(Duration(minutes: value));
    }

    return offsets;
  }

  SettingsBackupCalendarDisplay? _decodeCalendarDisplay(
    Map<String, dynamic> settings,
  ) {
    if (!settings.containsKey('calendarDisplay')) {
      return null;
    }

    final calendar = settings['calendarDisplay'];
    if (calendar is! Map<String, dynamic>) {
      throw const SettingsBackupFormatException(
        'The calendar display setting must be an object.',
      );
    }

    final hasDateFormat = calendar.containsKey('dateFormat');
    final hasTimeFormat = calendar.containsKey('timeFormat');
    final hasShowWeekday = calendar.containsKey('showWeekday');
    final hasFikaVisibility = calendar.containsKey('fikaVisibility');
    final hasFikaEmojis = calendar.containsKey('fikaEmojis');

    if (!hasDateFormat &&
        !hasTimeFormat &&
        !hasShowWeekday &&
        !hasFikaVisibility &&
        !hasFikaEmojis) {
      return null;
    }

    return SettingsBackupCalendarDisplay(
      dateFormat: hasDateFormat
          ? _decodeDateFormat(calendar['dateFormat'])
          : null,
      timeFormat: hasTimeFormat
          ? _decodeTimeFormat(calendar['timeFormat'])
          : null,
      showWeekday: hasShowWeekday
          ? _decodeShowWeekday(calendar['showWeekday'])
          : null,
      fikaVisibility: hasFikaVisibility
          ? _decodeFikaVisibility(calendar['fikaVisibility'])
          : null,
      fikaEmojis: hasFikaEmojis
          ? _decodeFikaEmojis(calendar['fikaEmojis'])
          : null,
    );
  }

  FikaVisibility _decodeFikaVisibility(Object? value) {
    if (value is! String) {
      throw const SettingsBackupFormatException(
        'The calendar fika visibility setting must be a string.',
      );
    }

    return switch (value) {
      'dont-show' => FikaVisibility.dontShow,
      'my-section' => FikaVisibility.mySection,
      'all' => FikaVisibility.all,
      _ => throw const SettingsBackupFormatException(
        'The calendar fika visibility setting is not supported.',
      ),
    };
  }

  Map<FikaSection, String> _decodeFikaEmojis(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const SettingsBackupFormatException(
        'The calendar fika symbols setting must be an object.',
      );
    }

    final emojis = <FikaSection, String>{};

    for (final entry in value.entries) {
      FikaSection? section;

      for (final candidate in FikaSection.values) {
        if (candidate.name == entry.key) {
          section = candidate;
          break;
        }
      }

      if (section == null) {
        throw const SettingsBackupFormatException(
          'The calendar fika symbols contain an unsupported section.',
        );
      }

      final symbol = entry.value;
      if (symbol is! String) {
        throw const SettingsBackupFormatException(
          'Calendar fika symbols must be strings.',
        );
      }

      final normalized = symbol.trim();

      if (normalized.characters.length > 1) {
        throw const SettingsBackupFormatException(
          'Calendar fika symbols must contain at most one symbol.',
        );
      }

      emojis[section] = normalized;
    }

    return emojis;
  }

  CalendarDateFormat _decodeDateFormat(Object? value) {
    if (value is! String) {
      throw const SettingsBackupFormatException(
        'The calendar date format must be a string.',
      );
    }

    return switch (value) {
      'compact' => CalendarDateFormat.compact,
      'numeric' => CalendarDateFormat.numeric,
      'written' => CalendarDateFormat.written,
      _ => throw const SettingsBackupFormatException(
        'The calendar date format is not supported.',
      ),
    };
  }

  CalendarTimeFormat _decodeTimeFormat(Object? value) {
    if (value is! String) {
      throw const SettingsBackupFormatException(
        'The calendar time format must be a string.',
      );
    }

    return switch (value) {
      '24-hour' => CalendarTimeFormat.twentyFourHour,
      '12-hour' => CalendarTimeFormat.twelveHour,
      _ => throw const SettingsBackupFormatException(
        'The calendar time format is not supported.',
      ),
    };
  }

  bool _decodeShowWeekday(Object? value) {
    if (value is! bool) {
      throw const SettingsBackupFormatException(
        'The calendar weekday setting must be a boolean.',
      );
    }

    return value;
  }
}

class SettingsBackupFormatException implements Exception {
  const SettingsBackupFormatException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class SettingsBackupUnsupportedVersionException
    extends SettingsBackupFormatException {
  SettingsBackupUnsupportedVersionException(this.version)
    : super('Settings backup schema version $version is not supported.');

  final int version;
}
