import '../../core/network/api_client.dart';

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

abstract interface class EventRegistrationService {
  Future<void> saveRegistration(int eventId, EventRegistrationRequest request);
}

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
