import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:highway_rewards/model/outlet.dart';
import 'package:highway_rewards/services/outletservice.dart';

import '../theme/app_theme.dart';
import 'redeem_confirm_screen.dart';

// ── Haversine distance (km) between two lat/lng points ────────────────────────
double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLon = (lon2 - lon1) * pi / 180;
  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) *
          cos(lat2 * pi / 180) *
          sin(dLon / 2) *
          sin(dLon / 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}

// ── Outlet entry with computed distance ───────────────────────────────────────
class _OutletEntry {
  final Outlet outlet;
  final double? distKm; // null if outlet has no coords or user loc unavailable
  _OutletEntry(this.outlet, this.distKm);
}

class OutletSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> reward;
  const OutletSelectionScreen({super.key, required this.reward});

  @override
  State<OutletSelectionScreen> createState() => _OutletSelectionScreenState();
}

class _OutletSelectionScreenState extends State<OutletSelectionScreen> {
  List<_OutletEntry> _entries = [];
  bool _isLoading = true;
  String? _errorMessage;

  // User location — null if unavailable/denied
  double? _userLat;
  double? _userLng;
  bool _locationLoading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  // Fetch location + outlets in parallel, then merge & sort
  Future<void> _init() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _locationLoading = true;
    });

    // Run both concurrently
    final results = await Future.wait([
      _fetchLocation(),
      OutletService.instance.fetchOutlets(),
    ]);

    if (!mounted) return;

    final outletResponse = results[1] as dynamic;

    if (outletResponse.success == true && outletResponse.data != null) {
      final outlets = outletResponse.data as List<Outlet>;
      _buildEntries(outlets);
      setState(() => _isLoading = false);
    } else {
      setState(() {
        _errorMessage = outletResponse.errorMessage as String?;
        _isLoading = false;
      });
    }
  }

  // Get GPS — returns silently on any failure (location is best-effort)
  Future<void> _fetchLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 8));

      _userLat = pos.latitude;
      _userLng = pos.longitude;
    } catch (_) {
      // location unavailable — list still shows, just unsorted
    } finally {
      _locationLoading = false;
    }
  }

  void _buildEntries(List<Outlet> outlets) {
    _entries = outlets.map((o) {
      double? dist;
      if (_userLat != null &&
          _userLng != null &&
          o.latitude != null &&
          o.longitude != null) {
        dist = _haversineKm(_userLat!, _userLng!, o.latitude!, o.longitude!);
      }
      return _OutletEntry(o, dist);
    }).toList();

    // Sort: outlets with distance first (nearest first), then the rest by name
    _entries.sort((a, b) {
      if (a.distKm != null && b.distKm != null) {
        return a.distKm!.compareTo(b.distKm!);
      }
      if (a.distKm != null) return -1;
      if (b.distKm != null) return 1;
      return a.outlet.name.compareTo(b.outlet.name);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: AppGradients.headerGradient,
            ),
            padding: const EdgeInsets.only(
              top: 50,
              left: 16,
              right: 16,
              bottom: 20,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Image.asset(
                  'assets/images/sarathi-sakha-logo.png',
                  height: 36,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'आउटलेट चुनें',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'रिडीम के लिए HPCL पंप चुनें',
                      style: TextStyle(fontSize: 15, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Selected Reward Card ────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child:
                        widget.reward['image_url'] != null &&
                            (widget.reward['image_url'] as String).isNotEmpty
                        ? Image.network(
                            widget.reward['image_url'] as String,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, a, b) => Image.asset(
                              widget.reward['icon'] as String? ??
                                  'assets/images/default_gift.png',
                              width: 40,
                              height: 40,
                              fit: BoxFit.contain,
                            ),
                          )
                        : Image.asset(
                            widget.reward['icon'] as String? ??
                                'assets/images/default_gift.png',
                            width: 40,
                            height: 40,
                            fit: BoxFit.contain,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.reward['name_hi'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      widget.reward['name'] as String,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textGrey,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: AppColors.primary,
                          size: 14,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${widget.reward['points']} लीटर',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Count bar + location pill ───────────────────────────────────────
          if (!_isLoading && _errorMessage == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppColors.textGrey,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'उपलब्ध HPCL आउटलेट (${_entries.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  // Location status pill
                  if (_locationLoading)
                    const Row(
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: AppColors.textGrey,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'लोकेशन…',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    )
                  else if (_userLat != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.my_location,
                            size: 11,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'नज़दीक पहले',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 11,
                            color: AppColors.textGrey,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'लोकेशन उपलब्ध नहीं',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

          const SizedBox(height: 8),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'आउटलेट लोड हो रहे हैं…',
              style: TextStyle(color: AppColors.textGrey, fontSize: 15),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textGrey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _init,
                icon: const Icon(Icons.refresh),
                label: const Text('फिर से कोशिश करें'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_entries.isEmpty) {
      return const Center(
        child: Text(
          'कोई आउटलेट उपलब्ध नहीं है।',
          style: TextStyle(color: AppColors.textGrey),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _init,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _entries.length,
        itemBuilder: (context, i) {
          final entry = _entries[i];
          return _OutletCard(
            outlet: entry.outlet,
            distKm: entry.distKm,
            isNearest: i == 0 && entry.distKm != null,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RedeemConfirmScreen(
                  reward: widget.reward,
                  outlet: entry.outlet.toMap(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Outlet Card
// ─────────────────────────────────────────────────────────────────────────────
class _OutletCard extends StatelessWidget {
  final Outlet outlet;
  final double? distKm;
  final bool isNearest;
  final VoidCallback onTap;

  const _OutletCard({
    required this.outlet,
    required this.distKm,
    required this.isNearest,
    required this.onTap,
  });

  String _fmtDist(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isNearest ? Colors.green.shade300 : Colors.grey.shade200,
            width: isNearest ? 1.5 : 1,
          ),
          boxShadow: isNearest
              ? [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Gas station icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isNearest ? Colors.green.shade50 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.local_gas_station,
                color: isNearest ? Colors.green : Colors.blue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Name + location info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + "nearest" badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          outlet.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isNearest) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(
                            'सबसे नज़दीक',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Highway / district
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: AppColors.textGrey,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          outlet.locationTag,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textGrey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Short address
                  if (outlet.address != null && outlet.address!.isNotEmpty)
                    Text(
                      outlet.shortAddress,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Distance badge + chevron
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (distKm != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isNearest
                          ? Colors.green.shade50
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.near_me,
                          size: 11,
                          color: isNearest
                              ? Colors.green.shade700
                              : Colors.blue.shade700,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _fmtDist(distKm!),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isNearest
                                ? Colors.green.shade700
                                : Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right, color: AppColors.textGrey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
