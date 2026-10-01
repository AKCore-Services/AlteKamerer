// -----------------------------------------------------------------------------
// auth_api.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Implements the AKCore mobile authentication API contract for login,
//   refresh-token rotation, and logout.
//
// Contains:
//   - AuthTokens: Access and refresh tokens returned by authentication.
//   - AuthService: Authentication operations used by the controller.
//   - AuthApi: HTTP implementation of AuthService.
//
// -----------------------------------------------------------------------------

import '../../core/network/api_client.dart';

/// Contains the access and refresh tokens returned by AKCore.
///
/// The access token authenticates API requests, while the refresh token
/// is persisted for restoring and renewing the session.
class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}

/// Defines the authentication operations required by `AuthController`.
///
/// Implementations must return both tokens after login or refresh and
/// support revoking the refresh token during logout.
abstract interface class AuthService {
  /// Authenticates [username] using [password] and returns both tokens.
  ///
  /// Throws [ApiException] when authentication is rejected and
  /// [FormatException] when the response does not contain valid tokens.
  Future<AuthTokens> login({
    required String username,
    required String password,
  });

  /// Exchanges [refreshToken] for a new access and refresh token pair.
  ///
  /// Throws [ApiException] when the request is rejected and
  /// [FormatException] when the response does not contain valid tokens.
  Future<AuthTokens> refresh(String refreshToken);

  /// Requests server-side revocation of [refreshToken].
  ///
  /// Throws [ApiException] when the server rejects the request.
  Future<void> logout(String refreshToken);
}

/// Implements mobile authentication through AKCore's `/api/v1/auth` API.
///
/// Login, refresh, and logout send requests without bearer authentication.
/// Token responses are validated before being returned to the controller.
class AuthApi implements AuthService {
  const AuthApi(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<AuthTokens> login({
    required String username,
    required String password,
  }) async {
    final response = await _apiClient.postJson(
      '/api/v1/auth/login',
      authenticated: false,
      body: {'username': username, 'password': password},
    );

    return _readTokens(response);
  }

  @override
  Future<AuthTokens> refresh(String refreshToken) async {
    final response = await _apiClient.postJson(
      '/api/v1/auth/refresh',
      authenticated: false,
      body: {'refreshToken': refreshToken},
    );

    return _readTokens(response);
  }

  @override
  Future<void> logout(String refreshToken) async {
    await _apiClient.postJson(
      '/api/v1/auth/logout',
      authenticated: false,
      body: {'refreshToken': refreshToken},
    );
  }

  AuthTokens _readTokens(Map<String, dynamic> response) {
    final authenticated = response['authenticated'];
    final accessToken = response['accessToken'];
    final refreshToken = response['refreshToken'];

    if (authenticated != true ||
        accessToken is! String ||
        accessToken.isEmpty ||
        refreshToken is! String ||
        refreshToken.isEmpty) {
      throw const FormatException('Invalid authentication response.');
    }

    return AuthTokens(accessToken: accessToken, refreshToken: refreshToken);
  }
}
