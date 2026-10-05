// -----------------------------------------------------------------------------
// app_shell.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Provides navigation for authenticated members and coordinates transitions
//   between the calendar, settings, event details, and registration screens.
//
// Contains:
//   - AppShell: Authenticated application navigation.
//
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../core/diagnostics/diagnostics_service.dart';
import '../auth/auth_controller.dart';
import '../calendar/calendar_controller.dart';
import '../calendar/calendar_event.dart';
import '../calendar/calendar_screen.dart';
import '../event_details/event_details_api.dart';
import '../event_details/event_details_cache.dart';
import '../event_details/event_details_controller.dart';
import '../event_details/event_details_screen.dart';
import '../event_details/event_details.dart';
import '../event_registration/event_registration_api.dart';
import '../event_registration/event_registration_controller.dart';
import '../event_registration/event_registration_screen.dart';
import '../notifications/notification_navigation_controller.dart';
import '../notifications/notification_sync_service.dart';
import '../settings/calendar_display_controller.dart';
import '../settings/reminder_preferences.dart';
import '../settings/locale_controller.dart';
import '../settings/reminder_settings_screen.dart';
import '../settings/settings_backup_file_service.dart';
import '../settings/settings_backup_service.dart';
import '../../l10n/app_localizations.dart';

/// Coordinates navigation within the authenticated application.
///
/// Owns the active top-level page, opens event details and registration
/// screens, and handles event navigation requested by notifications.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.authController,
    required this.calendarController,
    required this.eventDetailsService,
    required this.eventRegistrationService,
    this.eventDetailsCache,
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
  final EventDetailsCache? eventDetailsCache;
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
  State<AppShell> createState() => _AppShellState();
}

enum _ShellPage { calendar, settings }

class _AppShellState extends State<AppShell> {
  _ShellPage _currentPage = _ShellPage.calendar;

  @override
  void initState() {
    super.initState();

    widget.notificationNavigationController.addListener(
      _handleNotificationNavigation,
    );

    widget.notificationSync.sync();

    // A notification may have been opened before the authenticated
    // navigator was available. Process it after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openPendingNotification();
    });
  }

  @override
  void dispose() {
    widget.notificationNavigationController.removeListener(
      _handleNotificationNavigation,
    );

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: _currentPage == _ShellPage.calendar,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _currentPage == _ShellPage.calendar) {
          return;
        }

        setState(() {
          _currentPage = _ShellPage.calendar;
        });
      },
      child: Scaffold(
        appBar: AppBar(
          title: _currentPage == _ShellPage.calendar
              ? ListenableBuilder(
                  listenable: widget.calendarController,
                  builder: (context, child) {
                    return _calendarTitle(context, l10n);
                  },
                )
              : Text(_pageTitle(l10n)),
        ),
        drawer: Drawer(
          child: SafeArea(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_month),
                  title: Text(l10n.calendar),
                  selected: _currentPage == _ShellPage.calendar,
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _currentPage = _ShellPage.calendar;
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: Text(l10n.settings),
                  selected: _currentPage == _ShellPage.settings,
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _currentPage = _ShellPage.settings;
                    });
                  },
                ),
                const Spacer(),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: Text(l10n.logOut),
                  onTap: () async {
                    Navigator.of(context).pop();

                    try {
                      await widget.authController.logout();
                    } catch (_) {
                      // Local credentials are cleared even if server logout fails.
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        body: SafeArea(child: _pageBody),
      ),
    );
  }

  Widget _calendarTitle(BuildContext context, AppLocalizations l10n) {
    final controller = widget.calendarController;
    final cachedAt = controller.cachedAt;

    if (!controller.isShowingCachedData || cachedAt == null) {
      return Text(l10n.calendar);
    }

    final localCachedAt = cachedAt.toLocal();
    final material = MaterialLocalizations.of(context);
    final date = material.formatShortDate(localCachedAt);
    final time = material.formatTimeOfDay(
      TimeOfDay.fromDateTime(localCachedAt),
    );

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: l10n.calendar),
          TextSpan(
            text: '  ${l10n.calendarCachedTitle(date, time)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _pageTitle(AppLocalizations l10n) {
    return switch (_currentPage) {
      _ShellPage.calendar => l10n.calendar,
      _ShellPage.settings => l10n.settings,
    };
  }

  Widget get _pageBody {
    return switch (_currentPage) {
      _ShellPage.calendar => CalendarScreen(
        controller: widget.calendarController,
        displayController: widget.calendarDisplayController,
        onOpenEvent: _openEvent,
        onRefresh: widget.notificationSync.sync,
      ),
      _ShellPage.settings => ReminderSettingsScreen(
        reminderPreferences: widget.reminderPreferences,
        notificationSync: widget.notificationSync,
        localeController: widget.localeController,
        calendarDisplayController: widget.calendarDisplayController,
        settingsBackupService: widget.settingsBackupService,
        settingsBackupFileService: widget.settingsBackupFileService,
        diagnosticsService: widget.diagnosticsService,
        apiServer: widget.apiServer,
      ),
    };
  }

  // Notification requests can arrive outside the normal widget build cycle.
  // Schedule a frame so the pending event opens after the navigator is ready,
  // rather than attempting to push a route immediately.
  void _handleNotificationNavigation() {
    if (!mounted) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _openPendingNotification();
      }
    });

    WidgetsBinding.instance.scheduleFrame();
  }

  void _openPendingNotification() {
    final eventId = widget.notificationNavigationController
        .consumePendingEventId();

    if (eventId == null) {
      return;
    }

    _openEventById(eventId);
  }

  void _openEvent(CalendarEvent event) {
    _openEventById(event.id);
  }

  void _openEventById(int eventId) {
    final controller = EventDetailsController(
      widget.eventDetailsService,
      cache: widget.eventDetailsCache,
      diagnostics: widget.diagnosticsService,
    );

    Navigator.of(context).push(
      _AccessibleMaterialPageRoute<void>(
        disableAnimations: MediaQuery.disableAnimationsOf(context),
        builder: (context) {
          return EventDetailsScreen(
            eventId: eventId,
            controller: controller,
            onRegistrationPressed: (details) {
              _openRegistration(details, controller);
            },
          );
        },
      ),
    );
  }

  Future<void> _openRegistration(
    EventDetails event,
    EventDetailsController eventDetailsController,
  ) async {
    final registrationController = EventRegistrationController(
      widget.eventRegistrationService,
      event,
      diagnostics: widget.diagnosticsService,
    );

    final saved = await Navigator.of(context).push<bool>(
      _AccessibleMaterialPageRoute<bool>(
        disableAnimations: MediaQuery.disableAnimationsOf(context),
        builder: (context) {
          return EventRegistrationScreen(controller: registrationController);
        },
      ),
    );

    if (saved == true) {
      await eventDetailsController.load(event.id);
      await widget.notificationSync.sync();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).akServiceUpcomingSignupUpdated,
          ),
        ),
      );
    }
  }
}

class _AccessibleMaterialPageRoute<T> extends MaterialPageRoute<T> {
  _AccessibleMaterialPageRoute({
    required super.builder,
    required this.disableAnimations,
  });

  final bool disableAnimations;

  @override
  Duration get transitionDuration =>
      disableAnimations ? Duration.zero : super.transitionDuration;

  @override
  Duration get reverseTransitionDuration =>
      disableAnimations ? Duration.zero : super.reverseTransitionDuration;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (disableAnimations) {
      return child;
    }

    return super.buildTransitions(
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
