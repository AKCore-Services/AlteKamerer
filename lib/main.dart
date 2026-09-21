import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/network/access_token_store.dart';
import 'core/network/api_client.dart';
import 'core/storage/secure_credential_store.dart';
import 'features/auth/auth_api.dart';
import 'features/auth/auth_controller.dart';
import 'features/calendar/calendar_api.dart';
import 'features/calendar/calendar_controller.dart';
import 'features/event_details/event_details_api.dart';
import 'features/event_registration/event_registration_api.dart';
import 'features/me/me_api.dart';
import 'features/notifications/local_notification_service.dart';
import 'features/notifications/notification_navigation_controller.dart';
import 'features/notifications/notification_planner.dart';
import 'features/notifications/notification_sync_service.dart';
import 'features/settings/reminder_preferences.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  final stockholm = tz.getLocation('Europe/Stockholm');

  final config = AppConfig.fromEnvironment();
  final accessTokenStore = AccessTokenStore();
  final credentialStore = SecureCredentialStore();
  final sharedPreferences = await SharedPreferences.getInstance();
  final reminderPreferences = SharedPreferencesReminderPreferences(
    sharedPreferences,
  );
  final apiClient = ApiClient(config, accessTokenStore);
  final authApi = AuthApi(apiClient);
  final calendarApi = CalendarApi(apiClient);
  final calendarController = CalendarController(calendarApi);
  final meApi = MeApi(apiClient);
  final eventDetailsApi = EventDetailsApi(apiClient);
  final eventRegistrationApi = EventRegistrationApi(apiClient);
  final notificationNavigationController = NotificationNavigationController();

  final localNotificationService = LocalNotificationService(
    FlutterLocalNotificationsPlugin(),
    notificationNavigationController,
  );

  final notificationSync = NotificationSyncService(
    meApi,
    calendarController,
    NotificationPlanner(stockholm),
    localNotificationService,
    reminderPreferences,
  );

  await localNotificationService.initialize();

  final authController = AuthController(
    credentialStore,
    authApi,
    accessTokenStore,
  );

  await authController.restoreSession();

  apiClient.setRefreshSessionHandler(authController.refreshSession);

  runApp(
    AlteKamererApp(
      authController: authController,
      calendarController: calendarController,
      eventDetailsService: eventDetailsApi,
      eventRegistrationService: eventRegistrationApi,
      notificationNavigationController: notificationNavigationController,
      notificationSync: notificationSync,
      reminderPreferences: reminderPreferences,
    ),
  );
}
