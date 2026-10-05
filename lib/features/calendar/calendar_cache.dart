// -----------------------------------------------------------------------------
// calendar_cache.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Persists the authenticated member's most recently loaded calendar in
//   platform secure storage for read-only offline fallback.
//
// Contains:
//   - CachedCalendar: Events together with the time they were cached.
//   - CalendarCache: Calendar cache persistence contract.
//   - SecureCalendarCache: Secure-storage implementation.
//
// -----------------------------------------------------------------------------

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'calendar_event.dart';

/// A previously loaded calendar together with its cache timestamp.
class CachedCalendar {
  const CachedCalendar({required this.events, required this.cachedAt});

  final List<CalendarEvent> events;
  final DateTime cachedAt;
}

/// Persists read-only calendar data for authenticated offline fallback.
abstract interface class CalendarCache {
  Future<CachedCalendar?> read();

  Future<void> write(List<CalendarEvent> events, {required DateTime cachedAt});

  Future<void> clear();
}

/// Stores cached calendar data using platform secure storage.
///
/// Malformed cached content is ignored rather than exposed to the
/// application. Secure-storage access failures still propagate to callers.
class SecureCalendarCache implements CalendarCache {
  SecureCalendarCache({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _cacheKey = 'calendar_cache_v1';
  static const _invalidatedKey = 'calendar_cache_invalidated_v1';

  final FlutterSecureStorage _storage;

  @override
  Future<CachedCalendar?> read() async {
    if (await _isInvalidated()) {
      return null;
    }

    final source = await _storage.read(key: _cacheKey);

    if (source == null || source.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(source);

      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final cachedAtSource = decoded['cachedAt'];
      final eventsSource = decoded['events'];

      if (cachedAtSource is! String || eventsSource is! List) {
        return null;
      }

      final cachedAt = DateTime.tryParse(cachedAtSource);

      if (cachedAt == null) {
        return null;
      }

      final events = <CalendarEvent>[];

      for (final value in eventsSource) {
        if (value is! Map<String, dynamic>) {
          return null;
        }

        events.add(CalendarEvent.fromJson(value));
      }

      return CachedCalendar(
        events: List.unmodifiable(events),
        cachedAt: cachedAt.toUtc(),
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  @override
  Future<void> write(
    List<CalendarEvent> events, {
    required DateTime cachedAt,
  }) async {
    final source = jsonEncode({
      'cachedAt': cachedAt.toUtc().toIso8601String(),
      'events': events.map((event) => event.toJson()).toList(),
    });

    // A fresh backend response replaces any data from the previous session
    // before cached fallback is made available again.
    await _storage.write(key: _cacheKey, value: source);
    await _storage.delete(key: _invalidatedKey);
  }

  @override
  Future<void> clear() async {
    // Persist the invalidation before deletion so a surviving payload cannot
    // be exposed to a later authenticated session.
    await _storage.write(key: _invalidatedKey, value: '1');
    await _storage.delete(key: _cacheKey);
  }

  Future<bool> _isInvalidated() async {
    return await _storage.read(key: _invalidatedKey) == '1';
  }
}
