/// App-wide settings loaded from the OTP verify response.
/// Populated once at login and used across all screens.
class AppSettings {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  // ── Geo-fencing ────────────────────────────────────────────────────────────
  /// Whether GPS proximity check is required for REWARD REDEMPTIONS.
  /// Source: settings.geo_redemption_enabled.value == "true"
  bool geoRedemptionEnabled = false;

  /// Whether GPS proximity check is required for FUEL CLAIMS.
  /// Source: settings.geo_claim_enabled.value == "true"
  bool geoClaimEnabled = false;

  /// Max allowed distance in metres from outlet for GPS check.
  /// Source: settings.geo_distance_meters.value (default 100)
  double geoDistanceMeters = 100.0;

  /// Whether fuel claims require outlet-owner approval before auto-verify.
  /// Source: settings.verify_claim_enabled.value == "true"
  bool verifyClaimEnabled = false;

  // ── Parse from OTP verify response ────────────────────────────────────────
  /// Call this with the raw `settings` map from the verify-OTP response:
  /// {
  ///   "geo_redemption_enabled": { "value": "false", ... },
  ///   "geo_claim_enabled":      { "value": "false", ... },
  ///   "geo_distance_meters":    { "value": "100",   ... },
  ///   "verify_claim_enabled":   { "value": "false", ... }
  /// }
  void loadFromJson(Map<String, dynamic>? settings) {
    if (settings == null) return;

    geoRedemptionEnabled = _bool(settings['geo_redemption_enabled']);
    geoClaimEnabled      = _bool(settings['geo_claim_enabled']);
    verifyClaimEnabled   = _bool(settings['verify_claim_enabled']);
    geoDistanceMeters    = _double(settings['geo_distance_meters']) ?? 100.0;
  }

  void reset() {
    geoRedemptionEnabled = false;
    geoClaimEnabled      = false;
    geoDistanceMeters    = 100.0;
    verifyClaimEnabled   = false;
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Each setting is { "value": "true"/"false", "description": "..." }
  static bool _bool(dynamic entry) {
    if (entry == null) return false;
    if (entry is Map) {
      final v = entry['value']?.toString().toLowerCase().trim();
      return v == 'true' || v == '1' || v == 'yes';
    }
    // Fallback: if it's directly a bool or string
    if (entry is bool) return entry;
    return entry.toString().toLowerCase().trim() == 'true';
  }

  static double? _double(dynamic entry) {
    if (entry == null) return null;
    if (entry is Map) {
      final v = entry['value']?.toString().trim();
      return v != null ? double.tryParse(v) : null;
    }
    if (entry is num) return entry.toDouble();
    return double.tryParse(entry.toString().trim());
  }

  @override
  String toString() =>
      'AppSettings(geoRedemption=$geoRedemptionEnabled, '
      'geoClaim=$geoClaimEnabled, distance=${geoDistanceMeters}m, '
      'verifyClaim=$verifyClaimEnabled)';
}
