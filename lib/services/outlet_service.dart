import 'api_client.dart';
import 'api_response.dart';

// ── Model ──────────────────────────────────────────────────────────────────────

class Outlet {
  final String id;
  final String name;
  final String? highway;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? phone;
  final String? sapCode;
  final String? district;
  final String? contactPerson;
  final String? contactEmail;
  final bool isActive;

  const Outlet({
    required this.id,
    required this.name,
    this.highway,
    this.latitude,
    this.longitude,
    this.address,
    this.phone,
    this.sapCode,
    this.district,
    this.contactPerson,
    this.contactEmail,
    this.isActive = true,
  });

  factory Outlet.fromJson(Map<String, dynamic> json) {
    return Outlet(
      id:            json['id'] as String? ?? '',
      name:          json['name'] as String? ?? '',
      highway:       json['highway'] as String?,
      latitude:      (json['latitude'] as num?)?.toDouble(),
      longitude:     (json['longitude'] as num?)?.toDouble(),
      address:       json['address'] as String?,
      phone:         json['phone'] as String?,
      sapCode:       json['sap_code'] as String?,
      district:      json['district'] as String?,
      contactPerson: json['contact_person'] as String?,
      contactEmail:  json['contact_email'] as String?,
      isActive:      json['is_active'] as bool? ?? true,
    );
  }

  /// Short address — first ~30 chars of address field
  String get shortAddress {
    if (address == null || address!.isEmpty) return '';
    return address!.length > 32 ? '${address!.substring(0, 32)}...' : address!;
  }

  /// Highway + district label  e.g. "NH19, AGRA"
  String get highwayDistrict {
    final parts = <String>[];
    if (highway != null && highway!.isNotEmpty) parts.add(highway!);
    if (district != null && district!.isNotEmpty) parts.add(district!);
    return parts.join(', ');
  }

  /// Convert to the map format expected by RedeemConfirmScreen
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'highway': highway ?? '',
        'km': '',
        'lat': latitude,
        'lng': longitude,
        'address': address,
        'phone': phone,
        'district': district,
      };
}

// ── Service ───────────────────────────────────────────────────────────────────

class OutletService {
  OutletService._();
  static final OutletService instance = OutletService._();

  final _client = ApiClient.instance;

  /// GET /rest/v1/outlets?select=*&limit=50&is_active=eq.true
  Future<ApiResponse<List<Outlet>>> fetchOutlets({int limit = 50}) async {
    final response = await _client.getList(
      '/outlets',
      queryParams: {
        'select': '*',
        'limit': '$limit',
        'is_active': 'eq.true',
        'order': 'name.asc',
      },
    );

    if (!response.success) {
      return ApiResponse.error(
        response.errorMessage ?? 'आउटलेट लोड नहीं हो सके।',
        statusCode: response.statusCode,
      );
    }

    final items = (response.data ?? [])
        .map((json) => Outlet.fromJson(json))
        .toList();

    return ApiResponse.ok(items, statusCode: response.statusCode);
  }
}
