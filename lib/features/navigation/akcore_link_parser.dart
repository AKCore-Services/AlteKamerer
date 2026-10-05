// -----------------------------------------------------------------------------
// akcore_link_parser.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Converts supported canonical AKCore website URLs into AlteKamerer
//   navigation requests.
//
// -----------------------------------------------------------------------------

import 'app_navigation_controller.dart';

/// Parses canonical AKCore URLs that AlteKamerer can handle.
///
/// Currently supported:
///
/// - `https://www.altekamereren.org/upcoming` -> calendar
/// - `https://www.altekamereren.org/upcoming/Event/{id}` -> event details
///
/// Unrelated hosts, unsupported routes, and malformed event identifiers are
/// ignored so future AKCore routes can be added explicitly without changing
/// current navigation behavior.
class AkCoreLinkParser {
  const AkCoreLinkParser._();

  static const _host = 'www.altekamereren.org';

  static AppNavigationRequest? tryParse(Uri uri) {
    if (uri.scheme.toLowerCase() != 'https' ||
        uri.host.toLowerCase() != _host) {
      return null;
    }

    final segments = uri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);

    if (segments.length == 1 && segments[0].toLowerCase() == 'upcoming') {
      return const CalendarNavigationRequest();
    }

    if (segments.length == 3 &&
        segments[0].toLowerCase() == 'upcoming' &&
        segments[1].toLowerCase() == 'event') {
      final eventId = int.tryParse(segments[2]);

      if (eventId != null && eventId > 0) {
        return EventNavigationRequest(eventId);
      }
    }

    return null;
  }
}
