// -----------------------------------------------------------------------------
// notification_event_payload.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Encodes and validates the event identifier attached to a
//   notification for navigation back into the application.
//
// -----------------------------------------------------------------------------

import 'dart:convert';

/// Encodes event identifiers for notification navigation.
///
/// Invalid, missing, or malformed payloads are rejected rather than
/// opening an event with an unverified identifier.
class NotificationEventPayload {
  const NotificationEventPayload._();

  /// Encodes [eventId] as the JSON payload used for notification navigation.
  static String encode(int eventId) {
    return jsonEncode({'eventId': eventId});
  }

  /// Extracts a positive event identifier from a notification payload.
  ///
  /// Returns null for missing, malformed, or unexpected JSON data,
  /// including identifiers that are not positive integers.
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
