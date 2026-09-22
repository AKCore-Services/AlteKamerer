import 'package:altekamerer/features/notifications/notification_sync_service.dart';
import 'package:altekamerer/features/settings/locale_controller.dart';
import 'package:altekamerer/features/settings/locale_preferences.dart';
import 'package:altekamerer/features/settings/reminder_preferences.dart';
import 'package:altekamerer/features/settings/reminder_settings_screen.dart';
import 'package:altekamerer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('changing language resynchronizes notifications', (
    WidgetTester tester,
  ) async {
    final preferences = _FakeReminderPreferences([]);
    final notificationSync = _FakeNotificationSync();
    final localeController = _createLocaleController(
      AppLocalePreference.swedish,
    );

    await _pumpScreen(
      tester,
      preferences: preferences,
      notificationSync: notificationSync,
      localeController: localeController,
    );

    final languageSelector = tester
        .widget<DropdownButtonFormField<AppLocalePreference>>(
          find.byType(DropdownButtonFormField<AppLocalePreference>),
        );

    languageSelector.onChanged!(AppLocalePreference.english);
    await tester.pumpAndSettle();

    expect(localeController.preference, AppLocalePreference.english);
    expect(notificationSync.syncCount, 1);
  });

  testWidgets('loads configured reminders', (WidgetTester tester) async {
    final preferences = _FakeReminderPreferences([
      const Duration(hours: 5),
      const Duration(hours: 1),
    ]);

    await _pumpScreen(tester, preferences: preferences);

    expect(find.text('Påminnelser'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Inga påminnelser är aktiverade.'), findsNothing);
  });

  testWidgets('empty configuration shows reminders as disabled', (
    WidgetTester tester,
  ) async {
    final preferences = _FakeReminderPreferences([]);

    await _pumpScreen(tester, preferences: preferences);

    expect(find.text('Inga påminnelser är aktiverade.'), findsOneWidget);
  });

  testWidgets('adds and removes reminders', (WidgetTester tester) async {
    final preferences = _FakeReminderPreferences([]);

    await _pumpScreen(tester, preferences: preferences);

    await tester.tap(find.text('Lägg till påminnelse'));
    await tester.pump();

    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Inga påminnelser är aktiverade.'), findsNothing);

    await tester.tap(find.byTooltip('Ta bort påminnelse'));
    await tester.pump();

    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Inga påminnelser är aktiverade.'), findsOneWidget);
  });

  testWidgets('saves configured reminders and resynchronizes notifications', (
    WidgetTester tester,
  ) async {
    final preferences = _FakeReminderPreferences([
      const Duration(hours: 5),
      const Duration(hours: 1),
    ]);
    final notificationSync = _FakeNotificationSync();

    await _pumpScreen(
      tester,
      preferences: preferences,
      notificationSync: notificationSync,
    );

    await tester.tap(find.text('Spara inställningar'));
    await tester.pumpAndSettle();

    expect(preferences.savedOffsets, [
      const Duration(hours: 5),
      const Duration(hours: 1),
    ]);
    expect(notificationSync.syncCount, 1);
    expect(find.text('Påminnelser sparade.'), findsOneWidget);
  });

  testWidgets('saving empty configuration disables reminders', (
    WidgetTester tester,
  ) async {
    final preferences = _FakeReminderPreferences([]);
    final notificationSync = _FakeNotificationSync();

    await _pumpScreen(
      tester,
      preferences: preferences,
      notificationSync: notificationSync,
    );

    await tester.tap(find.text('Spara inställningar'));
    await tester.pumpAndSettle();

    expect(preferences.savedOffsets, isEmpty);
    expect(notificationSync.syncCount, 1);
  });

  testWidgets('rejects duplicate reminder times', (WidgetTester tester) async {
    final preferences = _FakeReminderPreferences([
      const Duration(hours: 1),
      const Duration(minutes: 60),
    ]);
    final notificationSync = _FakeNotificationSync();

    await _pumpScreen(
      tester,
      preferences: preferences,
      notificationSync: notificationSync,
    );

    await tester.tap(find.text('Spara inställningar'));
    await tester.pump();

    expect(
      find.text('Två påminnelser kan inte ha samma tid före aktiviteten.'),
      findsOneWidget,
    );
    expect(preferences.setCount, 0);
    expect(notificationSync.syncCount, 0);
  });

  testWidgets('rejects zero reminder time', (WidgetTester tester) async {
    final preferences = _FakeReminderPreferences([const Duration(hours: 1)]);
    final notificationSync = _FakeNotificationSync();

    await _pumpScreen(
      tester,
      preferences: preferences,
      notificationSync: notificationSync,
    );

    final field = find.byType(TextFormField).first;

    await tester.enterText(field, '0');
    await tester.tap(find.text('Spara inställningar'));
    await tester.pump();

    expect(
      find.text('Alla påminnelser måste ha en tid som är större än 0.'),
      findsOneWidget,
    );
    expect(preferences.setCount, 0);
    expect(notificationSync.syncCount, 0);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _FakeReminderPreferences preferences,
  _FakeNotificationSync? notificationSync,
  LocaleController? localeController,
}) async {
  final controller = localeController ?? _createLocaleController();

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('sv'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ReminderSettingsScreen(
          reminderPreferences: preferences,
          notificationSync: notificationSync ?? _FakeNotificationSync(),
          localeController: controller,
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

LocaleController _createLocaleController([
  AppLocalePreference preference = AppLocalePreference.system,
]) {
  return LocaleController(_FakeLocalePreferences(preference));
}

class _FakeReminderPreferences implements ReminderPreferences {
  _FakeReminderPreferences(this.offsets);

  final List<Duration> offsets;

  List<Duration>? savedOffsets;
  int setCount = 0;

  @override
  Future<List<Duration>> getReminderOffsets() async {
    return List.of(offsets);
  }

  @override
  Future<void> setReminderOffsets(List<Duration> offsets) async {
    setCount++;
    savedOffsets = List.of(offsets);
  }
}

class _FakeLocalePreferences implements LocalePreferences {
  _FakeLocalePreferences(this.preference);

  AppLocalePreference preference;

  @override
  Future<AppLocalePreference> getLocalePreference() async {
    return preference;
  }

  @override
  Future<void> setLocalePreference(AppLocalePreference preference) async {
    this.preference = preference;
  }
}

class _FakeNotificationSync implements NotificationSync {
  int syncCount = 0;
  int clearCount = 0;

  @override
  Future<void> sync() async {
    syncCount++;
  }

  @override
  Future<void> clear() async {
    clearCount++;
  }
}
