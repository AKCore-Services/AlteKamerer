import 'dart:convert';

import 'package:altekamerer/core/config/app_config.dart';
import 'package:altekamerer/core/network/access_token_store.dart';
import 'package:altekamerer/core/network/api_client.dart';
import 'package:altekamerer/features/me/me_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('getMe maps authenticated member response', () async {
    final tokenStore = AccessTokenStore()..set('access-token');

    late http.Request capturedRequest;

    final client = ApiClient(
      AppConfig(apiBaseUrl: Uri.parse('https://example.test')),
      tokenStore,
      httpClient: MockClient((request) async {
        capturedRequest = request;

        return http.Response(
          jsonEncode({
            'displayName': 'Test Testsson',
            'isMember': true,
            'isBallet': true,
            'availableInstruments': ['Trumpet', 'Trombon'],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final me = await MeApi(client).getMe();

    expect(capturedRequest.method, 'GET');
    expect(capturedRequest.url.path, '/api/v1/me');
    expect(capturedRequest.headers['Authorization'], 'Bearer access-token');

    expect(me.displayName, 'Test Testsson');
    expect(me.isMember, isTrue);
    expect(me.isBallet, isTrue);
    expect(me.availableInstruments, ['Trumpet', 'Trombon']);
  });

  test('getMe rejects invalid instrument collection', () async {
    final client = ApiClient(
      AppConfig(apiBaseUrl: Uri.parse('https://example.test')),
      AccessTokenStore(),
      httpClient: MockClient((request) async {
        return http.Response(
          jsonEncode({
            'displayName': 'Test Testsson',
            'isMember': true,
            'isBallet': false,
            'availableInstruments': {},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    expect(MeApi(client).getMe(), throwsA(isA<FormatException>()));
  });
}
