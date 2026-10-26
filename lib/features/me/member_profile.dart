// -----------------------------------------------------------------------------
// member_profile.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Represents the authenticated member's profile returned by AKCore.
//
// -----------------------------------------------------------------------------

/// Personal and membership information belonging to the authenticated member.
///
/// Administrative membership information is displayed by the mobile app but
/// is not editable through the member profile API.
class MemberProfile {
  const MemberProfile({
    required this.userName,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.instrument,
    required this.otherInstruments,
    required this.roles,
    required this.posts,
    required this.medal,
    required this.givenMedal,
  });

  /// Decodes the AKCore `/api/v1/profile` response.
  ///
  /// The response must contain the complete profile contract. Invalid or
  /// missing fields cause a [FormatException] rather than displaying
  /// incomplete account information as though it were authoritative.
  factory MemberProfile.fromJson(Map<String, dynamic> json) {
    String readString(String key) {
      final value = json[key];

      if (value is! String) {
        throw FormatException('Expected profile field "$key" to be a string.');
      }

      return value;
    }

    List<String> readStrings(String key) {
      final value = json[key];

      if (value is! List || value.any((item) => item is! String)) {
        throw FormatException(
          'Expected profile field "$key" to be a string array.',
        );
      }

      return List<String>.unmodifiable(value.cast<String>());
    }

    return MemberProfile(
      userName: readString('userName'),
      email: readString('email'),
      firstName: readString('firstName'),
      lastName: readString('lastName'),
      phone: readString('phone'),
      instrument: readString('instrument'),
      otherInstruments: readStrings('otherInstruments'),
      roles: readStrings('roles'),
      posts: readStrings('posts'),
      medal: readString('medal'),
      givenMedal: readString('givenMedal'),
    );
  }

  final String userName;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final String instrument;
  final List<String> otherInstruments;
  final List<String> roles;
  final List<String> posts;
  final String medal;
  final String givenMedal;

  String get displayName {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? userName : name;
  }
}

/// The personal fields a member may update through AKCore's profile API.
///
/// Administrative fields and credentials are intentionally excluded. AKCore
/// remains responsible for validating and applying the submitted values.
class MemberProfileUpdateRequest {
  const MemberProfileUpdateRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.instrument,
    required this.otherInstruments,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String instrument;
  final List<String> otherInstruments;

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'phone': phone,
    'instrument': instrument,
    'otherInstruments': otherInstruments,
  };
}

/// Existing AKCore registration statistics for the requested period.
///
/// These counters describe registrations, not verified attendance or medal
/// eligibility.
class MemberProfileStatistics {
  const MemberProfileStatistics({
    required this.totalGigs,
    required this.halan,
    required this.direct,
    required this.cantCome,
    required this.car,
    required this.instrument,
    required this.comment,
  });

  /// Decodes the AKCore `/api/v1/profile/statistics` response.
  factory MemberProfileStatistics.fromJson(Map<String, dynamic> json) {
    int readCount(String key) {
      final value = json[key];

      if (value is! int || value < 0) {
        throw FormatException(
          'Expected statistics field "$key" to be a non-negative integer.',
        );
      }

      return value;
    }

    return MemberProfileStatistics(
      totalGigs: readCount('totalGigs'),
      halan: readCount('halan'),
      direct: readCount('direct'),
      cantCome: readCount('cantCome'),
      car: readCount('car'),
      instrument: readCount('instrument'),
      comment: readCount('comment'),
    );
  }

  final int totalGigs;
  final int halan;
  final int direct;
  final int cantCome;
  final int car;
  final int instrument;
  final int comment;
}
