import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'access_token_store.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient(this._config, this._accessTokenStore, {http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final AppConfig _config;
  final AccessTokenStore _accessTokenStore;
  final http.Client _httpClient;

  Future<bool> Function()? _refreshSession;

  Future<Map<String, dynamic>> getJson(
    String path, {
    bool authenticated = true,
  }) async {
    var response = await _httpClient.get(
      _config.resolve(path),
      headers: _headers(authenticated: authenticated),
    );

    if (authenticated && response.statusCode == 401) {
      final refreshed = await _refreshAfterUnauthorized();

      if (refreshed) {
        response = await _httpClient.get(
          _config.resolve(path),
          headers: _headers(authenticated: true),
        );
      }
    }

    return _decodeJsonResponse(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final encodedBody = jsonEncode(body ?? <String, dynamic>{});

    var response = await _httpClient.post(
      _config.resolve(path),
      headers: _headers(authenticated: authenticated),
      body: encodedBody,
    );

    if (authenticated && response.statusCode == 401) {
      final refreshed = await _refreshAfterUnauthorized();

      if (refreshed) {
        response = await _httpClient.post(
          _config.resolve(path),
          headers: _headers(authenticated: true),
          body: encodedBody,
        );
      }
    }

    return _decodeJsonResponse(response);
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final encodedBody = jsonEncode(body ?? <String, dynamic>{});

    var response = await _httpClient.put(
      _config.resolve(path),
      headers: _headers(authenticated: authenticated),
      body: encodedBody,
    );

    if (authenticated && response.statusCode == 401) {
      final refreshed = await _refreshAfterUnauthorized();

      if (refreshed) {
        response = await _httpClient.put(
          _config.resolve(path),
          headers: _headers(authenticated: true),
          body: encodedBody,
        );
      }
    }

    return _decodeJsonResponse(response);
  }

  Future<bool> _refreshAfterUnauthorized() async {
    final refreshSession = _refreshSession;

    if (refreshSession == null) {
      return false;
    }

    return refreshSession();
  }

  Map<String, String> _headers({required bool authenticated}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (authenticated) {
      final accessToken = _accessTokenStore.accessToken;

      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      }
    }

    return headers;
  }

  Map<String, dynamic> _decodeJsonResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _readErrorMessage(response.body),
      );
    }

    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object response.');
    }

    return decoded;
  }

  String _readErrorMessage(String body) {
    if (body.isEmpty) {
      return 'Request failed.';
    }

    try {
      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];

        if (message is String && message.isNotEmpty) {
          return message;
        }
      }
    } on FormatException {
      // Fall through to the generic message.
    }

    return 'Request failed.';
  }

  void setRefreshSessionHandler(Future<bool> Function() handler) {
    _refreshSession = handler;
  }

  void close() {
    _httpClient.close();
  }
}
