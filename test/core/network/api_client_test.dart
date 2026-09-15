import 'dart:convert';

import 'package:altekamerer/core/config/app_config.dart';
import 'package:altekamerer/core/network/access_token_store.dart';
import 'package:altekamerer/core/network/api_client.dart';
import 'package:altekamerer/core/network/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('authenticated request sends access token', () async {
    late http.Request capturedRequest;

    final accessTokens = AccessTokenStore()..set('access-token');

    final client = ApiClient(
      AppConfig(apiBaseUrl: Uri.parse('https://akcore.example')),
      accessTokens,
      httpClient: MockClient((request) async {
        capturedRequest = request;

        return http.Response(
          jsonEncode({'value': 'ok'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    await client.getJson('/api/v1/example');

    expect(capturedRequest.headers['Authorization'], 'Bearer access-token');
  });

  test('authenticated 401 refreshes once and retries with new token', () async {
    final requests = <http.Request>[];
    final accessTokens = AccessTokenStore()..set('expired-access');

    var refreshCalls = 0;

    final client = ApiClient(
      AppConfig(apiBaseUrl: Uri.parse('https://akcore.example')),
      accessTokens,
      httpClient: MockClient((request) async {
        requests.add(request);

        if (requests.length == 1) {
          return http.Response(
            jsonEncode({'message': 'Unauthorized.'}),
            401,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response(
          jsonEncode({'value': 'ok'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    client.setRefreshSessionHandler(() async {
      refreshCalls += 1;
      accessTokens.set('fresh-access');
      return true;
    });

    final response = await client.getJson('/api/v1/example');

    expect(refreshCalls, 1);
    expect(requests, hasLength(2));
    expect(requests[0].headers['Authorization'], 'Bearer expired-access');
    expect(requests[1].headers['Authorization'], 'Bearer fresh-access');
    expect(response['value'], 'ok');
  });

  test('failed refresh does not retry authenticated request', () async {
    var requestCount = 0;
    var refreshCalls = 0;

    final accessTokens = AccessTokenStore()..set('expired-access');

    final client = ApiClient(
      AppConfig(apiBaseUrl: Uri.parse('https://akcore.example')),
      accessTokens,
      httpClient: MockClient((request) async {
        requestCount += 1;

        return http.Response(
          jsonEncode({'message': 'Unauthorized.'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    client.setRefreshSessionHandler(() async {
      refreshCalls += 1;
      return false;
    });

    await expectLater(
      client.getJson('/api/v1/example'),
      throwsA(
        isA<ApiException>().having(
          (exception) => exception.statusCode,
          'statusCode',
          401,
        ),
      ),
    );

    expect(refreshCalls, 1);
    expect(requestCount, 1);
  });

  test('retrying request that remains 401 does not refresh twice', () async {
    var requestCount = 0;
    var refreshCalls = 0;

    final accessTokens = AccessTokenStore()..set('expired-access');

    final client = ApiClient(
      AppConfig(apiBaseUrl: Uri.parse('https://akcore.example')),
      accessTokens,
      httpClient: MockClient((request) async {
        requestCount += 1;

        return http.Response(
          jsonEncode({'message': 'Unauthorized.'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    client.setRefreshSessionHandler(() async {
      refreshCalls += 1;
      accessTokens.set('fresh-access');
      return true;
    });

    await expectLater(
      client.getJson('/api/v1/example'),
      throwsA(
        isA<ApiException>().having(
          (exception) => exception.statusCode,
          'statusCode',
          401,
        ),
      ),
    );

    expect(refreshCalls, 1);
    expect(requestCount, 2);
  });

  test('unauthenticated request never invokes refresh handler', () async {
    var refreshCalls = 0;

    final client = ApiClient(
      AppConfig(apiBaseUrl: Uri.parse('https://akcore.example')),
      AccessTokenStore(),
      httpClient: MockClient(
        (request) async => http.Response(
          jsonEncode({'message': 'Invalid username or password.'}),
          401,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );

    client.setRefreshSessionHandler(() async {
      refreshCalls += 1;
      return true;
    });

    await expectLater(
      client.postJson(
        '/api/v1/auth/login',
        authenticated: false,
        body: {'username': 'member', 'password': 'wrong'},
      ),
      throwsA(isA<ApiException>()),
    );

    expect(refreshCalls, 0);
  });

  test('authenticated PUT refreshes once and retries with new token', () async {
    final requests = <http.Request>[];
    final accessTokens = AccessTokenStore()..set('expired-access');

    var refreshCalls = 0;

    final client = ApiClient(
      AppConfig(apiBaseUrl: Uri.parse('https://akcore.example')),
      accessTokens,
      httpClient: MockClient((request) async {
        requests.add(request);

        if (requests.length == 1) {
          return http.Response(
            jsonEncode({'message': 'Unauthorized.'}),
            401,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response('', 204);
      }),
    );

    client.setRefreshSessionHandler(() async {
      refreshCalls += 1;
      accessTokens.set('fresh-access');
      return true;
    });

    await client.putJson(
      '/api/v1/events/42/registration',
      body: {
        'where': 'Direkt',
        'car': false,
        'instrument': true,
        'comment': '',
        'selectedInstrument': 'Flöjt',
      },
    );

    expect(refreshCalls, 1);
    expect(requests, hasLength(2));

    expect(requests[0].method, 'PUT');
    expect(requests[0].headers['Authorization'], 'Bearer expired-access');

    expect(requests[1].method, 'PUT');
    expect(requests[1].headers['Authorization'], 'Bearer fresh-access');

    expect(requests[1].body, requests[0].body);
  });
}
