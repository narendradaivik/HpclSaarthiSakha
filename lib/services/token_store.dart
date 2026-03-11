/// In-memory token store.
/// Replace with flutter_secure_storage for production.
class TokenStore {
  TokenStore._();
  static final TokenStore instance = TokenStore._();

  String? _accessToken;
  String? _refreshToken;
  String? _userId;
  String? _driverId;
  String? _phone;

  // ── Getters ────────────────────────────────────────────────────────────────
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get userId => _userId;
  String? get driverId => _driverId;
  String? get phone => _phone;
  bool get hasToken => _accessToken != null && _accessToken!.isNotEmpty;

  // ── Setters ────────────────────────────────────────────────────────────────
  void saveTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String driverId,
    required String phone,
  }) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _userId = userId;
    _driverId = driverId;
    _phone = phone;
  }

  void clear() {
    _accessToken = null;
    _refreshToken = null;
    _userId = null;
    _driverId = null;
    _phone = null;
  }

  // ── Auth header ────────────────────────────────────────────────────────────
  Map<String, String> get authHeader =>
      hasToken ? {'Authorization': 'Bearer $_accessToken'} : {};
}
