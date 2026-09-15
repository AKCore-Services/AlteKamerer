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

  test('Hålan registration uses Hålan gathering time', () {
    final event = _event(signupState: 'Hålan');

    expect(event.displayTime, '18:00');
  });

  test('Direkt registration uses on-site time', () {
    final event = _event(signupState: 'Direkt');

    expect(event.displayTime, '18:30');
  });

  test('not registered uses on-site time', () {
    final event = _event();

    expect(event.displayTime, '18:30');
  });

  test('Kan inte komma uses on-site time but remains registered', () {
    final event = _event(signupState: 'Kan inte komma');

    expect(event.displayTime, '18:30');
    expect(event.isRegistered, isTrue);
    expect(event.isAttending, isFalse);
    expect(event.isRegisteredNotAttending, isTrue);
  });

  test('uses halan time when there time is unavailable', () {
    final event = _event(signupState: null, halanTime: '19:00', thereTime: '');

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
}

CalendarEvent _event({
  String? signupState,
  String halanTime = '18:00',
  String thereTime = '18:30',
  String startsTime = '19:00',
}) {
  return CalendarEvent(
    id: 1,
    type: 'Rep',
    name: 'Rep',
    place: 'Kårhuset',
    description: '',
    internalDescription: '',
    date: '2026-09-15',
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
