// -----------------------------------------------------------------------------
// event_registration_api.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Defines registration requests and submits them to the AKCore API.
//
// -----------------------------------------------------------------------------

import '../../core/network/api_client.dart';

/// Contains the registration values submitted to AKCore.
///
/// The `where` field carries the backend registration choice, while
/// transport and instrument fields retain the API's existing semantics.
class EventRegistrationRequest {
  const EventRegistrationRequest({
    required this.where,
    required this.car,
    required this.instrument,
    required this.comment,
    required this.selectedInstrument,
  });

  final String where;
  final bool car;
  final bool instrument;
  final String comment;
  final String? selectedInstrument;

  Map<String, dynamic> toJson() {
    return {
      'where': where,
      'car': car,
      'instrument': instrument,
      'comment': comment,
      'selectedInstrument': selectedInstrument,
    };
  }
}

/// Contract for saving a member's event registration.
abstract interface class EventRegistrationService {
  /// Submits [request] for the event identified by [eventId].
  ///
  /// Completes when AKCore accepts the registration. API failures propagate
  /// to the caller; this contract does not apply client-side eligibility rules.
  Future<void> saveRegistration(int eventId, EventRegistrationRequest request);
}

/// Saves registrations through `/api/v1/events/{id}/registration`.
class EventRegistrationApi implements EventRegistrationService {
  EventRegistrationApi(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<void> saveRegistration(
    int eventId,
    EventRegistrationRequest request,
  ) async {
    await _apiClient.putJson(
      '/api/v1/events/$eventId/registration',
      body: request.toJson(),
    );
  }
}
