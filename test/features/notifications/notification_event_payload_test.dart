import 'package:altekamerer/features/notifications/notification_event_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('encodes and parses event id', () {
    final payload = NotificationEventPayload.encode(42);

    expect(NotificationEventPayload.tryParse(payload), 42);
  });

  test('rejects missing payload', () {
    expect(NotificationEventPayload.tryParse(null), isNull);
    expect(NotificationEventPayload.tryParse(''), isNull);
  });

  test('rejects malformed payload', () {
    expect(NotificationEventPayload.tryParse('not-json'), isNull);
  });

  test('rejects payload without valid event id', () {
    expect(NotificationEventPayload.tryParse('{}'), isNull);

    expect(NotificationEventPayload.tryParse('{"eventId":0}'), isNull);

    expect(NotificationEventPayload.tryParse('{"eventId":"42"}'), isNull);
  });
}
