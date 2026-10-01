// -----------------------------------------------------------------------------
// notification_planner.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Determines which event reminders should be scheduled from
//   member relevance, event times, and reminder preferences.
//
// -----------------------------------------------------------------------------

import 'package:timezone/timezone.dart' as tz;

import '../calendar/calendar_event.dart';
import '../me/me.dart';
import 'notification_plan.dart';

/// Converts calendar events into scheduled reminder plans.
///
/// Applies the event's membership and registration relevance rules, selects
/// the applicable event time, and creates reminders using the supplied
/// timezone and reminder offsets.
class NotificationPlanner {
  NotificationPlanner(this.location);

  final tz.Location location;

  /// Builds future reminders for the member's relevant events.
  ///
  /// Non-members receive no plans. Events with unusable dates or times and
  /// reminders scheduled at or before [now] are excluded. Results are sorted
  /// by scheduled time, with both timestamps stored as UTC instants.
  List<NotificationPlan> buildPlans({
    required Me me,
    required List<CalendarEvent> events,
    required DateTime now,
    required List<Duration> reminderOffsets,
  }) {
    if (!me.isMember) {
      return const [];
    }

    final nowUtc = now.toUtc();
    final plans = <NotificationPlan>[];

    for (final event in events) {
      if (!_isRelevant(me, event)) {
        continue;
      }

      final eventTime = _eventTime(event, location);

      if (eventTime == null) {
        continue;
      }

      for (final offset in reminderOffsets) {
        final scheduledTime = eventTime.subtract(offset);

        if (!scheduledTime.toUtc().isAfter(nowUtc)) {
          continue;
        }

        plans.add(
          NotificationPlan(
            eventId: event.id,
            eventName: event.name,
            eventTime: eventTime.toUtc(),
            reminderOffset: offset,
            scheduledTime: scheduledTime.toUtc(),
          ),
        );
      }
    }

    plans.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    return plans;
  }

  bool _isRelevant(Me me, CalendarEvent event) {
    return event.isRelevantTo(isBallet: me.isBallet);
  }

  tz.TZDateTime? _eventTime(CalendarEvent event, tz.Location location) {
    final time = _preferredTime(event);

    if (time == null) {
      return null;
    }

    final date = DateTime.tryParse(event.date);

    if (date == null) {
      return null;
    }

    final parts = time.split(':');

    if (parts.length != 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }

    return tz.TZDateTime(
      location,
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }

  // A Hålan registration uses its own arrival time when available.
  // Otherwise prefer the general arrival time, then Hålan, then start time.
  // The backend's 00:00 placeholder is not treated as a usable time.
  String? _preferredTime(CalendarEvent event) {
    if (event.signupState == 'Hålan' && _hasUsableTime(event.halanTime)) {
      return event.halanTime;
    }

    if (_hasUsableTime(event.thereTime)) {
      return event.thereTime;
    }

    if (_hasUsableTime(event.halanTime)) {
      return event.halanTime;
    }

    if (_hasUsableTime(event.startsTime)) {
      return event.startsTime;
    }

    return null;
  }

  bool _hasUsableTime(String value) {
    return value.isNotEmpty && value != '00:00';
  }
}
