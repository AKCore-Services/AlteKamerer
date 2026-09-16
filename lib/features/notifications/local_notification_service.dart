import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'notification_event_payload.dart';
import 'notification_navigation_controller.dart';
import 'notification_plan.dart';

abstract interface class LocalNotificationScheduler {
  Future<void> reconcile(List<NotificationPlan> plans);

  Future<void> clear();
}

class LocalNotificationService implements LocalNotificationScheduler {
  LocalNotificationService(this._plugin, this._navigationController);

  static const _channelId = 'event-reminders';
  static const _channelName = 'Aktivitetspåminnelser';
  static const _channelDescription =
      'Påminnelser inför aktiviteter i AlteKamereren';

  final FlutterLocalNotificationsPlugin _plugin;
  final NotificationNavigationController _navigationController;

  late final tz.Location _stockholm;
  bool _permissionRequested = false;

  Future<void> initialize() async {
    tzdata.initializeTimeZones();
    _stockholm = tz.getLocation('Europe/Stockholm');

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _handleResponse,
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();

    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _handleResponse(launchDetails?.notificationResponse);
    }
  }

  @override
  Future<void> reconcile(List<NotificationPlan> plans) async {
    if (plans.isNotEmpty && !_permissionRequested) {
      _permissionRequested = true;

      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await android?.requestNotificationsPermission();
    }

    await _plugin.cancelAll();

    for (final plan in plans) {
      await _schedule(plan);
    }
  }

  @override
  Future<void> clear() async {
    await _plugin.cancelAll();
  }

  Future<void> _schedule(NotificationPlan plan) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _plugin.zonedSchedule(
      id: _notificationId(plan),
      title: plan.eventName,
      body: _bodyFor(plan),
      scheduledDate: tz.TZDateTime.from(plan.scheduledTime, _stockholm),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: NotificationEventPayload.encode(plan.eventId),
    );
  }

  int _notificationId(NotificationPlan plan) {
    final minutes = plan.reminderOffset.inMinutes;

    return ((plan.eventId * 100000) + minutes) & 0x7fffffff;
  }

  String _bodyFor(NotificationPlan plan) {
    final minutes = plan.reminderOffset.inMinutes;

    if (minutes % 60 == 0) {
      final hours = minutes ~/ 60;

      if (hours == 1) {
        return 'Börjar om 1 timme';
      }

      return 'Börjar om $hours timmar';
    }

    return 'Börjar om $minutes minuter';
  }

  void _handleResponse(NotificationResponse? response) {
    final eventId = NotificationEventPayload.tryParse(response?.payload);

    if (eventId != null) {
      _navigationController.openEvent(eventId);
    }
  }
}
