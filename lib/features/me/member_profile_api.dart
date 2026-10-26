// -----------------------------------------------------------------------------
// member_profile_api.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Reads and updates the authenticated member's profile and retrieves
//   registration statistics through the AKCore mobile API.
//
// -----------------------------------------------------------------------------

import '../../core/network/api_client.dart';
import 'member_profile.dart';

/// Profile operations available to the authenticated mobile member.
abstract interface class MemberProfileService {
  Future<MemberProfile> getProfile();

  /// Updates the authenticated member's permitted profile fields.
  ///
  /// Returns the complete saved profile from AKCore.
  Future<MemberProfile> updateProfile(MemberProfileUpdateRequest request);

  /// Retrieves AKCore's existing default rolling-period statistics.
  Future<MemberProfileStatistics> getStatistics();
}

/// Implements authenticated member profile operations through the AKCore API.
class MemberProfileApi implements MemberProfileService {
  MemberProfileApi(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<MemberProfile> getProfile() async {
    final json = await _apiClient.getJson('/api/v1/profile');
    return MemberProfile.fromJson(json);
  }

  /// Updates the authenticated member's editable profile fields.
  ///
  /// Returns the complete saved profile supplied by AKCore. Validation and
  /// identity failures are propagated through the existing API client.
  @override
  Future<MemberProfile> updateProfile(
    MemberProfileUpdateRequest request,
  ) async {
    final json = await _apiClient.putJson(
      '/api/v1/profile',
      body: request.toJson(),
    );

    return MemberProfile.fromJson(json);
  }

  @override
  Future<MemberProfileStatistics> getStatistics() async {
    final json = await _apiClient.getJson('/api/v1/profile/statistics');
    return MemberProfileStatistics.fromJson(json);
  }
}
