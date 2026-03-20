import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:highway_rewards/model/outlet.dart';
import 'package:http/http.dart' as http;

import '../services/api_client.dart';
import '../services/api_response.dart';
import '../services/api_constants.dart';
import '../services/token_store.dart';

class OutletService {
  OutletService._();
  static final OutletService instance = OutletService._();

  /// Fetches all active HPCL outlets from the Supabase REST `outlets` table.
  Future<ApiResponse<List<Outlet>>> fetchOutlets({
    String? highway,
    bool activeOnly = true,
  }) async {
    final queryParams = <String, String>{'select': '*', 'order': 'name.asc'};
    if (activeOnly) queryParams['is_active'] = 'eq.true';
    if (highway != null && highway.isNotEmpty) {
      queryParams['highway'] = 'eq.$highway';
    }

    final response = await ApiClient.instance.getList(
      '/outlets',
      queryParams: queryParams,
    );

    if (!response.success || response.data == null) {
      return ApiResponse.error(
        response.errorMessage ?? 'आउटलेट लोड नहीं हो पाए।',
      );
    }

    final outlets = response.data!.map(Outlet.fromJson).toList();
    return ApiResponse.ok(outlets);
  }

  /// Fetches nearby outlets sorted by distance using driver's lat/lng.
  /// Calls the Supabase Edge Function: /nearby-outlets
  Future<ApiResponse<List<Outlet>>> fetchNearbyOutlets({
    required double lat,
    required double lng,
  }) async {
    try {
      final token = TokenStore.instance.accessToken;
      final uri = Uri.parse('${ApiConstants.functionsBaseUrl}/nearest-outlets');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'apikey': ApiConstants.anonKey,
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'lat': lat, 'lng': lng}),
      );

      debugPrint(response.body);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final success = json['success'] as bool? ?? false;
        if (success) {
          final list = (json['outlets'] as List<dynamic>)
              .map((e) => Outlet.fromJson(e as Map<String, dynamic>))
              .toList();
          return ApiResponse.ok(list);
        }
        return ApiResponse.error(
          json['message'] as String? ?? 'नज़दीकी पंप नहीं मिले।',
        );
      }
      return ApiResponse.error('नज़दीकी पंप लोड नहीं हो पाए।');
    } catch (e) {
      return ApiResponse.error('नेटवर्क में समस्या: $e');
    }
  }
}
