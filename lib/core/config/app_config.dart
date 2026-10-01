// -----------------------------------------------------------------------------
// app_config.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Defines the AKCore API server configuration and resolves
//   relative API paths against its base URL.
//
// -----------------------------------------------------------------------------

/// Holds the AKCore API server configuration.
///
/// The server address is selected at build time and shared by API clients.
class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  final Uri apiBaseUrl;

  /// Reads the compile-time `API_BASE_URL` configuration.
  ///
  /// Defaults to the production website and rejects URLs that are not
  /// absolute HTTP(S) addresses.
  factory AppConfig.fromEnvironment() {
    const rawApiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://www.altekamereren.org',
    );

    final uri = Uri.tryParse(rawApiBaseUrl);

    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      throw StateError('API_BASE_URL must be an absolute HTTP(S) URL.');
    }

    return AppConfig(apiBaseUrl: uri);
  }

  /// Resolves an API path relative to the configured server URL.
  ///
  /// Normalizes the base URL and leading path separator so an API path
  /// does not accidentally replace a configured base path.
  Uri resolve(String path) {
    final normalizedBase = apiBaseUrl.toString().endsWith('/')
        ? apiBaseUrl
        : Uri.parse('${apiBaseUrl.toString()}/');

    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;

    return normalizedBase.resolve(normalizedPath);
  }
}
