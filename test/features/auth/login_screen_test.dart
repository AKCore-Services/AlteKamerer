import 'package:altekamerer/core/network/access_token_store.dart';
import 'package:altekamerer/core/network/api_exception.dart';
import 'package:altekamerer/core/storage/credential_store.dart';
import 'package:altekamerer/core/theme/app_theme.dart';
import 'package:altekamerer/features/auth/auth_api.dart';
import 'package:altekamerer/features/auth/auth_controller.dart';
import 'package:altekamerer/features/auth/login_screen.dart';
import 'package:altekamerer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('login submits username and password', (
    WidgetTester tester,
  ) async {
    final auth = FakeAuthService();
    final controller = _createController(auth);

    await tester.pumpWidget(_testApp(LoginScreen(authController: controller)));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Användarnamn'),
      ' medlem ',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Lösenord'),
      'secret',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Logga in'));
    await tester.pumpAndSettle();

    expect(auth.username, 'medlem');
    expect(auth.password, 'secret');
    expect(controller.status, AuthStatus.authenticated);
  });

  testWidgets('invalid credentials show feedback', (WidgetTester tester) async {
    final auth = FakeAuthService(
      loginError: const ApiException(
        statusCode: 401,
        message: 'Invalid username or password.',
      ),
    );
    final controller = _createController(auth);

    await tester.pumpWidget(_testApp(LoginScreen(authController: controller)));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Användarnamn'),
      'medlem',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Lösenord'),
      'wrong',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Logga in'));
    await tester.pumpAndSettle();

    expect(find.text('Fel användarnamn eller lösenord.'), findsOneWidget);
    expect(controller.status, AuthStatus.loading);
  });

  testWidgets('empty credentials are rejected locally', (
    WidgetTester tester,
  ) async {
    final auth = FakeAuthService();
    final controller = _createController(auth);

    await tester.pumpWidget(_testApp(LoginScreen(authController: controller)));

    await tester.tap(find.widgetWithText(FilledButton, 'Logga in'));
    await tester.pump();

    expect(find.text('Ange ditt användarnamn.'), findsOneWidget);
    expect(find.text('Ange ditt lösenord.'), findsOneWidget);
    expect(auth.loginCalls, 0);
  });
}

Widget _testApp(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    locale: const Locale('sv'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

AuthController _createController(FakeAuthService auth) {
  return AuthController(FakeCredentialStore(), auth, AccessTokenStore());
}

class FakeCredentialStore implements CredentialStore {
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
  FakeAuthService({this.loginError});

  final Object? loginError;

  String? username;
  String? password;
  int loginCalls = 0;

  @override
  Future<AuthTokens> login({
    required String username,
    required String password,
  }) async {
    loginCalls += 1;
    this.username = username;
    this.password = password;

    if (loginError != null) {
      throw loginError!;
    }

    return const AuthTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );
  }

  @override
  Future<AuthTokens> refresh(String refreshToken) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout(String refreshToken) async {}
}
