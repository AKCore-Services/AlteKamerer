// -----------------------------------------------------------------------------
// api_exception.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Represents unsuccessful HTTP responses from the AKCore mobile API.
//
// Contains:
//   - ApiException: HTTP status and user-facing error message.
//
// -----------------------------------------------------------------------------

/// Describes an unsuccessful response from the AKCore mobile API.
///
/// Preserves the HTTP status and the message extracted by `ApiClient`,
/// allowing callers to distinguish expected API rejections from other
/// failures.
class ApiException implements Exception {
  const ApiException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
