// -----------------------------------------------------------------------------
// api_client.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Provides shared JSON HTTP operations for the AKCore mobile API,
//   including bearer authentication and session-refresh retries.
//
// Contains:
//   - ApiClient: HTTP requests, response decoding, and authentication retries.
//
// -----------------------------------------------------------------------------

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'access_token_store.dart';
import 'api_exception.dart';

/// Sends JSON requests to the AKCore mobile API.
///
/// Adds the current bearer token to authenticated requests. On HTTP 401,
/// invokes the configured session-refresh handler and retries the request
/// once if refresh succeeds. Other unsuccessful responses become
/// [ApiException]s.
class ApiClient {
  ApiClient(this._config, this._accessTokenStore, {http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final AppConfig _config;
  final AccessTokenStore _accessTokenStore;
  final http.Client _httpClient;

  Future<bool> Function()? _refreshSession;

  /// Sends a GET request to [path] and returns its decoded JSON object.
  ///
  /// Includes the current bearer token when [authenticated] is true.
  /// On HTTP 401, attempts session refresh and retries once if successful.
  /// Throws [ApiException] for unsuccessful HTTP responses and
  /// [FormatException] for an invalid JSON response shape.
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

  /// Sends [body] as JSON in a POST request to [path].
  ///
  /// An omitted [body] is encoded as an empty JSON object.
  /// [authenticated] controls bearer authentication and automatic
  /// refresh/retry on HTTP 401. Returns the decoded JSON response.
  /// Throws [ApiException] for unsuccessful HTTP responses and
  /// [FormatException] for an invalid JSON response shape.
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

  /// Sends [body] as JSON in a PUT request to [path].
  ///
  /// An omitted [body] is encoded as an empty JSON object.
  /// [authenticated] controls bearer authentication and automatic
  /// refresh/retry on HTTP 401. Returns the decoded JSON response.
  /// Throws [ApiException] for unsuccessful HTTP responses and
  /// [FormatException] for an invalid JSON response shape.
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

  // Empty successful responses are represented as empty maps. Non-empty
  // successful responses must contain a JSON object.
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

  /// Registers the handler used to recover from HTTP 401 responses.
  ///
  /// The authentication controller supplies this handler after initialization.
  /// A request is not retried when no handler exists or refresh returns false.
  void setRefreshSessionHandler(Future<bool> Function() handler) {
    _refreshSession = handler;
  }

  void close() {
    _httpClient.close();
  }
}
