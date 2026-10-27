// -----------------------------------------------------------------------------
// member_credentials_api.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Changes the authenticated member's username and password through
//   AKCore's existing mobile credential endpoints.
//
// Contains:
//   - MemberCredentialsService: Credential-change operations.
//   - MemberCredentialsApi: Authenticated HTTP implementation.
//
// -----------------------------------------------------------------------------

import '../../core/network/api_client.dart';

/// Provides self-service credential changes for the current AKCore member.
///
/// Both operations require the current password. Password changes revoke
/// existing mobile sessions on the server.
abstract interface class MemberCredentialsService {
  /// Returns the username confirmed by AKCore after a successful change.
  Future<String> changeUsername({
    required String newUsername,
    required String currentPassword,
  });

  /// Changes the password without returning or retaining credential data.
  ///
  /// A successful response invalidates the member's existing mobile session.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}

/// Calls AKCore's existing authenticated `/api/v1/profile` endpoints.
class MemberCredentialsApi implements MemberCredentialsService {
  const MemberCredentialsApi(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<String> changeUsername({
    required String newUsername,
    required String currentPassword,
  }) async {
    final response = await _apiClient.putJson(
      '/api/v1/profile/username',
      body: {'newUsername': newUsername, 'currentPassword': currentPassword},
    );

    final confirmedUsername = response['userName'];

    if (confirmedUsername is! String || confirmedUsername.trim().isEmpty) {
      throw const FormatException('Invalid username change response.');
    }

    return confirmedUsername;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    // AKCore returns HTTP 204 with no response body.
    await _apiClient.putJson(
      '/api/v1/profile/password',
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }
}
