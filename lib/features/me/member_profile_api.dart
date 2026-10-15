// -----------------------------------------------------------------------------
// member_profile_api.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Retrieves the authenticated member's profile and registration statistics
//   through the AKCore mobile API.
//
// -----------------------------------------------------------------------------

import '../../core/network/api_client.dart';
import 'member_profile.dart';

/// Read-only profile operations available to the authenticated mobile member.
abstract interface class MemberProfileService {
  Future<MemberProfile> getProfile();

  /// Retrieves AKCore's existing default rolling-period statistics.
  Future<MemberProfileStatistics> getStatistics();
}

/// Implements profile retrieval through the authenticated AKCore API.
class MemberProfileApi implements MemberProfileService {
  MemberProfileApi(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<MemberProfile> getProfile() async {
    final json = await _apiClient.getJson('/api/v1/profile');
    return MemberProfile.fromJson(json);
  }

  @override
  Future<MemberProfileStatistics> getStatistics() async {
    final json = await _apiClient.getJson('/api/v1/profile/statistics');
    return MemberProfileStatistics.fromJson(json);
  }
}
