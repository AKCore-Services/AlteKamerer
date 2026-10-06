// -----------------------------------------------------------------------------
// secure_credential_store.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Persists refresh tokens and recent online-auth timestamps using platform
//   secure storage, and removes credentials from the earlier storage model.
//
// Contains:
//   - SecureCredentialStore: Secure implementation of CredentialStore.
//
// -----------------------------------------------------------------------------

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'credential_store.dart';

/// Stores mobile session-restoration data in platform secure storage.
///
/// Removes the legacy persisted access token during credential operations.
class SecureCredentialStore implements CredentialStore {
  SecureCredentialStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _refreshTokenKey = 'mobile_refresh_token';
  static const _lastOnlineAuthAtKey = 'mobile_last_online_auth_at';

  // ALTEKAMERE-7 temporarily persisted access tokens. Remove any such
  // credential when the new refresh-only model touches secure storage.
  static const _legacyAccessTokenKey = 'mobile_access_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readRefreshToken() async {
    await _storage.delete(key: _legacyAccessTokenKey);

    final refreshToken = await _storage.read(key: _refreshTokenKey);

    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    return refreshToken;
  }

  @override
  Future<void> writeRefreshToken(String refreshToken) async {
    await _storage.delete(key: _legacyAccessTokenKey);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  @override
  Future<DateTime?> readLastOnlineAuthAt() async {
    final source = await _storage.read(key: _lastOnlineAuthAtKey);

    if (source == null || source.isEmpty) {
      return null;
    }

    return DateTime.tryParse(source)?.toUtc();
  }

  @override
  Future<void> writeLastOnlineAuthAt(DateTime authenticatedAt) async {
    await _storage.write(
      key: _lastOnlineAuthAtKey,
      value: authenticatedAt.toUtc().toIso8601String(),
    );
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _legacyAccessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _lastOnlineAuthAtKey);
  }
}
