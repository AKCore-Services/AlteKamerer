import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_event_payload.dart';
import 'notification_navigation_controller.dart';

class LocalNotificationService {
  LocalNotificationService(this._plugin, this._navigationController);

  final FlutterLocalNotificationsPlugin _plugin;
  final NotificationNavigationController _navigationController;

  Future<void> initialize() async {
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

  void _handleResponse(NotificationResponse? response) {
    final eventId = NotificationEventPayload.tryParse(response?.payload);

    if (eventId != null) {
      _navigationController.openEvent(eventId);
    }
  }
}
