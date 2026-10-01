import '../network/api_exception.dart';

/// Produces technical error details for local diagnostics.
///
/// API failures include only the HTTP status, avoiding response messages
/// that could contain sensitive server information. Other failures include
/// the error type and, when supplied, the stack trace.
String diagnosticErrorDetails(Object error, [StackTrace? stackTrace]) {
  if (error is ApiException) {
    return 'HTTP ${error.statusCode}';
  }

  final errorType = error.runtimeType.toString();
  final stackText = stackTrace?.toString().trim() ?? '';

  if (stackText.isEmpty) {
    return errorType;
  }

  return '$errorType\n$stackText';
}
