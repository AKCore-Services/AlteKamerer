import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'diagnostic_entry.dart';

class DiagnosticsService {
  DiagnosticsService(
    this._preferences, {
    this.maxEntries = 50,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static const _storageKey = 'diagnostic_entries';

  final SharedPreferences _preferences;
  final int maxEntries;
  final DateTime Function() _now;

  Future<void> recordError({
    required String subsystem,
    required String message,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    try {
      final entries = await readEntries();

      final details = _sanitizeDetails(
        [
          if (error != null) error.toString(),
          if (stackTrace != null) stackTrace.toString(),
        ].join('\n'),
      );

      entries.add(
        DiagnosticEntry(
          timestamp: _now().toUtc(),
          severity: DiagnosticSeverity.error,
          subsystem: _sanitizeText(subsystem),
          message: _sanitizeText(message),
          details: details.isEmpty ? null : details,
        ),
      );

      final retained = entries.length <= maxEntries
          ? entries
          : entries.sublist(entries.length - maxEntries);

      await _preferences.setString(
        _storageKey,
        jsonEncode(retained.map((entry) => entry.toJson()).toList()),
      );
    } catch (_) {
      // Diagnostics are best-effort and must never affect app behavior.
    }
  }

  Future<List<DiagnosticEntry>> readEntries() async {
    final source = _preferences.getString(_storageKey);

    if (source == null || source.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(source);

      if (decoded is! List) {
        return [];
      }

      return decoded
          .map(DiagnosticEntry.fromJson)
          .whereType<DiagnosticEntry>()
          .toList();
    } on FormatException {
      return [];
    }
  }

  Future<void> clear() async {
    await _preferences.remove(_storageKey);
  }

  String buildReport({
    required String version,
    required String buildNumber,
    required String platform,
    required String apiServer,
    required List<DiagnosticEntry> entries,
    DateTime? generatedAt,
  }) {
    final generated = (generatedAt ?? _now()).toLocal();
    final buffer = StringBuffer()
      ..writeln('AlteKamerer diagnostics')
      ..writeln('Version: ${_sanitizeText(version)}')
      ..writeln('Build: ${_sanitizeText(buildNumber)}')
      ..writeln('Platform: ${_sanitizeText(platform)}')
      ..writeln('API server: ${_sanitizeText(apiServer)}')
      ..writeln('Generated: ${_formatTimestamp(generated)}');

    if (entries.isEmpty) {
      buffer.writeln();
      buffer.writeln('No diagnostic errors recorded.');
      return buffer.toString().trimRight();
    }

    for (final entry in entries) {
      buffer
        ..writeln()
        ..writeln(
          '[${_formatTimestamp(entry.timestamp.toLocal())}] '
          '${entry.severity.name.toUpperCase()} ${entry.subsystem}',
        )
        ..writeln(entry.message);

      if (entry.details case final details?) {
        buffer.writeln(details);
      }
    }

    return buffer.toString().trimRight();
  }

  String _sanitizeDetails(String value) {
    if (value.isEmpty) {
      return '';
    }

    var sanitized = value;

    final bearerPattern = RegExp(
      r'(authorization\s*[:=]\s*bearer\s+)[^\s,;]+',
      caseSensitive: false,
    );
    sanitized = sanitized.replaceAllMapped(
      bearerPattern,
      (match) => '${match.group(1)}[REDACTED]',
    );

    final credentialPattern = RegExp(
      r'(access[_-]?token|refresh[_-]?token|session[_-]?id|'
      r'device[_-]?token|notification[_-]?token|password)'
      r'(\s*[:=]\s*)[^\s,;}]+',
      caseSensitive: false,
    );
    sanitized = sanitized.replaceAllMapped(
      credentialPattern,
      (match) => '${match.group(1)}${match.group(2)}[REDACTED]',
    );

    final jsonCredentialPattern = RegExp(
      r'("?(?:accessToken|refreshToken|sessionId|deviceToken|'
      r'notificationToken|password)"?\s*:\s*)"[^"]*"',
      caseSensitive: false,
    );
    sanitized = sanitized.replaceAllMapped(
      jsonCredentialPattern,
      (match) => '${match.group(1)}"[REDACTED]"',
    );

    return _sanitizeText(sanitized);
  }

  String _sanitizeText(String value) {
    return value
        .replaceAll(RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F]'), '')
        .trim();
  }

  String _formatTimestamp(DateTime value) {
    String twoDigits(int number) => number.toString().padLeft(2, '0');

    return '${value.year.toString().padLeft(4, '0')}-'
        '${twoDigits(value.month)}-'
        '${twoDigits(value.day)} '
        '${twoDigits(value.hour)}:'
        '${twoDigits(value.minute)}:'
        '${twoDigits(value.second)}';
  }
}
