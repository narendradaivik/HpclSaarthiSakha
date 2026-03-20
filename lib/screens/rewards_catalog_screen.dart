import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/services.dart';
import 'outlet_selection_screen.dart';

class RewardsCatalogScreen extends StatefulWidget {
  final double? redeemableLiters;
  const RewardsCatalogScreen({super.key, this.redeemableLiters});

  @override
  State<RewardsCatalogScreen> createState() => _RewardsCatalogScreenState();
}

class _RewardsCatalogScreenState extends State<RewardsCatalogScreen> {
  List<Map<String, dynamic>> _rewards = [];
  bool _loading = true;
  String? _error;

  bool _litersLoading = false;
  double _redeemableLiters = 0;
  String? _litersError;

  @override
  void initState() {
    super.initState();

    // Seed best available value immediately (no flicker)
    if (widget.redeemableLiters != null && widget.redeemableLiters! > 0) {
      _redeemableLiters = widget.redeemableLiters!;
    } else if (UserSession.instance.isLoaded &&
        UserSession.instance.redeemableLiters > 0) {
      _redeemableLiters = UserSession.instance.redeemableLiters;
    }

    _fetchDriverStats();
    _loadRewards();
  }

  Future<void> _fetchDriverStats() async {
    setState(() {
      _litersLoading = true;
      _litersError = null;
    });
    final result = await DriverService.instance.fetchDriverStats();
    if (!mounted) return;
    if (result.success && result.data != null) {
      final stats = result.data!;
      UserSession.instance.update(
        redeemableLiters: stats.redeemableLiters,
        totalLiters: stats.totalLitersFueled,
        totalTransactions: stats.totalTransactions,
        driverName: stats.name ?? '',
        driverPhone: stats.phone,
        currentLevel: stats.currentLevel,
      );
      setState(() {
        _redeemableLiters = stats.redeemableLiters;
        _litersLoading = false;
        _litersError = null;
      });
    } else {
      setState(() {
        _litersLoading = false;
        _litersError = result.errorMessage ?? 'पॉइंट्स लोड नहीं हो सके।';
      });
    }
  }

  Future<void> _loadRewards() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await RewardsService.instance.fetchCatalog();
    if (!mounted) return;
    if (result.success && result.data != null && result.data!.isNotEmpty) {
      setState(() {
        _rewards = result.data!.map((r) => r.toMap()).toList();
        _loading = false;
        _error = null;
      });
    } else {
      setState(() {
        _rewards = [];
        _loading = false;
        _error = result.errorMessage ?? 'रिवॉर्ड्स लोड नहीं हो सके।';
      });
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadRewards(), _fetchDriverStats()]);
  }

  String _fmt(int n) {
    final s = n.toString();
    if (s.length == 5) return '${s.substring(0, 2)},${s.substring(2)}';
    if (s.length == 6) return '${s.substring(0, 3)},${s.substring(3)}';
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Column(
        children: [
          // ── HEADER ────────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1A4E),
                  Color(0xFF6B1535),
                  Color(0xFFCC0000),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              bottom: 24,
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/sarathi-sakha-logo.png',
                  height: 34,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'सभी रिवॉर्ड्स',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      _litersLoading
                          ? Container(
                              width: 160,
                              height: 11,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            )
                          : _litersError != null
                          ? GestureDetector(
                              onTap: _fetchDriverStats,
                              child: Row(
                                children: const [
                                  Icon(
                                    Icons.wifi_off,
                                    color: Colors.white54,
                                    size: 12,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'पॉइंट्स लोड नहीं हुए  ↻',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Text(
                              'आपके पास ${_redeemableLiters.round()} L रिडीम योग्य हैं',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── BODY ──────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _error != null && _rewards.isEmpty
                ? _fullErrorState()
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _refreshAll,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _rewards.length,
                      itemBuilder: (_, i) => _rewardCard(_rewards[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Full-screen error state ───────────────────────────────────────────────

  Widget _fullErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 52, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'इंटरनेट कनेक्शन की समस्या',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'रिवॉर्ड्स लोड नहीं हो सके। कृपया अपना इंटरनेट जांचें।',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshAll,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('पुनः प्रयास करें'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Reward Card ───────────────────────────────────────────────────────────

  Widget _rewardCard(Map<String, dynamic> r) {
    final int pts = r['points'] as int;
    final bool canRedeem = _redeemableLiters >= pts;
    final double needed = pts - _redeemableLiters;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: canRedeem ? Colors.green.shade200 : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row ───────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon / image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(
                    child:
                        r['image_url'] != null &&
                            (r['image_url'] as String).isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              r['image_url'] as String,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _b, _c) => Image.asset(
                                r['icon'] as String? ??
                                    'assets/images/default_gift.png',
                                width: 48,
                                height: 48,
                              ),
                            ),
                          )
                        : Image.asset(
                            r['icon'] as String? ??
                                'assets/images/default_gift.png',
                            width: 48,
                            height: 48,
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              r['name_hi'] as String? ?? r['name'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: canRedeem
                                  ? Colors.green.shade50
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${_fmt(pts)}L',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: canRedeem
                                    ? AppColors.redeemGreen
                                    : AppColors.textGrey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        r['name'] as String,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: canRedeem
                              ? 1.0
                              : (_redeemableLiters / pts).clamp(0.0, 1.0),
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            canRedeem ? AppColors.redeemGreen : Colors.orange,
                          ),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Bottom row ────────────────────────────────────────────────
            canRedeem
                ? SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OutletSelectionScreen(reward: r),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.redeemGreen,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'रिडीम करें',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'अभी ${needed.ceil()}L और चाहिए',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'रिडीम करें',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
