import 'package:altekamerer/core/network/access_token_store.dart';
import 'package:altekamerer/core/storage/credential_store.dart';
import 'package:altekamerer/features/auth/auth_api.dart';
import 'package:altekamerer/features/auth/auth_controller.dart';
import 'package:altekamerer/features/calendar/calendar_api.dart';
import 'package:altekamerer/features/calendar/calendar_controller.dart';
import 'package:altekamerer/features/calendar/calendar_event.dart';
import 'package:altekamerer/features/event_details/event_details.dart';
import 'package:altekamerer/features/event_details/event_details_api.dart';
import 'package:altekamerer/features/event_details/event_details_screen.dart';
import 'package:altekamerer/features/event_registration/event_registration_api.dart';
import 'package:altekamerer/features/event_registration/event_registration_screen.dart';
import 'package:altekamerer/features/notifications/notification_navigation_controller.dart';
import 'package:altekamerer/features/notifications/notification_sync_service.dart';
import 'package:altekamerer/features/settings/locale_controller.dart';
import 'package:altekamerer/features/settings/locale_preferences.dart';
import 'package:altekamerer/features/settings/reminder_preferences.dart';
import 'package:altekamerer/features/shell/app_shell.dart';
import 'package:altekamerer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tapping calendar event opens matching event details', (
    WidgetTester tester,
  ) async {
    final calendarController = CalendarController(_FakeCalendarService());
    final notificationSync = _FakeNotificationSync(calendarController);
    final eventDetailsService = _FakeEventDetailsService();
    final authController = AuthController(
      _FakeCredentialStore(),
      _FakeAuthService(),
      AccessTokenStore(),
    );
    final eventRegistrationService = _FakeEventRegistrationService();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('sv'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AppShell(
          authController: authController,
          calendarController: calendarController,
          eventDetailsService: eventDetailsService,
          eventRegistrationService: eventRegistrationService,
          notificationNavigationController: NotificationNavigationController(),
          notificationSync: notificationSync,
          reminderPreferences: _FakeReminderPreferences(),
          localeController: _createLocaleController(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Kårhusrep'), findsOneWidget);

    await tester.tap(find.text('Kårhusrep'));
    await tester.pumpAndSettle();

    expect(find.byType(EventDetailsScreen), findsOneWidget);
    expect(eventDetailsService.requestedEventIds, [42]);
    expect(find.text('Tisdagsrep'), findsOneWidget);
  });

  testWidgets('successful registration reloads event details', (
    WidgetTester tester,
  ) async {
    final calendarController = CalendarController(_FakeCalendarService());
    final notificationSync = _FakeNotificationSync(calendarController);
    final eventDetailsService = _FakeEventDetailsService();
    final registrationService = _FakeEventRegistrationService();

    final authController = AuthController(
      _FakeCredentialStore(),
      _FakeAuthService(),
      AccessTokenStore(),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('sv'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AppShell(
          authController: authController,
          calendarController: calendarController,
          eventDetailsService: eventDetailsService,
          eventRegistrationService: registrationService,
          notificationNavigationController: NotificationNavigationController(),
          notificationSync: notificationSync,
          reminderPreferences: _FakeReminderPreferences(),
          localeController: _createLocaleController(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Kårhusrep'));
    await tester.pumpAndSettle();

    expect(eventDetailsService.requestedEventIds, [42]);

    await tester.ensureVisible(find.text('Anmäl dig'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anmäl dig'));
    await tester.pumpAndSettle();

    expect(find.byType(EventRegistrationScreen), findsOneWidget);

    final whereDropdown = find.byType(DropdownButtonFormField<String>).first;

    await tester.tap(whereDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Direkt').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Spara anmälan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spara anmälan'));
    await tester.pumpAndSettle();

    expect(registrationService.eventIds, [42]);
    expect(registrationService.requests.single.where, 'Direkt');

    expect(eventDetailsService.requestedEventIds, [42, 42]);

    expect(notificationSync.syncCount, 2);
  });

  testWidgets('notification target opens matching event details', (
    WidgetTester tester,
  ) async {
    final calendarController = CalendarController(_FakeCalendarService());
    final notificationSync = _FakeNotificationSync(calendarController);
    final eventDetailsService = _FakeEventDetailsService();
    final registrationService = _FakeEventRegistrationService();
    final notificationNavigationController = NotificationNavigationController();

    final authController = AuthController(
      _FakeCredentialStore(),
      _FakeAuthService(),
      AccessTokenStore(),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('sv'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AppShell(
          authController: authController,
          calendarController: calendarController,
          eventDetailsService: eventDetailsService,
          eventRegistrationService: registrationService,
          notificationNavigationController: notificationNavigationController,
          notificationSync: notificationSync,
          reminderPreferences: _FakeReminderPreferences(),
          localeController: _createLocaleController(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    notificationNavigationController.openEvent(84);

    await tester.pumpAndSettle();

    expect(find.byType(EventDetailsScreen), findsOneWidget);
    expect(eventDetailsService.requestedEventIds, [84]);
  });

  testWidgets('pending notification opens after shell is created', (
    WidgetTester tester,
  ) async {
    final notificationNavigationController = NotificationNavigationController()
      ..openEvent(84);

    final eventDetailsService = _FakeEventDetailsService();
    final calendarController = CalendarController(_FakeCalendarService());
    final notificationSync = _FakeNotificationSync(calendarController);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('sv'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AppShell(
          authController: AuthController(
            _FakeCredentialStore(),
            _FakeAuthService(),
            AccessTokenStore(),
          ),
          calendarController: calendarController,
          eventDetailsService: eventDetailsService,
          eventRegistrationService: _FakeEventRegistrationService(),
          notificationNavigationController: notificationNavigationController,
          notificationSync: notificationSync,
          reminderPreferences: _FakeReminderPreferences(),
          localeController: _createLocaleController(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(EventDetailsScreen), findsOneWidget);
    expect(eventDetailsService.requestedEventIds, [84]);
    expect(notificationNavigationController.pendingEventId, isNull);
  });

  testWidgets('drawer switches between calendar and settings', (
    WidgetTester tester,
  ) async {
    final calendarController = CalendarController(_FakeCalendarService());

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('sv'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AppShell(
          authController: AuthController(
            _FakeCredentialStore(),
            _FakeAuthService(),
            AccessTokenStore(),
          ),
          calendarController: calendarController,
          eventDetailsService: _FakeEventDetailsService(),
          eventRegistrationService: _FakeEventRegistrationService(),
          notificationNavigationController: NotificationNavigationController(),
          notificationSync: _FakeNotificationSync(calendarController),
          reminderPreferences: _FakeReminderPreferences(),
          localeController: _createLocaleController(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Kårhusrep'), findsOneWidget);
    expect(find.text('Påminnelser'), findsNothing);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Inställningar'));
    await tester.pumpAndSettle();

    expect(find.text('Påminnelser'), findsOneWidget);
    expect(find.text('Kårhusrep'), findsNothing);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kalender'));
    await tester.pumpAndSettle();

    expect(find.text('Kårhusrep'), findsOneWidget);
    expect(find.text('Påminnelser'), findsNothing);
  });
}

class _FakeCalendarService implements CalendarService {
  @override
  Future<List<CalendarEvent>> getCalendar() async {
    return const [
      CalendarEvent(
        id: 42,
        type: 'Kårhusrep',
        name: 'Tisdagsrep',
        place: 'Kårhuset',
        description: '',
        internalDescription: '',
        date: '2026-09-15',
        halanTime: '18:00',
        thereTime: '18:30',
        startsTime: '19:00',
        playDuration: '',
        stand: '',
        signupState: null,
        coming: 0,
        notComing: 0,
        disabled: false,
      ),
    ];
  }
}

class _FakeEventDetailsService implements EventDetailsService {
  final List<int> requestedEventIds = [];

  @override
  Future<EventDetails> getEvent(int eventId) async {
    requestedEventIds.add(eventId);

    return EventDetails(
      id: eventId,
      type: 'Kårhusrep',
      name: 'Tisdagsrep',
      place: 'Kårhuset',
      description: 'Ordinarie repetition',
      internalDescription: '',
      date: '2026-09-15',
      halanTime: '18:00',
      thereTime: '18:30',
      startsTime: '19:00',
      playDuration: '',
      stand: '',
      signupState: null,
      coming: 0,
      notComing: 0,
      disabled: false,
      registrationAvailable: true,
      registration: const EventRegistrationSelection(
        where: null,
        car: false,
        instrument: true,
        comment: '',
        selectedInstrument: null,
        availableInstruments: [],
      ),
      attendees: const [],
    );
  }
}

class _FakeCredentialStore implements CredentialStore {
  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> writeRefreshToken(String refreshToken) async {}

  @override
  Future<void> clear() async {}
}

class _FakeAuthService implements AuthService {
  @override
  Future<AuthTokens> login({
    required String username,
    required String password,
  }) async {
    return const AuthTokens(accessToken: 'access', refreshToken: 'refresh');
  }

  @override
  Future<AuthTokens> refresh(String refreshToken) async {
    return const AuthTokens(accessToken: 'access', refreshToken: 'refresh');
  }

  @override
  Future<void> logout(String refreshToken) async {}
}

class _FakeEventRegistrationService implements EventRegistrationService {
  final List<int> eventIds = [];
  final List<EventRegistrationRequest> requests = [];

  @override
  Future<void> saveRegistration(
    int eventId,
    EventRegistrationRequest request,
  ) async {
    eventIds.add(eventId);
    requests.add(request);
  }
}

class _FakeNotificationSync implements NotificationSync {
  _FakeNotificationSync(this._calendarController);

  final CalendarController _calendarController;

  int syncCount = 0;
  int clearCount = 0;

  @override
  Future<void> sync() async {
    syncCount++;
    await _calendarController.load();
  }

  @override
  Future<void> clear() async {
    clearCount++;
  }
}

LocaleController _createLocaleController() {
  return LocaleController(_FakeLocalePreferences());
}

class _FakeLocalePreferences implements LocalePreferences {
  AppLocalePreference _preference = AppLocalePreference.system;

  @override
  Future<AppLocalePreference> getLocalePreference() async {
    return _preference;
  }

  @override
  Future<void> setLocalePreference(AppLocalePreference preference) async {
    _preference = preference;
  }
}

class _FakeReminderPreferences implements ReminderPreferences {
  @override
  Future<List<Duration>> getReminderOffsets() async {
    return defaultReminderOffsets;
  }

  @override
  Future<void> setReminderOffsets(List<Duration> offsets) async {}
}
