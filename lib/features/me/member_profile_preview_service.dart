// -----------------------------------------------------------------------------
// member_profile_preview_service.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Provides sample profile information when the profile API is unavailable
//   in the separately installed AlteKamerer Test application.
//
// -----------------------------------------------------------------------------

import '../../core/network/api_exception.dart';
import 'member_profile.dart';
import 'member_profile_api.dart';

/// Provides the same profile contract as AKCore using fictional information.
class MemberProfilePreviewData {
  static const profile = MemberProfile(
    userName: 'exempelanvandare',
    email: 'exempel@example.com',
    firstName: 'Förnamn',
    lastName: 'Efternamn',
    phone: '070-000 00 00',
    instrument: 'Trumpet',
    otherInstruments: ['Trombon', 'Horn'],
    roles: ['Medlem'],
    posts: ['Exempelpost'],
    medal: 'Exempelmedalj',
    givenMedal: 'Exempelmedalj',
  );

  static const statistics = MemberProfileStatistics(
    totalGigs: 20,
    halan: 8,
    direct: 6,
    cantCome: 4,
    car: 3,
    instrument: 5,
    comment: 2,
  );
}

/// Uses actual AKCore data whenever possible.
///
/// Placeholder data is permitted only in the separately installed test app.
/// Authentication errors and invalid API responses always propagate.
class MemberProfilePreviewService implements MemberProfileService {
  MemberProfilePreviewService(this._service, {required this.allowPreview});

  final MemberProfileService _service;
  final bool allowPreview;

  bool _profileIsPreview = false;
  bool _statisticsArePreview = false;

  bool get profileIsPreview => _profileIsPreview;
  bool get statisticsArePreview => _statisticsArePreview;

  @override
  Future<MemberProfile> getProfile() async {
    _profileIsPreview = false;

    try {
      return await _service.getProfile();
    } on ApiException catch (error) {
      if (!allowPreview || !_isUnavailable(error.statusCode)) {
        rethrow;
      }

      _profileIsPreview = true;
      return MemberProfilePreviewData.profile;
    }
  }

  /// Forwards genuine updates but never saves fictional preview data.
  @override
  Future<MemberProfile> updateProfile(
    MemberProfileUpdateRequest request,
  ) async {
    if (_profileIsPreview) {
      throw StateError('Preview profile data cannot be saved.');
    }

    return _service.updateProfile(request);
  }

  @override
  Future<MemberProfileStatistics> getStatistics() async {
    _statisticsArePreview = false;

    try {
      return await _service.getStatistics();
    } on ApiException catch (error) {
      if (!allowPreview || !_isUnavailable(error.statusCode)) {
        rethrow;
      }

      _statisticsArePreview = true;
      return MemberProfilePreviewData.statistics;
    }
  }

  static bool _isUnavailable(int statusCode) {
    return statusCode == 404 ||
        statusCode == 408 ||
        statusCode == 503 ||
        statusCode == 502 ||
        statusCode == 504;
  }
}
