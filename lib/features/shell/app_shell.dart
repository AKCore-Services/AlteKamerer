import 'package:flutter/material.dart';

import '../auth/auth_controller.dart';
import '../calendar/calendar_controller.dart';
import '../calendar/calendar_event.dart';
import '../calendar/calendar_screen.dart';
import '../event_details/event_details_api.dart';
import '../event_details/event_details_controller.dart';
import '../event_details/event_details_screen.dart';
import '../event_details/event_details.dart';
import '../event_registration/event_registration_api.dart';
import '../event_registration/event_registration_controller.dart';
import '../event_registration/event_registration_screen.dart';
import '../notifications/notification_navigation_controller.dart';
import '../notifications/notification_sync_service.dart';
import '../settings/reminder_preferences.dart';
import '../settings/reminder_settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.authController,
    required this.calendarController,
    required this.eventDetailsService,
    required this.eventRegistrationService,
    required this.notificationNavigationController,
    required this.notificationSync,
    required this.reminderPreferences,
  });

  final AuthController authController;
  final CalendarController calendarController;
  final EventDetailsService eventDetailsService;
  final EventRegistrationService eventRegistrationService;
  final NotificationNavigationController notificationNavigationController;
  final NotificationSync notificationSync;
  final ReminderPreferences reminderPreferences;

  @override
  State<AppShell> createState() => _AppShellState();
}

enum _ShellPage {
  calendar,
  settings,
}

class _AppShellState extends State<AppShell> {
  _ShellPage _currentPage = _ShellPage.calendar;

  @override
  void initState() {
    super.initState();

    widget.notificationNavigationController.addListener(
      _handleNotificationNavigation,
    );

    widget.notificationSync.sync();

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
    return Scaffold(
      appBar: AppBar(title: Text(_pageTitle)),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Kalender'),
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
                title: const Text('Inställningar'),
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
                title: const Text('Logga ut'),
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
    );
  }

  String get _pageTitle {
    return switch (_currentPage) {
      _ShellPage.calendar => 'Kalender',
      _ShellPage.settings => 'Inställningar',
    };
  }

  Widget get _pageBody {
    return switch (_currentPage) {
      _ShellPage.calendar => CalendarScreen(
        controller: widget.calendarController,
        onOpenEvent: _openEvent,
        onRefresh: widget.notificationSync.sync,
      ),
      _ShellPage.settings => ReminderSettingsScreen(
        reminderPreferences: widget.reminderPreferences,
        notificationSync: widget.notificationSync,
      ),
    };
  }

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
    final controller = EventDetailsController(widget.eventDetailsService);

    Navigator.of(context).push(
      MaterialPageRoute<void>(
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
    );

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) {
          return EventRegistrationScreen(controller: registrationController);
        },
      ),
    );

    if (saved == true) {
      await eventDetailsController.load(event.id);
      await widget.notificationSync.sync();
    }
  }
}
