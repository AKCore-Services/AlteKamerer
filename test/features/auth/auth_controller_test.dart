import 'dart:async';

import 'package:altekamerer/core/network/access_token_store.dart';
import 'package:altekamerer/core/network/api_exception.dart';
import 'package:altekamerer/core/storage/credential_store.dart';
import 'package:altekamerer/features/auth/auth_api.dart';
import 'package:altekamerer/features/auth/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('restoreSession is unauthenticated without refresh token', () async {
    final store = FakeCredentialStore();
    final auth = FakeAuthService();
    final accessTokens = AccessTokenStore();
    final controller = AuthController(store, auth, accessTokens);

    await controller.restoreSession();

    expect(controller.status, AuthStatus.unauthenticated);
    expect(auth.refreshCalls, isEmpty);
    expect(accessTokens.accessToken, isNull);
  });

  test('concurrent refresh calls share one token rotation', () async {
    final store = FakeCredentialStore();
    final refreshCompleter = Completer<AuthTokens>();
    final auth = FakeAuthService(
      loginResult: const AuthTokens(
        accessToken: 'old-access',
        refreshToken: 'old-refresh',
      ),
      refreshCompleter: refreshCompleter,
    );
    final accessTokens = AccessTokenStore();
    final controller = AuthController(store, auth, accessTokens);

    await controller.login(username: 'member', password: 'password');

    final firstRefresh = controller.refreshSession();
    final secondRefresh = controller.refreshSession();

    await Future<void>.delayed(Duration.zero);

    expect(auth.refreshCalls, ['old-refresh']);

    refreshCompleter.complete(
      const AuthTokens(accessToken: 'new-access', refreshToken: 'new-refresh'),
    );

    expect(await Future.wait([firstRefresh, secondRefresh]), [true, true]);
    expect(auth.refreshCalls, ['old-refresh']);
    expect(store.refreshToken, 'new-refresh');
    expect(accessTokens.accessToken, 'new-access');
    expect(controller.status, AuthStatus.authenticated);
  });

  test('restoreSession refreshes and rotates stored credentials', () async {
    final store = FakeCredentialStore(refreshToken: 'old-refresh');
    final auth = FakeAuthService(
      refreshResult: const AuthTokens(
        accessToken: 'new-access',
        refreshToken: 'new-refresh',
      ),
    );
    final accessTokens = AccessTokenStore();
    final controller = AuthController(store, auth, accessTokens);

    await controller.restoreSession();

    expect(auth.refreshCalls, ['old-refresh']);
    expect(store.refreshToken, 'new-refresh');
    expect(accessTokens.accessToken, 'new-access');
    expect(controller.status, AuthStatus.authenticated);
  });

  test('revoked stored session clears credentials', () async {
    final store = FakeCredentialStore(refreshToken: 'revoked-refresh');
    final auth = FakeAuthService(
      refreshError: const ApiException(
        statusCode: 401,
        message: 'Invalid refresh token.',
      ),
    );
    final accessTokens = AccessTokenStore();
    final controller = AuthController(store, auth, accessTokens);

    await controller.restoreSession();

    expect(store.refreshToken, isNull);
    expect(accessTokens.accessToken, isNull);
    expect(controller.status, AuthStatus.unauthenticated);
  });

  test('temporary restore failure preserves refresh credential', () async {
    final store = FakeCredentialStore(refreshToken: 'valid-refresh');
    final auth = FakeAuthService(
      refreshError: const ApiException(
        statusCode: 503,
        message: 'Service unavailable.',
      ),
    );
    final accessTokens = AccessTokenStore();
    final controller = AuthController(store, auth, accessTokens);

    await controller.restoreSession();

    expect(store.refreshToken, 'valid-refresh');
    expect(accessTokens.accessToken, isNull);
    expect(controller.status, AuthStatus.restoreFailed);
  });

  test('login stores refresh token and keeps access token in memory', () async {
    final store = FakeCredentialStore();
    final auth = FakeAuthService(
      loginResult: const AuthTokens(
        accessToken: 'access',
        refreshToken: 'refresh',
      ),
    );
    final accessTokens = AccessTokenStore();
    final controller = AuthController(store, auth, accessTokens);

    await controller.login(username: 'member', password: 'password');

    expect(auth.loginUsername, 'member');
    expect(auth.loginPassword, 'password');
    expect(store.refreshToken, 'refresh');
    expect(accessTokens.accessToken, 'access');
    expect(controller.status, AuthStatus.authenticated);
  });

  test('logout revokes refresh token and clears local session', () async {
    final store = FakeCredentialStore(refreshToken: 'refresh');
    final auth = FakeAuthService(
      refreshResult: const AuthTokens(
        accessToken: 'access',
        refreshToken: 'rotated-refresh',
      ),
    );
    final accessTokens = AccessTokenStore();
    final controller = AuthController(store, auth, accessTokens);

    await controller.restoreSession();
    await controller.logout();

    expect(auth.logoutCalls, ['rotated-refresh']);
    expect(store.refreshToken, isNull);
    expect(accessTokens.accessToken, isNull);
    expect(controller.status, AuthStatus.unauthenticated);
  });

  test('logout clears local session even if server logout fails', () async {
    final store = FakeCredentialStore(refreshToken: 'refresh');
    final auth = FakeAuthService(
      refreshResult: const AuthTokens(
        accessToken: 'access',
        refreshToken: 'rotated-refresh',
      ),
      logoutError: const ApiException(
        statusCode: 503,
        message: 'Service unavailable.',
      ),
    );
    final accessTokens = AccessTokenStore();
    final controller = AuthController(store, auth, accessTokens);

    await controller.restoreSession();

    await expectLater(controller.logout(), throwsA(isA<ApiException>()));

    expect(store.refreshToken, isNull);
    expect(accessTokens.accessToken, isNull);
    expect(controller.status, AuthStatus.unauthenticated);
  });
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
  FakeAuthService({
    this.loginResult,
    this.refreshResult,
    this.refreshError,
    this.refreshCompleter,
    this.logoutError,
  });

  final AuthTokens? loginResult;
  final AuthTokens? refreshResult;
  final Object? refreshError;
  final Completer<AuthTokens>? refreshCompleter;
  final Object? logoutError;

  String? loginUsername;
  String? loginPassword;
  final List<String> refreshCalls = [];
  final List<String> logoutCalls = [];

  @override
  Future<AuthTokens> login({
    required String username,
    required String password,
  }) async {
    loginUsername = username;
    loginPassword = password;

    return loginResult ??
        const AuthTokens(accessToken: 'access', refreshToken: 'refresh');
  }

  @override
  Future<AuthTokens> refresh(String refreshToken) async {
    refreshCalls.add(refreshToken);

    if (refreshCompleter != null) {
      return refreshCompleter!.future;
    }

    if (refreshError != null) {
      throw refreshError!;
    }

    return refreshResult ??
        const AuthTokens(accessToken: 'access', refreshToken: 'refresh');
  }

  @override
  Future<void> logout(String refreshToken) async {
    logoutCalls.add(refreshToken);

    if (logoutError != null) {
      throw logoutError!;
    }
  }
}
