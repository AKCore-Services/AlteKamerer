class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  final Uri apiBaseUrl;

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

  Uri resolve(String path) {
    final normalizedBase = apiBaseUrl.toString().endsWith('/')
        ? apiBaseUrl
        : Uri.parse('${apiBaseUrl.toString()}/');

    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;

    return normalizedBase.resolve(normalizedPath);
  }
}
