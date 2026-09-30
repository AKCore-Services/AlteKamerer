import '../network/api_exception.dart';

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
