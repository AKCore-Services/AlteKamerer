import 'package:altekamerer/app.dart';
import 'package:altekamerer/core/network/access_token_store.dart';
import 'package:altekamerer/core/network/api_exception.dart';
import 'package:altekamerer/core/storage/credential_store.dart';
import 'package:altekamerer/features/auth/auth_api.dart';
import 'package:altekamerer/features/auth/auth_controller.dart';
import 'package:altekamerer/features/auth/login_screen.dart';
import 'package:altekamerer/features/calendar/calendar_api.dart';
import 'package:altekamerer/features/calendar/calendar_cache.dart';
import 'package:altekamerer/features/calendar/calendar_controller.dart';
import 'package:altekamerer/features/calendar/calendar_event.dart';
import 'package:altekamerer/features/event_details/event_details.dart';
import 'package:altekamerer/features/event_details/event_details_api.dart';
import 'package:altekamerer/features/event_details/event_details_cache.dart';
import 'package:altekamerer/features/event_registration/event_registration_api.dart';
import 'package:altekamerer/features/notifications/notification_navigation_controller.dart';
import 'package:altekamerer/features/notifications/notification_sync_service.dart';
import 'package:altekamerer/features/settings/calendar_display_controller.dart';
import 'package:altekamerer/features/settings/calendar_display_preferences.dart';
import 'package:altekamerer/features/settings/locale_controller.dart';
import 'package:altekamerer/features/settings/locale_preferences.dart';
import 'package:altekamerer/features/settings/reminder_preferences.dart';
import 'package:altekamerer/features/settings/settings_backup_file_service.dart';
import 'package:altekamerer/features/settings/settings_backup_service.dart';
import 'package:altekamerer/features/shell/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('explicit Swedish preference renders Swedish UI', (
    WidgetTester tester,
  ) async {
    final authController = _createController();
    final localeController = await _createLocaleController(
      AppLocalePreference.swedish,
    );

    await authController.restoreSession();

    await tester.pumpWidget(
      AlteKamererApp(
        authController: authController,
        calendarController: _createCalendarController(),
        calendarDisplayController: _createCalendarDisplayController(),
        eventDetailsService: _FakeEventDetailsService(),
        eventRegistrationService: _FakeEventRegistrationService(),
        notificationNavigationController: NotificationNavigationController(),
        notificationSync: _FakeNotificationSync(),
        reminderPreferences: _FakeReminderPreferences(),
        localeController: localeController,
        settingsBackupService: _createSettingsBackupService(),
        settingsBackupFileService: _FakeSettingsBackupFileService(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Logga in'), findsWidgets);
    expect(find.text('Log in'), findsNothing);
  });

  testWidgets('explicit English preference renders English UI', (
    WidgetTester tester,
  ) async {
    final authController = _createController();
    final localeController = await _createLocaleController(
      AppLocalePreference.english,
    );

    await authController.restoreSession();

    await tester.pumpWidget(
      AlteKamererApp(
        authController: authController,
        calendarController: _createCalendarController(),
        calendarDisplayController: _createCalendarDisplayController(),
        eventDetailsService: _FakeEventDetailsService(),
        eventRegistrationService: _FakeEventRegistrationService(),
        notificationNavigationController: NotificationNavigationController(),
        notificationSync: _FakeNotificationSync(),
        reminderPreferences: _FakeReminderPreferences(),
        localeController: localeController,
        settingsBackupService: _createSettingsBackupService(),
        settingsBackupFileService: _FakeSettingsBackupFileService(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Log in'), findsWidgets);
    expect(find.text('Logga in'), findsNothing);
  });

  testWidgets('changing locale preference updates running app immediately', (
    WidgetTester tester,
  ) async {
    final authController = _createController();
    final localeController = await _createLocaleController(
      AppLocalePreference.swedish,
    );

    await authController.restoreSession();

    await tester.pumpWidget(
      AlteKamererApp(
        authController: authController,
        calendarController: _createCalendarController(),
        calendarDisplayController: _createCalendarDisplayController(),
        eventDetailsService: _FakeEventDetailsService(),
        eventRegistrationService: _FakeEventRegistrationService(),
        notificationNavigationController: NotificationNavigationController(),
        notificationSync: _FakeNotificationSync(),
        reminderPreferences: _FakeReminderPreferences(),
        localeController: localeController,
        settingsBackupService: _createSettingsBackupService(),
        settingsBackupFileService: _FakeSettingsBackupFileService(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Logga in'), findsWidgets);

    await localeController.setPreference(AppLocalePreference.english);
    await tester.pumpAndSettle();

    expect(find.text('Log in'), findsWidgets);
    expect(find.text('Logga in'), findsNothing);
  });

  testWidgets('system preference follows Swedish system locale', (
    WidgetTester tester,
  ) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.localesTestValue = const [Locale('sv')];

    addTearDown(binding.platformDispatcher.clearLocalesTestValue);

    final authController = _createController();
    final localeController = await _createLocaleController(
      AppLocalePreference.system,
    );

    await authController.restoreSession();

    await tester.pumpWidget(
      AlteKamererApp(
        authController: authController,
        calendarController: _createCalendarController(),
        calendarDisplayController: _createCalendarDisplayController(),
        eventDetailsService: _FakeEventDetailsService(),
        eventRegistrationService: _FakeEventRegistrationService(),
        notificationNavigationController: NotificationNavigationController(),
        notificationSync: _FakeNotificationSync(),
        reminderPreferences: _FakeReminderPreferences(),
        localeController: localeController,
        settingsBackupService: _createSettingsBackupService(),
        settingsBackupFileService: _FakeSettingsBackupFileService(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Logga in'), findsWidgets);
    expect(find.text('Log in'), findsNothing);
  });

  testWidgets(
    'system preference falls back to English for unsupported locale',
    (WidgetTester tester) async {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.localesTestValue = const [Locale('de')];

      addTearDown(binding.platformDispatcher.clearLocalesTestValue);

      final authController = _createController();
      final localeController = await _createLocaleController(
        AppLocalePreference.system,
      );

      await authController.restoreSession();

      await tester.pumpWidget(
        AlteKamererApp(
          authController: authController,
          calendarController: _createCalendarController(),
          calendarDisplayController: _createCalendarDisplayController(),
          eventDetailsService: _FakeEventDetailsService(),
          eventRegistrationService: _FakeEventRegistrationService(),
          notificationNavigationController: NotificationNavigationController(),
          notificationSync: _FakeNotificationSync(),
          reminderPreferences: _FakeReminderPreferences(),
          localeController: localeController,
          settingsBackupService: _createSettingsBackupService(),
          settingsBackupFileService: _FakeSettingsBackupFileService(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Log in'), findsWidgets);
      expect(find.text('Logga in'), findsNothing);
    },
  );

  testWidgets('loading state does not expose login or app shell', (
    WidgetTester tester,
  ) async {
    final controller = _createController();

    await tester.pumpWidget(
      AlteKamererApp(
        authController: controller,
        calendarController: _createCalendarController(),
        calendarDisplayController: _createCalendarDisplayController(),
        eventDetailsService: _FakeEventDetailsService(),
        eventRegistrationService: _FakeEventRegistrationService(),
        notificationNavigationController: NotificationNavigationController(),
        notificationSync: _FakeNotificationSync(),
        reminderPreferences: _FakeReminderPreferences(),
        localeController: await _createLocaleController(),
        settingsBackupService: _createSettingsBackupService(),
        settingsBackupFileService: _FakeSettingsBackupFileService(),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(AppShell), findsNothing);
  });

  testWidgets('unauthenticated state shows login only', (
    WidgetTester tester,
  ) async {
    final controller = _createController();

    await controller.restoreSession();

    await tester.pumpWidget(
      AlteKamererApp(
        authController: controller,
        calendarController: _createCalendarController(),
        calendarDisplayController: _createCalendarDisplayController(),
        eventDetailsService: _FakeEventDetailsService(),
        eventRegistrationService: _FakeEventRegistrationService(),
        notificationNavigationController: NotificationNavigationController(),
        notificationSync: _FakeNotificationSync(),
        reminderPreferences: _FakeReminderPreferences(),
        localeController: await _createLocaleController(),
        settingsBackupService: _createSettingsBackupService(),
        settingsBackupFileService: _FakeSettingsBackupFileService(),
      ),
    );

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
  });

  testWidgets('restored session shows app shell only', (
    WidgetTester tester,
  ) async {
    final controller = _createController(
      refreshToken: 'stored-refresh',
      refreshResult: const AuthTokens(
        accessToken: 'access',
        refreshToken: 'rotated-refresh',
      ),
    );

    await controller.restoreSession();

    await tester.pumpWidget(
      AlteKamererApp(
        authController: controller,
        calendarController: _createCalendarController(),
        calendarDisplayController: _createCalendarDisplayController(),
        eventDetailsService: _FakeEventDetailsService(),
        eventRegistrationService: _FakeEventRegistrationService(),
        notificationNavigationController: NotificationNavigationController(),
        notificationSync: _FakeNotificationSync(),
        reminderPreferences: _FakeReminderPreferences(),
        localeController: await _createLocaleController(),
        settingsBackupService: _createSettingsBackupService(),
        settingsBackupFileService: _FakeSettingsBackupFileService(),
      ),
    );

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('fresh calendar keeps plain calendar app bar title', (
    WidgetTester tester,
  ) async {
    final authController = _createController(
      refreshToken: 'stored-refresh',
      refreshResult: const AuthTokens(
        accessToken: 'access',
        refreshToken: 'rotated-refresh',
      ),
    );
    final calendarController = CalendarController(
      FakeCalendarService(events: const []),
    );

    await authController.restoreSession();
    await calendarController.load();

    await tester.pumpWidget(
      AlteKamererApp(
        authController: authController,
        calendarController: calendarController,
        calendarDisplayController: _createCalendarDisplayController(),
        eventDetailsService: _FakeEventDetailsService(),
        eventRegistrationService: _FakeEventRegistrationService(),
        notificationNavigationController: NotificationNavigationController(),
        notificationSync: _FakeNotificationSync(),
        reminderPreferences: _FakeReminderPreferences(),
        localeController: await _createLocaleController(),
        settingsBackupService: _createSettingsBackupService(),
        settingsBackupFileService: _FakeSettingsBackupFileService(),
      ),
    );

    await tester.pump();

    expect(find.text('Kalender'), findsOneWidget);
    expect(
      find.textContaining('Använder cache från', findRichText: true),
      findsNothing,
    );
  });

  testWidgets('cached fallback is identified in calendar app bar title', (
    WidgetTester tester,
  ) async {
    final authController = _createController(
      refreshToken: 'stored-refresh',
      refreshResult: const AuthTokens(
        accessToken: 'access',
        refreshToken: 'rotated-refresh',
      ),
    );
    final cachedAt = DateTime.utc(2026, 10, 5, 6, 30);
    final calendarController = CalendarController(
      FakeCalendarService(error: StateError('calendar failed')),
      cache: _FakeCalendarCache(
        value: CachedCalendar(events: const [], cachedAt: cachedAt),
      ),
    );

    await authController.restoreSession();
    await calendarController.load();

    await tester.pumpWidget(
      AlteKamererApp(
        authController: authController,
        calendarController: calendarController,
        calendarDisplayController: _createCalendarDisplayController(),
        eventDetailsService: _FakeEventDetailsService(),
        eventRegistrationService: _FakeEventRegistrationService(),
        notificationNavigationController: NotificationNavigationController(),
        notificationSync: _FakeNotificationSync(),
        reminderPreferences: _FakeReminderPreferences(),
        localeController: await _createLocaleController(),
        settingsBackupService: _createSettingsBackupService(),
        settingsBackupFileService: _FakeSettingsBackupFileService(),
      ),
    );

    await tester.pump();

    expect(calendarController.isShowingCachedData, isTrue);
    expect(
      find.textContaining('Använder cache från', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('authentication state change replaces login with app shell', (
    WidgetTester tester,
  ) async {
    final controller = _createController(
      loginResult: const AuthTokens(
        accessToken: 'access',
        refreshToken: 'refresh',
      ),
    );

    await controller.restoreSession();

    await tester.pumpWidget(
      AlteKamererApp(
        authController: controller,
        calendarController: _createCalendarController(),
        calendarDisplayController: _createCalendarDisplayController(),
        eventDetailsService: _FakeEventDetailsService(),
        eventRegistrationService: _FakeEventRegistrationService(),
        notificationNavigationController: NotificationNavigationController(),
        notificationSync: _FakeNotificationSync(),
        reminderPreferences: _FakeReminderPreferences(),
        localeController: await _createLocaleController(),
        settingsBackupService: _createSettingsBackupService(),
        settingsBackupFileService: _FakeSettingsBackupFileService(),
      ),
    );

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);

    await controller.login(username: 'member', password: 'password');

    await tester.pump();

    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);
  });

  testWidgets('temporary restore failure shows retryable error state', (
    WidgetTester tester,
  ) async {
    final auth = FakeAuthService(
      refreshError: const ApiException(
        statusCode: 503,
        message: 'Service unavailable.',
      ),
    );

    final controller = _createController(
      refreshToken: 'stored-refresh',
      authService: auth,
    );
    final eventDetailsCache = _TrackingEventDetailsCache();

    await controller.restoreSession();

    await tester.pumpWidget(
      AlteKamererApp(
        authController: controller,
        calendarController: _createCalendarController(),
        calendarDisplayController: _createCalendarDisplayController(),
        eventDetailsService: _FakeEventDetailsService(),
        eventRegistrationService: _FakeEventRegistrationService(),
        eventDetailsCache: eventDetailsCache,
        notificationNavigationController: NotificationNavigationController(),
        notificationSync: _FakeNotificationSync(),
        reminderPreferences: _FakeReminderPreferences(),
        localeController: await _createLocaleController(),
        settingsBackupService: _createSettingsBackupService(),
        settingsBackupFileService: _FakeSettingsBackupFileService(),
      ),
    );

    expect(find.text('Kunde inte ansluta'), findsOneWidget);
    expect(find.text('Försök igen'), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(AppShell), findsNothing);
    expect(eventDetailsCache.clearCount, 0);

    await tester.tap(find.text('Försök igen'));
    await tester.pump();

    expect(auth.refreshCalls, ['stored-refresh', 'stored-refresh']);
    expect(eventDetailsCache.clearCount, 0);
  });

  testWidgets('revoked stored session returns to login', (
    WidgetTester tester,
  ) async {
    final controller = _createController(
      refreshToken: 'revoked-refresh',
      authService: FakeAuthService(
        refreshError: const ApiException(
          statusCode: 401,
          message: 'Invalid refresh token.',
        ),
      ),
    );

    await controller.restoreSession();

    final eventDetailsCache = _TrackingEventDetailsCache();

    await tester.pumpWidget(
      AlteKamererApp(
        authController: controller,
        calendarController: _createCalendarController(),
        calendarDisplayController: _createCalendarDisplayController(),
        eventDetailsService: _FakeEventDetailsService(),
        eventRegistrationService: _FakeEventRegistrationService(),
        eventDetailsCache: eventDetailsCache,
        notificationNavigationController: NotificationNavigationController(),
        notificationSync: _FakeNotificationSync(),
        reminderPreferences: _FakeReminderPreferences(),
        localeController: await _createLocaleController(),
        settingsBackupService: _createSettingsBackupService(),
        settingsBackupFileService: _FakeSettingsBackupFileService(),
      ),
    );

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);

    await tester.pump();
    expect(eventDetailsCache.clearCount, 1);
  });

  testWidgets('logout returns authenticated app to login', (
    WidgetTester tester,
  ) async {
    final auth = FakeAuthService(
      refreshResult: const AuthTokens(
        accessToken: 'access',
        refreshToken: 'rotated-refresh',
      ),
    );

    final controller = _createController(
      refreshToken: 'stored-refresh',
      authService: auth,
    );
    final eventDetailsCache = _TrackingEventDetailsCache();

    await controller.restoreSession();

    await tester.pumpWidget(
      AlteKamererApp(
        authController: controller,
        calendarController: _createCalendarController(),
        calendarDisplayController: _createCalendarDisplayController(),
        eventDetailsService: _FakeEventDetailsService(),
        eventRegistrationService: _FakeEventRegistrationService(),
        eventDetailsCache: eventDetailsCache,
        notificationNavigationController: NotificationNavigationController(),
        notificationSync: _FakeNotificationSync(),
        reminderPreferences: _FakeReminderPreferences(),
        localeController: await _createLocaleController(),
        settingsBackupService: _createSettingsBackupService(),
        settingsBackupFileService: _FakeSettingsBackupFileService(),
      ),
    );

    expect(find.byType(AppShell), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Logga ut'), findsOneWidget);

    await tester.tap(find.text('Logga ut'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(auth.logoutCalls, ['rotated-refresh']);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
    expect(eventDetailsCache.clearCount, 1);
  });

  testWidgets('failed session refresh clears scheduled notifications', (
    WidgetTester tester,
  ) async {
    final auth = FakeAuthService(
      loginResult: const AuthTokens(
        accessToken: 'access',
        refreshToken: 'refresh',
      ),
      refreshError: const ApiException(
        statusCode: 401,
        message: 'Invalid refresh token.',
      ),
    );

    final controller = _createController(authService: auth);
    final notificationSync = _FakeNotificationSync();
    final eventDetailsCache = _TrackingEventDetailsCache();

    await controller.restoreSession();

    await tester.pumpWidget(
      AlteKamererApp(
        authController: controller,
        calendarController: _createCalendarController(),
        calendarDisplayController: _createCalendarDisplayController(),
        eventDetailsService: _FakeEventDetailsService(),
        eventRegistrationService: _FakeEventRegistrationService(),
        eventDetailsCache: eventDetailsCache,
        notificationNavigationController: NotificationNavigationController(),
        notificationSync: notificationSync,
        reminderPreferences: _FakeReminderPreferences(),
        localeController: await _createLocaleController(),
        settingsBackupService: _createSettingsBackupService(),
        settingsBackupFileService: _FakeSettingsBackupFileService(),
      ),
    );

    await tester.pump();

    expect(find.byType(LoginScreen), findsOneWidget);

    await controller.login(username: 'member', password: 'password');

    await tester.pump();

    expect(find.byType(AppShell), findsOneWidget);

    final clearCountBeforeRefresh = notificationSync.clearCount;
    final cacheClearCountBeforeRefresh = eventDetailsCache.clearCount;

    final refreshed = await controller.refreshSession();

    await tester.pump();

    expect(refreshed, isFalse);
    expect(controller.status, AuthStatus.unauthenticated);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
    expect(notificationSync.clearCount, clearCountBeforeRefresh + 1);
    expect(eventDetailsCache.clearCount, cacheClearCountBeforeRefresh + 1);
  });

  testWidgets(
    'notification waits for authentication before opening app shell',
    (WidgetTester tester) async {
      final notificationNavigationController =
          NotificationNavigationController()..openEvent(42);

      final controller = _createController(
        loginResult: const AuthTokens(
          accessToken: 'access',
          refreshToken: 'refresh',
        ),
      );

      await controller.restoreSession();

      await tester.pumpWidget(
        AlteKamererApp(
          authController: controller,
          calendarController: _createCalendarController(),
          calendarDisplayController: _createCalendarDisplayController(),
          eventDetailsService: _FakeEventDetailsService(),
          eventRegistrationService: _FakeEventRegistrationService(),
          notificationNavigationController: notificationNavigationController,
          notificationSync: _FakeNotificationSync(),
          reminderPreferences: _FakeReminderPreferences(),
          localeController: await _createLocaleController(),
          settingsBackupService: _createSettingsBackupService(),
          settingsBackupFileService: _FakeSettingsBackupFileService(),
        ),
      );

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(notificationNavigationController.pendingEventId, 42);

      await controller.login(username: 'member', password: 'password');

      await tester.pumpAndSettle();

      expect(find.byType(AppShell), findsNothing);
      expect(find.text('Test event'), findsOneWidget);
      expect(notificationNavigationController.pendingEventId, isNull);
    },
  );
}

CalendarDisplayController _createCalendarDisplayController() {
  return CalendarDisplayController(_FakeCalendarDisplayPreferences());
}

class _FakeCalendarDisplayPreferences implements CalendarDisplayPreferences {
  CalendarDisplaySettings settings = const CalendarDisplaySettings();

  @override
  Future<CalendarDisplaySettings> getSettings() async => settings;

  @override
  Future<void> setSettings(CalendarDisplaySettings settings) async {
    this.settings = settings;
  }
}

Future<LocaleController> _createLocaleController([
  AppLocalePreference preference = AppLocalePreference.swedish,
]) async {
  final controller = LocaleController(_FakeLocalePreferences(preference));

  await controller.load();

  return controller;
}

CalendarController _createCalendarController() {
  return CalendarController(FakeCalendarService());
}

AuthController _createController({
  String? refreshToken,
  AuthTokens? loginResult,
  AuthTokens? refreshResult,
  FakeAuthService? authService,
}) {
  return AuthController(
    FakeCredentialStore(refreshToken: refreshToken),
    authService ??
        FakeAuthService(loginResult: loginResult, refreshResult: refreshResult),
    AccessTokenStore(),
  );
}

class FakeCredentialStore implements CredentialStore {
  FakeCredentialStore({this.refreshToken});

  String? refreshToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> writeRefreshToken(String refreshToken) async {
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> clear() async {
    refreshToken = null;
  }
}

class FakeAuthService implements AuthService {
  FakeAuthService({this.loginResult, this.refreshResult, this.refreshError});

  final AuthTokens? loginResult;
  final AuthTokens? refreshResult;
  final Object? refreshError;

  final List<String> refreshCalls = [];
  final List<String> logoutCalls = [];

  @override
  Future<AuthTokens> login({
    required String username,
    required String password,
  }) async {
    return loginResult ??
        const AuthTokens(accessToken: 'access', refreshToken: 'refresh');
  }

  @override
  Future<AuthTokens> refresh(String refreshToken) async {
    refreshCalls.add(refreshToken);

    if (refreshError != null) {
      throw refreshError!;
    }

    return refreshResult ??
        const AuthTokens(accessToken: 'access', refreshToken: 'refresh');
  }

  @override
  Future<void> logout(String refreshToken) async {
    logoutCalls.add(refreshToken);
  }
}

class FakeCalendarService implements CalendarService {
  FakeCalendarService({this.events = const [], this.error});

  final List<CalendarEvent> events;
  final Object? error;

  @override
  Future<List<CalendarEvent>> getCalendar() async {
    if (error != null) {
      throw error!;
    }

    return events;
  }
}

class _FakeCalendarCache implements CalendarCache {
  _FakeCalendarCache({this.value});

  CachedCalendar? value;

  @override
  Future<CachedCalendar?> read() async => value;

  @override
  Future<void> write(
    List<CalendarEvent> events, {
    required DateTime cachedAt,
  }) async {
    value = CachedCalendar(
      events: List.unmodifiable(events),
      cachedAt: cachedAt,
    );
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}

class _TrackingEventDetailsCache implements EventDetailsCache {
  int clearCount = 0;

  @override
  Future<CachedEventDetails?> read(int eventId) async => null;

  @override
  Future<void> write(EventDetails event, {required DateTime cachedAt}) async {}

  @override
  Future<void> clear() async {
    clearCount++;
  }
}

class _FakeEventDetailsService implements EventDetailsService {
  @override
  Future<EventDetails> getEvent(int eventId) async {
    return EventDetails(
      id: eventId,
      type: 'Rep',
      name: 'Test event',
      place: '',
      description: '',
      internalDescription: '',
      date: '2026-09-15',
      halanTime: '',
      thereTime: '',
      startsTime: '',
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

class _FakeEventRegistrationService implements EventRegistrationService {
  @override
  Future<void> saveRegistration(
    int eventId,
    EventRegistrationRequest request,
  ) async {}
}

class _FakeNotificationSync implements NotificationSync {
  int clearCount = 0;

  @override
  Future<void> sync() async {}

  @override
  Future<void> clear() async {
    clearCount++;
  }
}

SettingsBackupService _createSettingsBackupService() {
  final localePreferences = _FakeLocalePreferences();
  final calendarPreferences = _FakeCalendarDisplayPreferences();

  return SettingsBackupService(
    localePreferences: localePreferences,
    reminderPreferences: _FakeReminderPreferences(),
    calendarDisplayPreferences: calendarPreferences,
    localeController: LocaleController(localePreferences),
    calendarDisplayController: CalendarDisplayController(calendarPreferences),
  );
}

class _FakeSettingsBackupFileService implements SettingsBackupFileService {
  @override
  Future<bool> save(String contents) async => true;

  @override
  Future<String?> pick() async => null;
}

class _FakeReminderPreferences implements ReminderPreferences {
  @override
  Future<List<Duration>> getReminderOffsets() async {
    return defaultReminderOffsets;
  }

  @override
  Future<void> setReminderOffsets(List<Duration> offsets) async {}
}

class _FakeLocalePreferences implements LocalePreferences {
  _FakeLocalePreferences([this._preference = AppLocalePreference.system]);

  AppLocalePreference _preference;

  @override
  Future<AppLocalePreference> getLocalePreference() async {
    return _preference;
  }

  @override
  Future<void> setLocalePreference(AppLocalePreference preference) async {
    _preference = preference;
  }
}
