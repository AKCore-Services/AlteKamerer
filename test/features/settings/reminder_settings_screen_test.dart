import 'package:altekamerer/features/notifications/notification_sync_service.dart';
import 'package:altekamerer/features/settings/calendar_display_controller.dart';
import 'package:altekamerer/features/settings/calendar_display_preferences.dart';
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

  testWidgets('calendar display settings update and persist immediately', (
    WidgetTester tester,
  ) async {
    final preferences = _FakeReminderPreferences([]);
    final calendarPreferences = _FakeCalendarDisplayPreferences(
      const CalendarDisplaySettings(),
    );
    final calendarController = CalendarDisplayController(calendarPreferences);
    await calendarController.load();

    await _pumpScreen(
      tester,
      preferences: preferences,
      calendarDisplayController: calendarController,
    );

    expect(find.text('Kalendervisning'), findsOneWidget);

    final dateSelector = tester
        .widget<DropdownButtonFormField<CalendarDateFormat>>(
          find.byType(DropdownButtonFormField<CalendarDateFormat>),
        );

    dateSelector.onChanged!(CalendarDateFormat.written);
    await tester.pumpAndSettle();

    expect(calendarController.settings.dateFormat, CalendarDateFormat.written);
    expect(calendarPreferences.settings.dateFormat, CalendarDateFormat.written);

    final timeSelector = tester
        .widget<DropdownButtonFormField<CalendarTimeFormat>>(
          find.byType(DropdownButtonFormField<CalendarTimeFormat>),
        );

    timeSelector.onChanged!(CalendarTimeFormat.twelveHour);
    await tester.pumpAndSettle();

    expect(
      calendarController.settings.timeFormat,
      CalendarTimeFormat.twelveHour,
    );
    expect(
      calendarPreferences.settings.timeFormat,
      CalendarTimeFormat.twelveHour,
    );

    final weekdaySwitch = tester.widget<SwitchListTile>(
      find.byType(SwitchListTile),
    );

    weekdaySwitch.onChanged!(true);
    await tester.pumpAndSettle();

    expect(calendarController.settings.showWeekday, isTrue);
    expect(calendarPreferences.settings.showWeekday, isTrue);
    expect(calendarPreferences.setCount, 3);
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

    final addReminder = find.text('Lägg till påminnelse');

    await tester.ensureVisible(addReminder);
    await tester.pumpAndSettle();
    await tester.tap(addReminder);
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

    final saveSettings = find.text('Spara inställningar');

    await tester.scrollUntilVisible(
      saveSettings,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(saveSettings);
    await tester.pumpAndSettle();

    expect(preferences.savedOffsets, [
      const Duration(hours: 5),
      const Duration(hours: 1),
    ]);
    expect(notificationSync.syncCount, 1);

    final statusText = find.text('Påminnelser sparade.');

    expect(statusText, findsOneWidget);

    final semantics = tester.getSemantics(statusText);
    expect(semantics.flagsCollection.isLiveRegion, isTrue);
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

    final saveSettings = find.text('Spara inställningar');

    await tester.scrollUntilVisible(
      saveSettings,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(saveSettings);
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

    final saveSettings = find.text('Spara inställningar');

    await tester.scrollUntilVisible(
      saveSettings,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(saveSettings);
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
    final saveSettings = find.text('Spara inställningar');

    await tester.scrollUntilVisible(
      saveSettings,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(saveSettings);
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
  CalendarDisplayController? calendarDisplayController,
}) async {
  final controller = localeController ?? _createLocaleController();
  final displayController =
      calendarDisplayController ?? _createCalendarDisplayController();

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
          calendarDisplayController: displayController,
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

CalendarDisplayController _createCalendarDisplayController([
  CalendarDisplaySettings settings = const CalendarDisplaySettings(),
]) {
  return CalendarDisplayController(_FakeCalendarDisplayPreferences(settings));
}

class _FakeCalendarDisplayPreferences implements CalendarDisplayPreferences {
  _FakeCalendarDisplayPreferences(this.settings);

  CalendarDisplaySettings settings;
  int setCount = 0;

  @override
  Future<CalendarDisplaySettings> getSettings() async => settings;

  @override
  Future<void> setSettings(CalendarDisplaySettings settings) async {
    setCount++;
    this.settings = settings;
  }
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
