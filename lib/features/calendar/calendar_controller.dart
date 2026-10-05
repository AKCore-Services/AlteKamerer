// -----------------------------------------------------------------------------
// calendar_controller.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Owns loaded calendar data, date navigation, and the filters applied to the calendar UI.
//
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';

import '../../core/diagnostics/diagnostic_error_details.dart';
import '../../core/diagnostics/diagnostics_service.dart';

import 'calendar_api.dart';
import 'calendar_cache.dart';
import 'calendar_event.dart';

enum CalendarStatus { loading, loaded, error }

/// Available date ranges for displaying calendar events.
enum CalendarView { upcoming, today, week, month }

/// Filters events by the member's registration state.
enum CalendarRegistrationFilter { all, coming, notRegistered, notComing }

/// Coordinates calendar loading and presentation state.
///
/// Retrieves events through [CalendarService] and applies date, event type,
/// registration, and search filters to the loaded collection.
class CalendarController extends ChangeNotifier {
  CalendarController(
    this._calendarService, {
    this._cache,
    DateTime Function()? now,
    this._diagnostics,
  }) : _now = now ?? DateTime.now;

  final CalendarService _calendarService;
  final CalendarCache? _cache;
  final DateTime Function() _now;
  final DiagnosticsService? _diagnostics;

  CalendarStatus _status = CalendarStatus.loading;
  List<CalendarEvent> _events = const [];
  Object? _error;
  bool _isShowingCachedData = false;
  DateTime? _cachedAt;

  CalendarView _view = CalendarView.upcoming;

  String? get eventTypeFilter => _eventTypeFilter;
  CalendarRegistrationFilter get registrationFilter => _registrationFilter;
  String get searchQuery => _searchQuery;

  /// Returns the distinct event types in the loaded calendar, sorted
  /// alphabetically.
  List<String> get availableEventTypes {
    final types = _events.map((event) => event.type).toSet().toList()..sort();
    return types;
  }

  DateTime? _focusedDate;
  String? _eventTypeFilter;
  CalendarRegistrationFilter _registrationFilter =
      CalendarRegistrationFilter.all;
  String _searchQuery = '';

  CalendarStatus get status => _status;

  List<CalendarEvent> get events => _events;

  Object? get error => _error;

  /// Whether the currently displayed calendar came from offline cache.
  bool get isShowingCachedData => _isShowingCachedData;

  /// When the displayed cached calendar was last retrieved from AKCore.
  ///
  /// Null while displaying fresh backend data.
  DateTime? get cachedAt => _cachedAt;

  CalendarView get view => _view;

  /// Returns the focused calendar date, defaulting to today.
  ///
  /// The time component is removed before the date is exposed.
  DateTime get focusedDate {
    final value = _focusedDate ?? _today;
    return DateTime(value.year, value.month, value.day);
  }

  /// Returns events matching the selected view and all active filters.
  ///
  /// Date, type, registration, and search conditions are combined rather
  /// than applied as alternative ways of matching an event.
  List<CalendarEvent> get visibleEvents {
    final dateFilteredEvents = switch (_view) {
      CalendarView.upcoming => _events,
      CalendarView.today => _events.where(_isToday),
      CalendarView.week => _events.where(_isInFocusedWeek),
      CalendarView.month => _events.where(_isInFocusedMonth),
    };

    return dateFilteredEvents
        .where(_matchesEventType)
        .where(_matchesRegistration)
        .where(_matchesSearch)
        .toList();
  }

  /// Changes the calendar view and updates the focused date as needed.
  ///
  /// Switching to today focuses the current date. Entering week or month
  /// view initializes an unset focused date to today. Other transitions
  /// preserve the existing focused date.
  void setView(CalendarView view) {
    if (_view == view) {
      return;
    }

    _view = view;

    if (view == CalendarView.today) {
      _focusedDate = _today;
    } else if (view != CalendarView.upcoming) {
      _focusedDate ??= _today;
    }

    notifyListeners();
  }

  void setEventTypeFilter(String? type) {
    if (_eventTypeFilter == type) {
      return;
    }
    _eventTypeFilter = type;
    notifyListeners();
  }

  void setRegistrationFilter(CalendarRegistrationFilter filter) {
    if (_registrationFilter == filter) {
      return;
    }

    _registrationFilter = filter;
    notifyListeners();
  }

  /// Clears the event-type and registration filters.
  ///
  /// Preserves the search query, selected view, and focused date.
  /// Does nothing when both filters are already at their defaults.
  void resetFilters() {
    if (_eventTypeFilter == null &&
        _registrationFilter == CalendarRegistrationFilter.all) {
      return;
    }

    _eventTypeFilter = null;
    _registrationFilter = CalendarRegistrationFilter.all;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) {
      return;
    }

    _searchQuery = query;
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

