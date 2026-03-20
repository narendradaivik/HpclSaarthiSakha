import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_constants.dart';
import 'api_response.dart';
import 'token_store.dart';

// ── Bill Extract Result ────────────────────────────────────────────────────────
// Matches the actual /extract-bill response:
// {
//   "success": true,
//   "invoice_url": "https://..."       ← TOP LEVEL
//   "data": {
//     "fuel_type", "quantity_liters", "rate_per_liter", "total_amount",
//     "outlet_name", "date", "vehicle_number", "bill_number",
//     "is_hpcl",             ← bool
//     "outlet_id",           ← UUID of matched HPCL outlet
//     "matched_outlet_name"  ← canonical outlet name from DB
//   }
// }

class BillExtractResult {
  final String fuelType;
  final double quantity;
  final double ratePerLitre;
  final double totalAmount;
  final String outlet; // raw outlet name from bill OCR
  final String date;
  final String vehicleNumber;
  final String billNumber;
  final int points;

  /// Whether this bill is from a genuine HPCL outlet (from data.is_hpcl)
  final bool isHpcl;

  /// UUID of the matched HPCL outlet — use this as outlet_id in submitClaim
  final String? outletId;

  /// Canonical outlet name matched from the HPCL database
  final String? matchedOutletName;

  /// Public URL of the uploaded bill image (top-level invoice_url)
  final String? invoiceUrl;

  const BillExtractResult({
    required this.fuelType,
    required this.quantity,
    required this.ratePerLitre,
    required this.totalAmount,
    required this.outlet,
    required this.date,
    required this.vehicleNumber,
    required this.billNumber,
    required this.points,
    this.isHpcl = true,
    this.outletId,
    this.matchedOutletName,
    this.invoiceUrl,
  });

  /// Parse the full /extract-bill JSON response.
  factory BillExtractResult.fromJson(Map<String, dynamic> raw) {
    // invoice_url lives at TOP LEVEL (not inside data)
    final invoiceUrl = _str(raw['invoice_url']);

    // All bill fields are inside raw['data']
    final d = raw['data'] is Map<String, dynamic>
        ? raw['data'] as Map<String, dynamic>
        : <String, dynamic>{};

    final qty = _num(d['quantity_liters']) ?? _num(d['quantity']) ?? 0.0;
    final rate = _num(d['rate_per_liter']) ?? _num(d['rate']) ?? 0.0;
    final total = _num(d['total_amount']) ?? _num(d['total']) ?? 0.0;
    final pts = _numInt(d['points']) ?? qty.round();

    final fuel = _str(d['fuel_type']) ?? _str(d['fuelType']) ?? 'डीज़ल';
    final outletName = _str(d['outlet_name']) ?? _str(d['outlet']) ?? '';
    final dateStr = _str(d['date']) ?? _str(d['bill_date']) ?? '';
    final vehicle = _str(d['vehicle_number']) ?? _str(d['vehicle_no']) ?? '';
    final billNo = _str(d['bill_number']) ?? _str(d['invoice_number']) ?? '';

    // is_hpcl — bool from data, defaults to true if missing
    final isHpcl = d['is_hpcl'] as bool? ?? true;

    // outlet_id and matched_outlet_name — from data
    final outletId = _str(d['outlet_id']);
    final matchedOutletName = _str(d['matched_outlet_name']);

    return BillExtractResult(
      fuelType: fuel,
      quantity: qty,
      ratePerLitre: rate,
      totalAmount: total,
      outlet: outletName,
      date: dateStr,
      vehicleNumber: vehicle,
      billNumber: billNo,
      points: pts,
      isHpcl: isHpcl,
      outletId: outletId,
      matchedOutletName: matchedOutletName,
      invoiceUrl: invoiceUrl,
    );
  }

  BillExtractResult copyWith({
    String? fuelType,
    double? quantity,
    double? ratePerLitre,
    double? totalAmount,
    String? outlet,
    String? date,
    String? vehicleNumber,
    String? billNumber,
    int? points,
    bool? isHpcl,
    String? outletId,
    String? matchedOutletName,
    String? invoiceUrl,
  }) {
    return BillExtractResult(
      fuelType: fuelType ?? this.fuelType,
      quantity: quantity ?? this.quantity,
      ratePerLitre: ratePerLitre ?? this.ratePerLitre,
      totalAmount: totalAmount ?? this.totalAmount,
      outlet: outlet ?? this.outlet,
      date: date ?? this.date,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      billNumber: billNumber ?? this.billNumber,
      points: points ?? this.points,
      isHpcl: isHpcl ?? this.isHpcl,
      outletId: outletId ?? this.outletId,
      matchedOutletName: matchedOutletName ?? this.matchedOutletName,
      invoiceUrl: invoiceUrl ?? this.invoiceUrl,
    );
  }

