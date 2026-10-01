// -----------------------------------------------------------------------------
// diagnostic_entry.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Defines a persisted diagnostic record and its JSON representation.
//
// -----------------------------------------------------------------------------

enum DiagnosticSeverity { error }

/// Represents one locally retained application diagnostic.
///
/// Records when an error occurred, which subsystem reported it, and any
/// additional details available for a diagnostic report.
class DiagnosticEntry {
  const DiagnosticEntry({
    required this.timestamp,
    required this.severity,
    required this.subsystem,
    required this.message,
    this.details,
  });

  final DateTime timestamp;
  final DiagnosticSeverity severity;
  final String subsystem;
  final String message;
  final String? details;

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toUtc().toIso8601String(),
      'severity': severity.name,
      'subsystem': subsystem,
      'message': message,
      if (details != null) 'details': details,
    };
  }

  /// Reconstructs a diagnostic entry from its stored JSON representation.
  ///
  /// Returns null when validation fails, including an invalid timestamp,
  /// unsupported severity, or missing required text fields.
  /// Unexpected field types may throw during decoding.
  static DiagnosticEntry? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return null;
    }

    final timestamp = DateTime.tryParse(value['timestamp'] as String? ?? '');
    final severityName = value['severity'];
    final subsystem = value['subsystem'];
    final message = value['message'];
    final details = value['details'];

    if (timestamp == null ||
        severityName != DiagnosticSeverity.error.name ||
        subsystem is! String ||
        subsystem.isEmpty ||
        message is! String ||
        message.isEmpty ||
        (details != null && details is! String)) {
      return null;
    }

    return DiagnosticEntry(
      timestamp: timestamp.toUtc(),
      severity: DiagnosticSeverity.error,
      subsystem: subsystem,
      message: message,
      details: details as String?,
    );
  }
}
