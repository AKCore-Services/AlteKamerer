import 'package:flutter/foundation.dart';

import 'calendar_api.dart';
import 'calendar_event.dart';

enum CalendarStatus { loading, loaded, error }

class CalendarController extends ChangeNotifier {
  CalendarController(this._calendarService);

  final CalendarService _calendarService;

  CalendarStatus _status = CalendarStatus.loading;
  List<CalendarEvent> _events = const [];
  Object? _error;

  CalendarStatus get status => _status;

  List<CalendarEvent> get events => _events;

  Object? get error => _error;

  Future<void> load() async {
    _status = CalendarStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _events = await _calendarService.getCalendar();
      _status = CalendarStatus.loaded;
    } catch (error) {
      _events = const [];
      _error = error;
      _status = CalendarStatus.error;
    }

    notifyListeners();
  }
}
