// -----------------------------------------------------------------------------
// calendar_api.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Retrieves calendar events from the AKCore mobile API.
//
// -----------------------------------------------------------------------------

import '../../core/network/api_client.dart';
import 'calendar_event.dart';

/// Contract for retrieving the member's calendar events.
abstract interface class CalendarService {
  /// Retrieves the current member's calendar events.
  ///
  /// Returns the event collection supplied by AKCore.
  ///
  /// Throws [FormatException] if the response does not contain a valid
  /// event collection. HTTP failures propagate from the API client.
  Future<List<CalendarEvent>> getCalendar();
}

/// Loads and validates calendar data from `/api/v1/calendar`.
///
/// Rejects malformed event collections rather than silently omitting
/// invalid entries.
class CalendarApi implements CalendarService {
  CalendarApi(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<CalendarEvent>> getCalendar() async {
    final json = await _apiClient.getJson('/api/v1/calendar');
    final events = json['events'];

    if (events is! List) {
      throw const FormatException('Expected calendar events array.');
    }

    return events.map((event) {
      if (event is! Map<String, dynamic>) {
        throw const FormatException('Expected calendar event object.');
      }

      return CalendarEvent.fromJson(event);
    }).toList();
  }
}
