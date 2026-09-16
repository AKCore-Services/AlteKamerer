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