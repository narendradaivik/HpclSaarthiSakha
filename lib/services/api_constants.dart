class ApiConstants {
  // ── Base URLs ──────────────────────────────────────────────────────────────
  static const String functionsBaseUrl =
      'https://zmptycrokdhqifoxglvj.supabase.co/functions/v1';
  static const String restBaseUrl =
      'https://zmptycrokdhqifoxglvj.supabase.co/rest/v1';

  // Keep single baseUrl pointing to functions (used by ApiClient for POST auth)
  static const String baseUrl = functionsBaseUrl;

  // ── Supabase anon key (required for REST table calls) ─────────────────────
  // Replace with your actual anon key from Supabase dashboard → Settings → API
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InptcHR5Y3Jva2RocWlmb3hnbHZqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYxMzk4MjksImV4cCI6MjA4MTcxNTgyOX0.ArRObdf_iyrd7K5dbanamT5UKEuKv0CdGswGQw_BNrA';

  // ── Endpoints ──────────────────────────────────────────────────────────────
  static const String mockOtp = '/mock-otp';
  static const String rewardsCatalog = '/rewards_catalog';
  static const String driverStats   = '/driver-stats';
  static const String driverProfile = '/driver-profile';
  static const String fuelClaimHistory = '/fuel-claim-history';
  static const String extractBill      = '/extract-bill';
  static const String submitFuelClaim  = '/submit-fuel-claim';

  // ── REST table endpoints ───────────────────────────────────────────────────
  static const String outlets = '/outlets';

  // ── Actions ────────────────────────────────────────────────────────────────
  static const String actionSend = 'send';
  static const String actionVerify = 'verify';

  // ── Timeouts ───────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
