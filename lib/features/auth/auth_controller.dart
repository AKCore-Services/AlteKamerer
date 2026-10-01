// -----------------------------------------------------------------------------
// auth_controller.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Owns the mobile authentication lifecycle, including login, session
//   restoration, token refresh, logout, and observable session state.
//
// Contains:
//   - AuthStatus: Authentication and restoration states.
//   - AuthController: Session state and credential lifecycle.
//
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';

import '../../core/diagnostics/diagnostic_error_details.dart';
import '../../core/diagnostics/diagnostics_service.dart';
import '../../core/network/access_token_store.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/credential_store.dart';
import 'auth_api.dart';

/// States used to select authenticated, login, or recovery UI.
///
/// [restoreFailed] distinguishes a failed session check from a confirmed
/// unauthenticated session, allowing the user to retry restoration.
enum AuthStatus { loading, unauthenticated, authenticated, restoreFailed }

/// Coordinates authentication and the lifetime of mobile credentials.
///
/// Persists refresh tokens through [CredentialStore], keeps access tokens
/// in memory, and exposes session state to the application. Also provides
/// the refresh handler used by `ApiClient` for expired access tokens.
class AuthController extends ChangeNotifier {
  AuthController(
    this._credentialStore,
    this._authService,
    this._accessTokenStore, {
    this._diagnostics,
  });

  final CredentialStore _credentialStore;
  final AuthService _authService;
  final AccessTokenStore _accessTokenStore;
  final DiagnosticsService? _diagnostics;

  AuthStatus _status = AuthStatus.loading;
  String? _refreshToken;
  Future<bool>? _refreshInFlight;

  AuthStatus get status => _status;

  bool get isAuthenticated => _status == AuthStatus.authenticated;

  String? get accessToken => _accessTokenStore.accessToken;

  /// Attempts to restore a session using the persisted refresh token.
  ///
  /// A missing or rejected token produces an unauthenticated state.
  /// Other failures retain the stored credentials and enter [AuthStatus.restoreFailed]
  /// so restoration can be retried.
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
    } on ApiException catch (exception, stackTrace) {
      if (exception.statusCode == 401) {
        await _clearSession();
        return;
      }

      await _diagnostics?.recordError(
        subsystem: 'Authentication',
        message: 'Session restore failed',
        error: diagnosticErrorDetails(exception, stackTrace),
      );
      _clearMemorySession();
      _status = AuthStatus.restoreFailed;
      notifyListeners();
    } catch (error, stackTrace) {
      await _diagnostics?.recordError(
        subsystem: 'Authentication',
        message: 'Session restore failed',
        error: diagnosticErrorDetails(error, stackTrace),
      );
      _clearMemorySession();
      _status = AuthStatus.restoreFailed;
      notifyListeners();
    }
  }

  /// Authenticates the supplied credentials and establishes a session.
  ///
  /// On success, persists the refresh token, updates the in-memory access
  /// token, and notifies listeners of the authenticated state.
  ///
  /// Authentication or persistence failures propagate to the caller.
  Future<void> login({
    required String username,
    required String password,
  }) async {
    try {
      final tokens = await _authService.login(
        username: username,
        password: password,
      );

      await _setSession(tokens);
    } on ApiException catch (exception, stackTrace) {
      if (exception.statusCode != 401) {
        await _diagnostics?.recordError(
          subsystem: 'Authentication',
          message: 'Login failed',
          error: diagnosticErrorDetails(exception, stackTrace),
        );
      }
      rethrow;
    } catch (error, stackTrace) {
      await _diagnostics?.recordError(
        subsystem: 'Authentication',
        message: 'Login failed',
        error: diagnosticErrorDetails(error, stackTrace),
      );
      rethrow;
    }
  }

  /// Refreshes the current session, sharing an in-flight refresh request.
  ///
  /// Concurrent callers receive the same result, avoiding multiple requests
  /// that could compete to rotate the same refresh token. Returns false when
  /// the session cannot be renewed because its credentials are unavailable
  /// or rejected; other failures are propagated.
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
    } on ApiException catch (exception, stackTrace) {
      if (exception.statusCode == 401) {
        await _clearSession();
        return false;
      }

      await _diagnostics?.recordError(
        subsystem: 'Authentication',
        message: 'Session refresh failed',
        error: diagnosticErrorDetails(exception, stackTrace),
      );
      rethrow;
    } catch (error, stackTrace) {
      await _diagnostics?.recordError(
        subsystem: 'Authentication',
        message: 'Session refresh failed',
        error: diagnosticErrorDetails(error, stackTrace),
      );
      rethrow;
    }
  }

  /// Revokes the current refresh token and clears local session state.
  ///
  /// Local credentials are cleared even when the server request fails.
  /// The server error is recorded and rethrown to the caller.
  Future<void> logout() async {
    final refreshToken = _refreshToken;

    try {
      if (refreshToken != null) {
        await _authService.logout(refreshToken);
      }
    } catch (error, stackTrace) {
      await _diagnostics?.recordError(
        subsystem: 'Authentication',
        message: 'Logout failed',
        error: diagnosticErrorDetails(error, stackTrace),
      );
      rethrow;
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
