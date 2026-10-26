import 'dart:convert';

import 'package:altekamerer/core/config/app_config.dart';
import 'package:altekamerer/core/network/access_token_store.dart';
import 'package:altekamerer/core/network/api_client.dart';
import 'package:altekamerer/core/network/api_exception.dart';
import 'package:altekamerer/features/me/member_profile.dart';
import 'package:altekamerer/features/me/member_profile_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final profileJson = <String, dynamic>{
    'userName': 'testmember',
    'email': 'test@example.com',
    'firstName': 'Test',
    'lastName': 'Testsson',
    'phone': '0701234567',
    'instrument': 'Trumpet',
    'otherInstruments': ['Trombon'],
    'roles': ['Medlem'],
    'posts': ['Materialförvaltare'],
    'medal': 'Silver',
    'givenMedal': 'Brons',
  };

  final statisticsJson = <String, dynamic>{
    'totalGigs': 20,
    'halan': 8,
    'direct': 5,
    'cantCome': 3,
    'car': 2,
    'instrument': 4,
    'comment': 1,
  };

  test('decodes complete authenticated profile', () {
    final profile = MemberProfile.fromJson(profileJson);

    expect(profile.userName, 'testmember');
    expect(profile.displayName, 'Test Testsson');
    expect(profile.instrument, 'Trumpet');
    expect(profile.otherInstruments, ['Trombon']);
    expect(profile.roles, ['Medlem']);
    expect(profile.posts, ['Materialförvaltare']);
    expect(profile.medal, 'Silver');
    expect(profile.givenMedal, 'Brons');
  });

  test('falls back to username when the display name is empty', () {
    final profile = MemberProfile.fromJson({
      ...profileJson,
      'firstName': '',
      'lastName': '',
    });

    expect(profile.displayName, 'testmember');
  });

  test('rejects incomplete profile responses', () {
    final invalid = Map<String, dynamic>.from(profileJson)..remove('roles');

    expect(
      () => MemberProfile.fromJson(invalid),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects invalid profile collections', () {
    expect(
      () => MemberProfile.fromJson({
        ...profileJson,
        'otherInstruments': ['Trombon', 123],
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('decodes registration statistics', () {
    final statistics = MemberProfileStatistics.fromJson(statisticsJson);

    expect(statistics.totalGigs, 20);
    expect(statistics.halan, 8);
    expect(statistics.direct, 5);
    expect(statistics.cantCome, 3);
    expect(statistics.car, 2);
    expect(statistics.instrument, 4);
    expect(statistics.comment, 1);
  });

  test('rejects invalid statistics', () {
    expect(
      () => MemberProfileStatistics.fromJson({
        ...statisticsJson,
        'totalGigs': -1,
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test(
    'retrieves profile and statistics using bearer authentication',
    () async {
      final paths = <String>[];
      final tokenStore = AccessTokenStore()..set('access-token');

      final client = ApiClient(
        AppConfig(apiBaseUrl: Uri.parse('https://example.test')),
        tokenStore,
        httpClient: MockClient((request) async {
          paths.add(request.url.path);

          expect(request.method, 'GET');
          expect(request.headers['Authorization'], 'Bearer access-token');

          final data = switch (request.url.path) {
            '/api/v1/profile' => profileJson,
            '/api/v1/profile/statistics' => statisticsJson,
            _ => throw StateError('Unexpected API request: ${request.url}'),
          };

          return http.Response(
            jsonEncode(data),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final api = MemberProfileApi(client);

      final profile = await api.getProfile();
      final statistics = await api.getStatistics();

      expect(profile.displayName, 'Test Testsson');
      expect(statistics.totalGigs, 20);

      expect(paths, ['/api/v1/profile', '/api/v1/profile/statistics']);
    },
  );

  test(
    'updates only editable profile fields and decodes saved profile',
    () async {
      final tokenStore = AccessTokenStore()..set('access-token');

      final client = ApiClient(
        AppConfig(apiBaseUrl: Uri.parse('https://example.test')),
        tokenStore,
        httpClient: MockClient((request) async {
          expect(request.method, 'PUT');
          expect(request.url.path, '/api/v1/profile');
          expect(request.headers['Authorization'], 'Bearer access-token');

          expect(jsonDecode(request.body), {
            'firstName': 'Updated',
            'lastName': 'Member',
            'email': 'updated@example.com',
            'phone': '0709876543',
            'instrument': 'Klarinett',
            'otherInstruments': ['Flöjt', 'Trumpet'],
          });

          return http.Response(
            jsonEncode({
              ...profileJson,
              'firstName': 'Updated',
              'lastName': 'Member',
              'email': 'updated@example.com',
              'phone': '0709876543',
              'instrument': 'Klarinett',
              'otherInstruments': ['Flöjt', 'Trumpet'],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final api = MemberProfileApi(client);

      final profile = await api.updateProfile(
        const MemberProfileUpdateRequest(
          firstName: 'Updated',
          lastName: 'Member',
          email: 'updated@example.com',
          phone: '0709876543',
          instrument: 'Klarinett',
          otherInstruments: ['Flöjt', 'Trumpet'],
        ),
      );

      expect(profile.displayName, 'Updated Member');
      expect(profile.email, 'updated@example.com');
      expect(profile.instrument, 'Klarinett');
      expect(profile.otherInstruments, ['Flöjt', 'Trumpet']);

      expect(profile.userName, 'testmember');
      expect(profile.roles, ['Medlem']);
      expect(profile.medal, 'Silver');
    },
  );

  test('propagates rejected profile updates', () async {
    final tokenStore = AccessTokenStore()..set('access-token');

    final client = ApiClient(
      AppConfig(apiBaseUrl: Uri.parse('https://example.test')),
      tokenStore,
      httpClient: MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/v1/profile');

        return http.Response(
          jsonEncode({'error': 'DuplicateInstrument'}),
          400,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final api = MemberProfileApi(client);

    await expectLater(
      api.updateProfile(
        const MemberProfileUpdateRequest(
          firstName: 'Test',
          lastName: 'Testsson',
          email: 'test@example.com',
          phone: '0701234567',
          instrument: 'Trumpet',
          otherInstruments: ['Trumpet'],
        ),
      ),
      throwsA(isA<ApiException>()),
    );
  });
}
