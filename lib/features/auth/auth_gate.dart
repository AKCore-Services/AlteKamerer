// -----------------------------------------------------------------------------
// auth_gate.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Selects the application content according to the current authentication
//   state and coordinates notification cleanup when a session ends.
//
// Contains:
//   - AuthGate: Authentication-dependent application entry point.
//
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../core/diagnostics/diagnostics_service.dart';
import '../../core/theme/ak_status_view.dart';
import '../../l10n/app_localizations.dart';
import '../calendar/calendar_controller.dart';
import '../event_details/event_details_api.dart';
import '../event_registration/event_registration_api.dart';
import '../notifications/notification_navigation_controller.dart';
import '../notifications/notification_sync_service.dart';
import '../settings/calendar_display_controller.dart';
import '../settings/locale_controller.dart';
import '../settings/reminder_preferences.dart';
import '../settings/settings_backup_file_service.dart';
import '../settings/settings_backup_service.dart';
import '../shell/app_shell.dart';
import 'auth_controller.dart';
import 'login_screen.dart';

/// Displays the appropriate application content for the current session.
///
/// Shows the login screen, authenticated application, or session recovery
/// state, and clears scheduled notifications when authentication ends.
class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.authController,
    required this.calendarController,
    required this.eventDetailsService,
    required this.eventRegistrationService,
    required this.notificationNavigationController,
    required this.notificationSync,
    required this.reminderPreferences,
    required this.localeController,
    required this.calendarDisplayController,
    required this.settingsBackupService,
    required this.settingsBackupFileService,
    this.diagnosticsService,
    this.apiServer,
  });

  final AuthController authController;
  final CalendarController calendarController;
  final EventDetailsService eventDetailsService;
  final EventRegistrationService eventRegistrationService;
  final NotificationNavigationController notificationNavigationController;
  final NotificationSync notificationSync;
  final ReminderPreferences reminderPreferences;
  final LocaleController localeController;
  final CalendarDisplayController calendarDisplayController;
  final SettingsBackupService settingsBackupService;
  final SettingsBackupFileService settingsBackupFileService;
  final DiagnosticsService? diagnosticsService;
  final String? apiServer;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  AuthStatus? _previousStatus;

  @override
  void initState() {
    super.initState();

    _previousStatus = widget.authController.status;
    widget.authController.addListener(_handleAuthChanged);

    if (widget.authController.status == AuthStatus.unauthenticated) {
      _clearNotifications();
    }
  }

  @override
  void dispose() {
    widget.authController.removeListener(_handleAuthChanged);
    super.dispose();
  }

  void _handleAuthChanged() {
    final status = widget.authController.status;

    if (status == AuthStatus.unauthenticated &&
        _previousStatus != AuthStatus.unauthenticated) {
      _clearNotifications();
    }

    _previousStatus = status;
  }

  Future<void> _clearNotifications() async {
    try {
      await widget.notificationSync.clear();
    } catch (_) {
      // Authentication state must not depend on notification cleanup.
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.authController,
      builder: (context, child) {
        final l10n = AppLocalizations.of(context);

        return switch (widget.authController.status) {
          AuthStatus.loading => const Scaffold(
            body: SafeArea(child: AkLoadingView()),
          ),
          AuthStatus.unauthenticated => LoginScreen(
            authController: widget.authController,
          ),
          AuthStatus.authenticated => AppShell(
            authController: widget.authController,
            calendarController: widget.calendarController,
            eventDetailsService: widget.eventDetailsService,
            eventRegistrationService: widget.eventRegistrationService,
            notificationNavigationController:
                widget.notificationNavigationController,
            notificationSync: widget.notificationSync,
            reminderPreferences: widget.reminderPreferences,
            localeController: widget.localeController,
            calendarDisplayController: widget.calendarDisplayController,
            settingsBackupService: widget.settingsBackupService,
            settingsBackupFileService: widget.settingsBackupFileService,
            diagnosticsService: widget.diagnosticsService,
            apiServer: widget.apiServer,
          ),
          AuthStatus.restoreFailed => Scaffold(
            body: SafeArea(
              child: AkErrorView(
                title: l10n.connectionFailed,
                message: l10n.sessionCheckFailed,
                onRetry: () {
                  widget.authController.restoreSession();
                },
              ),
            ),
          ),
        };
      },
    );
  }
}