  bool get isCurrentPeriod {
    switch (_view) {
      case CalendarView.upcoming:
      case CalendarView.today:
        return true;
      case CalendarView.week:
        return _startOfWeek(focusedDate) == _startOfWeek(_today);
      case CalendarView.month:
        return focusedDate.year == _today.year &&
            focusedDate.month == _today.month;
    }
  }

  /// Whether navigation to an earlier calendar period is available.
  ///
  /// Week and month navigation stops at the current period.
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

  /// Clears calendar data associated with the authenticated session.
  ///
  /// Removes both the secure offline cache and any currently loaded member
  /// calendar so data cannot carry across authenticated sessions.
  Future<void> clearSessionData() async {
    _events = const [];
    _error = null;
    _isShowingCachedData = false;
    _cachedAt = null;
    _status = CalendarStatus.loading;
    notifyListeners();

    await _cache?.clear();
  }

  /// Reloads calendar events from the backend.
  ///
  /// Successful responses replace the secure offline cache. If the backend
  /// request fails, a previously cached calendar is exposed as stale data.
  /// Without usable cached data, the controller enters the error state.
  Future<void> load() async {
    _status = CalendarStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final events = await _calendarService.getCalendar();

      _events = events;
      _error = null;
      _isShowingCachedData = false;
      _cachedAt = null;
      _status = CalendarStatus.loaded;

      await _updateCache(events);
    } catch (error, stackTrace) {
      await _diagnostics?.recordError(
        subsystem: 'Calendar',
        message: 'Calendar loading failed',
        error: diagnosticErrorDetails(error, stackTrace),
      );

      final cached = await _readCache();

      if (cached != null) {
        _events = cached.events;
        _error = null;
        _isShowingCachedData = true;
        _cachedAt = cached.cachedAt;
        _status = CalendarStatus.loaded;
      } else {
        _events = const [];
        _error = error;
        _isShowingCachedData = false;
        _cachedAt = null;
        _status = CalendarStatus.error;
      }
    }

    notifyListeners();
  }

  /// Restores the most recently cached calendar without contacting AKCore.
  ///
  /// Returns whether usable cached data was available. A restored calendar is
  /// explicitly marked as cached until a later backend refresh succeeds.
  Future<bool> restoreCached() async {
    final cached = await _readCache();

    if (cached == null) {
      return false;
    }

    _events = cached.events;
    _error = null;
    _isShowingCachedData = true;
    _cachedAt = cached.cachedAt;
    _status = CalendarStatus.loaded;
    notifyListeners();

    return true;
  }

  /// Refreshes calendar data without hiding an already displayed calendar.
  ///
  /// When no calendar is currently loaded, this uses the normal [load]
  /// behavior. Otherwise the current data remains visible while AKCore is
  /// queried. A failed refresh preserves that data instead of replacing the
  /// screen with a loading or error state.
  Future<void> refresh() async {
    if (_status != CalendarStatus.loaded) {
      await load();
      return;
    }

    try {
      final events = await _calendarService.getCalendar();

      _events = events;
      _error = null;
      _isShowingCachedData = false;
      _cachedAt = null;
      _status = CalendarStatus.loaded;

      await _updateCache(events);
      notifyListeners();
    } catch (error, stackTrace) {
      await _diagnostics?.recordError(
        subsystem: 'Calendar',
        message: 'Calendar background refresh failed',
        error: diagnosticErrorDetails(error, stackTrace),
      );
    }
  }

  Future<CachedCalendar?> _readCache() async {
    final cache = _cache;

    if (cache == null) {
      return null;
    }

    try {
      return await cache.read();
    } catch (error, stackTrace) {
      await _diagnostics?.recordError(
        subsystem: 'Calendar',
        message: 'Calendar cache loading failed',
        error: diagnosticErrorDetails(error, stackTrace),
      );

      return null;
    }
  }

  Future<void> _updateCache(List<CalendarEvent> events) async {
    final cache = _cache;

    if (cache == null) {
      return;
    }

    try {
      await cache.write(events, cachedAt: _now().toUtc());
    } catch (error, stackTrace) {
      await _diagnostics?.recordError(
        subsystem: 'Calendar',
        message: 'Calendar cache update failed',
        error: diagnosticErrorDetails(error, stackTrace),
      );
    }
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

  bool _matchesEventType(CalendarEvent event) {
    final type = _eventTypeFilter;

    return type == null || event.type == type;
  }

  bool _matchesRegistration(CalendarEvent event) {
    return switch (_registrationFilter) {
      CalendarRegistrationFilter.all => true,
      CalendarRegistrationFilter.coming => event.isAttending,
      CalendarRegistrationFilter.notRegistered => !event.isRegistered,
      CalendarRegistrationFilter.notComing => event.isRegisteredNotAttending,
    };
  }

  bool _matchesSearch(CalendarEvent event) {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return true;
    }

    return event.name.toLowerCase().contains(query) ||
        event.place.toLowerCase().contains(query) ||
        event.description.toLowerCase().contains(query) ||
        event.type.toLowerCase().contains(query);
  }
}
