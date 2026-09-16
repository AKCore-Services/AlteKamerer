import 'package:altekamerer/features/calendar/calendar_event.dart';
import 'package:altekamerer/features/me/me.dart';
import 'package:altekamerer/features/notifications/notification_planner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  late tz.Location stockholm;

  setUpAll(() {
    tzdata.initializeTimeZones();
    stockholm = tz.getLocation('Europe/Stockholm');
  });

  const orchestraMember = Me(
    displayName: 'Orkestermedlem',
    isMember: true,
    isBallet: false,
    availableInstruments: [],
  );

  const balletMember = Me(
    displayName: 'Balettmedlem',
    isMember: true,
    isBallet: true,
    availableInstruments: [],
  );

  CalendarEvent event({
    int id = 42,
    String type = 'Rep',
    String signupState = '',
    String date = '2026-09-20',
    String halanTime = '18:00',
    String thereTime = '18:30',
    String startsTime = '19:00',
  }) {
    return CalendarEvent(
      id: id,
      type: type,
      name: 'Testevent',
      place: 'Kårhuset',
      description: '',
      internalDescription: '',
      date: date,
      halanTime: halanTime,
      thereTime: thereTime,
      startsTime: startsTime,
      playDuration: '',
      stand: '',
      signupState: signupState.isEmpty ? null : signupState,
      coming: 0,
      notComing: 0,
      disabled: false,
    );
  }

  group('relevance', () {
    test('orchestra member gets Rep but not Balettrep', () {
      final planner = NotificationPlanner(
        stockholm,
        reminderOffsets: [Duration(hours: 1)],
      );

      final plans = planner.buildPlans(
        me: orchestraMember,
        events: [
          event(id: 1, type: 'Rep'),
          event(id: 2, type: 'Balettrep'),
        ],
        now: DateTime.utc(2026, 9, 20, 8),
      );

      expect(plans.map((plan) => plan.eventId), [1]);
    });

    test('ballet member gets Balettrep but not Rep', () {
      final planner = NotificationPlanner(
        stockholm,
        reminderOffsets: [Duration(hours: 1)],
      );

      final plans = planner.buildPlans(
        me: balletMember,
        events: [
          event(id: 1, type: 'Rep'),
          event(id: 2, type: 'Balettrep'),
        ],
        now: DateTime.utc(2026, 9, 20, 8),
      );

      expect(plans.map((plan) => plan.eventId), [2]);
    });

    test('shared rehearsal types are relevant to members', () {
      final planner = NotificationPlanner(
        stockholm,
        reminderOffsets: [Duration(hours: 1)],
      );

      final events = [
        event(id: 1, type: 'Kårhusrep'),
        event(id: 2, type: 'Athenrep'),
        event(id: 3, type: 'Samlingsrep'),
        event(id: 4, type: 'Fikarep'),
      ];

      final plans = planner.buildPlans(
        me: orchestraMember,
        events: events,
        now: DateTime.utc(2026, 9, 20, 8),
      );

      expect(plans.map((plan) => plan.eventId), [1, 2, 3, 4]);
    });

    test('attending signup makes other event type relevant', () {
      final planner = NotificationPlanner(
        stockholm,
        reminderOffsets: [Duration(hours: 1)],
      );

      final plans = planner.buildPlans(
        me: orchestraMember,
        events: [event(type: 'Spelning', signupState: 'Direkt')],
        now: DateTime.utc(2026, 9, 20, 8),
      );

      expect(plans, hasLength(1));
    });

    test('Kan inte komma always suppresses notification', () {
      final planner = NotificationPlanner(
        stockholm,
        reminderOffsets: [Duration(hours: 1)],
      );

      final plans = planner.buildPlans(
        me: orchestraMember,
        events: [event(type: 'Rep', signupState: 'Kan inte komma')],
        now: DateTime.utc(2026, 9, 20, 8),
      );

      expect(plans, isEmpty);
    });

    test('non-member receives no notifications', () {
      final planner = NotificationPlanner(
        stockholm,
        reminderOffsets: [Duration(hours: 1)],
      );

      const nonMember = Me(
        displayName: 'Inte medlem',
        isMember: false,
        isBallet: false,
        availableInstruments: [],
      );

      final plans = planner.buildPlans(
        me: nonMember,
        events: [event(type: 'Rep', signupState: 'Direkt')],
        now: DateTime.utc(2026, 9, 20, 8),
      );

      expect(plans, isEmpty);
    });
  });

  group('timing', () {
    test('defaults schedule reminders 8 hours and 1 hour before event', () {
      final planner = NotificationPlanner(stockholm);

      final plans = planner.buildPlans(
        me: orchestraMember,
        events: [event(type: 'Rep')],
        now: DateTime.utc(2026, 9, 20, 6),
      );

      expect(plans, hasLength(2));

      expect(plans[0].scheduledTime, DateTime.utc(2026, 9, 20, 8, 30));

      expect(plans[1].scheduledTime, DateTime.utc(2026, 9, 20, 15, 30));
    });

    test('Hålan signup uses Hålan time', () {
      final planner = NotificationPlanner(
        stockholm,
        reminderOffsets: [Duration(hours: 1)],
      );

      final plans = planner.buildPlans(
        me: orchestraMember,
        events: [event(signupState: 'Hålan')],
        now: DateTime.utc(2026, 9, 20, 8),
      );

      expect(plans.single.eventTime, DateTime.utc(2026, 9, 20, 16));
      expect(plans.single.scheduledTime, DateTime.utc(2026, 9, 20, 15));
    });

    test('Direkt signup uses normal arrival time', () {
      final planner = NotificationPlanner(
        stockholm,
        reminderOffsets: [Duration(hours: 1)],
      );

      final plans = planner.buildPlans(
        me: orchestraMember,
        events: [event(signupState: 'Direkt')],
        now: DateTime.utc(2026, 9, 20, 8),
      );

      expect(plans.single.eventTime, DateTime.utc(2026, 9, 20, 16, 30));
    });

    test('past reminder times are not scheduled', () {
      final planner = NotificationPlanner(stockholm);

      final plans = planner.buildPlans(
        me: orchestraMember,
        events: [event()],
        now: DateTime.utc(2026, 9, 20, 10),
      );

      expect(plans, hasLength(1));
      expect(plans.single.reminderOffset, const Duration(hours: 1));
    });

    test('event without usable time is skipped', () {
      final planner = NotificationPlanner(stockholm);

      final plans = planner.buildPlans(
        me: orchestraMember,
        events: [
          event(halanTime: '00:00', thereTime: '00:00', startsTime: '00:00'),
        ],
        now: DateTime.utc(2026, 9, 20, 6),
      );

      expect(plans, isEmpty);
    });

    test('8 hour reminder remains 8 real hours before event across DST', () {
      final planner = NotificationPlanner(
        stockholm,
        reminderOffsets: [const Duration(hours: 8)],
      );

      final plans = planner.buildPlans(
        me: orchestraMember,
        events: [event(date: '2026-10-25', thereTime: '10:00')],
        now: DateTime.utc(2026, 10, 24, 20),
      );

      expect(plans, hasLength(1));

      expect(
        plans.single.eventTime.difference(plans.single.scheduledTime),
        const Duration(hours: 8),
      );
    });
  });
}
