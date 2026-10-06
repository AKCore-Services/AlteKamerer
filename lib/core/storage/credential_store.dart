// -----------------------------------------------------------------------------
// credential_store.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Defines the persistent credential-storage contract used to restore
//   authenticated sessions.
//
// Contains:
//   - CredentialStore: Refresh-token and recent-auth persistence interface.
//
// -----------------------------------------------------------------------------

/// Defines persistent storage for mobile session restoration.
///
/// The authentication controller persists the refresh token together with the
/// time of the most recent successful online authentication. Access tokens are
/// managed separately in memory.
abstract interface class CredentialStore {
  /// Reads the persisted refresh token, or returns null when absent.
  Future<String?> readRefreshToken();

  /// Persists [refreshToken] for subsequent session restoration.
  Future<void> writeRefreshToken(String refreshToken);

  /// Reads when the session was last successfully authenticated online.
  Future<DateTime?> readLastOnlineAuthAt();

  /// Persists when the session was successfully authenticated online.
  Future<void> writeLastOnlineAuthAt(DateTime authenticatedAt);

  /// Removes all persisted session-restoration data.
  Future<void> clear();
}
