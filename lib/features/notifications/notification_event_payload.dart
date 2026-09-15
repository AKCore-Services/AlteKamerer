import 'dart:convert';

class NotificationEventPayload {
  const NotificationEventPayload._();

  static String encode(int eventId) {
    return jsonEncode({'eventId': eventId});
  }

  static int? tryParse(String? payload) {
    if (payload == null || payload.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(payload);

      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final eventId = decoded['eventId'];

      if (eventId is int && eventId > 0) {
        return eventId;
      }

      return null;
    } on FormatException {
      return null;
    }
  }
}
