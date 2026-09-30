import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/diagnostics/diagnostics_service.dart';
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
import 'features/settings/calendar_display_controller.dart';
import 'features/settings/calendar_display_preferences.dart';
import 'features/settings/locale_controller.dart';
import 'features/settings/locale_preferences.dart';
import 'features/settings/reminder_preferences.dart';
import 'features/settings/settings_backup_file_service.dart';
import 'features/settings/settings_backup_service.dart';

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
  final diagnosticsService = DiagnosticsService(sharedPreferences);

  final previousFlutterErrorHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    unawaited(
      diagnosticsService.recordError(
        subsystem: 'Application',
        message: 'Unexpected Flutter error',
      ),
    );

    if (previousFlutterErrorHandler != null) {
      previousFlutterErrorHandler(details);
    } else {
      FlutterError.presentError(details);
    }
  };

  final previousPlatformErrorHandler = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    unawaited(
      diagnosticsService.recordError(
        subsystem: 'Application',
        message: 'Unexpected platform error',
      ),
    );

    return previousPlatformErrorHandler?.call(error, stackTrace) ?? false;
  };

  final localePreferences = SharedPreferencesLocalePreferences(
    sharedPreferences,
  );
  final localeController = LocaleController(localePreferences);
  await localeController.load();

  final calendarDisplayPreferences =
      SharedPreferencesCalendarDisplayPreferences(sharedPreferences);
  final calendarDisplayController = CalendarDisplayController(
    calendarDisplayPreferences,
  );
  await calendarDisplayController.load();

  final reminderPreferences = SharedPreferencesReminderPreferences(
    sharedPreferences,
  );
  final settingsBackupService = SettingsBackupService(
    localePreferences: localePreferences,
    reminderPreferences: reminderPreferences,
    calendarDisplayPreferences: calendarDisplayPreferences,
    localeController: localeController,
    calendarDisplayController: calendarDisplayController,
  );
  const settingsBackupFileService = FilePickerSettingsBackupFileService();

  final apiClient = ApiClient(config, accessTokenStore);
  final authApi = AuthApi(apiClient);
  final calendarApi = CalendarApi(apiClient);
  final calendarController = CalendarController(
    calendarApi,
    diagnostics: diagnosticsService,
  );
  final meApi = MeApi(apiClient);
  final eventDetailsApi = EventDetailsApi(apiClient);
  final eventRegistrationApi = EventRegistrationApi(apiClient);
  final notificationNavigationController = NotificationNavigationController();

  final localNotificationService = LocalNotificationService(
    FlutterLocalNotificationsPlugin(),
    notificationNavigationController,
    localeController,
  );

  final notificationSync = NotificationSyncService(
    meApi,
    calendarController,
    NotificationPlanner(stockholm),
    localNotificationService,
    reminderPreferences,
    diagnostics: diagnosticsService,
  );

  await localNotificationService.initialize();

  final authController = AuthController(
    credentialStore,
    authApi,
    accessTokenStore,
    diagnostics: diagnosticsService,
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
      localeController: localeController,
      calendarDisplayController: calendarDisplayController,
      settingsBackupService: settingsBackupService,
      settingsBackupFileService: settingsBackupFileService,
      diagnosticsService: diagnosticsService,
      apiServer: config.apiBaseUrl.origin,
    ),
  );
}
