import 'dart:convert';

import 'package:altekamerer/core/config/app_config.dart';
import 'package:altekamerer/core/network/access_token_store.dart';
import 'package:altekamerer/core/network/api_client.dart';
import 'package:altekamerer/features/event_details/event_details_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('getEvent parses authenticated event detail response', () async {
    final tokenStore = AccessTokenStore()..set('access-token');

    late http.Request capturedRequest;

    final client = ApiClient(
      AppConfig(apiBaseUrl: Uri.parse('https://example.test')),
      tokenStore,
      httpClient: MockClient((request) async {
        capturedRequest = request;

        return http.Response(
          jsonEncode({
            'id': 42,
            'type': 'Rep',
            'name': 'Tisdagsrep',
            'place': 'Kårhuset',
            'description': 'Ordinarie repetition',
            'internalDescription': '',
            'date': '2026-09-15',
            'halanTime': '18:00',
            'thereTime': '18:30',
            'startsTime': '19:00',
            'playDuration': '120',
            'stand': '',
            'signupState': 'Hålan',
            'coming': 12,
            'notComing': 3,
            'disabled': false,
            'registrationAvailable': true,
            'registration': {
              'where': 'Hålan',
              'car': false,
              'instrument': true,
              'comment': '',
              'selectedInstrument': 'Flöjt',
              'availableInstruments': ['Flöjt'],
            },
            'attendees': [
              {
                'personName': 'Test Member',
                'where': 'Hålan',
                'car': false,
                'instrument': true,
                'instrumentName': 'Flöjt',
                'comment': '',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final event = await EventDetailsApi(client).getEvent(42);

    expect(capturedRequest.method, 'GET');
    expect(capturedRequest.url.path, '/api/v1/events/42');
    expect(capturedRequest.headers['Authorization'], 'Bearer access-token');

    expect(event.id, 42);
    expect(event.type, 'Rep');
    expect(event.name, 'Tisdagsrep');
    expect(event.place, 'Kårhuset');
    expect(event.description, 'Ordinarie repetition');
    expect(event.date, '2026-09-15');
    expect(event.halanTime, '18:00');
    expect(event.thereTime, '18:30');
    expect(event.startsTime, '19:00');
    expect(event.signupState, 'Hålan');
    expect(event.coming, 12);
    expect(event.notComing, 3);
    expect(event.disabled, isFalse);
    expect(event.registrationAvailable, isTrue);
    expect(event.isAttending, isTrue);

    expect(event.registration.where, 'Hålan');
    expect(event.registration.selectedInstrument, 'Flöjt');
    expect(event.registration.availableInstruments, ['Flöjt']);

    expect(event.attendees, hasLength(1));
    expect(event.attendees.single.personName, 'Test Member');
    expect(event.attendees.single.instrumentName, 'Flöjt');
  });
}
