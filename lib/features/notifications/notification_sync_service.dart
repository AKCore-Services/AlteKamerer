// -----------------------------------------------------------------------------
// notification_sync_service.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Coordinates calendar loading, member relevance, reminder
//   preferences, planning, and device notification scheduling.
//
// -----------------------------------------------------------------------------

import '../../core/diagnostics/diagnostic_error_details.dart';
import '../../core/diagnostics/diagnostics_service.dart';
import '../calendar/calendar_controller.dart';
import '../me/me_api.dart';
import '../settings/reminder_preferences.dart';
import 'local_notification_service.dart';
import 'notification_planner.dart';

/// Contract for refreshing or clearing scheduled event reminders.
abstract interface class NotificationSync {
  Future<void> sync();

  Future<void> clear();
}

/// Coordinates reminder planning and local notification scheduling.
///
/// Retrieves calendar and member data, applies reminder preferences through
/// [NotificationPlanner], and reconciles the resulting local notifications.
class NotificationSyncService implements NotificationSync {
  NotificationSyncService(
    this._meService,
    this._calendarController,
    this._planner,
    this._notificationScheduler,
    this._reminderPreferences, {
    DateTime Function()? now,
    this._diagnostics,
  }) : _now = now ?? (() => DateTime.now().toUtc());

  final MeService _meService;
  final CalendarController _calendarController;
  final NotificationPlanner _planner;
  final LocalNotificationScheduler _notificationScheduler;
  final ReminderPreferences _reminderPreferences;
  final DateTime Function() _now;
  final DiagnosticsService? _diagnostics;

  @override
  /// Refreshes scheduled reminders from current calendar data.
  ///
  /// If calendar loading fails, existing reminders are left unchanged.
  /// Subsequent synchronization failures are recorded when diagnostics are
  /// available and do not propagate to the calendar UI.
  Future<void> sync() async {
    await _calendarController.refresh();

    if (_calendarController.status != CalendarStatus.loaded) {
      return;
    }

    try {
      final me = await _meService.getMe();

      final reminderOffsets = await _reminderPreferences.getReminderOffsets();

      final plans = _planner.buildPlans(
        me: me,
        events: _calendarController.events,
        now: _now(),
        reminderOffsets: reminderOffsets,
      );

      await _notificationScheduler.reconcile(plans);
    } catch (error, stackTrace) {
      await _diagnostics?.recordError(
        subsystem: 'Notifications',
        message: 'Notification synchronization failed',
        error: diagnosticErrorDetails(error, stackTrace),
      );
      // Notification synchronisation must not make the calendar unusable.
    }
  }

  @override
  Future<void> clear() {
    return _notificationScheduler.clear();
  }
}
