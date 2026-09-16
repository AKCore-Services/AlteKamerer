import 'package:altekamerer/features/calendar/calendar_api.dart';
import 'package:altekamerer/features/calendar/calendar_controller.dart';
import 'package:altekamerer/features/calendar/calendar_event.dart';
import 'package:altekamerer/features/me/me.dart';
import 'package:altekamerer/features/me/me_api.dart';
import 'package:altekamerer/features/notifications/local_notification_service.dart';
import 'package:altekamerer/features/notifications/notification_plan.dart';
import 'package:altekamerer/features/notifications/notification_planner.dart';
import 'package:altekamerer/features/notifications/notification_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  late tz.Location stockholm;

  setUpAll(() {
    tzdata.initializeTimeZones();
    stockholm = tz.getLocation('Europe/Stockholm');
  });

  test('sync refreshes calendar and reconciles notification plans', () async {
    final calendarController = CalendarController(_FakeCalendarService());
    final scheduler = _FakeNotificationScheduler();

    final service = NotificationSyncService(
      _FakeMeService(),
      calendarController,
      NotificationPlanner(stockholm),
      scheduler,
      now: () => DateTime.utc(2026, 9, 20, 6),
    );

    await service.sync();

    expect(calendarController.status, CalendarStatus.loaded);
    expect(calendarController.events, hasLength(1));

    expect(scheduler.reconciledPlans, hasLength(2));
    expect(scheduler.reconciledPlans.map((plan) => plan.reminderOffset), [
      const Duration(hours: 8),
      const Duration(hours: 1),
    ]);
  });

  test('clear delegates to local notification scheduler', () async {
    final scheduler = _FakeNotificationScheduler();

    final service = NotificationSyncService(
      _FakeMeService(),
      CalendarController(_FakeCalendarService()),
      NotificationPlanner(stockholm),
      scheduler,
    );

    await service.clear();

    expect(scheduler.clearCount, 1);
  });

  test('failed calendar load does not replace notification schedule', () async {
    final scheduler = _FakeNotificationScheduler();

    final service = NotificationSyncService(
      _FakeMeService(),
      CalendarController(_FailingCalendarService()),
      NotificationPlanner(stockholm),
      scheduler,
    );

    await service.sync();

    expect(scheduler.reconcileCount, 0);
  });
}

class _FakeCalendarService implements CalendarService {
  @override
  Future<List<CalendarEvent>> getCalendar() async {
    return const [
      CalendarEvent(
        id: 42,
        type: 'Kårhusrep',
        name: 'Tisdagsrep',
        place: 'Kårhuset',
        description: '',
        internalDescription: '',
        date: '2026-09-20',
        halanTime: '18:00',
        thereTime: '18:30',
        startsTime: '19:00',
        playDuration: '',
        stand: '',
        signupState: null,
        coming: 0,
        notComing: 0,
        disabled: false,
      ),
    ];
  }
}

class _FailingCalendarService implements CalendarService {
  @override
  Future<List<CalendarEvent>> getCalendar() {
    throw Exception('calendar failed');
  }
}

class _FakeMeService implements MeService {
  @override
  Future<Me> getMe() async {
    return const Me(
      displayName: 'Test',
      isMember: true,
      isBallet: false,
      availableInstruments: [],
    );
  }
}

class _FakeNotificationScheduler implements LocalNotificationScheduler {
  List<NotificationPlan> reconciledPlans = const [];
  int reconcileCount = 0;
  int clearCount = 0;

  @override
  Future<void> reconcile(List<NotificationPlan> plans) async {
    reconcileCount++;
    reconciledPlans = plans;
  }

  @override
  Future<void> clear() async {
    clearCount++;
  }
}
