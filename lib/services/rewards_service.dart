import 'api_client.dart';
import 'api_constants.dart';
import 'api_response.dart';

// ── Model ─────────────────────────────────────────────────────────────

class RewardItem {
  final String id;
  final String name;
  final String nameHi;
  final String? description;
  final String? descriptionHi;
  final int volumeRequired; // litres required
  final int rewardValue; // points cost
  final String rewardType;
  final String? imageUrl;
  final bool isActive;
  final DateTime? createdAt;

  const RewardItem({
    required this.id,
    required this.name,
    required this.nameHi,
    this.description,
    this.descriptionHi,
    required this.volumeRequired,
    required this.rewardValue,
    required this.rewardType,
    this.imageUrl,
    required this.isActive,
    this.createdAt,
  });

  factory RewardItem.fromJson(Map<String, dynamic> json) {
    return RewardItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameHi: json['name_hi'] as String? ?? json['name'] as String? ?? '',
      description: json['description'] as String?,
      descriptionHi: json['description_hi'] as String?,
      volumeRequired: (json['volume_required'] as num?)?.toInt() ?? 0,
      rewardValue: (json['reward_value'] as num?)?.toInt() ?? 0,
      rewardType: json['reward_type'] as String? ?? 'gift',
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  /// 🔥 Returns local asset image path
  String get iconPath {
    final n = name.toLowerCase();

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

  /// Convert to Map for dashboard
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'name_hi': nameHi,
    'points': volumeRequired,
    'reward_value': rewardValue,
    'icon': iconPath, // ✅ FIXED (string value)
    'volume_required': volumeRequired,
    'reward_type': rewardType,
    'image_url': imageUrl,
  };
}

// ── Service ───────────────────────────────────────────────────────────

class RewardsService {
  RewardsService._();
  static final RewardsService instance = RewardsService._();

  final _client = ApiClient.instance;

  Future<ApiResponse<List<RewardItem>>> fetchCatalog({int limit = 50}) async {
    final response = await _client.getList(
      ApiConstants.rewardsCatalog,
      queryParams: {
        'select': '*',
        'limit': '$limit',
        'is_active': 'eq.true',
        'order': 'reward_value.asc',
      },
    );

    if (!response.success) {
      return ApiResponse.error(
        response.errorMessage ?? 'रिवॉर्ड्स लोड नहीं हो सके।',
        statusCode: response.statusCode,
      );
    }

    final items = (response.data ?? [])
        .map((json) => RewardItem.fromJson(json))
        .toList();

    return ApiResponse.ok(items, statusCode: response.statusCode);
  }
}
