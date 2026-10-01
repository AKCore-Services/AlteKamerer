// -----------------------------------------------------------------------------
// event_details_api.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Retrieves detailed information about individual AKCore events.
//
// -----------------------------------------------------------------------------

import '../../core/network/api_client.dart';
import 'event_details.dart';

/// Contract for loading an event by its AKCore identifier.
abstract interface class EventDetailsService {
  /// Retrieves the details for [eventId].
  ///
  /// Returns the event information supplied by AKCore. HTTP failures
  /// propagate from the API client.
  Future<EventDetails> getEvent(int eventId);
}

/// Retrieves event details from `/api/v1/events/{id}`.
class EventDetailsApi implements EventDetailsService {
  EventDetailsApi(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<EventDetails> getEvent(int eventId) async {
    final json = await _apiClient.getJson('/api/v1/events/$eventId');
    return EventDetails.fromJson(json);
  }
}
