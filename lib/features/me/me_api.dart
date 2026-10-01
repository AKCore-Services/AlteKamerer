// -----------------------------------------------------------------------------
// me_api.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Retrieves the authenticated member's profile information
//   from the AKCore mobile API.
//
// -----------------------------------------------------------------------------

import '../../core/network/api_client.dart';
import 'me.dart';

/// Contract for retrieving the current authenticated member.
abstract interface class MeService {
  /// Retrieves the currently authenticated member.
  ///
  /// API failures and invalid response data propagate to the caller.
  Future<Me> getMe();
}

/// Retrieves current-member information from `/api/v1/me`.
///
/// Converts the API response into the [Me] model used by the app.
class MeApi implements MeService {
  MeApi(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<Me> getMe() async {
    final json = await _apiClient.getJson('/api/v1/me');

    return Me.fromJson(json);
  }
}
