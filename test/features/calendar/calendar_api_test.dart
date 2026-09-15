import 'dart:convert';

import 'package:altekamerer/core/config/app_config.dart';
import 'package:altekamerer/core/network/access_token_store.dart';
import 'package:altekamerer/core/network/api_client.dart';
import 'package:altekamerer/features/calendar/calendar_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('getCalendar maps authenticated calendar response', () async {
    final tokenStore = AccessTokenStore()..set('access-token');

    late http.Request capturedRequest;

    final client = ApiClient(
      AppConfig(apiBaseUrl: Uri.parse('https://example.test')),
      tokenStore,
      httpClient: MockClient((request) async {
        capturedRequest = request;

        return http.Response(
          jsonEncode({
            'events': [
              {
                'id': 42,
                'type': 'Kårhusrep',
                'name': 'Tisdagsrep',
                'place': 'Kårhuset',
                'description': 'Beskrivning',
                'internalDescription': 'Intern information',
                'date': '2026-09-15',
                'halanTime': '18:00',
                'thereTime': '18:30',
                'startsTime': '19:00',
                'playDuration': '120 min',
                'stand': '',
                'signupState': 'Hålan',
                'coming': 12,
                'notComing': 3,
                'disabled': false,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final events = await CalendarApi(client).getCalendar();

    expect(capturedRequest.method, 'GET');
    expect(capturedRequest.url.path, '/api/v1/calendar');
    expect(capturedRequest.headers['Authorization'], 'Bearer access-token');

    expect(events, hasLength(1));

    final event = events.single;

    expect(event.id, 42);
    expect(event.type, 'Kårhusrep');
    expect(event.name, 'Tisdagsrep');
    expect(event.place, 'Kårhuset');
    expect(event.description, 'Beskrivning');
    expect(event.internalDescription, 'Intern information');
    expect(event.date, '2026-09-15');
    expect(event.halanTime, '18:00');
    expect(event.thereTime, '18:30');
    expect(event.startsTime, '19:00');
    expect(event.playDuration, '120 min');
    expect(event.stand, '');
    expect(event.signupState, 'Hålan');
    expect(event.coming, 12);
    expect(event.notComing, 3);
    expect(event.disabled, isFalse);
  });

  test('getCalendar accepts empty event list', () async {
    final client = ApiClient(
      AppConfig(apiBaseUrl: Uri.parse('https://example.test')),
      AccessTokenStore(),
      httpClient: MockClient((request) async {
        return http.Response(
          jsonEncode({'events': []}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final events = await CalendarApi(client).getCalendar();

    expect(events, isEmpty);
  });

  test('getCalendar rejects invalid event collection', () async {
    final client = ApiClient(
      AppConfig(apiBaseUrl: Uri.parse('https://example.test')),
      AccessTokenStore(),
      httpClient: MockClient((request) async {
        return http.Response(
          jsonEncode({'events': {}}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    expect(CalendarApi(client).getCalendar(), throwsA(isA<FormatException>()));
  });
}
