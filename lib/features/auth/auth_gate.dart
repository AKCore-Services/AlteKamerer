import 'package:flutter/material.dart';

import '../calendar/calendar_controller.dart';
import '../event_details/event_details_api.dart';
import '../event_registration/event_registration_api.dart';
import '../notifications/notification_navigation_controller.dart';
import '../shell/app_shell.dart';
import '../../core/theme/ak_status_view.dart';
import 'auth_controller.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.authController,
    required this.calendarController,
    required this.eventDetailsService,
    required this.eventRegistrationService,
    required this.notificationNavigationController,
  });

  final AuthController authController;
  final CalendarController calendarController;
  final EventDetailsService eventDetailsService;
  final EventRegistrationService eventRegistrationService;
  final NotificationNavigationController notificationNavigationController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: authController,
      builder: (context, child) {
        return switch (authController.status) {
          AuthStatus.loading => const Scaffold(
            body: SafeArea(child: AkLoadingView()),
          ),
          AuthStatus.unauthenticated => LoginScreen(
            authController: authController,
          ),
          AuthStatus.authenticated => AppShell(
            authController: authController,
            calendarController: calendarController,
            eventDetailsService: eventDetailsService,
            eventRegistrationService: eventRegistrationService,
            notificationNavigationController: notificationNavigationController,
          ),
          AuthStatus.restoreFailed => Scaffold(
            body: SafeArea(
              child: AkErrorView(
                title: 'Kunde inte ansluta',
                message: 'AlteKamerer kunde inte kontrollera din inloggning mot AKCore.',
                onRetry: () {
                  authController.restoreSession();
                },
              ),
            ),
          ),
        };
      },
    );
  }
}
