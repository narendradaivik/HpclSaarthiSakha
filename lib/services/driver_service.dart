import 'api_client.dart';
import 'api_constants.dart';
import 'api_response.dart';

// ── Driver Stats Model ─────────────────────────────────────────────────────────

class DriverStats {
  final String driverId;
  final String? name;
  final String phone;
  final String? truckNumber;
  final double totalLitersFueled;
  final double totalLitersAllClaims;
  final double pendingLiters;
  final double redeemableLiters;
  final int totalTransactions;
  final int verifiedTransactions;
  final int currentLevel;
  final DateTime? memberSince;

  const DriverStats({
    required this.driverId,
    this.name,
    required this.phone,
    this.truckNumber,
    required this.totalLitersFueled,
    required this.totalLitersAllClaims,
    required this.pendingLiters,
    required this.redeemableLiters,
    required this.totalTransactions,
    required this.verifiedTransactions,
    required this.currentLevel,
    this.memberSince,
  });

  factory DriverStats.fromJson(Map<String, dynamic> json) {
    return DriverStats(
      driverId: json['driver_id'] as String? ?? '',
      name: json['name'] as String?,
      phone: json['phone'] as String? ?? '',
      truckNumber: json['truck_number'] as String?,
      totalLitersFueled: (json['total_liters_fueled'] as num?)?.toDouble() ?? 0,
      totalLitersAllClaims:
          (json['total_liters_all_claims'] as num?)?.toDouble() ?? 0,
      pendingLiters: (json['pending_liters'] as num?)?.toDouble() ?? 0,
      redeemableLiters: (json['redeemable_liters'] as num?)?.toDouble() ?? 0,
      totalTransactions: (json['total_transactions'] as num?)?.toInt() ?? 0,
      verifiedTransactions:
          (json['verified_transactions'] as num?)?.toInt() ?? 0,
      currentLevel: (json['current_level'] as num?)?.toInt() ?? 1,
      memberSince: json['member_since'] != null
          ? DateTime.tryParse(json['member_since'] as String)
          : null,
    );
  }

  String get levelLabel {
    switch (currentLevel) {
      case 1:
        return 'Level 1 — ब्रॉन्ज़';
      case 2:
        return 'Level 2 — सिल्वर';
      case 3:
        return 'Level 3 — गोल्ड';
      default:
        return 'Level $currentLevel';
    }
  }

  String get memberSinceFormatted {
    if (memberSince == null) return '—';
    return '${memberSince!.day}/${memberSince!.month}/${memberSince!.year}';
  }
}

// ── Fuel Claim Models ──────────────────────────────────────────────────────────

class FuelClaimSummary {
  final int totalClaims;
  final double totalLitersClaimed;
  final double verifiedLiters;

  const FuelClaimSummary({
    required this.totalClaims,
    required this.totalLitersClaimed,
    required this.verifiedLiters,
  });

  factory FuelClaimSummary.fromJson(Map<String, dynamic> json) {
    return FuelClaimSummary(
      totalClaims: (json['total_claims'] as num?)?.toInt() ?? 0,
      totalLitersClaimed:
          (json['total_liters_claimed'] as num?)?.toDouble() ?? 0,
      verifiedLiters: (json['verified_liters'] as num?)?.toDouble() ?? 0,
    );
  }
}

class FuelClaim {
  final String id;
  final double liters;
  final double? ratePerLiter;
  final double? totalAmount;
  final String status; // pending / verified / rejected
  final String? outletName; // derived from nested outlet object
  final String? outletHighway;
  final String? outletDistrict;
  final String? outletAddress;
  final String? fuelType;
  final String? billNumber;
  final String? vehicleNumber;
  final String? invoiceUrl;
  final DateTime? claimDate;

  const FuelClaim({
    required this.id,
    required this.liters,
    this.ratePerLiter,
    this.totalAmount,
    required this.status,
    this.outletName,
    this.outletHighway,
    this.outletDistrict,
    this.outletAddress,
    this.fuelType,
    this.billNumber,
    this.vehicleNumber,
    this.invoiceUrl,
    this.claimDate,
  });

