import 'package:altekamerer/core/network/access_token_store.dart';
import 'package:altekamerer/core/network/api_exception.dart';
import 'package:altekamerer/core/storage/credential_store.dart';
import 'package:altekamerer/features/auth/auth_api.dart';
import 'package:altekamerer/features/auth/auth_controller.dart';
import 'package:altekamerer/features/auth/login_screen.dart';
import 'package:altekamerer/features/me/member_credentials_api.dart';
import 'package:altekamerer/features/me/member_password_change_screen.dart';
import 'package:altekamerer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<_Fixture> showEmbeddedPasswordForm(
    WidgetTester tester, {
    Object? passwordChangeError,
  }) async {
    final store = _CredentialStore();
    final authService = _AuthService();
    final accessTokens = AccessTokenStore();

    final auth = AuthController(store, authService, accessTokens);

    await auth.login(username: 'old-member', password: 'CurrentPassword1');

    final credentials = _CredentialsService(
      passwordChangeError: passwordChangeError,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('sv'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ListenableBuilder(
          listenable: auth,
          builder: (context, _) {
            if (!auth.isAuthenticated) {
              return LoginScreen(authController: auth);
            }

            return Scaffold(
              body: SingleChildScrollView(
                child: MemberPasswordChangeScreen(
                  embedded: true,
                  authController: auth,
                  credentialsService: credentials,
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    return _Fixture(
      auth: auth,
      authService: authService,
      credentials: credentials,
      store: store,
      accessTokens: accessTokens,
    );
  }

  Future<void> submitPasswordChange(WidgetTester tester) async {
    final fields = find.byType(TextFormField);

    await tester.enterText(fields.at(0), 'CurrentPassword1');
    await tester.enterText(fields.at(1), 'NewPassword2');
    await tester.enterText(fields.at(2), 'NewPassword2');

    await tester.tap(find.widgetWithText(FilledButton, 'Uppdatera lösenord'));

    await tester.pumpAndSettle();
  }

  testWidgets('successful password change clears credentials and shows login', (
    tester,
  ) async {
    final fixture = await showEmbeddedPasswordForm(tester);

    expect(fixture.auth.status, AuthStatus.authenticated);
    expect(fixture.store.refreshToken, 'refresh-token');
    expect(fixture.accessTokens.accessToken, 'access-token');

    await submitPasswordChange(tester);

    expect(fixture.credentials.passwordRequests, [
      ('CurrentPassword1', 'NewPassword2'),
    ]);

    expect(fixture.auth.status, AuthStatus.unauthenticated);
    expect(fixture.store.refreshToken, isNull);
    expect(fixture.store.lastOnlineAuthAt, isNull);
    expect(fixture.accessTokens.accessToken, isNull);

    // AKCore already revoked mobile sessions after a password change.
    expect(fixture.authService.logoutCalls, isEmpty);

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(MemberPasswordChangeScreen), findsNothing);
    expect(
      find.text('Lösenordet har uppdaterats. Logga in igen för att fortsätta.'),
      findsOneWidget,
    );
  });

  testWidgets('unconfirmed password change also clears credentials', (
    tester,
  ) async {
    final fixture = await showEmbeddedPasswordForm(
      tester,
      passwordChangeError: const ApiException(
        statusCode: 503,
        message: 'password=server-secret',
      ),
    );

    await submitPasswordChange(tester);

    expect(fixture.credentials.passwordRequests, hasLength(1));
    expect(fixture.auth.status, AuthStatus.unauthenticated);
    expect(fixture.store.refreshToken, isNull);
    expect(fixture.accessTokens.accessToken, isNull);
    expect(fixture.authService.logoutCalls, isEmpty);

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(
      find.textContaining('Det gick inte att bekräfta lösenordsändringen.'),
      findsOneWidget,
    );
    expect(find.textContaining('server-secret'), findsNothing);
  });

  testWidgets('rejected password change preserves the authenticated session', (
    tester,
  ) async {
    final fixture = await showEmbeddedPasswordForm(
      tester,
      passwordChangeError: const ApiException(
        statusCode: 400,
        message: 'InvalidCurrentPassword',
      ),
    );

    await submitPasswordChange(tester);

    expect(fixture.credentials.passwordRequests, hasLength(1));
    expect(fixture.auth.status, AuthStatus.authenticated);
    expect(fixture.store.refreshToken, 'refresh-token');
    expect(fixture.accessTokens.accessToken, 'access-token');
    expect(fixture.authService.logoutCalls, isEmpty);

    expect(find.byType(LoginScreen), findsNothing);
    expect(
      find.text('Kontrollera ditt nuvarande och nya lösenord och försök igen.'),
      findsOneWidget,
    );
  });

  testWidgets('leaving the embedded form preserves the session', (
    tester,
  ) async {
    final fixture = await showEmbeddedPasswordForm(tester);

    // Leaving Settings without submitting must not affect authentication.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    expect(fixture.credentials.passwordRequests, isEmpty);
    expect(fixture.auth.status, AuthStatus.authenticated);
    expect(fixture.store.refreshToken, 'refresh-token');
    expect(fixture.accessTokens.accessToken, 'access-token');
    expect(find.byType(MemberPasswordChangeScreen), findsNothing);
    expect(find.byType(LoginScreen), findsNothing);
  });
}

class _Fixture {
  const _Fixture({
    required this.auth,
    required this.authService,
    required this.credentials,
    required this.store,
    required this.accessTokens,
  });

  final AuthController auth;
  final _AuthService authService;
  final _CredentialsService credentials;
  final _CredentialStore store;
  final AccessTokenStore accessTokens;
}

class _CredentialStore implements CredentialStore {
  String? refreshToken;
  DateTime? lastOnlineAuthAt;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> writeRefreshToken(String value) async {
    refreshToken = value;
  }

  @override
  Future<DateTime?> readLastOnlineAuthAt() async => lastOnlineAuthAt;

  @override
  Future<void> writeLastOnlineAuthAt(DateTime value) async {
    lastOnlineAuthAt = value;
  }

  @override
  Future<void> clear() async {
    refreshToken = null;
    lastOnlineAuthAt = null;
  }
}

class _AuthService implements AuthService {
  final List<String> logoutCalls = [];

  @override
  Future<AuthTokens> login({
    required String username,
    required String password,
  }) async {
    return const AuthTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );
  }

  @override
  Future<AuthTokens> refresh(String refreshToken) async {
    return const AuthTokens(
      accessToken: 'refreshed-access',
      refreshToken: 'refreshed-token',
    );
  }

  @override
  Future<void> logout(String refreshToken) async {
    logoutCalls.add(refreshToken);
  }
}

class _CredentialsService implements MemberCredentialsService {
  _CredentialsService({this.passwordChangeError});

  final Object? passwordChangeError;
  final List<(String, String)> passwordRequests = [];

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    passwordRequests.add((currentPassword, newPassword));

    if (passwordChangeError != null) {
      throw passwordChangeError!;
    }
  }

  @override
  Future<String> changeUsername({
    required String newUsername,
    required String currentPassword,
  }) async {
    throw UnsupportedError('Not used in password-change tests.');
  }
}
