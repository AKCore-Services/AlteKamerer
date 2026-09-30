import 'dart:async';

import 'package:altekamerer/features/calendar/calendar_api.dart';
import 'package:altekamerer/core/diagnostics/diagnostics_service.dart';
import 'package:altekamerer/features/calendar/calendar_controller.dart';
import 'package:altekamerer/features/calendar/calendar_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('load exposes successful calendar result', () async {
    final event = _event();
    final controller = CalendarController(FakeCalendarService(events: [event]));

    await controller.load();

    expect(controller.status, CalendarStatus.loaded);
    expect(controller.events, [event]);
    expect(controller.error, isNull);
  });

  test('load exposes empty successful result', () async {
    final controller = CalendarController(
      FakeCalendarService(events: const []),
    );

    await controller.load();

    expect(controller.status, CalendarStatus.loaded);
    expect(controller.events, isEmpty);
    expect(controller.error, isNull);
  });

  test('load exposes error and clears stale events', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final diagnostics = DiagnosticsService(preferences);
    final service = FakeCalendarService(events: [_event()]);
    final controller = CalendarController(service, diagnostics: diagnostics);

    await controller.load();

    expect(controller.events, isNotEmpty);

    service.error = StateError('calendar failed');

    await controller.load();

    expect(controller.status, CalendarStatus.error);
    expect(controller.events, isEmpty);
    expect(controller.error, isA<StateError>());

    final entries = await diagnostics.readEntries();
    expect(entries, hasLength(1));
    expect(entries.single.subsystem, 'Calendar');
    expect(entries.single.message, 'Calendar loading failed');
    expect(entries.single.details, contains('StateError'));
  });

  test('load returns to loading before retry completes', () async {
    final service = DeferredCalendarService();
    final controller = CalendarController(service);

    final load = controller.load();

    expect(controller.status, CalendarStatus.loading);

    service.complete(const []);

    await load;

    expect(controller.status, CalendarStatus.loaded);
    expect(controller.events, isEmpty);
  });

  test('upcoming is the default view and exposes all loaded events', () async {
    final first = _event(id: 1, date: '2026-09-15');
    final second = _event(id: 2, date: '2026-10-02');

    final controller = CalendarController(
      FakeCalendarService(events: [first, second]),
      now: () => DateTime(2026, 9, 15, 12),
    );

    await controller.load();

    expect(controller.view, CalendarView.upcoming);
    expect(controller.visibleEvents, [first, second]);
  });

  test('today view exposes only events on the current date', () async {
    final today = _event(id: 1, date: '2026-09-15');
    final tomorrow = _event(id: 2, date: '2026-09-16');

    final controller = CalendarController(
      FakeCalendarService(events: [today, tomorrow]),
      now: () => DateTime(2026, 9, 15, 12),
    );

    await controller.load();
    controller.setView(CalendarView.today);

    expect(controller.visibleEvents, [today]);
  });

  test('week view uses Monday through Sunday', () async {
    final monday = _event(id: 1, date: '2026-09-14');
    final sunday = _event(id: 2, date: '2026-09-20');
    final nextMonday = _event(id: 3, date: '2026-09-21');

    final controller = CalendarController(
      FakeCalendarService(events: [monday, sunday, nextMonday]),
      now: () => DateTime(2026, 9, 16),
    );

    await controller.load();
    controller.setView(CalendarView.week);

    expect(controller.visibleEvents, [monday, sunday]);
  });

  test('month view exposes events in the focused month', () async {
    final september = _event(id: 1, date: '2026-09-30');
    final october = _event(id: 2, date: '2026-10-01');

    final controller = CalendarController(
      FakeCalendarService(events: [september, october]),
      now: () => DateTime(2026, 9, 15),
    );

    await controller.load();
    controller.setView(CalendarView.month);

    expect(controller.visibleEvents, [september]);
  });

  test('current period follows focused week and month', () {
    final controller = CalendarController(
      FakeCalendarService(events: const []),
      now: () => DateTime(2026, 9, 16),
    );

    controller.setView(CalendarView.week);
    expect(controller.isCurrentPeriod, isTrue);

    controller.showNextPeriod();
    expect(controller.isCurrentPeriod, isFalse);

    controller.showCurrentPeriod();
    expect(controller.isCurrentPeriod, isTrue);

    controller.setView(CalendarView.month);
    expect(controller.isCurrentPeriod, isTrue);

    controller.showNextPeriod();
    expect(controller.isCurrentPeriod, isFalse);

    controller.showCurrentPeriod();
    expect(controller.isCurrentPeriod, isTrue);
  });

  test('today resets stale period focus before switching to week', () {
    final controller = CalendarController(
      FakeCalendarService(events: const []),
      now: () => DateTime(2026, 9, 16),
    );

    controller.setView(CalendarView.week);
    controller.showNextPeriod();
    expect(controller.isCurrentPeriod, isFalse);

    controller.setView(CalendarView.today);
    controller.setView(CalendarView.week);

    expect(controller.focusedDate, DateTime(2026, 9, 16));
    expect(controller.isCurrentPeriod, isTrue);
  });

  test('week navigation moves focused date by seven days', () {
    final controller = CalendarController(
      FakeCalendarService(events: const []),
      now: () => DateTime(2026, 9, 16),
    );

    controller.setView(CalendarView.week);

    expect(controller.canShowPreviousPeriod, isFalse);
    expect(controller.focusedDate, DateTime(2026, 9, 16));

    controller.showNextPeriod();
    expect(controller.canShowPreviousPeriod, isTrue);
    expect(controller.focusedDate, DateTime(2026, 9, 23));

    controller.showPreviousPeriod();
    expect(controller.canShowPreviousPeriod, isFalse);
    expect(controller.focusedDate, DateTime(2026, 9, 16));
  });

  test('month navigation crosses year boundaries', () {
    final controller = CalendarController(
      FakeCalendarService(events: const []),
      now: () => DateTime(2026, 12, 15),
    );

    controller.setView(CalendarView.month);
    expect(controller.canShowPreviousPeriod, isFalse);

    controller.showNextPeriod();
    expect(controller.canShowPreviousPeriod, isTrue);
    expect(controller.focusedDate, DateTime(2027, 1, 1));

    controller.showPreviousPeriod();
    expect(controller.canShowPreviousPeriod, isFalse);
    expect(controller.focusedDate, DateTime(2026, 12, 1));
  });

  test('cannot navigate before the current week or month', () {
    final controller = CalendarController(
      FakeCalendarService(events: const []),
      now: () => DateTime(2026, 9, 15),
    );

    controller.setView(CalendarView.week);
    controller.showPreviousPeriod();

    expect(controller.focusedDate, DateTime(2026, 9, 15));

    controller.setView(CalendarView.month);
    controller.showPreviousPeriod();

    expect(controller.focusedDate, DateTime(2026, 9, 15));
  });

  test('showCurrentPeriod returns navigation to today', () {
    final controller = CalendarController(
      FakeCalendarService(events: const []),
      now: () => DateTime(2026, 9, 15),
    );

    controller.setView(CalendarView.month);
    controller.showNextPeriod();
    controller.showNextPeriod();

    controller.showCurrentPeriod();

    expect(controller.focusedDate, DateTime(2026, 9, 15));
  });

  test('invalid event dates remain in upcoming but not dated views', () async {
    final invalid = _event(id: 1, date: 'not-a-date');

    final controller = CalendarController(
      FakeCalendarService(events: [invalid]),
      now: () => DateTime(2026, 9, 15),
    );

    await controller.load();

    expect(controller.visibleEvents, [invalid]);

    controller.setView(CalendarView.today);

    expect(controller.visibleEvents, isEmpty);
  });

  test('Hålan registration uses Hålan gathering time', () {
    final event = _event(signupState: 'Hålan');

    expect(event.displayTime, '18:00');
  });

  test('Rep Direkt registration uses Hålan time as on-site time', () {
    final event = _event(
      type: 'Rep',
      signupState: 'Direkt',
      halanTime: '18:00',
      thereTime: '00:00',
    );

    expect(event.effectiveThereTime, '18:00');
    expect(event.displayTime, '18:00');
  });

  test('Balettrep Direkt registration uses Hålan time as on-site time', () {
    final event = _event(
      type: 'Balettrep',
      signupState: 'Direkt',
      halanTime: '18:15',
      thereTime: '00:00',
    );

    expect(event.effectiveThereTime, '18:15');
    expect(event.displayTime, '18:15');
  });

  test('other event types keep their explicit on-site time', () {
    final event = _event(
      type: 'Spelning',
      signupState: 'Direkt',
      halanTime: '18:00',
      thereTime: '18:30',
    );

    expect(event.effectiveThereTime, '18:30');
    expect(event.displayTime, '18:30');
  });

  test('not registered uses on-site time', () {
    final event = _event(type: 'Spelning');

    expect(event.displayTime, '18:30');
  });

  test('Kan inte komma uses on-site time but remains registered', () {
    final event = _event(type: 'Spelning', signupState: 'Kan inte komma');

    expect(event.displayTime, '18:30');
    expect(event.isRegistered, isTrue);
    expect(event.isAttending, isFalse);
    expect(event.isRegisteredNotAttending, isTrue);
  });
  test('uses halan time when there time is unavailable', () {
    final event = _event(
      type: 'Spelning',
      signupState: null,
      halanTime: '19:00',
      thereTime: '',
    );

    expect(event.displayTime, '19:00');
  });

  test('uses start time when gathering times are unavailable', () {
    final event = _event(
      signupState: null,
      halanTime: '',
      thereTime: '',
      startsTime: '09:35',
    );

    expect(event.displayTime, '09:35');
  });

  test('event type filter exposes only the selected activity type', () async {
    final rep = _event(id: 1, type: 'Rep');
    final karhusrep = _event(id: 2, type: 'Kårhusrep');
    final performance = _event(id: 3, type: 'Spelning');

    final controller = CalendarController(
      FakeCalendarService(events: [rep, karhusrep, performance]),
    );

    await controller.load();
    controller.setEventTypeFilter('Rep');

    expect(controller.visibleEvents, [rep]);
  });

  test('coming status includes Hålan and Direkt registrations', () async {
    final halan = _event(id: 1, signupState: 'Hålan');
    final direct = _event(id: 2, signupState: 'Direkt');
    final cannotCome = _event(id: 3, signupState: 'Kan inte komma');
    final unregistered = _event(id: 4);

    final controller = CalendarController(
      FakeCalendarService(events: [halan, direct, cannotCome, unregistered]),
    );

    await controller.load();
    controller.setRegistrationFilter(CalendarRegistrationFilter.coming);

    expect(controller.visibleEvents, [halan, direct]);
  });

  test('not registered status exposes only unregistered events', () async {
    final halan = _event(id: 1, signupState: 'Hålan');
    final cannotCome = _event(id: 2, signupState: 'Kan inte komma');
    final unregistered = _event(id: 3);

    final controller = CalendarController(
      FakeCalendarService(events: [halan, cannotCome, unregistered]),
    );

    await controller.load();
    controller.setRegistrationFilter(CalendarRegistrationFilter.notRegistered);

    expect(controller.visibleEvents, [unregistered]);
  });

  test('not coming status exposes only Kan inte komma registrations', () async {
    final halan = _event(id: 1, signupState: 'Hålan');
    final direct = _event(id: 2, signupState: 'Direkt');
    final cannotCome = _event(id: 3, signupState: 'Kan inte komma');
    final unregistered = _event(id: 4);

    final controller = CalendarController(
      FakeCalendarService(events: [halan, direct, cannotCome, unregistered]),
    );

    await controller.load();
    controller.setRegistrationFilter(CalendarRegistrationFilter.notComing);

    expect(controller.visibleEvents, [cannotCome]);
  });

  test('activity and status filters compose with date view', () async {
    final matching = _event(
      id: 1,
      type: 'Rep',
      signupState: 'Direkt',
      date: '2026-09-15',
    );
    final wrongStatus = _event(
      id: 2,
      type: 'Rep',
      signupState: 'Kan inte komma',
      date: '2026-09-15',
    );
    final wrongType = _event(
      id: 3,
      type: 'Kårhusrep',
      signupState: 'Direkt',
      date: '2026-09-15',
    );
    final wrongDate = _event(
      id: 4,
      type: 'Rep',
      signupState: 'Direkt',
      date: '2026-09-16',
    );

    final controller = CalendarController(
      FakeCalendarService(
        events: [matching, wrongStatus, wrongType, wrongDate],
      ),
      now: () => DateTime(2026, 9, 15),
    );

    await controller.load();
    controller.setView(CalendarView.today);
    controller.setEventTypeFilter('Rep');
    controller.setRegistrationFilter(CalendarRegistrationFilter.coming);

    expect(controller.visibleEvents, [matching]);
  });

  test(
    'reset filters clears activity and status without clearing search',
    () async {
      final matching = _event(
        id: 1,
        type: 'Rep',
        name: 'Monday orchestra',
        signupState: 'Direkt',
      );
      final other = _event(
        id: 2,
        type: 'Spelning',
        name: 'Tuesday performance',
      );

      final controller = CalendarController(
        FakeCalendarService(events: [matching, other]),
      );

      await controller.load();
      controller.setEventTypeFilter('Rep');
      controller.setRegistrationFilter(CalendarRegistrationFilter.coming);
      controller.setSearchQuery('Monday');

      controller.resetFilters();

      expect(controller.eventTypeFilter, isNull);
      expect(controller.registrationFilter, CalendarRegistrationFilter.all);
      expect(controller.searchQuery, 'Monday');
      expect(controller.visibleEvents, [matching]);
    },
  );

  test('search matches event name, location, description, and type', () async {
    final nameMatch = _event(id: 1, name: 'Autumn Concert');
    final placeMatch = _event(id: 2, place: 'Stora salen');
    final descriptionMatch = _event(
      id: 3,
      description: 'Bring your red folder',
    );
    final typeMatch = _event(id: 4, type: 'Spelning');
    final noMatch = _event(id: 5, name: 'Unrelated activity');

    final controller = CalendarController(
      FakeCalendarService(
        events: [nameMatch, placeMatch, descriptionMatch, typeMatch, noMatch],
      ),
    );

    await controller.load();

    controller.setSearchQuery('Autumn');
    expect(controller.visibleEvents, [nameMatch]);

    controller.setSearchQuery('Stora');
    expect(controller.visibleEvents, [placeMatch]);

    controller.setSearchQuery('red folder');
    expect(controller.visibleEvents, [descriptionMatch]);

    controller.setSearchQuery('Spelning');
    expect(controller.visibleEvents, [typeMatch]);
  });

  test(
    'search is case-insensitive and ignores surrounding whitespace',
    () async {
      final match = _event(id: 1, name: 'HÖSTKONSERT');
      final other = _event(id: 2, name: 'Repetition');

      final controller = CalendarController(
        FakeCalendarService(events: [match, other]),
      );

      await controller.load();
      controller.setSearchQuery('  höstkonsert  ');

      expect(controller.visibleEvents, [match]);
    },
  );

  test('empty search query does not filter calendar events', () async {
    final first = _event(id: 1);
    final second = _event(id: 2);

    final controller = CalendarController(
      FakeCalendarService(events: [first, second]),
    );

    await controller.load();

    controller.setSearchQuery('something');
    expect(controller.visibleEvents, isEmpty);

    controller.setSearchQuery('   ');
    expect(controller.visibleEvents, [first, second]);
  });

  test('search composes with date, activity, and status filters', () async {
    final matching = _event(
      id: 1,
      type: 'Rep',
      name: 'Monday orchestra',
      date: '2026-09-15',
      signupState: 'Direkt',
    );
    final wrongSearch = _event(
      id: 2,
      type: 'Rep',
      name: 'Tuesday orchestra',
      date: '2026-09-15',
      signupState: 'Direkt',
    );
    final wrongType = _event(
      id: 3,
      type: 'Kårhusrep',
      name: 'Monday orchestra',
      date: '2026-09-15',
      signupState: 'Direkt',
    );
    final wrongDate = _event(
      id: 4,
      type: 'Rep',
      name: 'Monday orchestra',
      date: '2026-09-16',
      signupState: 'Direkt',
    );

    final controller = CalendarController(
      FakeCalendarService(
        events: [matching, wrongSearch, wrongType, wrongDate],
      ),
      now: () => DateTime(2026, 9, 15),
    );

    await controller.load();

    controller.setView(CalendarView.today);
    controller.setEventTypeFilter('Rep');
    controller.setRegistrationFilter(CalendarRegistrationFilter.coming);
    controller.setSearchQuery('Monday');

    expect(controller.visibleEvents, [matching]);
  });

  test('search does not include internal description', () async {
    final event = _event(id: 1, internalDescription: 'secret-search-value');

    final controller = CalendarController(FakeCalendarService(events: [event]));

    await controller.load();
    controller.setSearchQuery('secret-search-value');

    expect(controller.visibleEvents, isEmpty);
  });
}

