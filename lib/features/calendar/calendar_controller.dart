import 'package:flutter/foundation.dart';

import 'calendar_api.dart';
import 'calendar_event.dart';

enum CalendarStatus { loading, loaded, error }

enum CalendarView { upcoming, today, week, month }

enum CalendarFilter {
  all,
  rehearsals,
  performances,
  social,
  registered,
  relevant,
}

class CalendarController extends ChangeNotifier {
  CalendarController(this._calendarService, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final CalendarService _calendarService;
  final DateTime Function() _now;

  CalendarStatus _status = CalendarStatus.loading;
  List<CalendarEvent> _events = const [];
  Object? _error;

  CalendarView _view = CalendarView.upcoming;
  CalendarFilter get filter => _filter;

  String? get eventTypeFilter => _eventTypeFilter;

  bool? get isBallet => _isBallet;

  List<String> get availableEventTypes {
    final types = _events.map((event) => event.type).toSet().toList()..sort();
    return types;
  }

  DateTime? _focusedDate;
  CalendarFilter _filter = CalendarFilter.all;
  String? _eventTypeFilter;
  bool? _isBallet;

  CalendarStatus get status => _status;

  List<CalendarEvent> get events => _events;

  Object? get error => _error;

  CalendarView get view => _view;

  DateTime get focusedDate {
    final value = _focusedDate ?? _today;
    return DateTime(value.year, value.month, value.day);
  }

  List<CalendarEvent> get visibleEvents {
    final dateFilteredEvents = switch (_view) {
      CalendarView.upcoming => _events,
      CalendarView.today => _events.where(_isToday),
      CalendarView.week => _events.where(_isInFocusedWeek),
      CalendarView.month => _events.where(_isInFocusedMonth),
    };

    return dateFilteredEvents
        .where(_matchesFilter)
        .where(_matchesEventType)
        .toList();
  }

  void setView(CalendarView view) {
    if (_view == view) {
      return;
    }

    _view = view;

    if (view != CalendarView.upcoming) {
      _focusedDate ??= _today;
    }

    notifyListeners();
  }

  void setFilter(CalendarFilter filter) {
    if (_filter == filter) {
      return;
    }

    _filter = filter;
    notifyListeners();
  }

  void setEventTypeFilter(String? type) {
    if (_eventTypeFilter == type) {
      return;
    }

    _eventTypeFilter = type;
    notifyListeners();
  }

  void setMemberContext({required bool isBallet}) {
    if (_isBallet == isBallet) {
      return;
    }

    _isBallet = isBallet;
    notifyListeners();
  }

  void setFocusedDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);

    if (_focusedDate == normalized) {
      return;
    }

    _focusedDate = normalized;
    notifyListeners();
  }

  bool get canShowPreviousPeriod {
    switch (_view) {
      case CalendarView.upcoming:
      case CalendarView.today:
        return false;
      case CalendarView.week:
        return _startOfWeek(focusedDate).isAfter(_startOfWeek(_today));
      case CalendarView.month:
        final focusedMonth = DateTime(focusedDate.year, focusedDate.month);
        final currentMonth = DateTime(_today.year, _today.month);
        return focusedMonth.isAfter(currentMonth);
    }
  }

  void showPreviousPeriod() {
    if (!canShowPreviousPeriod) {
      return;
    }

    switch (_view) {
      case CalendarView.upcoming:
      case CalendarView.today:
        return;
      case CalendarView.week:
        setFocusedDate(focusedDate.subtract(const Duration(days: 7)));
      case CalendarView.month:
        setFocusedDate(DateTime(focusedDate.year, focusedDate.month - 1, 1));
    }
  }

  void showNextPeriod() {
    switch (_view) {
      case CalendarView.upcoming:
      case CalendarView.today:
        return;
      case CalendarView.week:
        setFocusedDate(focusedDate.add(const Duration(days: 7)));
      case CalendarView.month:
        setFocusedDate(DateTime(focusedDate.year, focusedDate.month + 1, 1));
    }
  }

  void showCurrentPeriod() {
    setFocusedDate(_today);
  }

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

  DateTime get _today {
    final now = _now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _isToday(CalendarEvent event) {
    final date = _eventDate(event);

    if (date == null) {
      return false;
    }

    return date == _today;
  }

  bool _isInFocusedWeek(CalendarEvent event) {
    final date = _eventDate(event);

    if (date == null) {
      return false;
    }

    final start = _startOfWeek(focusedDate);
    final end = start.add(const Duration(days: 7));

    return !date.isBefore(start) && date.isBefore(end);
  }

  DateTime _startOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - DateTime.monday));
  }

  bool _isInFocusedMonth(CalendarEvent event) {
    final date = _eventDate(event);

    if (date == null) {
      return false;
    }

    return date.year == focusedDate.year && date.month == focusedDate.month;
  }

  DateTime? _eventDate(CalendarEvent event) {
    final value = DateTime.tryParse(event.date);

    if (value == null) {
      return null;
    }

    return DateTime(value.year, value.month, value.day);
  }

  bool _matchesFilter(CalendarEvent event) {
    return switch (_filter) {
      CalendarFilter.all => true,
      CalendarFilter.rehearsals => event.isRehearsal,
      CalendarFilter.performances => event.isPerformance,
      CalendarFilter.social => event.isSocialEvent,
      CalendarFilter.registered => event.isRegistered,
      CalendarFilter.relevant =>
        _isBallet != null && event.isRelevantTo(isBallet: _isBallet!),
    };
  }

  bool _matchesEventType(CalendarEvent event) {
    final type = _eventTypeFilter;

    return type == null || event.type == type;
  }
}