  factory FuelClaim.fromJson(Map<String, dynamic> json) {
    // Outlet is a nested object: { name, highway, district, address }
    final outlet = json['outlet'] as Map<String, dynamic>?;

    return FuelClaim(
      id: json['id'] as String? ?? '',
      // API uses quantity_liters; fall back to liters for compatibility
      liters:
          (json['quantity_liters'] as num?)?.toDouble() ??
          (json['liters'] as num?)?.toDouble() ??
          0,
      ratePerLiter: (json['rate_per_liter'] as num?)?.toDouble(),
      totalAmount: (json['total_amount'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'pending',
      // Outlet fields — from nested object first, then flat fallbacks
      outletName:
          outlet?['name'] as String? ??
          outlet?['outlet_name'] as String? ??
          json['outlet_name'] as String?,
      outletHighway: outlet?['highway'] as String?,
      outletDistrict: outlet?['district'] as String?,
      outletAddress: outlet?['address'] as String?,
      fuelType: json['fuel_type'] as String?,
      billNumber: json['bill_number'] as String?,
      vehicleNumber: json['vehicle_number'] as String?,
      invoiceUrl: json['invoice_url'] as String?,
      // API uses created_at; fall back to claim_date
      claimDate: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : json['claim_date'] != null
          ? DateTime.tryParse(json['claim_date'] as String)
          : null,
    );
  }

  /// e.g. "RAJ AUTOMOBILES • NH19"
  String get outletDisplayName {
    final parts = <String>[];
    if (outletName != null) parts.add(outletName!);
    if (outletHighway != null) parts.add(outletHighway!);
    return parts.join(' • ');
  }

  String get statusHi {
    switch (status) {
      case 'verified':
        return 'सत्यापित';
      case 'pending':
        return 'लंबित';
      case 'rejected':
        return 'अस्वीकृत';
      default:
        return status;
    }
  }

  String get dateFormatted {
    if (claimDate == null) return '—';
    return '${claimDate!.day}/${claimDate!.month}/${claimDate!.year}';
  }
}

class FuelClaimHistoryResult {
  final String driverId;
  final FuelClaimSummary summary;
  final List<FuelClaim> claims;
  final int total;
  final int returned;

  const FuelClaimHistoryResult({
    required this.driverId,
    required this.summary,
    required this.claims,
    required this.total,
    required this.returned,
  });

  bool get isEmpty => claims.isEmpty;
}

// ── Driver Service ─────────────────────────────────────────────────────────────

class DriverService {
  DriverService._();
  static final DriverService instance = DriverService._();

  final _client = ApiClient.instance;

  /// GET /driver-stats
  /// Returns driver's total liters, redeemable liters, transactions, level.
  /// Requires Bearer token (set after OTP verify).
  Future<ApiResponse<DriverStats>> fetchDriverStats() async {
    final response = await _client.get(
      ApiConstants.driverStats,
      useRestBase: false,
    );

    if (!response.success) {
      return ApiResponse.error(
        response.errorMessage ?? 'ड्राइवर डेटा लोड नहीं हो सका।',
        statusCode: response.statusCode,
      );
    }

    // Response: { success: true, data: { driver_id, name, ... } }
    final data = response.data!['data'] as Map<String, dynamic>?;
    if (data == null) {
      return ApiResponse.error('Invalid driver stats response');
    }

    return ApiResponse.ok(
      DriverStats.fromJson(data),
      statusCode: response.statusCode,
    );
  }

  /// GET /fuel-claim-history?select=*&limit=10
  /// Returns driver's fuel claim history with outlet details.
  /// Requires Bearer token.
  Future<ApiResponse<FuelClaimHistoryResult>> fetchFuelClaimHistory({
    int limit = 10,
    int offset = 0,
  }) async {
    final response = await _client.get(
      ApiConstants.fuelClaimHistory,
      queryParams: {'select': '*', 'limit': '$limit', 'offset': '$offset'},
      useRestBase: false,
    );
    print(response);
    if (!response.success) {
      return ApiResponse.error(
        response.errorMessage ?? 'फ्यूल हिस्ट्री लोड नहीं हो सकी।',
        statusCode: response.statusCode,
      );
    }

    final json = response.data!;
    final summaryJson = json['summary'] as Map<String, dynamic>? ?? {};
    final paginationJson = json['pagination'] as Map<String, dynamic>? ?? {};
    final dataList = json['data'] as List<dynamic>? ?? [];

    final result = FuelClaimHistoryResult(
      driverId: json['driver_id'] as String? ?? '',
      summary: FuelClaimSummary.fromJson(summaryJson),
      claims: dataList
          .whereType<Map<String, dynamic>>()
          .map(FuelClaim.fromJson)
          .toList(),
      total: (paginationJson['limit'] as num?)?.toInt() ?? limit,
      returned: (paginationJson['returned'] as num?)?.toInt() ?? 0,
    );

    return ApiResponse.ok(result, statusCode: response.statusCode);
  }
}

// ── Driver Profile (full) ─────────────────────────────────────────────────────
// Response: { success, data: { driver:{}, vehicles:[], ledger:[], redemptions:[] } }

class DriverVehicle {
  final String id;
  final String
  vehicleNumber; // API may return as int (e.g. 4792) — always toString'd
  final String? vehicleType;
  final bool isPrimary;
  final DateTime? addedAt;

  const DriverVehicle({
    required this.id,
    required this.vehicleNumber,
    this.vehicleType,
    this.isPrimary = false,
    this.addedAt,
  });

  factory DriverVehicle.fromJson(Map<String, dynamic> j) => DriverVehicle(
    id: j['id'] as String? ?? '',
    // vehicle_number can be int or string from the API
    vehicleNumber: j['vehicle_number']?.toString() ?? '',
    vehicleType: j['vehicle_type'] as String?,
    isPrimary: j['is_primary'] as bool? ?? false,
    // API uses 'added_at', fallback to 'created_at'
    addedAt: (j['added_at'] ?? j['created_at']) != null
        ? DateTime.tryParse((j['added_at'] ?? j['created_at']).toString())
        : null,
  );
}

class LedgerEntry {
  final String id;

  /// Raw entry_type from API: 'credit_fuel' | 'debit_redeem' (or legacy 'credit'|'debit')
  final String entryType;

  /// Signed amount from API — positive for credits, negative for debits
  final double amount;

  /// Absolute liters (always positive)
  double get liters => amount.abs();

  /// Balance after this transaction (directly from API's balance_after)
  final double balanceAfter;
  final String description;
  final DateTime? createdAt;
  final String? referenceId;

  const LedgerEntry({
    required this.id,
    required this.entryType,
    required this.amount,
    required this.balanceAfter,
    required this.description,
    this.createdAt,
    this.referenceId,
  });

  /// True for any credit entry (fuel claim etc.)
  bool get isCredit => entryType.startsWith('credit') || amount > 0;

  factory LedgerEntry.fromJson(Map<String, dynamic> j) {
    final rawAmount = (j['amount'] as num?)?.toDouble() ?? 0;
    return LedgerEntry(
      id: j['id'] as String? ?? '',
      entryType:
          j['entry_type'] as String? ??
          (rawAmount >= 0 ? 'credit_fuel' : 'debit_redeem'),
      amount: rawAmount,
      balanceAfter: (j['balance_after'] as num?)?.toDouble() ?? 0,
      description: j['description'] as String? ?? j['notes'] as String? ?? '',
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'] as String)
          : null,
      referenceId: j['reference_id'] as String?,
    );
  }
}

class DriverProfile {
  final DriverStats driver;
  final List<DriverVehicle> vehicles;
  final List<LedgerEntry> ledger;

  const DriverProfile({
    required this.driver,
    required this.vehicles,
    required this.ledger,
  });
}

extension DriverServiceProfile on DriverService {
  Future<ApiResponse<DriverProfile>> fetchDriverProfile() async {
    final response = await _client.get(
      ApiConstants.driverProfile,
      useRestBase: false,
    );

    if (!response.success) {
      return ApiResponse.error(
        response.errorMessage ?? 'प्रोफ़ाइल लोड नहीं हो सकी।',
        statusCode: response.statusCode,
      );
    }

    final data = response.data!['data'] as Map<String, dynamic>?;
    if (data == null) return ApiResponse.error('Invalid profile response');

    final driverJson = data['driver'] as Map<String, dynamic>? ?? {};
    final vehiclesJson = data['vehicles'] as List<dynamic>? ?? [];
    final ledgerJson = data['ledger'] as List<dynamic>? ?? [];

    // Map driver json field names from driver-profile API
    // driver-profile returns: total_volume, redeemable_volume, total_transactions etc.
    final mappedDriver = <String, dynamic>{
      'driver_id': driverJson['id'],
      'name': driverJson['name'],
      'phone': driverJson['phone'],
      'truck_number': driverJson['truck_number'],
      'total_liters_fueled':
          (driverJson['total_volume'] ??
          driverJson['total_liters_fueled'] ??
          0),
      'total_liters_all_claims':
          (driverJson['total_liters_all_claims'] ??
          driverJson['total_volume'] ??
          0),
      'pending_liters': (driverJson['pending_liters'] ?? 0),
      'redeemable_liters':
          (driverJson['redeemable_volume'] ??
          driverJson['redeemable_liters'] ??
          0),
      'total_transactions': (driverJson['total_transactions'] ?? 0),
      'verified_transactions': (driverJson['verified_transactions'] ?? 0),
      'current_level': (driverJson['current_level'] ?? 1),
      'member_since': driverJson['member_since'],
    };

    return ApiResponse.ok(
      DriverProfile(
        driver: DriverStats.fromJson(mappedDriver),
        vehicles: vehiclesJson
            .map((v) => DriverVehicle.fromJson(v as Map<String, dynamic>))
            .toList(),
        ledger: ledgerJson
            .map((l) => LedgerEntry.fromJson(l as Map<String, dynamic>))
            .toList(),
      ),
      statusCode: response.statusCode,
    );
  }
}
