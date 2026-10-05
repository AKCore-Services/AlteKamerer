import 'package:altekamerer/features/navigation/akcore_link_parser.dart';
import 'package:altekamerer/features/navigation/app_navigation_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses canonical upcoming URL as calendar navigation', () {
    final request = AkCoreLinkParser.tryParse(
      Uri.parse('https://www.altekamereren.org/upcoming'),
    );

    expect(request, isA<CalendarNavigationRequest>());
  });

  test('accepts trailing slash on upcoming URL', () {
    final request = AkCoreLinkParser.tryParse(
      Uri.parse('https://www.altekamereren.org/upcoming/'),
    );

    expect(request, isA<CalendarNavigationRequest>());
  });

  test('parses canonical event URL', () {
    final request = AkCoreLinkParser.tryParse(
      Uri.parse('https://www.altekamereren.org/upcoming/Event/42'),
    );

    expect(
      request,
      isA<EventNavigationRequest>().having(
        (request) => request.eventId,
        'eventId',
        42,
      ),
    );
  });

  test('matches supported route segments case-insensitively', () {
    final request = AkCoreLinkParser.tryParse(
      Uri.parse('https://www.altekamereren.org/UPCOMING/event/42'),
    );

    expect(
      request,
      isA<EventNavigationRequest>().having(
        (request) => request.eventId,
        'eventId',
        42,
      ),
    );
  });

  test('rejects unrelated host', () {
    final request = AkCoreLinkParser.tryParse(
      Uri.parse('https://example.org/upcoming/Event/42'),
    );

    expect(request, isNull);
  });

  test('rejects non-https URL', () {
    final request = AkCoreLinkParser.tryParse(
      Uri.parse('http://www.altekamereren.org/upcoming/Event/42'),
    );

    expect(request, isNull);
  });

  test('rejects malformed and non-positive event identifiers', () {
    expect(
      AkCoreLinkParser.tryParse(
        Uri.parse('https://www.altekamereren.org/upcoming/Event/nope'),
      ),
      isNull,
    );

    expect(
      AkCoreLinkParser.tryParse(
        Uri.parse('https://www.altekamereren.org/upcoming/Event/0'),
      ),
      isNull,
    );
  });

  test('rejects unsupported AKCore route', () {
    final request = AkCoreLinkParser.tryParse(
      Uri.parse('https://www.altekamereren.org/settings'),
    );

    expect(request, isNull);
  });
}
