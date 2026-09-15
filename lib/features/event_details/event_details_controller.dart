import 'package:flutter/foundation.dart';

import 'event_details.dart';
import 'event_details_api.dart';

enum EventDetailsStatus { loading, loaded, error }

class EventDetailsController extends ChangeNotifier {
  EventDetailsController(this._eventDetailsService);

  final EventDetailsService _eventDetailsService;

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
    } catch (error) {
      _event = null;
      _error = error;
      _status = EventDetailsStatus.error;
    }

    notifyListeners();
  }
}
