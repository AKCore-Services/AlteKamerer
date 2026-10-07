import 'dart:convert';

import 'package:altekamerer/features/event_details/event_details.dart';
import 'package:altekamerer/features/event_details/event_details_cache.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('returns null when event has not been cached', () async {
    final cache = SecureEventDetailsCache();

    expect(await cache.read(42), isNull);
  });

  test('round trips cached event details and timestamp', () async {
    final cache = SecureEventDetailsCache();
    final event = _event();
    final cachedAt = DateTime.utc(2026, 10, 5, 7, 30);

    await cache.write(event, cachedAt: cachedAt);

    final result = await cache.read(42);

    expect(result, isNotNull);
    expect(result!.cachedAt, cachedAt);

    final restored = result.event;

    expect(restored.id, event.id);
    expect(restored.name, event.name);
    expect(restored.fikaCollection, event.fikaCollection);
    expect(restored.signupState, event.signupState);
    expect(restored.registration.where, event.registration.where);
    expect(
      restored.registration.availableInstruments,
      event.registration.availableInstruments,
    );
    expect(restored.attendees, hasLength(1));
    expect(restored.attendees.single.personName, 'Test Member');
  });

  test('keeps cached events separated by event id', () async {
    final cache = SecureEventDetailsCache();

    await cache.write(
      _event(id: 42, name: 'First'),
      cachedAt: DateTime.utc(2026, 10, 5, 7),
    );
    await cache.write(
      _event(id: 43, name: 'Second'),
      cachedAt: DateTime.utc(2026, 10, 5, 8),
    );

    expect((await cache.read(42))!.event.name, 'First');
    expect((await cache.read(43))!.event.name, 'Second');
  });

  test('clear removes all cached event details', () async {
    final cache = SecureEventDetailsCache();

    await cache.write(_event(), cachedAt: DateTime.utc(2026, 10, 5, 7));

    await cache.clear();

    expect(await cache.read(42), isNull);
  });

  test('fresh session does not resurrect invalidated event details', () async {
    const storage = FlutterSecureStorage();
    final cache = SecureEventDetailsCache(storage: storage);
    final oldEvent = _event(id: 42, name: 'Old session');

    await cache.write(oldEvent, cachedAt: DateTime.utc(2026, 10, 4, 18));
    await cache.clear();

    // Simulate the previous payload surviving deletion while the persistent
    // authentication-boundary invalidation marker remains.
    await storage.write(
      key: 'event_details_cache_v1',
      value: jsonEncode({
        '42': {
          'cachedAt': DateTime.utc(2026, 10, 4, 18).toIso8601String(),
          'event': oldEvent.toJson(),
        },
      }),
    );

    expect(await cache.read(42), isNull);

    await cache.write(
      _event(id: 43, name: 'Fresh session'),
      cachedAt: DateTime.utc(2026, 10, 5, 8),
    );

    expect(await cache.read(42), isNull);

    final fresh = await cache.read(43);

    expect(fresh, isNotNull);
    expect(fresh!.event.name, 'Fresh session');
  });
}

EventDetails _event({int id = 42, String name = 'Tisdagsrep'}) {
  return EventDetails(
    id: id,
    type: 'Kårhusrep',
    name: name,
    place: 'Kårhuset',
    description: 'Ordinarie repetition',
    internalDescription: 'Intern information',
    fikaCollection: 'Flöjt,Sax',
    date: '2026-09-15',
    halanTime: '18:00',
    thereTime: '18:30',
    startsTime: '19:00',
    playDuration: '120 min',
    stand: '',
    signupState: 'Hålan',
    coming: 12,
    notComing: 3,
    disabled: false,
    registrationAvailable: true,
    registration: const EventRegistrationSelection(
      where: 'Hålan',
      car: false,
      instrument: true,
      comment: 'Kommentar',
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
