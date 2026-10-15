import 'dart:convert';

import 'package:altekamerer/core/config/app_config.dart';
import 'package:altekamerer/core/network/access_token_store.dart';
import 'package:altekamerer/core/network/api_client.dart';
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
}
