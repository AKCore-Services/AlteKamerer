import '../../core/network/api_client.dart';

class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}

abstract interface class AuthService {
  Future<AuthTokens> login({
    required String username,
    required String password,
  });

  Future<AuthTokens> refresh(String refreshToken);

  Future<void> logout(String refreshToken);
}

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
