// -----------------------------------------------------------------------------
// notification_plan.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Represents a single planned event reminder, including its
//   event time, reminder offset, and scheduled notification time.
//
// -----------------------------------------------------------------------------

/// Describes one reminder to be scheduled for an event.
///
/// Event and scheduled times are absolute UTC instants, while the reminder
/// offset determines how far in advance the notification should fire.
class NotificationPlan {
  const NotificationPlan({
    required this.eventId,
    required this.eventName,
    required this.eventTime,
    required this.reminderOffset,
    required this.scheduledTime,
  });

  final int eventId;
  final String eventName;

  /// Absolute UTC instant at which the event occurs.
  final DateTime eventTime;

  final Duration reminderOffset;

  /// Absolute UTC instant at which this reminder should fire.
  final DateTime scheduledTime;
}
