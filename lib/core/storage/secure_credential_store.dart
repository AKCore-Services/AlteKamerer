import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'credential_store.dart';

class SecureCredentialStore implements CredentialStore {
  SecureCredentialStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _refreshTokenKey = 'mobile_refresh_token';

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
  Future<void> clear() async {
    await _storage.delete(key: _legacyAccessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
