import 'api_client.dart';
import 'api_constants.dart';
import 'api_response.dart';
import 'app_settings.dart';
import 'token_store.dart';

// ── Models ─────────────────────────────────────────────────────────────────────

class SendOtpResult {
  final bool success;
  final String message;
  const SendOtpResult({required this.success, required this.message});
}

class VerifyOtpResult {
  final bool   verified;
  final String userId;
  final String driverId;   // ← separate driver UUID
  final String phone;
  final String accessToken;
  final String refreshToken;
  final int    expiresIn;
  final String message;

  const VerifyOtpResult({
    required this.verified,
    required this.userId,
    required this.driverId,
    required this.phone,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.message,
  });

  factory VerifyOtpResult.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResult(
      verified:     json['verified']      as bool?   ?? false,
      userId:       json['user_id']        as String? ?? '',
      driverId:     json['driver_id']      as String? ?? '',
      phone:        json['phone']          as String? ?? '',
      accessToken:  json['access_token']   as String? ?? '',
      refreshToken: json['refresh_token']  as String? ?? '',
      expiresIn:    json['expires_in']     as int?    ?? 3600,
      message:      json['message']        as String? ?? '',
    );
  }
}

// ── AuthService ────────────────────────────────────────────────────────────────

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _client = ApiClient.instance;

  /// Send OTP to driver's phone number.
  Future<ApiResponse<SendOtpResult>> sendOtp(String phone) async {
    final response = await _client.post(
      ApiConstants.mockOtp,
      body: {'action': ApiConstants.actionSend, 'phone': phone},
    );

    if (!response.success) {
      return ApiResponse.error(
        response.errorMessage ?? 'OTP भेजने में समस्या।',
        statusCode: response.statusCode,
      );
    }

    return ApiResponse.ok(
      SendOtpResult(
        success: response.data!['success'] as bool? ?? true,
        message: response.data!['message'] as String? ?? 'OTP भेजा गया।',
      ),
      statusCode: response.statusCode,
    );
  }

  /// Verify OTP entered by user.
  ///
  /// On success:
  /// • Saves access_token, refresh_token, driver_id to TokenStore
  /// • Saves geo settings to AppSettings
  Future<ApiResponse<VerifyOtpResult>> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await _client.post(
      ApiConstants.mockOtp,
      body: {
        'action': ApiConstants.actionVerify,
        'phone': phone,
        'otp': otp,
      },
    );

    if (!response.success) {
      return ApiResponse.error(
        response.errorMessage ?? 'OTP सत्यापन विफल।',
        statusCode: response.statusCode,
      );
    }

    final json   = response.data!;
    final result = VerifyOtpResult.fromJson(json);

    if (!result.verified) {
      return ApiResponse.error(
        'OTP गलत है। दोबारा कोशिश करें।',
        statusCode: response.statusCode,
      );
    }

    // ── Save auth tokens ───────────────────────────────────────────────────
    TokenStore.instance.saveTokens(
      accessToken:  result.accessToken,
      refreshToken: result.refreshToken,
      userId:       result.userId,
      phone:        result.phone,
      driverId:     result.driverId.isNotEmpty ? result.driverId : result.userId,
    );

    // ── Save feature-flag settings ─────────────────────────────────────────
    // settings = { "geo_redemption_enabled": { "value": "false", ... }, ... }
    final settings = json['settings'] as Map<String, dynamic>?;
    AppSettings.instance.loadFromJson(settings);

    return ApiResponse.ok(result, statusCode: response.statusCode);
  }

  void logout() {
    TokenStore.instance.clear();
    AppSettings.instance.reset();
  }
}
