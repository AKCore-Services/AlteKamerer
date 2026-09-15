import 'package:flutter/foundation.dart';

class NotificationNavigationController extends ChangeNotifier {
  int? _pendingEventId;

  int? get pendingEventId => _pendingEventId;

  void openEvent(int eventId) {
    _pendingEventId = eventId;
    notifyListeners();
  }

  int? consumePendingEventId() {
    final eventId = _pendingEventId;
    _pendingEventId = null;
    return eventId;
  }
}
