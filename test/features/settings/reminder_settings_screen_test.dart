import 'package:altekamerer/core/diagnostics/diagnostics_service.dart';
import 'package:altekamerer/features/fika/fika_section.dart';
import 'package:altekamerer/features/notifications/notification_sync_service.dart';
import 'package:altekamerer/features/settings/calendar_display_controller.dart';
import 'package:altekamerer/features/settings/calendar_display_preferences.dart';
import 'package:altekamerer/features/settings/locale_controller.dart';
import 'package:altekamerer/features/settings/locale_preferences.dart';
import 'package:altekamerer/features/settings/reminder_preferences.dart';
import 'package:altekamerer/features/settings/reminder_settings_screen.dart';
import 'package:altekamerer/features/settings/settings_backup_file_service.dart';
import 'package:altekamerer/features/settings/settings_backup_service.dart';
import 'package:altekamerer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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

  testWidgets('fika display settings update and reset immediately', (
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

    final visibilitySelector = tester
        .widget<DropdownButtonFormField<FikaVisibility>>(
          find.byType(DropdownButtonFormField<FikaVisibility>),
        );

    visibilitySelector.onChanged!(FikaVisibility.mySection);
    await tester.pumpAndSettle();

    expect(
      calendarController.settings.fikaVisibility,
      FikaVisibility.mySection,
    );
    expect(
      calendarPreferences.settings.fikaVisibility,
      FikaVisibility.mySection,
    );

    final saxField = find.byKey(const ValueKey('fika-emoji-sax'));

    await tester.scrollUntilVisible(
      saxField,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(saxField, '⭐');
    await tester.pumpAndSettle();

    expect(calendarController.settings.fikaEmojiFor(FikaSection.sax), '⭐');

    await tester.enterText(saxField, '');
    await tester.pumpAndSettle();

    await tester.enterText(saxField, 'AB');
    await tester.pumpAndSettle();

    expect(calendarController.settings.fikaEmojiFor(FikaSection.sax), 'A');

    await tester.enterText(saxField, '');
    await tester.pumpAndSettle();

    expect(
      calendarController.settings.fikaEmojiFor(FikaSection.sax),
      defaultFikaEmojis[FikaSection.sax],
    );

    var visibleSaxField = tester.widget<TextField>(
      find.descendant(of: saxField, matching: find.byType(TextField)),
    );
    expect(visibleSaxField.controller?.text, isEmpty);

    await tester.enterText(saxField, '⭐');
    await tester.pumpAndSettle();

    final resetButton = find.text('Återställ fikasymboler');

    await tester.scrollUntilVisible(
      resetButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(resetButton);
    await tester.pumpAndSettle();

    expect(calendarController.settings.fikaEmojis, defaultFikaEmojis);
    expect(
      calendarController.settings.fikaVisibility,
      FikaVisibility.mySection,
    );

    visibleSaxField = tester.widget<TextField>(
      find.descendant(of: saxField, matching: find.byType(TextField)),
    );
    expect(
      visibleSaxField.controller?.text,
      defaultFikaEmojis[FikaSection.sax],
    );
  });

  testWidgets('settings sections can be collapsed and expanded', (
    WidgetTester tester,
  ) async {
    final preferences = _FakeReminderPreferences([]);

    await _pumpScreen(tester, preferences: preferences);

    expect(find.text('Språk'), findsNWidgets(2));

    final languageHeader = find.ancestor(
      of: find.text('Språk').first,
      matching: find.byType(InkWell),
    );

    expect(languageHeader, findsOneWidget);

    await tester.tap(languageHeader);
    await tester.pumpAndSettle();

    expect(find.text('Språk'), findsOneWidget);

    await tester.tap(languageHeader);
    await tester.pumpAndSettle();

    expect(find.text('Språk'), findsNWidgets(2));
  });

  testWidgets(
    'Diagnostics shows version, platform, API server, and recorded errors',
    (WidgetTester tester) async {
      final preferences = _FakeReminderPreferences([]);
      final sharedPreferences = await SharedPreferences.getInstance();
      final diagnosticsService = DiagnosticsService(sharedPreferences);

      await diagnosticsService.recordError(
        subsystem: 'Calendar',
        message: 'Calendar loading failed',
        error: 'HTTP 503',
      );

      await _pumpScreen(
        tester,
        preferences: preferences,
        diagnosticsService: diagnosticsService,
        apiServer: 'https://api.example.test',
        diagnosticsMetadataLoader: () async => const DiagnosticsMetadata(
          version: '1.1.1',
          buildNumber: '42',
          platform: 'Android 16',
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Diagnostik'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('1.1.1'), findsNothing);
      expect(find.text('42'), findsNothing);
      expect(find.text('Android 16'), findsNothing);
      expect(find.text('Calendar: Calendar loading failed'), findsNothing);

      await tester.tap(find.text('Diagnostik'));
      await tester.pumpAndSettle();

      expect(find.text('1.1.1'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('Android 16'), findsOneWidget);
      expect(find.text('https://api.example.test'), findsOneWidget);
      expect(find.text('Calendar: Calendar loading failed'), findsOneWidget);
      expect(find.text('HTTP 503'), findsOneWidget);
    },
  );

  testWidgets('Diagnostics copies a diagnostic report', (
    WidgetTester tester,
  ) async {
    final preferences = _FakeReminderPreferences([]);
    final sharedPreferences = await SharedPreferences.getInstance();
    final diagnosticsService = DiagnosticsService(sharedPreferences);
    String? copiedReport;

    await diagnosticsService.recordError(
      subsystem: 'Authentication',
      message: 'Login failed',
      error: 'HTTP 503',
    );

    await _pumpScreen(
      tester,
      preferences: preferences,
      diagnosticsService: diagnosticsService,
      apiServer: 'https://api.example.test',
      diagnosticsMetadataLoader: () async => const DiagnosticsMetadata(
        version: '1.1.1',
        buildNumber: '42',
        platform: 'Android 16',
      ),
      diagnosticClipboardWriter: (report) async {
        copiedReport = report;
      },
    );

    await tester.scrollUntilVisible(
      find.text('Diagnostik'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Diagnostik'));
    await tester.pumpAndSettle();

    final copyButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Kopiera diagnostikrapport'),
    );
    expect(copyButton.onPressed, isNotNull);

    copyButton.onPressed!();
    await tester.pumpAndSettle();

    expect(copiedReport, isNotNull);
    expect(copiedReport, contains('Version: 1.1.1'));
    expect(copiedReport, contains('Build: 42'));
    expect(copiedReport, contains('Platform: Android 16'));
    expect(copiedReport, contains('API server: https://api.example.test'));
    expect(copiedReport, contains('ERROR Authentication'));
    expect(copiedReport, contains('Login failed'));
    expect(copiedReport, contains('HTTP 503'));
    expect(find.text('Diagnostikrapporten kopierades.'), findsOneWidget);
  });

  testWidgets('Diagnostics clears local diagnostic logs', (
    WidgetTester tester,
  ) async {
    final preferences = _FakeReminderPreferences([]);
    final sharedPreferences = await SharedPreferences.getInstance();
    final diagnosticsService = DiagnosticsService(sharedPreferences);

    await diagnosticsService.recordError(
      subsystem: 'Notifications',
      message: 'Notification synchronization failed',
      error: 'network unavailable',
    );

    await _pumpScreen(
      tester,
      preferences: preferences,
      diagnosticsService: diagnosticsService,
      apiServer: 'https://api.example.test',
      diagnosticsMetadataLoader: () async => const DiagnosticsMetadata(
        version: '1.1.1',
        buildNumber: '42',
        platform: 'Android 16',
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Diagnostik'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Diagnostik'));
    await tester.pumpAndSettle();

    expect(
      find.text('Notifications: Notification synchronization failed'),
      findsOneWidget,
    );

    final clearButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Rensa diagnostikloggar'),
    );
    expect(clearButton.onPressed, isNotNull);

    clearButton.onPressed!();
    await tester.pumpAndSettle();

    expect(await diagnosticsService.readEntries(), isEmpty);
    expect(
      find.text('Notifications: Notification synchronization failed'),
      findsNothing,
    );
    expect(find.text('Inga diagnostikfel har registrerats.'), findsOneWidget);
    expect(find.text('Diagnostikloggarna rensades.'), findsOneWidget);
  });

  testWidgets('About is last, collapsed by default, and shows app version', (
    WidgetTester tester,
  ) async {
    final preferences = _FakeReminderPreferences([]);

    await _pumpScreen(
      tester,
      preferences: preferences,
      appVersionLoader: () async => '9.8.7',
    );

    expect(find.text('AlteKamerer · Version 9.8.7'), findsNothing);

    final aboutHeader = find.text('Om');

    await tester.scrollUntilVisible(
      aboutHeader,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(aboutHeader);
    await tester.pumpAndSettle();

    expect(aboutHeader, findsOneWidget);

    final saveCenter = tester.getCenter(find.text('Spara inställningar'));
    final aboutCenter = tester.getCenter(aboutHeader);
    expect(aboutCenter.dy, greaterThan(saveCenter.dy));

    await tester.tap(aboutHeader);
    await tester.pumpAndSettle();

    expect(find.text('AlteKamerer · Version 9.8.7'), findsOneWidget);
  });

  testWidgets('About describes the app and launches repository URLs', (
    WidgetTester tester,
  ) async {
    final preferences = _FakeReminderPreferences([]);
    final launchedUris = <Uri>[];

    await _pumpScreen(
      tester,
      preferences: preferences,
      appVersionLoader: () async => '1.1.1',
      externalUrlLauncher: (uri) async {
        launchedUris.add(uri);
        return true;
      },
    );

    final aboutHeader = find.text('Om');

    await tester.scrollUntilVisible(
      aboutHeader,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(aboutHeader);
    await tester.pumpAndSettle();

    await tester.tap(aboutHeader);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Flutter och AKCores mobil-API'),
      findsOneWidget,
    );
    expect(
      find.text('Om du vill hjälpa till att utveckla appen'),
      findsOneWidget,
    );

    final akCoreRepository = find.text('AKCore-kodförråd');
    await tester.ensureVisible(akCoreRepository);
    await tester.pumpAndSettle();
    await tester.tap(akCoreRepository);
    await tester.pump();

    final alteKamererRepository = find.text('AlteKamerer-kodförråd');
    await tester.ensureVisible(alteKamererRepository);
    await tester.pumpAndSettle();
    await tester.tap(alteKamererRepository);
    await tester.pump();

    expect(
      launchedUris,
      equals([
        Uri.parse('https://github.com/LudHag/AKCore'),
        Uri.parse('https://github.com/AKCore-Services/AlteKamerer'),
      ]),
    );
  });

  testWidgets('About is localized in English', (WidgetTester tester) async {
    final preferences = _FakeReminderPreferences([]);

    await _pumpScreen(
      tester,
      preferences: preferences,
      locale: const Locale('en'),
      appVersionLoader: () async => '1.1.1',
    );

    await tester.scrollUntilVisible(
      find.text('About'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();

    expect(find.text('AlteKamerer · Version 1.1.1'), findsOneWidget);
    expect(
      find.textContaining('Flutter and the AKCore mobile API'),
      findsOneWidget,
    );
    expect(find.text('If you want to help develop this app'), findsOneWidget);
    expect(find.text('AKCore repository'), findsOneWidget);
    expect(find.text('AlteKamerer repository'), findsOneWidget);
  });

  testWidgets('About supports large text and exposes expansion semantics', (
    WidgetTester tester,
  ) async {
    final preferences = _FakeReminderPreferences([]);
    final semantics = tester.ensureSemantics();

    await _pumpScreen(
      tester,
      preferences: preferences,
      appVersionLoader: () async => '1.1.1',
      textScaler: const TextScaler.linear(2),
    );

    await tester.scrollUntilVisible(
      find.text('Om'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.text('Om')),
      matchesSemantics(
        label: 'Om',
        isButton: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
        hasExpandedState: true,
        isExpanded: false,
      ),
    );

    await tester.tap(find.text('Om'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    expect(
      tester.getSemantics(find.text('Om')),
      matchesSemantics(
        isButton: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
        hasExpandedState: true,
        isExpanded: true,
      ),
    );

    await tester.scrollUntilVisible(
      find.text('AlteKamerer-kodförråd'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('AlteKamerer-kodförråd'), findsOneWidget);

    semantics.dispose();
  });

  testWidgets('exports settings through the file service', (
    WidgetTester tester,
  ) async {
    final preferences = _FakeReminderPreferences([
      const Duration(hours: 5),
      const Duration(hours: 1),
    ]);
    final localePreferences = _FakeLocalePreferences(
      AppLocalePreference.swedish,
    );
    final localeController = LocaleController(localePreferences);
    await localeController.load();

    final calendarPreferences = _FakeCalendarDisplayPreferences(
      const CalendarDisplaySettings(
        dateFormat: CalendarDateFormat.numeric,
        timeFormat: CalendarTimeFormat.twelveHour,
        showWeekday: true,
      ),
    );
    final calendarController = CalendarDisplayController(calendarPreferences);
    await calendarController.load();

    final backupService = SettingsBackupService(
      localePreferences: localePreferences,
      reminderPreferences: preferences,
      calendarDisplayPreferences: calendarPreferences,
      localeController: localeController,
      calendarDisplayController: calendarController,
    );
    final fileService = _FakeSettingsBackupFileService();

    await _pumpScreen(
      tester,
      preferences: preferences,
      localeController: localeController,
      calendarDisplayController: calendarController,
      settingsBackupService: backupService,
      settingsBackupFileService: fileService,
    );

    await _openBackupSection(tester);
    await tester.tap(find.text('Exportera inställningar'));
    await tester.pumpAndSettle();

    expect(fileService.savedContents, isNotNull);
    expect(fileService.savedContents, contains('"schemaVersion": 1'));
    expect(fileService.savedContents, contains('"language": "sv"'));
    expect(fileService.savedContents, contains('"offsetMinutes": ['));
    expect(fileService.savedContents, contains('300'));
    expect(fileService.savedContents, contains('60'));
    expect(fileService.savedContents, isNot(contains('token')));
    expect(find.text('Inställningarna exporterades.'), findsOneWidget);
  });

  testWidgets('invalid import is rejected without confirmation or writes', (
    WidgetTester tester,
  ) async {
    final preferences = _FakeReminderPreferences([const Duration(hours: 5)]);
    final localePreferences = _FakeLocalePreferences(
      AppLocalePreference.swedish,
    );
    final localeController = LocaleController(localePreferences);
    await localeController.load();

    final calendarPreferences = _FakeCalendarDisplayPreferences(
      const CalendarDisplaySettings(),
    );
    final calendarController = CalendarDisplayController(calendarPreferences);
    await calendarController.load();

    final backupService = SettingsBackupService(
      localePreferences: localePreferences,
      reminderPreferences: preferences,
      calendarDisplayPreferences: calendarPreferences,
      localeController: localeController,
      calendarDisplayController: calendarController,
    );
    final fileService = _FakeSettingsBackupFileService(
      pickedContents: '''
{
  "schemaVersion": 1,
  "settings": {
    "language": "invalid"
  }
}
''',
    );

    await _pumpScreen(
      tester,
      preferences: preferences,
      localeController: localeController,
      calendarDisplayController: calendarController,
      settingsBackupService: backupService,
      settingsBackupFileService: fileService,
    );

    await _openBackupSection(tester);
    await tester.tap(find.text('Importera inställningar'));
    await tester.pumpAndSettle();

    expect(find.text('Importera inställningar?'), findsNothing);
    expect(
      find.text('Det här är inte en giltig AlteKamerer-inställningsfil.'),
      findsOneWidget,
    );
    expect(localePreferences.setCount, 0);
    expect(preferences.setCount, 0);
    expect(calendarPreferences.setCount, 0);
  });

  testWidgets(
    'valid import requires confirmation and cancel preserves settings',
    (WidgetTester tester) async {
      final preferences = _FakeReminderPreferences([const Duration(hours: 5)]);
      final localePreferences = _FakeLocalePreferences(
        AppLocalePreference.swedish,
      );
      final localeController = LocaleController(localePreferences);
      await localeController.load();

      final calendarPreferences = _FakeCalendarDisplayPreferences(
        const CalendarDisplaySettings(),
      );
      final calendarController = CalendarDisplayController(calendarPreferences);
      await calendarController.load();

      final backupService = SettingsBackupService(
        localePreferences: localePreferences,
        reminderPreferences: preferences,
        calendarDisplayPreferences: calendarPreferences,
        localeController: localeController,
        calendarDisplayController: calendarController,
      );
      final fileService = _FakeSettingsBackupFileService(
        pickedContents: '''
{
  "schemaVersion": 1,
  "settings": {
    "language": "en",
    "reminders": {
      "offsetMinutes": [30]
    }
  }
}
''',
      );

      await _pumpScreen(
        tester,
        preferences: preferences,
        localeController: localeController,
        calendarDisplayController: calendarController,
        settingsBackupService: backupService,
        settingsBackupFileService: fileService,
      );

      await _openBackupSection(tester);
      await tester.tap(find.text('Importera inställningar'));
      await tester.pumpAndSettle();

      expect(find.text('Importera inställningar?'), findsOneWidget);
      expect(localePreferences.setCount, 0);
      expect(preferences.setCount, 0);
      expect(calendarPreferences.setCount, 0);

      await tester.tap(find.text('Avbryt'));
      await tester.pumpAndSettle();

      expect(localeController.preference, AppLocalePreference.swedish);
      expect(await preferences.getReminderOffsets(), [
        const Duration(hours: 5),
      ]);
      expect(localePreferences.setCount, 0);
      expect(preferences.setCount, 0);
      expect(calendarPreferences.setCount, 0);
    },
  );

  testWidgets('confirmed import applies settings and refreshes reminders', (
    WidgetTester tester,
  ) async {
    final preferences = _FakeReminderPreferences([const Duration(hours: 5)]);
    final notificationSync = _FakeNotificationSync();
    final localePreferences = _FakeLocalePreferences(
      AppLocalePreference.swedish,
    );
    final localeController = LocaleController(localePreferences);
    await localeController.load();

    final calendarPreferences = _FakeCalendarDisplayPreferences(
      const CalendarDisplaySettings(),
    );
    final calendarController = CalendarDisplayController(calendarPreferences);
    await calendarController.load();

    final backupService = SettingsBackupService(
      localePreferences: localePreferences,
      reminderPreferences: preferences,
      calendarDisplayPreferences: calendarPreferences,
      localeController: localeController,
      calendarDisplayController: calendarController,
    );
    final fileService = _FakeSettingsBackupFileService(
      pickedContents: '''
{
  "schemaVersion": 1,
  "settings": {
    "language": "en",
    "reminders": {
      "offsetMinutes": [30]
    },
    "calendarDisplay": {
      "dateFormat": "written",
      "timeFormat": "12-hour",
      "showWeekday": true,
        "fikaVisibility": "all",
        "fikaEmojis": {
          "sax": "S"
        }
    }
  }
}
''',
    );

    await _pumpScreen(
      tester,
      preferences: preferences,
      notificationSync: notificationSync,
      localeController: localeController,
      calendarDisplayController: calendarController,
      settingsBackupService: backupService,
      settingsBackupFileService: fileService,
    );

    await _openBackupSection(tester);
    await tester.tap(find.text('Importera inställningar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Importera').last);
    await tester.pumpAndSettle();

    expect(localeController.preference, AppLocalePreference.english);
    expect(calendarController.settings.dateFormat, CalendarDateFormat.written);
    expect(
      calendarController.settings.timeFormat,
      CalendarTimeFormat.twelveHour,
    );
    expect(calendarController.settings.showWeekday, isTrue);
    expect(calendarController.settings.fikaVisibility, FikaVisibility.all);
    expect(calendarController.settings.fikaEmojiFor(FikaSection.sax), 'S');

    final calendarDisplayHeader = find.text('Kalendervisning');
    await tester.scrollUntilVisible(
      calendarDisplayHeader,
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(calendarDisplayHeader);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('fika-visibility-all')), findsOneWidget);

    final saxField = find.byKey(const ValueKey('fika-emoji-sax'));
    final visibleSaxField = tester.widget<TextField>(
      find.descendant(of: saxField, matching: find.byType(TextField)),
    );
    expect(visibleSaxField.controller?.text, 'S');

    expect(await preferences.getReminderOffsets(), [
      const Duration(minutes: 30),
    ]);
    expect(notificationSync.syncCount, 1);
  });

  testWidgets('canceling file selection leaves settings unchanged', (
    WidgetTester tester,
  ) async {
    final preferences = _FakeReminderPreferences([const Duration(hours: 5)]);
    final fileService = _FakeSettingsBackupFileService();

    await _pumpScreen(
      tester,
      preferences: preferences,
      settingsBackupFileService: fileService,
    );

    await _openBackupSection(tester);
    await tester.tap(find.text('Importera inställningar'));
    await tester.pumpAndSettle();

    expect(find.text('Importera inställningar?'), findsNothing);
    expect(preferences.setCount, 0);
  });

  testWidgets('loads configured reminders', (WidgetTester tester) async {
    final preferences = _FakeReminderPreferences([
      const Duration(hours: 5),
      const Duration(hours: 1),
    ]);

    await _pumpScreen(tester, preferences: preferences);
    await _scrollToReminders(tester);

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
    await _scrollToReminders(tester);

    expect(find.text('Inga påminnelser är aktiverade.'), findsOneWidget);
  });

  testWidgets('adds and removes reminders', (WidgetTester tester) async {
    final preferences = _FakeReminderPreferences([]);

    await _pumpScreen(tester, preferences: preferences);
    await _scrollToReminders(tester);

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

    await _scrollToReminders(tester);

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
  Locale locale = const Locale('sv'),
  DiagnosticsService? diagnosticsService,
  String? apiServer,
  DiagnosticsMetadataLoader? diagnosticsMetadataLoader,
  DiagnosticClipboardWriter? diagnosticClipboardWriter,
  AppVersionLoader? appVersionLoader,
  ExternalUrlLauncher? externalUrlLauncher,
  SettingsBackupService? settingsBackupService,
  SettingsBackupFileService? settingsBackupFileService,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  final controller = localeController ?? _createLocaleController();
  final displayController =
      calendarDisplayController ?? _createCalendarDisplayController();

  final backupLocalePreferences = _FakeLocalePreferences(controller.preference);
  final backupCalendarPreferences = _FakeCalendarDisplayPreferences(
    displayController.settings,
  );
  final backupService =
      settingsBackupService ??
      SettingsBackupService(
        localePreferences: backupLocalePreferences,
        reminderPreferences: preferences,
        calendarDisplayPreferences: backupCalendarPreferences,
        localeController: controller,
        calendarDisplayController: displayController,
      );

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        );
      },
      home: Scaffold(
        body: ReminderSettingsScreen(
          reminderPreferences: preferences,
          notificationSync: notificationSync ?? _FakeNotificationSync(),
          localeController: controller,
          calendarDisplayController: displayController,
          settingsBackupService: backupService,
          settingsBackupFileService:
              settingsBackupFileService ?? _FakeSettingsBackupFileService(),
          diagnosticsService: diagnosticsService,
          apiServer: apiServer,
          diagnosticsMetadataLoader: diagnosticsMetadataLoader,
          diagnosticClipboardWriter: diagnosticClipboardWriter,
          appVersionLoader: appVersionLoader,
          externalUrlLauncher: externalUrlLauncher,
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

Future<void> _scrollToReminders(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Påminnelser'),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> _openBackupSection(WidgetTester tester) async {
  final scrollable = find.byType(Scrollable).first;
  final backupHeader = find.text('Säkerhetskopiera och återställ');

  await tester.scrollUntilVisible(backupHeader, 300, scrollable: scrollable);
  await tester.pumpAndSettle();
  await tester.tap(backupHeader);
  await tester.pumpAndSettle();

  await tester.scrollUntilVisible(
    find.text('Importera inställningar'),
    100,
    scrollable: scrollable,
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
  _FakeReminderPreferences(List<Duration> offsets)
    : offsets = List<Duration>.of(offsets);

  List<Duration> offsets;
  List<Duration>? savedOffsets;
  int setCount = 0;

  @override
  Future<List<Duration>> getReminderOffsets() async {
    return List.of(offsets);
  }

  @override
  Future<void> setReminderOffsets(List<Duration> offsets) async {
    setCount++;
    this.offsets = List.of(offsets);
    savedOffsets = List.of(offsets);
  }
}

class _FakeLocalePreferences implements LocalePreferences {
  _FakeLocalePreferences(this.preference);

  AppLocalePreference preference;
  int setCount = 0;

  @override
  Future<AppLocalePreference> getLocalePreference() async {
    return preference;
  }

  @override
  Future<void> setLocalePreference(AppLocalePreference preference) async {
    setCount++;
    this.preference = preference;
  }
}

class _FakeSettingsBackupFileService implements SettingsBackupFileService {
  _FakeSettingsBackupFileService({this.pickedContents});

  final String? pickedContents;
  String? savedContents;

  @override
  Future<bool> save(String contents) async {
    savedContents = contents;
    return true;
  }

  @override
  Future<String?> pick() async => pickedContents;
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
