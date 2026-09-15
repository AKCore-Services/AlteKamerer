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
