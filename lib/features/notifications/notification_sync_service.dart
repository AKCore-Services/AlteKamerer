import '../calendar/calendar_controller.dart';
import '../me/me_api.dart';
import 'local_notification_service.dart';
import 'notification_planner.dart';

abstract interface class NotificationSync {
  Future<void> sync();

  Future<void> clear();
}

class NotificationSyncService implements NotificationSync {
  NotificationSyncService(
    this._meService,
    this._calendarController,
    this._planner,
    this._notificationScheduler, {
    DateTime Function()? now,
  }) : _now = now ?? (() => DateTime.now().toUtc());

  final MeService _meService;
  final CalendarController _calendarController;
  final NotificationPlanner _planner;
  final LocalNotificationScheduler _notificationScheduler;
  final DateTime Function() _now;

  @override
  Future<void> sync() async {
    await _calendarController.load();

    if (_calendarController.status != CalendarStatus.loaded) {
      return;
    }

    try {
      final me = await _meService.getMe();

      final plans = _planner.buildPlans(
        me: me,
        events: _calendarController.events,
        now: _now(),
      );

      await _notificationScheduler.reconcile(plans);
    } catch (_) {
      // Notification synchronisation must not make the calendar unusable.
    }
  }

  @override
  Future<void> clear() {
    return _notificationScheduler.clear();
  }
}
