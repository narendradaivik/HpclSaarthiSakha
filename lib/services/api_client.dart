import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_constants.dart';
import 'api_response.dart';
import 'token_store.dart';

/// Generic HTTP client.
/// Supports both Supabase Edge Functions (POST) and REST table queries (GET).
/// Auto-attaches Authorization Bearer token when available.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  // ── Headers ────────────────────────────────────────────────────────────────

  /// Headers for Edge Function calls (auth via Bearer token after login)
  Map<String, String> get _functionHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    ...TokenStore.instance.authHeader,
  };

  /// Headers for Supabase REST table calls (requires apikey)
  Map<String, String> get _restHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'apikey': ApiConstants.anonKey,
    ...TokenStore.instance.authHeader, // Bearer token after login
  };

  // ── POST (Edge Functions) ─────────────────────────────────────────────────
  Future<ApiResponse<Map<String, dynamic>>> post(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('${ApiConstants.functionsBaseUrl}$endpoint');
    _log('POST', uri.toString(), body);

    try {
      final response = await http
          .post(uri, headers: _functionHeaders, body: jsonEncode(body))
          .timeout(ApiConstants.receiveTimeout);

      return _handleObjectResponse(response);
    } on SocketException {
      return ApiResponse.error('इंटरनेट कनेक्शन नहीं है। कृपया जाँचें।');
    } on HttpException catch (e) {
      return ApiResponse.error('HTTP Error: ${e.message}');
    } on FormatException {
      return ApiResponse.error('Server से गलत डेटा मिला।');
    } catch (e) {
      return ApiResponse.error('कुछ गलत हो गया: $e');
    }
  }

  // ── GET Object (Edge Functions returning {}) ──────────────────────────────
  Future<ApiResponse<Map<String, dynamic>>> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool useRestBase = false,
  }) async {
    var uri = Uri.parse(
      '${useRestBase ? ApiConstants.restBaseUrl : ApiConstants.functionsBaseUrl}$endpoint',
    );
    if (queryParams != null) {
      uri = uri.replace(queryParameters: queryParams);
    }
    _log('GET', uri.toString(), null);

    try {
      final response = await http
          .get(uri, headers: useRestBase ? _restHeaders : _functionHeaders)
          .timeout(ApiConstants.receiveTimeout);

      return _handleObjectResponse(response);
    } on SocketException {
      return ApiResponse.error('इंटरनेट कनेक्शन नहीं है। कृपया जाँचें।');
    } catch (e) {
      return ApiResponse.error('कुछ गलत हो गया: $e');
    }
  }

  // ── GET List (REST tables returning [...]) ────────────────────────────────
  Future<ApiResponse<List<Map<String, dynamic>>>> getList(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    var uri = Uri.parse('${ApiConstants.restBaseUrl}$endpoint');
    if (queryParams != null) {
      uri = uri.replace(queryParameters: queryParams);
    }
    _log('GET LIST', uri.toString(), null);

    try {
      final response = await http
          .get(uri, headers: _restHeaders)
          .timeout(ApiConstants.receiveTimeout);

      return _handleListResponse(response);
    } on SocketException {
      return ApiResponse.error('इंटरनेट कनेक्शन नहीं है। कृपया जाँचें।');
    } on HttpException catch (e) {
      return ApiResponse.error('HTTP Error: ${e.message}');
    } on FormatException {
      return ApiResponse.error('Server से गलत डेटा मिला।');
    } catch (e) {
      return ApiResponse.error('कुछ गलत हो गया: $e');
    }
  }

  // ── Response handlers ──────────────────────────────────────────────────────

  ApiResponse<Map<String, dynamic>> _handleObjectResponse(
    http.Response response,
  ) {
    _logResponse(response.statusCode, response.body);

    try {
      final decoded = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic>) {
          if (decoded['success'] == false) {
            return ApiResponse.error(
              decoded['message'] as String? ?? 'कुछ गलत हो गया।',
              statusCode: response.statusCode,
            );
          }
          return ApiResponse.ok(decoded, statusCode: response.statusCode);
        }
        return ApiResponse.error(
          'Unexpected format',
          statusCode: response.statusCode,
        );
      }

      final msg = decoded is Map
          ? (decoded['message'] as String? ??
                decoded['error'] as String? ??
                'Server Error (${response.statusCode})')
          : 'Server Error (${response.statusCode})';
      return ApiResponse.error(msg, statusCode: response.statusCode);
    } catch (_) {
      return ApiResponse.error('Parse error', statusCode: response.statusCode);
    }
  }

  ApiResponse<List<Map<String, dynamic>>> _handleListResponse(
    http.Response response,
  ) {
    _logResponse(response.statusCode, response.body);

    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          final list = decoded.whereType<Map<String, dynamic>>().toList();
          return ApiResponse.ok(list, statusCode: response.statusCode);
        }
        return ApiResponse.error(
          'Expected array response',
          statusCode: response.statusCode,
        );
      }

      final decoded = jsonDecode(response.body);
      final msg = decoded is Map
          ? (decoded['message'] as String? ?? 'Server Error')
          : 'Server Error (${response.statusCode})';
      return ApiResponse.error(msg, statusCode: response.statusCode);
    } catch (_) {
      return ApiResponse.error('Parse error', statusCode: response.statusCode);
    }
  }

  // ── Logging ────────────────────────────────────────────────────────────────
  void _log(String method, String url, Map<String, dynamic>? body) {
    // ignore: avoid_print
    debugPrint('🌐 [$method] $url');
    if (body != null) debugPrint('   📤 ${jsonEncode(body)}');
  }

  void _logResponse(int code, String body) {
    final icon = code >= 200 && code < 300 ? '✅' : '❌';
    // ignore: avoid_print
    debugPrint(
      '$icon [$code] ${body.length > 200 ? '${body.substring(0, 200)}…' : body}',
    );
  }
}
