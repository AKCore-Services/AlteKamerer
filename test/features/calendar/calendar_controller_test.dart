import 'dart:async';

import 'package:altekamerer/features/calendar/calendar_api.dart';
import 'package:altekamerer/features/calendar/calendar_controller.dart';
import 'package:altekamerer/features/calendar/calendar_event.dart';
import 'package:flutter_test/flutter_test.dart';

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
    final service = FakeCalendarService(events: [_event()]);
    final controller = CalendarController(service);

    await controller.load();

    expect(controller.events, isNotEmpty);

    service.error = StateError('calendar failed');

    await controller.load();

    expect(controller.status, CalendarStatus.error);
    expect(controller.events, isEmpty);
    expect(controller.error, isA<StateError>());
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

  test('rehearsal filter uses AKCore rehearsal event types', () async {
    final rehearsals = [
      _event(id: 1, type: 'Rep'),
      _event(id: 2, type: 'Kårhusrep'),
      _event(id: 3, type: 'Balettrep'),
      _event(id: 4, type: 'Athenrep'),
      _event(id: 5, type: 'Samlingsrep'),
      _event(id: 6, type: 'Fikarep'),
    ];
    final performance = _event(id: 7, type: 'Spelning');

    final controller = CalendarController(
      FakeCalendarService(events: [...rehearsals, performance]),
    );

    await controller.load();
    controller.setFilter(CalendarFilter.rehearsals);

    expect(controller.visibleEvents, rehearsals);
  });

  test('performance filter exposes only Spelning', () async {
    final performance = _event(id: 1, type: 'Spelning');
    final other = _event(id: 2, type: 'Evenemang');

    final controller = CalendarController(
      FakeCalendarService(events: [performance, other]),
    );

    await controller.load();
    controller.setFilter(CalendarFilter.performances);

    expect(controller.visibleEvents, [performance]);
  });

  test('social filter exposes Fest but not generic Evenemang', () async {
    final fest = _event(id: 1, type: 'Fest');
    final evenemang = _event(id: 2, type: 'Evenemang');

    final controller = CalendarController(
      FakeCalendarService(events: [fest, evenemang]),
    );

    await controller.load();
    controller.setFilter(CalendarFilter.social);

    expect(controller.visibleEvents, [fest]);
  });

  test(
    'registered filter includes attending and not-attending registrations',
    () async {
      final halan = _event(id: 1, signupState: 'Hålan');
      final direct = _event(id: 2, signupState: 'Direkt');
      final cannotCome = _event(id: 3, signupState: 'Kan inte komma');
      final unregistered = _event(id: 4);

      final controller = CalendarController(
        FakeCalendarService(events: [halan, direct, cannotCome, unregistered]),
      );

      await controller.load();
      controller.setFilter(CalendarFilter.registered);

      expect(controller.visibleEvents, [halan, direct, cannotCome]);
    },
  );

  test('relevant filter mirrors AKCore orchestra-member relevance', () async {
    final rep = _event(id: 1, type: 'Rep');
    final balletRep = _event(id: 2, type: 'Balettrep');
    final sharedRep = _event(id: 3, type: 'Kårhusrep');
    final registered = _event(id: 4, type: 'Spelning', signupState: 'Direkt');
    final declined = _event(id: 5, type: 'Rep', signupState: 'Kan inte komma');

    final controller = CalendarController(
      FakeCalendarService(
        events: [rep, balletRep, sharedRep, registered, declined],
      ),
    );

    await controller.load();
    controller.setMemberContext(isBallet: false);
    controller.setFilter(CalendarFilter.relevant);

    expect(controller.visibleEvents, [rep, sharedRep, registered]);
  });

  test('relevant filter mirrors AKCore ballet-member relevance', () async {
    final rep = _event(id: 1, type: 'Rep');
    final balletRep = _event(id: 2, type: 'Balettrep');
    final sharedRep = _event(id: 3, type: 'Fikarep');

    final controller = CalendarController(
      FakeCalendarService(events: [rep, balletRep, sharedRep]),
    );

    await controller.load();
    controller.setMemberContext(isBallet: true);
    controller.setFilter(CalendarFilter.relevant);

    expect(controller.visibleEvents, [balletRep, sharedRep]);
  });

  test(
    'event type filter composes with date view and semantic filter',
    () async {
      final todayRep = _event(id: 1, type: 'Rep', date: '2026-09-15');
      final todayKarRep = _event(id: 2, type: 'Kårhusrep', date: '2026-09-15');
      final tomorrowRep = _event(id: 3, type: 'Rep', date: '2026-09-16');

      final controller = CalendarController(
        FakeCalendarService(events: [todayRep, todayKarRep, tomorrowRep]),
        now: () => DateTime(2026, 9, 15),
      );

      await controller.load();
      controller.setView(CalendarView.today);
      controller.setFilter(CalendarFilter.rehearsals);
      controller.setEventTypeFilter('Rep');

      expect(controller.visibleEvents, [todayRep]);
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

  test('search composes with date, semantic, and event type filters', () async {
    final matching = _event(
      id: 1,
      type: 'Rep',
      name: 'Monday orchestra',
      date: '2026-09-15',
    );
    final wrongSearch = _event(
      id: 2,
      type: 'Rep',
      name: 'Tuesday orchestra',
      date: '2026-09-15',
    );
    final wrongType = _event(
      id: 3,
      type: 'Kårhusrep',
      name: 'Monday orchestra',
      date: '2026-09-15',
    );
    final wrongDate = _event(
      id: 4,
      type: 'Rep',
      name: 'Monday orchestra',
      date: '2026-09-16',
    );

    final controller = CalendarController(
      FakeCalendarService(
        events: [matching, wrongSearch, wrongType, wrongDate],
      ),
      now: () => DateTime(2026, 9, 15),
    );

    await controller.load();

    controller.setView(CalendarView.today);
    controller.setFilter(CalendarFilter.rehearsals);
    controller.setEventTypeFilter('Rep');
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
