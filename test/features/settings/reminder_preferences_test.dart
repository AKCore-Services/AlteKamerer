import 'package:altekamerer/features/settings/reminder_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('returns five and one hour defaults when no preference exists', () async {
    final preferences = await SharedPreferences.getInstance();
    final reminderPreferences = SharedPreferencesReminderPreferences(
      preferences,
    );

    expect(await reminderPreferences.getReminderOffsets(), [
      const Duration(hours: 5),
      const Duration(hours: 1),
    ]);
  });

  test('persists configured reminder offsets', () async {
    final preferences = await SharedPreferences.getInstance();
    final reminderPreferences = SharedPreferencesReminderPreferences(
      preferences,
    );

    await reminderPreferences.setReminderOffsets([
      const Duration(days: 1),
      const Duration(hours: 2),
      const Duration(minutes: 30),
    ]);

    expect(await reminderPreferences.getReminderOffsets(), [
      const Duration(days: 1),
      const Duration(hours: 2),
      const Duration(minutes: 30),
    ]);
  });

  test('persists an empty reminder list', () async {
    final preferences = await SharedPreferences.getInstance();
    final reminderPreferences = SharedPreferencesReminderPreferences(
      preferences,
    );

    await reminderPreferences.setReminderOffsets(const []);

    expect(await reminderPreferences.getReminderOffsets(), isEmpty);
  });

  test('ignores invalid stored reminder offsets', () async {
    SharedPreferences.setMockInitialValues({
      'reminder_offsets_minutes': ['300', 'invalid', '0', '-60', '60'],
    });

    final preferences = await SharedPreferences.getInstance();
    final reminderPreferences = SharedPreferencesReminderPreferences(
      preferences,
    );

    expect(await reminderPreferences.getReminderOffsets(), [
      const Duration(hours: 5),
      const Duration(hours: 1),
    ]);
  });
}