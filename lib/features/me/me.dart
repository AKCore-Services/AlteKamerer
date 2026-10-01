// -----------------------------------------------------------------------------
// me.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Represents current-member information returned by AKCore.
//
// -----------------------------------------------------------------------------

/// Contains the authenticated member information used by the app.
///
/// Membership and ballet association inform reminder relevance, while
/// available instruments are used by the registration interface.
class Me {
  const Me({
    required this.displayName,
    required this.isMember,
    required this.isBallet,
    required this.availableInstruments,
  });

  /// Decodes the current-member API response.
  ///
  /// A missing display name becomes an empty string. The membership flags
  /// and available instrument collection must have their expected types.
  factory Me.fromJson(Map<String, dynamic> json) {
    final instruments = json['availableInstruments'];

    if (instruments is! List) {
      throw const FormatException('Expected available instruments array.');
    }

    return Me(
      displayName: json['displayName'] as String? ?? '',
      isMember: json['isMember'] as bool,
      isBallet: json['isBallet'] as bool,
      availableInstruments: instruments.cast<String>(),
    );
  }

  final String displayName;
  final bool isMember;
  final bool isBallet;
  final List<String> availableInstruments;
}
