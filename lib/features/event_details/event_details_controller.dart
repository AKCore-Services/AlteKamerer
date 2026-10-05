// -----------------------------------------------------------------------------
// event_details_controller.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Manages the loading, success, and failure states of event details.
//
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';

import '../../core/diagnostics/diagnostic_error_details.dart';
import '../../core/diagnostics/diagnostics_service.dart';

import 'event_details.dart';
import 'event_details_api.dart';
import 'event_details_cache.dart';

enum EventDetailsStatus { loading, loaded, error }

/// Loads event details and exposes their state to the UI.
///
/// Loading another event clears the previous result. Failed backend requests
/// fall back to cached details when available; otherwise the error state is
/// exposed. Failures are recorded when diagnostics are configured.
class EventDetailsController extends ChangeNotifier {
  EventDetailsController(
    this._eventDetailsService, {
    this._cache,
    DateTime Function()? now,
    this._diagnostics,
  }) : _now = now ?? DateTime.now;

  final EventDetailsService _eventDetailsService;
  final EventDetailsCache? _cache;
  final DateTime Function() _now;
  final DiagnosticsService? _diagnostics;

  EventDetailsStatus _status = EventDetailsStatus.loading;
  EventDetails? _event;
  Object? _error;
  bool _isShowingCachedData = false;
  DateTime? _cachedAt;

  EventDetailsStatus get status => _status;

  EventDetails? get event => _event;

  Object? get error => _error;

  /// Whether the displayed event details came from offline cache.
  bool get isShowingCachedData => _isShowingCachedData;

  /// When the displayed cached details were last retrieved from AKCore.
  ///
  /// Null while displaying fresh backend data.
  DateTime? get cachedAt => _cachedAt;

  /// Loads event details from AKCore, falling back to secure cached data.
  ///
  /// Successful responses replace the cached copy for this event. Failed
  /// requests expose the last cached details when available; otherwise the
  /// controller enters the error state.
  Future<void> load(int eventId) async {
    _status = EventDetailsStatus.loading;
    _event = null;
    _error = null;
    _isShowingCachedData = false;
    _cachedAt = null;
    notifyListeners();

    try {
      final event = await _eventDetailsService.getEvent(eventId);

      _event = event;
      _error = null;
      _isShowingCachedData = false;
      _cachedAt = null;
      _status = EventDetailsStatus.loaded;

      await _updateCache(event);
    } catch (error, stackTrace) {
      await _diagnostics?.recordError(
        subsystem: 'Event details',
        message: 'Event details loading failed',
        error: diagnosticErrorDetails(error, stackTrace),
      );

      final cached = await _readCache(eventId);

      if (cached != null) {
        _event = cached.event;
        _error = null;
        _isShowingCachedData = true;
        _cachedAt = cached.cachedAt;
        _status = EventDetailsStatus.loaded;
      } else {
        _event = null;
        _error = error;
        _status = EventDetailsStatus.error;
      }
    }

    notifyListeners();
  }

  /// Refreshes an already displayed event without hiding its current details.
  ///
  /// If this controller has not successfully loaded the requested event yet,
  /// normal [load] behavior is used. A failed background refresh preserves the
  /// currently displayed event and registration state.
  Future<void> refresh(int eventId) async {
    if (_status != EventDetailsStatus.loaded || _event?.id != eventId) {
      await load(eventId);
      return;
    }

    try {
      final event = await _eventDetailsService.getEvent(eventId);

      _event = event;
      _error = null;
      _isShowingCachedData = false;
      _cachedAt = null;
      _status = EventDetailsStatus.loaded;

      await _updateCache(event);
      notifyListeners();
    } catch (error, stackTrace) {
      await _diagnostics?.recordError(
        subsystem: 'Event details',
        message: 'Event details background refresh failed',
        error: diagnosticErrorDetails(error, stackTrace),
      );
    }
  }

  Future<CachedEventDetails?> _readCache(int eventId) async {
    final cache = _cache;

    if (cache == null) {
      return null;
    }

    try {
      return await cache.read(eventId);
    } catch (error, stackTrace) {
      await _diagnostics?.recordError(
        subsystem: 'Event details',
        message: 'Event details cache loading failed',
        error: diagnosticErrorDetails(error, stackTrace),
      );

      return null;
    }
  }

  Future<void> _updateCache(EventDetails event) async {
    final cache = _cache;

    if (cache == null) {
      return;
    }

    try {
      await cache.write(event, cachedAt: _now().toUtc());
    } catch (error, stackTrace) {
      await _diagnostics?.recordError(
        subsystem: 'Event details',
        message: 'Event details cache update failed',
        error: diagnosticErrorDetails(error, stackTrace),
      );
    }
  }
}
