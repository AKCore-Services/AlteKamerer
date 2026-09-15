abstract interface class CredentialStore {
  Future<String?> readRefreshToken();

  Future<void> writeRefreshToken(String refreshToken);

  Future<void> clear();
}
