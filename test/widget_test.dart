import 'package:altekamerer/app.dart';
import 'package:altekamerer/core/network/access_token_store.dart';
import 'package:altekamerer/core/network/api_exception.dart';
import 'package:altekamerer/core/storage/credential_store.dart';
import 'package:altekamerer/features/auth/auth_api.dart';
import 'package:altekamerer/features/auth/auth_controller.dart';
import 'package:altekamerer/features/auth/login_screen.dart';
import 'package:altekamerer/features/calendar/calendar_api.dart';
import 'package:altekamerer/features/calendar/calendar_controller.dart';
import 'package:altekamerer/features/calendar/calendar_event.dart';
import 'package:altekamerer/features/event_details/event_details.dart';
import 'package:altekamerer/features/event_details/event_details_api.dart';
import 'package:altekamerer/features/event_registration/event_registration_api.dart';
import 'package:altekamerer/features/notifications/notification_navigation_controller.dart';
import 'package:altekamerer/features/notifications/notification_sync_service.dart';
import 'package:altekamerer/features/shell/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('loading state does not expose login or app shell', (
    WidgetTester tester,
  ) async {
    final controller = _createController();

    await tester.pumpWidget(
      AlteKamererApp(
        authController: controller,
        calendarController: _createCalendarController(),
        eventDetailsService: _FakeEventDetailsService(),
        eventRegistrationService: _FakeEventRegistrationService(),
        notificationNavigationController: NotificationNavigationController(),
        notificationSync: _FakeNotificationSync(),
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
        eventDetailsService: _FakeEventDetailsService(),
        eventRegistrationService: _FakeEventRegistrationService(),
        notificationNavigationController: NotificationNavigationController(),
        notificationSync: _FakeNotificationSync(),
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
        eventDetailsService: _FakeEventDetailsService(),
        eventRegistrationService: _FakeEventRegistrationService(),
        notificationNavigationController: NotificationNavigationController(),
        notificationSync: _FakeNotificationSync(),
      ),
    );

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
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
        eventDetailsService: _FakeEventDetailsService(),
        eventRegistrationService: _FakeEventRegistrationService(),
        notificationNavigationController: NotificationNavigationController(),
        notificationSync: _FakeNotificationSync(),
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

    await controller.restoreSession();

    await tester.pumpWidget(
      AlteKamererApp(
        authController: controller,
        calendarController: _createCalendarController(),
        eventDetailsService: _FakeEventDetailsService(),
        eventRegistrationService: _FakeEventRegistrationService(),
        notificationNavigationController: NotificationNavigationController(),
        notificationSync: _FakeNotificationSync(),
      ),
    );

    expect(find.text('Kunde inte ansluta'), findsOneWidget);
    expect(find.text('Försök igen'), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(AppShell), findsNothing);

    await tester.tap(find.text('Försök igen'));
    await tester.pump();

    expect(auth.refreshCalls, ['stored-refresh', 'stored-refresh']);
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

    await tester.pumpWidget(
      AlteKamererApp(
        authController: controller,
        calendarController: _createCalendarController(),
        eventDetailsService: _FakeEventDetailsService(),
        eventRegistrationService: _FakeEventRegistrationService(),
        notificationNavigationController: NotificationNavigationController(),
        notificationSync: _FakeNotificationSync(),
      ),
    );

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
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

    await controller.restoreSession();

    await tester.pumpWidget(
      AlteKamererApp(
        authController: controller,
        calendarController: _createCalendarController(),
        eventDetailsService: _FakeEventDetailsService(),
        eventRegistrationService: _FakeEventRegistrationService(),
        notificationNavigationController: NotificationNavigationController(),
        notificationSync: _FakeNotificationSync(),
      ),
    );

    expect(find.byType(AppShell), findsOneWidget);

    await tester.tap(find.byTooltip('Logga ut'));
    await tester.pumpAndSettle();

    expect(auth.logoutCalls, ['rotated-refresh']);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
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

    await controller.restoreSession();

    await tester.pumpWidget(
      AlteKamererApp(
        authController: controller,
        calendarController: _createCalendarController(),
        eventDetailsService: _FakeEventDetailsService(),
        eventRegistrationService: _FakeEventRegistrationService(),
        notificationNavigationController: NotificationNavigationController(),
        notificationSync: notificationSync,
      ),
    );

    await tester.pump();

    expect(find.byType(LoginScreen), findsOneWidget);

    await controller.login(username: 'member', password: 'password');

    await tester.pump();

    expect(find.byType(AppShell), findsOneWidget);

    final clearCountBeforeRefresh = notificationSync.clearCount;

    final refreshed = await controller.refreshSession();

    await tester.pump();

    expect(refreshed, isFalse);
    expect(controller.status, AuthStatus.unauthenticated);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
    expect(notificationSync.clearCount, clearCountBeforeRefresh + 1);
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
          eventDetailsService: _FakeEventDetailsService(),
          eventRegistrationService: _FakeEventRegistrationService(),
          notificationNavigationController: notificationNavigationController,
          notificationSync: _FakeNotificationSync(),
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
  @override
  Future<List<CalendarEvent>> getCalendar() async {
    return const [];
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
