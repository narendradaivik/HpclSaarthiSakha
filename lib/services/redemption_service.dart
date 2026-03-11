import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import 'api_constants.dart';
import 'api_response.dart';
import 'token_store.dart';

// ── Redeem Reward Result ───────────────────────────────────────────────────────

class RedeemRewardResult {
  final String redemptionNumber;
  final String status;
  final String driverName;
  final String rewardName;
  final String rewardNameHi;
  final double volumeDeducted;
  final double remainingVolume;
  final String? deliveryAddress;
  final String? deliveryPhone;
  final DateTime? requestedAt;

  const RedeemRewardResult({
    required this.redemptionNumber,
    required this.status,
    required this.driverName,
    required this.rewardName,
    required this.rewardNameHi,
    required this.volumeDeducted,
    required this.remainingVolume,
    this.deliveryAddress,
    this.deliveryPhone,
    this.requestedAt,
  });

  factory RedeemRewardResult.fromJson(Map<String, dynamic> json) {
    final r = json['redemption'] as Map<String, dynamic>? ?? {};
    return RedeemRewardResult(
      redemptionNumber:
          r['redemption_number'] as String? ??
          json['redemption_number'] as String? ??
          'RDM-000000',
      status: r['status'] as String? ?? 'requested',
      driverName: json['driver_name'] as String? ?? '',
      rewardName: json['reward_name'] as String? ?? '',
      rewardNameHi: json['reward_name_hi'] as String? ?? '',
      volumeDeducted: (json['volume_deducted'] as num?)?.toDouble() ?? 0.0,
      remainingVolume: (json['remaining_volume'] as num?)?.toDouble() ?? 0.0,
      deliveryAddress: r['delivery_address'] as String?,
      deliveryPhone: r['delivery_phone'] as String?,
      requestedAt: r['requested_at'] != null
          ? DateTime.tryParse(r['requested_at'] as String)
          : null,
    );
  }
}

// ── Redemption Model ───────────────────────────────────────────────────────────

class Redemption {
  final String id;
  final String rewardId;
  final String rewardNameHi;
  final String rewardNameEn;
  final int rewardPoints;
  final String status;
  final String? deliveryAddress;
  final String? deliveryPhone;
  final String? redemptionNumber;
  final DateTime? requestedAt;
  final DateTime? updatedAt;

  const Redemption({
    required this.id,
    required this.rewardId,
    required this.rewardNameHi,
    required this.rewardNameEn,
    required this.rewardPoints,
    required this.status,
    this.deliveryAddress,
    this.deliveryPhone,
    this.redemptionNumber,
    this.requestedAt,
    this.updatedAt,
  });

