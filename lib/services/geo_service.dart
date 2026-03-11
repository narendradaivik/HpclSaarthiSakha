import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'app_settings.dart';

class GeoService {
  /// Dynamic allowed radius — comes from AppSettings (set at login from server).
  /// Falls back to 100m if not yet loaded.
  static double get allowedRadiusMeters => AppSettings.instance.geoDistanceMeters;

  /// Haversine formula — returns distance in metres between two lat/lng points.
  static double distanceInMeters(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _toRad(double deg) => deg * pi / 180;

  /// Check location permission and get current position.
  static Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );
  }

  /// Returns [LocationCheckResult] based on dynamic radius from [AppSettings].
  static Future<LocationCheckResult> checkProximity({
    required double outletLat,
    required double outletLng,
  }) async {
    final position = await getCurrentPosition();

    if (position == null) {
      return const LocationCheckResult(
        allowed: false,
        reason: LocationDenyReason.permissionDenied,
        distanceMeters: null,
      );
    }

    final dist = distanceInMeters(
      position.latitude, position.longitude,
      outletLat, outletLng,
    );

    return LocationCheckResult(
      allowed:        dist <= allowedRadiusMeters,
      reason:         dist > allowedRadiusMeters
                        ? LocationDenyReason.tooFar
                        : LocationDenyReason.none,
      distanceMeters: dist,
      userLat:        position.latitude,
      userLng:        position.longitude,
    );
  }
}

enum LocationDenyReason { none, permissionDenied, tooFar }

class LocationCheckResult {
  final bool allowed;
  final LocationDenyReason reason;
  final double? distanceMeters;
  final double? userLat;
  final double? userLng;

  const LocationCheckResult({
    required this.allowed,
    required this.reason,
    required this.distanceMeters,
    this.userLat,
    this.userLng,
  });
}
