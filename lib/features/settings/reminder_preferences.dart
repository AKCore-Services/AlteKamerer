// -----------------------------------------------------------------------------
// reminder_preferences.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Defines reminder timing preferences and their local persistence.
//
// -----------------------------------------------------------------------------

import 'package:shared_preferences/shared_preferences.dart';

const defaultReminderOffsets = [Duration(hours: 5), Duration(hours: 1)];

/// Provides the reminder offsets used by notification planning.
///
/// Offsets represent the time before an event at which reminders should fire.
abstract interface class ReminderPreferences {
  Future<List<Duration>> getReminderOffsets();

  Future<void> setReminderOffsets(List<Duration> offsets);
}

/// Persists reminder offsets as positive minute values.
///
/// Uses [defaultReminderOffsets] when no preference has been saved.
/// Invalid stored values are discarded rather than preventing loading.
class SharedPreferencesReminderPreferences implements ReminderPreferences {
  SharedPreferencesReminderPreferences(this._preferences);

  static const _reminderOffsetsKey = 'reminder_offsets_minutes';

  final SharedPreferences _preferences;

  @override
  Future<List<Duration>> getReminderOffsets() async {
    final storedOffsets = _preferences.getStringList(_reminderOffsetsKey);

    if (storedOffsets == null) {
      return defaultReminderOffsets;
    }

    final offsets = storedOffsets
        .map(int.tryParse)
        .whereType<int>()
        .where((minutes) => minutes > 0)
        .map((minutes) => Duration(minutes: minutes))
        .toList();

    return offsets;
  }

  @override
  Future<void> setReminderOffsets(List<Duration> offsets) async {
    final minutes = offsets
        .where((offset) => offset > Duration.zero)
        .map((offset) => offset.inMinutes.toString())
        .toList();

    await _preferences.setStringList(_reminderOffsetsKey, minutes);
  }
}
