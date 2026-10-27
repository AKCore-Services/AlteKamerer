import 'dart:convert';

import 'package:altekamerer/core/config/app_config.dart';
import 'package:altekamerer/core/network/access_token_store.dart';
import 'package:altekamerer/core/network/api_client.dart';
import 'package:altekamerer/core/network/api_exception.dart';
import 'package:altekamerer/features/me/member_credentials_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'username change sends current credentials and reads confirmed name',
    () async {
      final tokens = AccessTokenStore()..set('access-token');

      final client = ApiClient(
        AppConfig(apiBaseUrl: Uri.parse('https://example.test')),
        tokens,
        httpClient: MockClient((request) async {
          expect(request.method, 'PUT');
          expect(request.url.path, '/api/v1/profile/username');
          expect(request.headers['Authorization'], 'Bearer access-token');
          expect(jsonDecode(request.body), {
            'newUsername': 'updated-member',
            'currentPassword': 'CurrentPassword1',
          });

          return http.Response(
            jsonEncode({'userName': 'updated-member'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final api = MemberCredentialsApi(client);

      expect(
        await api.changeUsername(
          newUsername: 'updated-member',
          currentPassword: 'CurrentPassword1',
        ),
        'updated-member',
      );
    },
  );

  test('username change rejects an invalid successful response', () async {
    final client = ApiClient(
      AppConfig(apiBaseUrl: Uri.parse('https://example.test')),
      AccessTokenStore()..set('access-token'),
      httpClient: MockClient((_) async => http.Response('{}', 200)),
    );

    final api = MemberCredentialsApi(client);

    await expectLater(
      api.changeUsername(
        newUsername: 'updated-member',
        currentPassword: 'CurrentPassword1',
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test(
    'username validation errors propagate without changing session',
    () async {
      final tokens = AccessTokenStore()..set('access-token');

      final client = ApiClient(
        AppConfig(apiBaseUrl: Uri.parse('https://example.test')),
        tokens,
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({'error': 'DuplicateUserName'}),
            400,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );

      final api = MemberCredentialsApi(client);

      await expectLater(
        api.changeUsername(
          newUsername: 'existing-member',
          currentPassword: 'CurrentPassword1',
        ),
        throwsA(
          isA<ApiException>().having(
            (error) => error.statusCode,
            'statusCode',
            400,
          ),
        ),
      );

      expect(tokens.accessToken, 'access-token');
    },
  );

  test('password change accepts the empty HTTP 204 response', () async {
    final client = ApiClient(
      AppConfig(apiBaseUrl: Uri.parse('https://example.test')),
      AccessTokenStore()..set('access-token'),
      httpClient: MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/v1/profile/password');
        expect(request.headers['Authorization'], 'Bearer access-token');
        expect(jsonDecode(request.body), {
          'currentPassword': 'CurrentPassword1',
          'newPassword': 'NewPassword2',
        });

        return http.Response('', 204);
      }),
    );

    final api = MemberCredentialsApi(client);

    await api.changePassword(
      currentPassword: 'CurrentPassword1',
      newPassword: 'NewPassword2',
    );
  });

  test('unauthorized password changes are rejected', () async {
    final client = ApiClient(
      AppConfig(apiBaseUrl: Uri.parse('https://example.test')),
      AccessTokenStore()..set('access-token'),
      httpClient: MockClient((_) async => http.Response('', 401)),
    );

    final api = MemberCredentialsApi(client);

    await expectLater(
      api.changePassword(
        currentPassword: 'CurrentPassword1',
        newPassword: 'NewPassword2',
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          401,
        ),
      ),
    );
  });
}
