// -----------------------------------------------------------------------------
// event_details_cache.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Persists previously loaded authenticated event details in platform secure
//   storage for read-only offline fallback.
//
// Contains:
//   - CachedEventDetails: Event details with their retrieval timestamp.
//   - EventDetailsCache: Event-details cache persistence contract.
//   - SecureEventDetailsCache: Secure-storage implementation.
//
// -----------------------------------------------------------------------------

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'event_details.dart';

/// Previously loaded event details together with their cache timestamp.
class CachedEventDetails {
  const CachedEventDetails({required this.event, required this.cachedAt});

  final EventDetails event;
  final DateTime cachedAt;
}

/// Persists read-only event details for authenticated offline fallback.
abstract interface class EventDetailsCache {
  Future<CachedEventDetails?> read(int eventId);

  Future<void> write(EventDetails event, {required DateTime cachedAt});

  Future<void> clear();
}

/// Stores cached event details using platform secure storage.
///
/// Event details are keyed by event ID under one dedicated secure-storage
/// entry. Malformed cached data is ignored rather than exposed to the app.
class SecureEventDetailsCache implements EventDetailsCache {
  SecureEventDetailsCache({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _cacheKey = 'event_details_cache_v1';
  static const _invalidatedKey = 'event_details_cache_invalidated_v1';

  final FlutterSecureStorage _storage;

  @override
  Future<CachedEventDetails?> read(int eventId) async {
    if (await _isInvalidated()) {
      return null;
    }

    final entries = await _readEntries();
    final value = entries[eventId.toString()];

    if (value is! Map<String, dynamic>) {
      return null;
    }

    try {
      final cachedAtSource = value['cachedAt'];
      final eventSource = value['event'];

      if (cachedAtSource is! String || eventSource is! Map<String, dynamic>) {
        return null;
      }

      final cachedAt = DateTime.tryParse(cachedAtSource);

      if (cachedAt == null) {
        return null;
      }

      final event = EventDetails.fromJson(eventSource);

      if (event.id != eventId) {
        return null;
      }

      return CachedEventDetails(event: event, cachedAt: cachedAt.toUtc());
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  @override
  Future<void> write(EventDetails event, {required DateTime cachedAt}) async {
    final entries = <String, dynamic>{};

    // Never merge a fresh session with payloads invalidated at the previous
    // authentication boundary.
    if (!await _isInvalidated()) {
      entries.addAll(await _readEntries());
    }

    entries[event.id.toString()] = {
      'cachedAt': cachedAt.toUtc().toIso8601String(),
      'event': event.toJson(),
    };

    await _storage.write(key: _cacheKey, value: jsonEncode(entries));
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

  Future<Map<String, dynamic>> _readEntries() async {
    final source = await _storage.read(key: _cacheKey);

    if (source == null || source.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(source);

      if (decoded is! Map<String, dynamic>) {
        return {};
      }

      return Map<String, dynamic>.from(decoded);
    } on FormatException {
      return {};
    } on TypeError {
      return {};
    }
  }
}
