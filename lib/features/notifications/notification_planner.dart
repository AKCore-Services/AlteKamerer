import 'package:timezone/timezone.dart' as tz;

import '../calendar/calendar_event.dart';
import '../me/me.dart';
import 'notification_plan.dart';

const defaultReminderOffsets = [Duration(hours: 8), Duration(hours: 1)];

class NotificationPlanner {
  NotificationPlanner(
    this.location, {
    this.reminderOffsets = defaultReminderOffsets,
  });

  final tz.Location location;
  final List<Duration> reminderOffsets;

  List<NotificationPlan> buildPlans({
    required Me me,
    required List<CalendarEvent> events,
    required DateTime now,
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
    if (event.signupState == 'Kan inte komma') {
      return false;
    }

    if (event.signupState == 'Hålan' || event.signupState == 'Direkt') {
      return true;
    }

    return switch (event.type) {
      'Rep' => !me.isBallet,
      'Balettrep' => me.isBallet,
      'Kårhusrep' => true,
      'Athenrep' => true,
      'Samlingsrep' => true,
      'Fikarep' => true,
      _ => false,
    };
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
