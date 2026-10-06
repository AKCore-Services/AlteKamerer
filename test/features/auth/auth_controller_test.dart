import 'dart:async';

import 'package:altekamerer/core/diagnostics/diagnostics_service.dart';
import 'package:altekamerer/core/network/access_token_store.dart';
import 'package:altekamerer/core/network/api_exception.dart';
import 'package:altekamerer/core/storage/credential_store.dart';
import 'package:altekamerer/features/auth/auth_api.dart';
import 'package:altekamerer/features/auth/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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
    // Keep the first refresh pending while a second caller arrives, so
    // the test can verify that both share the same token-rotation request.
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
    final now = DateTime.utc(2026, 10, 6, 10);
    final store = FakeCredentialStore(refreshToken: 'old-refresh');
    final auth = FakeAuthService(
      refreshResult: const AuthTokens(
        accessToken: 'new-access',
        refreshToken: 'new-refresh',
      ),
    );
    final accessTokens = AccessTokenStore();
    final controller = AuthController(
      store,
      auth,
      accessTokens,
      now: () => now,
    );

    await controller.restoreSession();

    expect(auth.refreshCalls, ['old-refresh']);
    expect(store.refreshToken, 'new-refresh');
    expect(store.lastOnlineAuthAt, now);
    expect(accessTokens.accessToken, 'new-access');
    expect(controller.status, AuthStatus.authenticated);
  });

  test('revoked stored session clears credentials', () async {
    final store = FakeCredentialStore(
      refreshToken: 'revoked-refresh',
      lastOnlineAuthAt: DateTime.utc(2026, 10, 6, 9),
    );
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
    expect(store.lastOnlineAuthAt, isNull);
    expect(accessTokens.accessToken, isNull);
    expect(controller.status, AuthStatus.unauthenticated);
  });

  test(
    'temporary restore failure opens offline session within 24-hour grace',
    () async {
      final now = DateTime.utc(2026, 10, 6, 10);
      final store = FakeCredentialStore(
        refreshToken: 'valid-refresh',
        lastOnlineAuthAt: now.subtract(const Duration(hours: 23)),
      );
      final auth = FakeAuthService(
        refreshError: const ApiException(
          statusCode: 503,
          message: 'Service unavailable.',
        ),
      );
      final accessTokens = AccessTokenStore();
      final controller = AuthController(
        store,
        auth,
        accessTokens,
        now: () => now,
      );

      await controller.restoreSession();

      expect(store.refreshToken, 'valid-refresh');
      expect(accessTokens.accessToken, isNull);
      expect(controller.status, AuthStatus.offlineAuthenticated);
      expect(controller.isAuthenticated, isTrue);
    },
  );

  test('temporary restore failure rejects expired offline grace', () async {
    final now = DateTime.utc(2026, 10, 6, 10);
    final store = FakeCredentialStore(
      refreshToken: 'valid-refresh',
      lastOnlineAuthAt: now.subtract(const Duration(hours: 24)),
    );
    final auth = FakeAuthService(
      refreshError: const ApiException(
        statusCode: 503,
        message: 'Service unavailable.',
      ),
    );
    final controller = AuthController(
      store,
      auth,
      AccessTokenStore(),
      now: () => now,
    );

    await controller.restoreSession();

    expect(store.refreshToken, 'valid-refresh');
    expect(controller.status, AuthStatus.restoreFailed);
    expect(controller.isAuthenticated, isFalse);
  });

  test(
    'temporary restore failure rejects missing online-auth timestamp',
    () async {
      final store = FakeCredentialStore(refreshToken: 'valid-refresh');
      final auth = FakeAuthService(
        refreshError: const ApiException(
          statusCode: 503,
          message: 'Service unavailable.',
        ),
      );
      final controller = AuthController(
        store,
        auth,
        AccessTokenStore(),
        now: () => DateTime.utc(2026, 10, 6, 10),
      );

      await controller.restoreSession();

      expect(store.refreshToken, 'valid-refresh');
      expect(controller.status, AuthStatus.restoreFailed);
      expect(controller.isAuthenticated, isFalse);
    },
  );

  test('non-temporary restore failure requires recovery UI', () async {
    final store = FakeCredentialStore(refreshToken: 'valid-refresh');
    final auth = FakeAuthService(
      refreshError: const ApiException(
        statusCode: 400,
        message: 'Invalid request.',
      ),
    );
    final controller = AuthController(store, auth, AccessTokenStore());

    await controller.restoreSession();

    expect(store.refreshToken, 'valid-refresh');
    expect(controller.status, AuthStatus.restoreFailed);
    expect(controller.isAuthenticated, isFalse);
  });

  test('non-401 login failure is recorded without server message', () async {
    final preferences = await SharedPreferences.getInstance();
    final diagnostics = DiagnosticsService(preferences);
    final controller = AuthController(
      FakeCredentialStore(),
      FakeAuthService(
        loginError: const ApiException(
          statusCode: 503,
          message: 'password=server-secret',
        ),
      ),
      AccessTokenStore(),
      diagnostics: diagnostics,
    );

    await expectLater(
      controller.login(username: 'member', password: 'password'),
      throwsA(isA<ApiException>()),
    );

    final entries = await diagnostics.readEntries();

    expect(entries, hasLength(1));
    expect(entries.single.subsystem, 'Authentication');
    expect(entries.single.message, 'Login failed');
    expect(entries.single.details, contains('HTTP 503'));
    expect(entries.single.details, isNot(contains('server-secret')));
  });

  test('invalid credentials are not recorded as diagnostic errors', () async {
    final preferences = await SharedPreferences.getInstance();
    final diagnostics = DiagnosticsService(preferences);
    final controller = AuthController(
      FakeCredentialStore(),
      FakeAuthService(
        loginError: const ApiException(
          statusCode: 401,
          message: 'Invalid username or password.',
        ),
      ),
      AccessTokenStore(),
      diagnostics: diagnostics,
    );

    await expectLater(
      controller.login(username: 'member', password: 'wrong'),
      throwsA(isA<ApiException>()),
    );

    expect(await diagnostics.readEntries(), isEmpty);
  });

  test(
    'login stores refresh token, auth timestamp, and access token',
    () async {
      final now = DateTime.utc(2026, 10, 6, 10);
      final store = FakeCredentialStore();
      final auth = FakeAuthService(
        loginResult: const AuthTokens(
          accessToken: 'access',
          refreshToken: 'refresh',
        ),
      );
      final accessTokens = AccessTokenStore();
      final controller = AuthController(
        store,
        auth,
        accessTokens,
        now: () => now,
      );

      await controller.login(username: 'member', password: 'password');

      expect(auth.loginUsername, 'member');
      expect(auth.loginPassword, 'password');
      expect(store.refreshToken, 'refresh');
      expect(store.lastOnlineAuthAt, now);
      expect(accessTokens.accessToken, 'access');
      expect(controller.status, AuthStatus.authenticated);
    },
  );

  test('logout revokes refresh token and clears local session', () async {
    final store = FakeCredentialStore(
      refreshToken: 'refresh',
      lastOnlineAuthAt: DateTime.utc(2026, 10, 6, 9),
    );
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
    expect(store.lastOnlineAuthAt, isNull);
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
  FakeCredentialStore({this.refreshToken, this.lastOnlineAuthAt});

  String? refreshToken;
  DateTime? lastOnlineAuthAt;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> writeRefreshToken(String refreshToken) async {
    this.refreshToken = refreshToken;
  }

  @override
  Future<DateTime?> readLastOnlineAuthAt() async => lastOnlineAuthAt;

  @override
  Future<void> writeLastOnlineAuthAt(DateTime authenticatedAt) async {
    lastOnlineAuthAt = authenticatedAt.toUtc();
  }

  @override
  Future<void> clear() async {
    refreshToken = null;
    lastOnlineAuthAt = null;
  }
}

class FakeAuthService implements AuthService {
  FakeAuthService({
    this.loginResult,
    this.loginError,
    this.refreshResult,
    this.refreshError,
    this.refreshCompleter,
    this.logoutError,
  });

  final AuthTokens? loginResult;
  final Object? loginError;
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

    if (loginError != null) {
      throw loginError!;
    }

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
