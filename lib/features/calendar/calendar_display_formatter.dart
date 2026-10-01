// -----------------------------------------------------------------------------
// calendar_display_formatter.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Formats calendar dates and times using the selected language
//   and the member's display preferences.
//
// -----------------------------------------------------------------------------

import 'package:intl/intl.dart';

import '../settings/calendar_display_preferences.dart';

/// Formats calendar dates and times for display.
///
/// Applies the selected locale and date/time preferences while preserving
/// the original input when it cannot be parsed.
class CalendarDisplayFormatter {
  const CalendarDisplayFormatter();

  /// Formats an event date using the configured date style.
  ///
  /// Optionally prefixes the localized weekday. Invalid date strings
  /// are returned unchanged.
  String formatDate(
    String value, {
    required String locale,
    required CalendarDisplaySettings settings,
  }) {
    final date = DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    final dateFormat = switch (settings.dateFormat) {
      CalendarDateFormat.compact => DateFormat('dd/MM', locale),
      CalendarDateFormat.numeric => DateFormat.yMd(locale),
      CalendarDateFormat.written => DateFormat.yMMMd(locale),
    };

    final formattedDate = dateFormat.format(date);

    if (!settings.showWeekday) {
      return formattedDate;
    }

    final weekday = DateFormat.E(locale).format(date);
    return '$weekday $formattedDate';
  }

  /// Formats a clock time using the configured 12- or 24-hour style.
  ///
  /// Accepts valid `H:mm` or `HH:mm` values. Invalid times are returned
  /// unchanged rather than being replaced with a misleading value.
  String formatTime(
    String value, {
    required String locale,
    required CalendarDisplaySettings settings,
  }) {
    final time = _parseTime(value);

    if (time == null) {
      return value;
    }

    final date = DateTime(2000, 1, 1, time.$1, time.$2);

    return switch (settings.timeFormat) {
      CalendarTimeFormat.twentyFourHour => DateFormat.Hm(locale).format(date),
      CalendarTimeFormat.twelveHour => DateFormat(
        'h:mm a',
        locale,
      ).format(date),
    };
  }

  (int, int)? _parseTime(String value) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value);

    if (match == null) {
      return null;
    }

    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);

    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }

    return (hour, minute);
  }
}
