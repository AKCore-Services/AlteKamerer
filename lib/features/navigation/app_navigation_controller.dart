// -----------------------------------------------------------------------------
// app_navigation_controller.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Retains application navigation requests until the authenticated app shell
//   is ready to handle them.
//
// Contains:
//   - AppNavigationRequest: Typed navigation request.
//   - CalendarNavigationRequest: Opens the authenticated calendar.
//   - EventNavigationRequest: Opens one event.
//   - AppNavigationController: Queues the most recent navigation request.
//
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';

/// A destination that AlteKamerer can open after authentication is available.
sealed class AppNavigationRequest {
  const AppNavigationRequest();
}

/// Opens the authenticated calendar.
final class CalendarNavigationRequest extends AppNavigationRequest {
  const CalendarNavigationRequest();
}

/// Opens the event identified by [eventId].
final class EventNavigationRequest extends AppNavigationRequest {
  const EventNavigationRequest(this.eventId);

  final int eventId;
}

/// Holds the most recent request until authenticated navigation is available.
///
/// Notification taps, external links, and future supported link sources share
/// this queue so startup/authentication timing is handled consistently.
class AppNavigationController extends ChangeNotifier {
  AppNavigationRequest? _pendingRequest;

  AppNavigationRequest? get pendingRequest => _pendingRequest;

  /// Returns the pending event identifier when the current request is an event.
  ///
  /// This keeps event-specific callers and authentication tests simple while
  /// the underlying navigation queue supports multiple destination types.
  int? get pendingEventId {
    return switch (_pendingRequest) {
      EventNavigationRequest(:final eventId) => eventId,
      _ => null,
    };
  }

  /// Queues an already parsed navigation [request].
  void openRequest(AppNavigationRequest request) {
    _queue(request);
  }

  /// Queues the authenticated calendar for navigation.
  void openCalendar() {
    openRequest(const CalendarNavigationRequest());
  }

  /// Queues [eventId] for navigation.
  void openEvent(int eventId) {
    if (eventId <= 0) {
      return;
    }

    openRequest(EventNavigationRequest(eventId));
  }

  /// Returns and clears the pending navigation request.
  ///
  /// Consuming a request prevents the same notification or external link from
  /// navigating repeatedly.
  AppNavigationRequest? consumePendingRequest() {
    final request = _pendingRequest;
    _pendingRequest = null;
    return request;
  }

  void _queue(AppNavigationRequest request) {
    _pendingRequest = request;
    notifyListeners();
  }
}