  // ── Private parse helpers ─────────────────────────────────────────────────
  static double? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', ''));
    return null;
  }

  static int? _numInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v.replaceAll(',', ''));
    return null;
  }

  static String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  // ── Display helpers ───────────────────────────────────────────────────────
  String get quantityFormatted => '${quantity.toStringAsFixed(2)} लीटर';
  String get rateFormatted => '₹${ratePerLitre.toStringAsFixed(2)}';
  String get totalFormatted => '₹${totalAmount.toStringAsFixed(1)}';

  /// Best outlet name to display: matched DB name > raw OCR name
  String get displayOutletName => matchedOutletName ?? outlet;
}

// ── Bill Service ──────────────────────────────────────────────────────────────

class BillService {
  BillService._();
  static final BillService instance = BillService._();

  // ── 1. Extract bill via Gemini AI OCR ────────────────────────────────────
  Future<ApiResponse<BillExtractResult>> extractBill(
    File imageFile,
    String driverId, {
    double? driverLat,
    double? driverLng,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final uri = Uri.parse('${ApiConstants.functionsBaseUrl}/extract-bill');

      final body = <String, dynamic>{
        'imageBase64': base64Image,
        'driver_id': driverId,
        if (driverLat != null) 'driver_lat': driverLat,
        if (driverLng != null) 'driver_lng': driverLng,
      };

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'apikey': ApiConstants.anonKey,
              'Authorization':
                  'Bearer ${TokenStore.instance.accessToken ?? ApiConstants.anonKey}',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200 || response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final isSuccess = json['success'] as bool? ?? false;

        if (!isSuccess) {
          // NOT_HPCL or other rejection — parse whatever data came back
          return ApiResponse(
            success: false,
            data: BillExtractResult.fromJson(json),
            errorMessage:
                json['error'] as String? ??
                json['message'] as String? ??
                'बिल स्वीकार नहीं हुआ।',
            errorCode: json['error_code'] as String?,
            statusCode: response.statusCode,
          );
        }

        return ApiResponse.ok(
          BillExtractResult.fromJson(json),
          statusCode: response.statusCode,
        );
      } else {
        String msg = 'कुछ गड़बड़ हुई (${response.statusCode})।';
        try {
          final err = jsonDecode(response.body);
          if (err is Map) {
            msg = (err['error'] ?? err['message'] ?? err['msg'] ?? msg)
                .toString();
          }
        } catch (_) {}
        return ApiResponse.error(msg, statusCode: response.statusCode);
      }
    } on SocketException {
      return ApiResponse.error('इंटरनेट कनेक्शन नहीं है। कृपया जाँचें।');
    } on HttpException catch (e) {
      return ApiResponse.error('HTTP Error: ${e.message}');
    } catch (e) {
      return ApiResponse.error('कुछ गलत हो गया: $e');
    }
  }

  // ── 2. Submit fuel claim ──────────────────────────────────────────────────
  //  POST /functions/v1/submit-claim
  //  Body: { driver_id, outlet_id, quantity, invoice_url | invoice_image_base64 }
  //
  //  outlet_id comes from BillExtractResult.outletId (matched by the API).
  //  Falls back to UserSession.selectedOutletId if outletId is null.
  Future<ApiResponse<Map<String, dynamic>>> submitClaim({
    required BillExtractResult bill,
    required String outletId,
    required String? imageBase64,
    double? driverLat,
    double? driverLng,
  }) async {
    try {
      final driverId = TokenStore.instance.driverId;
      if (driverId == null) {
        return ApiResponse.error('Driver ID नहीं मिला। कृपया लॉगिन करें।');
      }

      final body = <String, dynamic>{
        'driver_id': driverId,
        'outlet_id': outletId,
        'quantity': bill.quantity,
        'receipt_number': bill.billNumber,
        // Prefer invoice_url — image already uploaded by extract-bill
        if (bill.invoiceUrl != null) 'invoice_url': bill.invoiceUrl,
        if (imageBase64 != null) 'invoice_image_base64': imageBase64,
        // Driver GPS — only included when available
        if (driverLat != null) 'driver_lat': driverLat,
        if (driverLng != null) 'driver_lng': driverLng,
      };
      // ignore: avoid_print

      debugPrint(jsonEncode(body));

      final uri = Uri.parse('${ApiConstants.functionsBaseUrl}/submit-claim');

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'apikey': ApiConstants.anonKey,
              'Authorization':
                  'Bearer ${TokenStore.instance.accessToken ?? ApiConstants.anonKey}',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.ok(
          jsonDecode(response.body) as Map<String, dynamic>,
          statusCode: response.statusCode,
        );
      } else {
        String msg = 'क्लेम सबमिट नहीं हो सका (${response.statusCode})।';
        try {
          final err = jsonDecode(response.body);
          if (err is Map) {
            msg = (err['error'] ?? err['message'] ?? err['msg'] ?? msg)
                .toString();
          }
        } catch (_) {}
        return ApiResponse.error(msg, statusCode: response.statusCode);
      }
    } on SocketException {
      return ApiResponse.error('इंटरनेट कनेक्शन नहीं है। कृपया जाँचें।');
    } catch (e) {
      return ApiResponse.error('कुछ गलत हो गया: $e');
    }
  }
}
