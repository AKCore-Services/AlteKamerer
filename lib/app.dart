import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/auth_gate.dart';
import 'features/calendar/calendar_controller.dart';
import 'features/event_details/event_details_api.dart';
import 'features/event_registration/event_registration_api.dart';
import 'features/notifications/notification_navigation_controller.dart';
import 'features/notifications/notification_sync_service.dart';
import 'features/settings/locale_controller.dart';
import 'l10n/app_localizations.dart';
import 'features/settings/reminder_preferences.dart';

class AlteKamererApp extends StatelessWidget {
  const AlteKamererApp({
    super.key,
    required this.authController,
    required this.calendarController,
    required this.eventDetailsService,
    required this.eventRegistrationService,
    required this.notificationNavigationController,
    required this.notificationSync,
    required this.reminderPreferences,
    required this.localeController,
  });

  final AuthController authController;
  final CalendarController calendarController;
  final EventDetailsService eventDetailsService;
  final EventRegistrationService eventRegistrationService;
  final NotificationNavigationController notificationNavigationController;
  final NotificationSync notificationSync;
  final ReminderPreferences reminderPreferences;
  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: localeController,
      builder: (context, _) {
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          locale: localeController.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          localeResolutionCallback: (locale, supportedLocales) {
            return switch (locale?.languageCode) {
              'sv' => const Locale('sv'),
              'en' => const Locale('en'),
              _ => const Locale('en'),
            };
          },
          home: AuthGate(
            authController: authController,
            calendarController: calendarController,
            eventDetailsService: eventDetailsService,
            eventRegistrationService: eventRegistrationService,
            notificationNavigationController: notificationNavigationController,
            notificationSync: notificationSync,
            reminderPreferences: reminderPreferences,
            localeController: localeController,
          ),
        );
      },
    );
  }
}
