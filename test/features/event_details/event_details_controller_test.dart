import 'dart:async';

import 'package:altekamerer/core/diagnostics/diagnostics_service.dart';
import 'package:altekamerer/features/event_details/event_details.dart';
import 'package:altekamerer/features/event_details/event_details_api.dart';
import 'package:altekamerer/features/event_details/event_details_cache.dart';
import 'package:altekamerer/features/event_details/event_details_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('refresh preserves displayed event while request is pending', () async {
    final initial = _event();
    final updated = _event(signupState: 'Direkt');
    final service = _DeferredEventDetailsService();
    final controller = EventDetailsController(service);

    final initialLoad = controller.load(42);
    service.complete(initial);
    await initialLoad;

    service.reset();

    final refresh = controller.refresh(42);

    expect(controller.status, EventDetailsStatus.loaded);
    expect(controller.event, same(initial));

    service.complete(updated);
    await refresh;

    expect(controller.status, EventDetailsStatus.loaded);
    expect(controller.event, same(updated));
    expect(controller.event!.signupState, 'Direkt');
    expect(controller.isShowingCachedData, isFalse);
  });

  test('failed refresh preserves displayed event', () async {
    final initial = _event();
    final service = _MutableEventDetailsService(event: initial);
    final controller = EventDetailsController(service);

    await controller.load(42);

    service.error = StateError('refresh failed');
    await controller.refresh(42);

    expect(controller.status, EventDetailsStatus.loaded);
    expect(controller.event, same(initial));
    expect(controller.error, isNull);
  });

  test('successful refresh updates event-details cache', () async {
    final initial = _event();
    final updated = _event(signupState: 'Direkt');
    final cache = _FakeEventDetailsCache();
    final service = _MutableEventDetailsService(event: initial);
    final controller = EventDetailsController(service, cache: cache);

    await controller.load(42);

    service.event = updated;
    await controller.refresh(42);

    expect(cache.value, isNotNull);
    expect(cache.value!.event, same(updated));
    expect(controller.event!.signupState, 'Direkt');
  });

  test('load exposes loaded event', () async {
    final event = _event();
    final controller = EventDetailsController(
      _FakeEventDetailsService(event: event),
    );

    await controller.load(42);

    expect(controller.status, EventDetailsStatus.loaded);
    expect(controller.event, same(event));
    expect(controller.error, isNull);
  });

  test('successful load updates event-details cache', () async {
    final event = _event();
    final cache = _FakeEventDetailsCache();
    final now = DateTime(2026, 10, 5, 8, 30);
    final controller = EventDetailsController(
      _FakeEventDetailsService(event: event),
      cache: cache,
      now: () => now,
    );

    await controller.load(42);

    expect(cache.value, isNotNull);
    expect(cache.value!.event, same(event));
    expect(cache.value!.cachedAt, now.toUtc());
    expect(controller.isShowingCachedData, isFalse);
    expect(controller.cachedAt, isNull);
  });

  test('failed load falls back to cached event details', () async {
    final event = _event();
    final cachedAt = DateTime.utc(2026, 10, 4, 18);
    final cache = _FakeEventDetailsCache(
      value: CachedEventDetails(event: event, cachedAt: cachedAt),
    );
    final controller = EventDetailsController(
      _FakeEventDetailsService(error: Exception('failed')),
      cache: cache,
    );

    await controller.load(42);

    expect(controller.status, EventDetailsStatus.loaded);
    expect(controller.event, same(event));
    expect(controller.error, isNull);
    expect(controller.isShowingCachedData, isTrue);
    expect(controller.cachedAt, cachedAt);
  });

  test('load exposes error state when service fails', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final diagnostics = DiagnosticsService(preferences);
    final controller = EventDetailsController(
      _FakeEventDetailsService(error: Exception('failed')),
      diagnostics: diagnostics,
    );

    await controller.load(42);

    expect(controller.status, EventDetailsStatus.error);
    expect(controller.event, isNull);
    expect(controller.error, isNotNull);

    final entries = await diagnostics.readEntries();
    expect(entries, hasLength(1));
    expect(entries.single.subsystem, 'Event details');
    expect(entries.single.message, 'Event details loading failed');
    expect(entries.single.details, contains('Exception'));
  });

  test('Rep uses Hålan time as effective on-site time', () {
    final event = _event(type: 'Rep', halanTime: '18:00', thereTime: '00:00');

    expect(event.effectiveThereTime, '18:00');
  });

  test('normal event keeps explicit on-site time', () {
    final event = _event(
      type: 'Spelning',
      halanTime: '18:00',
      thereTime: '18:30',
    );

    expect(event.effectiveThereTime, '18:30');
  });
}

EventDetails _event({
  String type = 'Rep',
  String halanTime = '18:00',
  String thereTime = '18:30',
  String? signupState = 'Hålan',
}) {
  return EventDetails(
    id: 42,
    type: type,
    name: 'Tisdagsrep',
    place: 'Kårhuset',
    description: 'Ordinarie repetition',
    internalDescription: '',
    date: '2026-09-15',
    halanTime: halanTime,
    thereTime: thereTime,
    startsTime: '19:00',
    playDuration: '120',
    stand: '',
    signupState: signupState,
    coming: 12,
    notComing: 3,
    disabled: false,
    registrationAvailable: true,
    registration: const EventRegistrationSelection(
      where: 'Hålan',
      car: false,
      instrument: true,
      comment: '',
      selectedInstrument: 'Flöjt',
      availableInstruments: ['Flöjt'],
    ),
    attendees: const [
      EventAttendee(
        personName: 'Test Member',
        where: 'Hålan',
        car: false,
        instrument: true,
        instrumentName: 'Flöjt',
        comment: '',
      ),
    ],
  );
}

class _FakeEventDetailsCache implements EventDetailsCache {
  _FakeEventDetailsCache({this.value});

  CachedEventDetails? value;

  @override
  Future<CachedEventDetails?> read(int eventId) async {
    final value = this.value;

    if (value == null || value.event.id != eventId) {
      return null;
    }

    return value;
  }

  @override
  Future<void> write(EventDetails event, {required DateTime cachedAt}) async {
    value = CachedEventDetails(event: event, cachedAt: cachedAt);
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}

class _MutableEventDetailsService implements EventDetailsService {
  _MutableEventDetailsService({required this.event});

  EventDetails event;
  Object? error;

  @override
  Future<EventDetails> getEvent(int eventId) async {
    if (error != null) {
      throw error!;
    }

    return event;
  }
}

class _DeferredEventDetailsService implements EventDetailsService {
  Completer<EventDetails> _completer = Completer<EventDetails>();

  void complete(EventDetails event) {
    _completer.complete(event);
  }

  void reset() {
    _completer = Completer<EventDetails>();
  }

  @override
  Future<EventDetails> getEvent(int eventId) {
    return _completer.future;
  }
}

class _FakeEventDetailsService implements EventDetailsService {
  _FakeEventDetailsService({this.event, this.error});

  final EventDetails? event;
  final Object? error;

  @override
  Future<EventDetails> getEvent(int eventId) async {
    if (error != null) {
      throw error!;
    }

    return event!;
  }
}
