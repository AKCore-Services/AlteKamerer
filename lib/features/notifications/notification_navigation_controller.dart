// -----------------------------------------------------------------------------
// notification_navigation_controller.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Retains event navigation requests until the authenticated
//   application is ready to open the requested event.
//
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';

/// Holds the event requested by the most recent notification tap.
///
/// Separates notification callbacks from widget navigation, allowing taps
/// received during application startup to be handled by the app shell.
class NotificationNavigationController extends ChangeNotifier {
  int? _pendingEventId;

  int? get pendingEventId => _pendingEventId;

  /// Queues [eventId] for navigation and notifies listeners.
  ///
  /// Replaces any previous pending request. The application shell
  /// consumes the identifier when it is ready to navigate.
  void openEvent(int eventId) {
    _pendingEventId = eventId;
    notifyListeners();
  }

  /// Returns and clears the pending event identifier.
  ///
  /// Consuming the request prevents the same notification from opening
  /// the event repeatedly.
  int? consumePendingEventId() {
    final eventId = _pendingEventId;
    _pendingEventId = null;
    return eventId;
  }
}
