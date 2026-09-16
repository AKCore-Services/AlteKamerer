import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/auth_gate.dart';
import 'features/calendar/calendar_controller.dart';
import 'features/event_details/event_details_api.dart';
import 'features/event_registration/event_registration_api.dart';
import 'features/notifications/notification_navigation_controller.dart';
import 'features/notifications/notification_sync_service.dart';

class AlteKamererApp extends StatelessWidget {
  const AlteKamererApp({
    super.key,
    required this.authController,
    required this.calendarController,
    required this.eventDetailsService,
    required this.eventRegistrationService,
    required this.notificationNavigationController,
    required this.notificationSync,
  });

  final AuthController authController;
  final CalendarController calendarController;
  final EventDetailsService eventDetailsService;
  final EventRegistrationService eventRegistrationService;
  final NotificationNavigationController notificationNavigationController;
  final NotificationSync notificationSync;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AlteKamerer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: AuthGate(
        authController: authController,
        calendarController: calendarController,
        eventDetailsService: eventDetailsService,
        eventRegistrationService: eventRegistrationService,
        notificationNavigationController: notificationNavigationController,
        notificationSync: notificationSync,
      ),
    );
  }
}
