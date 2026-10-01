// -----------------------------------------------------------------------------
// settings_backup_service.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Coordinates exporting and importing preferences while keeping
//   the active settings controllers synchronized.
//
// -----------------------------------------------------------------------------

import 'calendar_display_controller.dart';
import 'calendar_display_preferences.dart';
import 'locale_controller.dart';
import 'locale_preferences.dart';
import 'reminder_preferences.dart';
import 'settings_backup.dart';

/// Coordinates settings backup and restoration across preference stores.
///
/// Merges imported values with existing preferences and reloads the affected
/// controllers after a successful import.
class SettingsBackupService {
  const SettingsBackupService({
    required this._localePreferences,
    required this._reminderPreferences,
    required this._calendarDisplayPreferences,
    required this._localeController,
    required this._calendarDisplayController,
    this._codec = const SettingsBackupCodec(),
  });

  final LocalePreferences _localePreferences;
  final ReminderPreferences _reminderPreferences;
  final CalendarDisplayPreferences _calendarDisplayPreferences;
  final LocaleController _localeController;
  final CalendarDisplayController _calendarDisplayController;
  final SettingsBackupCodec _codec;

  /// Exports the currently persisted preferences as versioned JSON.
  ///
  /// Reads language, reminder offsets, and calendar display settings
  /// from their respective stores without changing the active settings.
  /// Storage failures propagate to the caller.
  Future<String> exportSettings() async {
    final snapshot = await _readCurrentSettings();

    return _codec.encode(
      SettingsBackup(
        locale: snapshot.locale,
        reminderOffsets: snapshot.reminderOffsets,
        calendarDisplay: SettingsBackupCalendarDisplay(
          dateFormat: snapshot.calendarDisplay.dateFormat,
          timeFormat: snapshot.calendarDisplay.timeFormat,
          showWeekday: snapshot.calendarDisplay.showWeekday,
        ),
      ),
    );
  }

  /// Validates [source] and returns its decoded settings.
  ///
  /// Does not modify persisted preferences or application state.
  /// Propagates format and unsupported-version errors from the codec.
  SettingsBackup validateImport(String source) {
    return _codec.decode(source);
  }

  /// Applies a validated backup while preserving unspecified settings.
  ///
  /// Captures the previous settings before writing. If an update fails,
  /// attempts to restore that snapshot and rethrows the original failure.
  /// Rollback is best-effort when the underlying storage is itself failing.
  Future<void> importSettings(SettingsBackup backup) async {
    final previous = await _readCurrentSettings();
    final replacement = _merge(previous, backup);

    try {
      await _writeSettings(replacement);
    } catch (error, stackTrace) {
      try {
        await _writeSettings(previous);
      } catch (_) {
        // Preserve the original import failure. Rollback is best-effort if the
        // underlying local storage itself is failing.
      }

      Error.throwWithStackTrace(error, stackTrace);
    }

    await _localeController.load();
    await _calendarDisplayController.load();
  }

  Future<_SettingsSnapshot> _readCurrentSettings() async {
    final locale = await _localePreferences.getLocalePreference();
    final reminderOffsets = await _reminderPreferences.getReminderOffsets();
    final calendarDisplay = await _calendarDisplayPreferences.getSettings();

    return _SettingsSnapshot(
      locale: locale,
      reminderOffsets: List<Duration>.unmodifiable(reminderOffsets),
      calendarDisplay: calendarDisplay,
    );
  }

  _SettingsSnapshot _merge(_SettingsSnapshot current, SettingsBackup backup) {
    final importedCalendar = backup.calendarDisplay;

    return _SettingsSnapshot(
      locale: backup.locale ?? current.locale,
      reminderOffsets: List<Duration>.unmodifiable(
        backup.reminderOffsets ?? current.reminderOffsets,
      ),
      calendarDisplay: CalendarDisplaySettings(
        dateFormat:
            importedCalendar?.dateFormat ?? current.calendarDisplay.dateFormat,
        timeFormat:
            importedCalendar?.timeFormat ?? current.calendarDisplay.timeFormat,
        showWeekday:
            importedCalendar?.showWeekday ??
            current.calendarDisplay.showWeekday,
      ),
    );
  }

  Future<void> _writeSettings(_SettingsSnapshot settings) async {
    await _localePreferences.setLocalePreference(settings.locale);
    await _reminderPreferences.setReminderOffsets(settings.reminderOffsets);
    await _calendarDisplayPreferences.setSettings(settings.calendarDisplay);
  }
}

class _SettingsSnapshot {
  const _SettingsSnapshot({
    required this.locale,
    required this.reminderOffsets,
    required this.calendarDisplay,
  });

  final AppLocalePreference locale;
  final List<Duration> reminderOffsets;
  final CalendarDisplaySettings calendarDisplay;
}
