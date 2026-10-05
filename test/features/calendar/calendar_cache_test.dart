import 'dart:convert';

import 'package:altekamerer/features/calendar/calendar_cache.dart';
import 'package:altekamerer/features/calendar/calendar_event.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('returns null when no calendar has been cached', () async {
    final cache = SecureCalendarCache();

    expect(await cache.read(), isNull);
  });

  test('round trips cached calendar events and timestamp', () async {
    final cache = SecureCalendarCache();
    final cachedAt = DateTime.utc(2026, 10, 5, 6, 30);
    final event = _event();

    await cache.write([event], cachedAt: cachedAt);

    final result = await cache.read();

    expect(result, isNotNull);
    expect(result!.cachedAt, cachedAt);
    expect(result.events, hasLength(1));

    final restored = result.events.single;

    expect(restored.id, event.id);
    expect(restored.type, event.type);
    expect(restored.name, event.name);
    expect(restored.place, event.place);
    expect(restored.description, event.description);
    expect(restored.internalDescription, event.internalDescription);
    expect(restored.date, event.date);
    expect(restored.halanTime, event.halanTime);
    expect(restored.thereTime, event.thereTime);
    expect(restored.startsTime, event.startsTime);
    expect(restored.playDuration, event.playDuration);
    expect(restored.stand, event.stand);
    expect(restored.signupState, event.signupState);
    expect(restored.coming, event.coming);
    expect(restored.notComing, event.notComing);
    expect(restored.disabled, event.disabled);
  });

  test('ignores malformed cached content', () async {
    FlutterSecureStorage.setMockInitialValues({
      'calendar_cache_v1': '{"cachedAt":"broken","events":[]}',
    });

    final cache = SecureCalendarCache();

    expect(await cache.read(), isNull);
  });

  test('clear removes cached calendar', () async {
    final cache = SecureCalendarCache();

    await cache.write([_event()], cachedAt: DateTime.utc(2026, 10, 5));

    expect(await cache.read(), isNotNull);

    await cache.clear();

    expect(await cache.read(), isNull);
  });

  test(
    'invalidated payload stays hidden until fresh calendar replaces it',
    () async {
      const storage = FlutterSecureStorage();
      final cache = SecureCalendarCache(storage: storage);
      final oldEvent = _event();

      await cache.write([oldEvent], cachedAt: DateTime.utc(2026, 10, 4));
      await cache.clear();

      // Simulate a stale secure payload surviving deletion while the persistent
      // authentication-boundary invalidation marker remains.
      await storage.write(
        key: 'calendar_cache_v1',
        value: jsonEncode({
          'cachedAt': DateTime.utc(2026, 10, 4).toIso8601String(),
          'events': [oldEvent.toJson()],
        }),
      );

      expect(await cache.read(), isNull);

      final freshEvent = CalendarEvent(
        id: 43,
        type: oldEvent.type,
        name: 'Fresh event',
        place: oldEvent.place,
        description: oldEvent.description,
        internalDescription: oldEvent.internalDescription,
        date: oldEvent.date,
        halanTime: oldEvent.halanTime,
        thereTime: oldEvent.thereTime,
        startsTime: oldEvent.startsTime,
        playDuration: oldEvent.playDuration,
        stand: oldEvent.stand,
        signupState: oldEvent.signupState,
        coming: oldEvent.coming,
        notComing: oldEvent.notComing,
        disabled: oldEvent.disabled,
      );

      await cache.write([freshEvent], cachedAt: DateTime.utc(2026, 10, 5));

      final restored = await cache.read();

      expect(restored, isNotNull);
      expect(restored!.events.single.id, 43);
      expect(restored.events.single.name, 'Fresh event');
    },
  );
}

CalendarEvent _event() {
  return const CalendarEvent(
    id: 42,
    type: 'Spelning',
    name: 'Cached event',
    place: 'AF-borgen',
    description: 'Description',
    internalDescription: 'Internal description',
    date: '2026-10-05',
    halanTime: '18:00',
    thereTime: '18:30',
    startsTime: '19:00',
    playDuration: '01:00',
    stand: 'Konsert',
    signupState: 'Direkt',
    coming: 12,
    notComing: 3,
    disabled: false,
  );
}