CalendarEvent _event({
  int id = 1,
  String type = 'Rep',
  String name = 'Rep',
  String place = 'Kårhuset',
  String description = '',
  String internalDescription = '',
  String? signupState,
  String date = '2026-09-15',
  String halanTime = '18:00',
  String thereTime = '18:30',
  String startsTime = '19:00',
}) {
  return CalendarEvent(
    id: id,
    type: type,
    name: name,
    place: place,
    description: description,
    internalDescription: internalDescription,
    date: date,
    halanTime: halanTime,
    thereTime: thereTime,
    startsTime: startsTime,
    playDuration: '',
    stand: '',
    signupState: signupState,
    coming: 0,
    notComing: 0,
    disabled: false,
  );
}

class FakeCalendarService implements CalendarService {
  FakeCalendarService({required this.events});

  List<CalendarEvent> events;
  Object? error;

  @override
  Future<List<CalendarEvent>> getCalendar() async {
    if (error != null) {
      throw error!;
    }

    return events;
  }
}

class DeferredCalendarService implements CalendarService {
  final Completer<List<CalendarEvent>> _completer =
      Completer<List<CalendarEvent>>();

  void complete(List<CalendarEvent> events) {
    _completer.complete(events);
  }

  @override
  Future<List<CalendarEvent>> getCalendar() {
    return _completer.future;
  }
}
