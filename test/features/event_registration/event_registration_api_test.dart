import 'dart:convert';

import 'package:altekamerer/core/config/app_config.dart';
import 'package:altekamerer/core/network/access_token_store.dart';
import 'package:altekamerer/core/network/api_client.dart';
import 'package:altekamerer/features/event_registration/event_registration_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('saveRegistration puts authenticated registration payload', () async {
    final tokenStore = AccessTokenStore()..set('access-token');

    late http.Request capturedRequest;

    final client = ApiClient(
      AppConfig(apiBaseUrl: Uri.parse('https://example.test')),
      tokenStore,
      httpClient: MockClient((request) async {
        capturedRequest = request;
        return http.Response('', 204);
      }),
    );

    final api = EventRegistrationApi(client);

    await api.saveRegistration(
      42,
      const EventRegistrationRequest(
        where: 'Direkt',
        car: true,
        instrument: false,
        comment: 'Kommer direkt',
        selectedInstrument: 'Flöjt',
      ),
    );

    expect(capturedRequest.method, 'PUT');
    expect(capturedRequest.url.path, '/api/v1/events/42/registration');
    expect(capturedRequest.headers['Authorization'], 'Bearer access-token');

    expect(jsonDecode(capturedRequest.body), {
      'where': 'Direkt',
      'car': true,
      'instrument': false,
      'comment': 'Kommer direkt',
      'selectedInstrument': 'Flöjt',
    });
  });
}
