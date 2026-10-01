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

enum EventDetailsStatus { loading, loaded, error }

/// Loads event details and exposes their state to the UI.
///
/// Loading another event clears the previous result. Failures are exposed
/// through the error state and recorded when diagnostics are configured.
class EventDetailsController extends ChangeNotifier {
  EventDetailsController(this._eventDetailsService, {this._diagnostics});

  final EventDetailsService _eventDetailsService;
  final DiagnosticsService? _diagnostics;

  EventDetailsStatus _status = EventDetailsStatus.loading;
  EventDetails? _event;
  Object? _error;

  EventDetailsStatus get status => _status;

  EventDetails? get event => _event;

  Object? get error => _error;

  Future<void> load(int eventId) async {
    _status = EventDetailsStatus.loading;
    _event = null;
    _error = null;
    notifyListeners();

    try {
      _event = await _eventDetailsService.getEvent(eventId);
      _status = EventDetailsStatus.loaded;
    } catch (error, stackTrace) {
      _event = null;
      _error = error;
      _status = EventDetailsStatus.error;
      await _diagnostics?.recordError(
        subsystem: 'Event details',
        message: 'Event details loading failed',
        error: diagnosticErrorDetails(error, stackTrace),
      );
    }

    notifyListeners();
  }
}
