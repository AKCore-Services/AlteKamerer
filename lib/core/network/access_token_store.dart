// -----------------------------------------------------------------------------
// access_token_store.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Keeps the current access token in memory for authenticated
//   API requests without persisting it to device storage.
//
// Contains:
//   - AccessTokenStore: In-memory access-token storage.
//
// -----------------------------------------------------------------------------

/// Holds the current access token for authenticated API requests.
///
/// Access tokens are kept in memory. Persistent session restoration uses
/// the refresh token managed separately by `CredentialStore`.
class AccessTokenStore {
  String? _accessToken;

  String? get accessToken => _accessToken;

  void set(String accessToken) {
    _accessToken = accessToken;
  }

  void clear() {
    _accessToken = null;
  }
}