  factory Redemption.fromJson(Map<String, dynamic> json) {
    final reward = json['reward'] as Map<String, dynamic>?;
    return Redemption(
      id: json['id'] as String? ?? '',
      rewardId: json['reward_id'] as String? ?? '',
      rewardNameHi:
          reward?['name_hi'] as String? ??
          json['reward_name_hi'] as String? ??
          reward?['name'] as String? ??
          '—',
      rewardNameEn:
          reward?['name'] as String? ??
          json['reward_name_en'] as String? ??
          '—',
      rewardPoints:
          (reward?['reward_value'] as num?)?.toInt() ??
          (reward?['volume_required'] as num?)?.toInt() ??
          (json['reward_points'] as num?)?.toInt() ??
          0,
      status: json['status'] as String? ?? 'pending',
      deliveryAddress: json['delivery_address'] as String?,
      deliveryPhone: json['delivery_phone'] as String?,
      redemptionNumber: json['redemption_number'] as String?,
      requestedAt: (json['requested_at'] ?? json['created_at']) != null
          ? DateTime.tryParse(
              (json['requested_at'] ?? json['created_at']) as String,
            )
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  bool get isDelivered => status == 'delivered';
  bool get isRejected => status == 'rejected';
  bool get isDispatched => status == 'dispatched';
  bool get isApproved => status == 'approved';

  String get statusHi {
    switch (status) {
      case 'requested':
        return 'चेक किया जा रहा है';
      case 'pending':
        return 'चेक किया जा रहा है';
      case 'approved':
        return 'स्वीकृत';
      case 'dispatched':
        return 'भेजा गया';
      case 'delivered':
        return 'डिलीवर हो गया';
      case 'rejected':
        return 'अस्वीकृत';
      default:
        return status;
    }
  }

  String get iconPath {
    final n = rewardNameEn.toLowerCase();

    // 🔥 Pair of Radial Tyres 1000/20 (CHECK FIRST)
    if (n.contains('pair') && n.contains('tyre')) {
      return 'assets/images/pair-tyres.png';
    }

    // Single Radial Tyre
    if (n.contains('radial') || n.contains('tyre')) {
      return 'assets/images/radial-tyre.png';
    }

    // Torch
    if (n.contains('torch') || n.contains('oil')) {
      return 'assets/images/torch.png';
    }

    // T-Shirt
    if (n.contains('tshirt') || n.contains('t-shirt') || n.contains('shirt')) {
      return 'assets/images/tshirt-new.png';
    }

    // Iron Press
    if (n.contains('iron') || n.contains('press')) {
      return 'assets/images/iron-press.png';
    }

    // Thali Set
    if (n.contains('thali')) {
      return 'assets/images/thali-set.png';
    }

    // Dinner Set
    if (n.contains('dinner')) {
      return 'assets/images/dinner-set.png';
    }

    // Water Jug
    if (n.contains('water') || n.contains('jug')) {
      return 'assets/images/water-jug.png';
    }

    // Table Fan
    if (n.contains('table') && n.contains('fan')) {
      return 'assets/images/table-fan.png';
    }

    // Fan
    if (n.contains('fan')) {
      return 'assets/images/fan.png';
    }

    // Mixer Grinder
    if (n.contains('mixer') || n.contains('grinder')) {
      return 'assets/images/mixer-grinder.png';
    }

    // Smart Watch
    if (n.contains('smart watch') || n.contains('smartwatch')) {
      return 'assets/images/smart-watch.png';
    }

    // Wrist Watch
    if (n.contains('wrist')) {
      return 'assets/images/wrist-watch.png';
    }

    // Smartphone
    if (n.contains('smartphone') ||
        n.contains('mobile') ||
        n.contains('phone')) {
      return 'assets/images/smartphone.png';
    }

    // Refrigerator
    if (n.contains('refrigerator') || n.contains('fridge')) {
      return 'assets/images/refrigerator.png';
    }

    // Air Conditioner
    if (n.contains('air conditioner') || n.contains('ac')) {
      return 'assets/images/air-conditioner.png';
    }

    // Bike
    if (n.contains('bike') || n.contains('wheeler')) {
      return 'assets/images/bike.png';
    }

    // Radio
    if (n.contains('radio')) {
      return 'assets/images/radio.png';
    }

    // Headphones
    if (n.contains('headphone')) {
      return 'assets/images/headphones.png';
    }

    // Pressure Cooker
    if (n.contains('pressure') || n.contains('cooker')) {
      return 'assets/images/pressure-cooker.png';
    }

    // Shopping Voucher
    if (n.contains('voucher') || n.contains('shopping')) {
      return 'assets/images/shopping-voucher.png';
    }

    // Wall Clock
    if (n.contains('clock')) {
      return 'assets/images/wall-clock.png';
    }

    return 'assets/images/default_gift.png';
  }
}

// ── Redemption Service ─────────────────────────────────────────────────────────

class RedemptionService {
  RedemptionService._();
  static final RedemptionService instance = RedemptionService._();

  final _client = ApiClient.instance;

  // ── Redeem a reward ────────────────────────────────────────────────────────
  //
  //  POST /functions/v1/redeem-reward
  //  Body: { driver_id, reward_id, delivery_phone, delivery_address }
  //
  //  Success 200:
  //  { "success": true, "redemption": { "redemption_number", "status", ... },
  //    "driver_name", "reward_name", "reward_name_hi",
  //    "volume_deducted": 10, "remaining_volume": 185.89 }
  //
  //  Error 400:
  //  { "error": "Insufficient redeemable volume", "available": 0.33, "required": 10 }
  //
  //  On 400: returns ApiResponse.error with errorCode="INSUFFICIENT_VOLUME"
  //          and errorData = { "available": 0.33, "required": 10, "error": "..." }
  //          so the UI can show a rich dialog.

  Future<ApiResponse<RedeemRewardResult>> redeemReward({
    required String rewardId,
    required String deliveryPhone,
    required String deliveryAddress,
  }) async {
    final driverId = TokenStore.instance.driverId;
    if (driverId == null) {
      return ApiResponse.error('Driver ID नहीं मिला। कृपया लॉगिन करें।');
    }

    try {
      final uri = Uri.parse('${ApiConstants.functionsBaseUrl}/redeem-reward');

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'apikey': ApiConstants.anonKey,
              'Authorization':
                  'Bearer ${TokenStore.instance.accessToken ?? ApiConstants.anonKey}',
            },
            body: jsonEncode({
              'driver_id': driverId,
              'reward_id': rewardId,
              'delivery_phone': deliveryPhone,
              'delivery_address': deliveryAddress,
            }),
          )
          .timeout(const Duration(seconds: 30));

      print(response.body);

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (json['success'] == false) {
          return ApiResponse.error(
            json['message'] as String? ?? 'रिडीम नहीं हो सका।',
            statusCode: response.statusCode,
            errorData: json,
          );
        }
        return ApiResponse.ok(
          RedeemRewardResult.fromJson(json),
          statusCode: response.statusCode,
        );
      }

      // ── 400 / other error ──────────────────────────────────────────────────
      // Parse available / required from error body
      final errorMsg =
          json['error'] as String? ??
          json['message'] as String? ??
          'रिडीम नहीं हो सका (${response.statusCode})।';
      final available = (json['available'] as num?)?.toDouble();
      final required_ = (json['required'] as num?)?.toDouble();

      // Determine a machine-readable code
      String errorCode = 'REDEEM_ERROR';
      if (available != null && required_ != null) {
        errorCode = 'INSUFFICIENT_VOLUME';
      }

      return ApiResponse.error(
        errorMsg,
        statusCode: response.statusCode,
        errorCode: errorCode,
        errorData: {
          ...json,
          if (available != null) 'available': available,
          if (required_ != null) 'required': required_,
        },
      );
    } on SocketException {
      return ApiResponse.error('इंटरनेट कनेक्शन नहीं है। कृपया जाँचें।');
    } catch (e) {
      return ApiResponse.error('कुछ गलत हो गया: $e');
    }
  }

  // ── Fetch redemption history ───────────────────────────────────────────────
  //
  //  GET /rest/v1/redemptions
  //    ?select=*,reward:rewards_catalog(name,name_hi,reward_value,reward_type),
  //            driver:drivers(name,phone,truck_number)
  //    &order=requested_at.desc&limit=20
  //
  //  Each item:
  //  { id, driver_id, reward_id, status, redemption_number,
  //    delivery_address, delivery_phone, requested_at,
  //    reward: { name, name_hi, reward_value: 10, reward_type: "gift" },
  //    driver: { name, phone, truck_number } }

  Future<ApiResponse<List<Redemption>>> fetchMyRedemptions({
    int limit = 20,
  }) async {
    final response = await _client.getList(
      '/redemptions',
      queryParams: {
        'select':
            '*,reward:rewards_catalog(name,name_hi,reward_value,reward_type),driver:drivers(name,phone,truck_number)',
        'order': 'requested_at.desc',
        'limit': '$limit',
      },
    );
    print(response);

    if (!response.success) {
      return ApiResponse.error(
        response.errorMessage ?? 'रिडेम्पशन हिस्ट्री लोड नहीं हो सकी।',
        statusCode: response.statusCode,
      );
    }

    return ApiResponse.ok(
      (response.data ?? []).map(Redemption.fromJson).toList(),
      statusCode: response.statusCode,
    );
  }
}
