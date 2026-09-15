import '../../core/network/api_client.dart';
import 'event_details.dart';

abstract interface class EventDetailsService {
  Future<EventDetails> getEvent(int eventId);
}

class EventDetailsApi implements EventDetailsService {
  EventDetailsApi(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<EventDetails> getEvent(int eventId) async {
    final json = await _apiClient.getJson('/api/v1/events/$eventId');
    return EventDetails.fromJson(json);
  }
}
