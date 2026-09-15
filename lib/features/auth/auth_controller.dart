import 'package:flutter/foundation.dart';

import '../../core/network/access_token_store.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/credential_store.dart';
import 'auth_api.dart';

enum AuthStatus { loading, unauthenticated, authenticated, restoreFailed }

class AuthController extends ChangeNotifier {
  AuthController(
    this._credentialStore,
    this._authService,
    this._accessTokenStore,
  );

  final CredentialStore _credentialStore;
  final AuthService _authService;
  final AccessTokenStore _accessTokenStore;

  AuthStatus _status = AuthStatus.loading;
  String? _refreshToken;
  Future<bool>? _refreshInFlight;

  AuthStatus get status => _status;

  bool get isAuthenticated => _status == AuthStatus.authenticated;

  String? get accessToken => _accessTokenStore.accessToken;

  Future<void> restoreSession() async {
    _status = AuthStatus.loading;
    notifyListeners();

    final refreshToken = await _credentialStore.readRefreshToken();

    if (refreshToken == null) {
      _clearMemorySession();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      final tokens = await _authService.refresh(refreshToken);
      await _setSession(tokens);
    } on ApiException catch (exception) {
      if (exception.statusCode == 401) {
        await _clearSession();
        return;
      }

      _clearMemorySession();
      _status = AuthStatus.restoreFailed;
      notifyListeners();
    } catch (_) {
      _clearMemorySession();
      _status = AuthStatus.restoreFailed;
      notifyListeners();
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final tokens = await _authService.login(
      username: username,
      password: password,
    );

    await _setSession(tokens);
  }

  Future<bool> refreshSession() {
    return _refreshInFlight ??= _refreshSessionSingleFlight();
  }

  Future<bool> _refreshSessionSingleFlight() async {
    try {
      return await _performRefreshSession();
    } finally {
      _refreshInFlight = null;
    }
  }

  Future<bool> _performRefreshSession() async {
    final refreshToken = _refreshToken;

    if (refreshToken == null) {
      await _clearSession();
      return false;
    }

    try {
      final tokens = await _authService.refresh(refreshToken);
      await _setSession(tokens);
      return true;
    } on ApiException catch (exception) {
      if (exception.statusCode == 401) {
        await _clearSession();
        return false;
      }

      rethrow;
    }
  }

  Future<void> logout() async {
    final refreshToken = _refreshToken;

    try {
      if (refreshToken != null) {
        await _authService.logout(refreshToken);
      }
    } finally {
      await _clearSession();
    }
  }

  Future<void> _setSession(AuthTokens tokens) async {
    await _credentialStore.writeRefreshToken(tokens.refreshToken);

    _accessTokenStore.set(tokens.accessToken);
    _refreshToken = tokens.refreshToken;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> _clearSession() async {
    await _credentialStore.clear();

    _clearMemorySession();
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void _clearMemorySession() {
    _accessTokenStore.clear();
    _refreshToken = null;
  }
}
