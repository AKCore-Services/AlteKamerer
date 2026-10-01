// -----------------------------------------------------------------------------
// credential_store.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Defines the persistent credential-storage contract used to restore
//   authenticated sessions.
//
// Contains:
//   - CredentialStore: Refresh-token persistence interface.
//
// -----------------------------------------------------------------------------

/// Defines persistent storage for the mobile refresh token.
///
/// The authentication controller uses this interface to restore sessions
/// across app launches. Access tokens are managed separately in memory.
abstract interface class CredentialStore {
  /// Reads the persisted refresh token, or returns null when absent.
  Future<String?> readRefreshToken();

  /// Persists [refreshToken] for subsequent session restoration.
  Future<void> writeRefreshToken(String refreshToken);

  /// Removes the persisted refresh token.
  Future<void> clear();
}
