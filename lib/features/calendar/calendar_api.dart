import '../../core/network/api_client.dart';
import 'calendar_event.dart';

abstract interface class CalendarService {
  Future<List<CalendarEvent>> getCalendar();
}

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
