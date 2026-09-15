import 'dart:convert';

import 'package:altekamerer/core/config/app_config.dart';
import 'package:altekamerer/core/network/access_token_store.dart';
import 'package:altekamerer/core/network/api_client.dart';
import 'package:altekamerer/core/network/api_exception.dart';
import 'package:altekamerer/features/auth/auth_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('login posts credentials and returns tokens', () async {
    late http.Request capturedRequest;

    final client = _createApiClient((request) async {
      capturedRequest = request;

      return http.Response(
        jsonEncode({
          'authenticated': true,
          'accessToken': 'access-token',
          'refreshToken': 'refresh-token',
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final authApi = AuthApi(client);

    final tokens = await authApi.login(
      username: 'member',
      password: 'password',
    );

    expect(
      capturedRequest.url,
      Uri.parse('https://akcore.example/api/v1/auth/login'),
    );
    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.headers['Authorization'], isNull);
    expect(jsonDecode(capturedRequest.body), {
      'username': 'member',
      'password': 'password',
    });

    expect(tokens.accessToken, 'access-token');
    expect(tokens.refreshToken, 'refresh-token');
  });

  test('login exposes invalid credential response as ApiException', () async {
    final client = _createApiClient(
      (request) async => http.Response(
        jsonEncode({'message': 'Invalid username or password.'}),
        401,
        headers: {'content-type': 'application/json'},
      ),
    );

    final authApi = AuthApi(client);

    await expectLater(
      authApi.login(username: 'member', password: 'wrong'),
      throwsA(
        isA<ApiException>()
            .having((exception) => exception.statusCode, 'statusCode', 401)
            .having(
              (exception) => exception.message,
              'message',
              'Invalid username or password.',
            ),
      ),
    );
  });

  test('refresh posts refresh token and returns rotated tokens', () async {
    late http.Request capturedRequest;

    final client = _createApiClient((request) async {
      capturedRequest = request;

      return http.Response(
        jsonEncode({
          'authenticated': true,
          'accessToken': 'new-access-token',
          'refreshToken': 'new-refresh-token',
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final authApi = AuthApi(client);

    final tokens = await authApi.refresh('old-refresh-token');

    expect(
      capturedRequest.url,
      Uri.parse('https://akcore.example/api/v1/auth/refresh'),
    );
    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.headers['Authorization'], isNull);
    expect(jsonDecode(capturedRequest.body), {
      'refreshToken': 'old-refresh-token',
    });

    expect(tokens.accessToken, 'new-access-token');
    expect(tokens.refreshToken, 'new-refresh-token');
  });

  test('logout posts refresh token without bearer authentication', () async {
    late http.Request capturedRequest;

    final client = _createApiClient((request) async {
      capturedRequest = request;
      return http.Response('', 204);
    });

    final authApi = AuthApi(client);

    await authApi.logout('refresh-token');

    expect(
      capturedRequest.url,
      Uri.parse('https://akcore.example/api/v1/auth/logout'),
    );
    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.headers['Authorization'], isNull);
    expect(jsonDecode(capturedRequest.body), {'refreshToken': 'refresh-token'});
  });

  test('authentication response requires both tokens', () async {
    final client = _createApiClient(
      (request) async => http.Response(
        jsonEncode({
          'authenticated': true,
          'accessToken': 'access-token',
          'refreshToken': '',
        }),
        200,
        headers: {'content-type': 'application/json'},
      ),
    );

    final authApi = AuthApi(client);

    await expectLater(
      authApi.login(username: 'member', password: 'password'),
      throwsA(isA<FormatException>()),
    );
  });
}

ApiClient _createApiClient(
  Future<http.Response> Function(http.Request request) handler,
) {
  return ApiClient(
    AppConfig(apiBaseUrl: Uri.parse('https://akcore.example')),
    AccessTokenStore(),
    httpClient: MockClient(handler),
  );
}
