import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/services.dart';
import '../services/outletservice.dart';
import '../model/outlet.dart';
import 'rewards_catalog_screen.dart';
import 'outlet_selection_screen.dart';
import 'profile_screen.dart';
import 'reward_claim_screen.dart';

// ─── DASHBOARD SHELL ──────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  void _onNavTap(int index) {
    if (index == 3) {
      _showShareSheet();
      return;
    }
    setState(() => _currentIndex = index);
  }

  void _showShareSheet() {
    const shareUrl =
        'https://play.google.com/store/apps/details?id=com.hpcl.highwayrewards';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (ctx) => _ShareSheet(
        onCopy: () {
          Clipboard.setData(const ClipboardData(text: shareUrl));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('लिंक कॉपी हो गया!'),
              duration: Duration(seconds: 1),
              backgroundColor: AppColors.redeemGreen,
            ),
          );
        },
      ),
    );
  }

  DateTime? _lastBackPress;

  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'बाहर निकलने के लिए फिर से दबाएं',
            style: TextStyle(color: Colors.white),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF1A1A4E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return false;
    }
    SystemNavigator.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onWillPop();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: _currentIndex == 0
            ? HomeTab(onSwitchTab: (i) => setState(() => _currentIndex = i))
            : _currentIndex == 1
            ? RewardsCatalogScreen(
                redeemableLiters: UserSession.instance.redeemableLiters,
              )
            : _currentIndex == 4
            ? const ProfileScreen()
            : const HomeTab(),
        floatingActionButton: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RewardClaimScreen()),
          ),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF4444), AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.qr_code_scanner, color: Colors.white, size: 26),
                SizedBox(height: 3),
                Text(
                  'रिडीम\nदावा करें',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          child: SizedBox(
            height: 68,
            child: Row(
              children: [
                _navItem(Icons.home, 'होम', 0),
                _navItem(Icons.card_giftcard, 'रिडीम', 1),
                const Expanded(child: SizedBox()),
                _navItem(Icons.group_add, 'जोड़े', 3),
                _navItem(Icons.person, 'प्रोफाइल', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isActive = _currentIndex == index && index != 3;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onNavTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.primary : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? AppColors.primary : Colors.grey,
              ),
            ),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 3),
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── SHARE SHEET ──────────────────────────────────────────────────────────────

class _ShareSheet extends StatelessWidget {
  final VoidCallback onCopy;
  const _ShareSheet({required this.onCopy});
  static const shareUrl =
      'https://play.google.com/store/apps/details?id=com.hpcl.highwayrewards';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'दोस्तों को जोड़ें',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.black54,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'अपने दोस्तों को Highway Rewards ऐप शेयर करें और साथ में पॉइंट्स कमाएं',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    shareUrl,
                    style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onCopy,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.copy,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _btn(
                context,
                Icons.chat_bubble_outline,
                'WhatsApp',
                Colors.grey.shade100,
                Colors.green,
              ),
              const SizedBox(width: 10),
              _btn(
                context,
                Icons.sms_outlined,
                'SMS',
                Colors.grey.shade100,
                Colors.blue,
              ),
              const SizedBox(width: 10),
              _btn(
                context,
                Icons.share,
                'और शेयर',
                AppColors.primary.withValues(alpha: 0.1),
                AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _btn(
    BuildContext ctx,
    IconData icon,
    String label,
    Color bg,
    Color iconColor,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.of(ctx).pop(),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.textDark),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── HOME TAB ─────────────────────────────────────────────────────────────────

class HomeTab extends StatefulWidget {
  final void Function(int)? onSwitchTab;
  const HomeTab({super.key, this.onSwitchTab});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  DriverStats? _stats;
  bool _statsLoading = true;

  List<Map<String, dynamic>> _rewards = [];
  bool _rewardsLoading = true;
  String? _rewardsError;

  FuelClaimHistoryResult? _fuelHistory;
  bool _fuelLoading = true;
  String? _fuelError;

  List<Redemption> _redemptions = [];
  bool _redemptionsLoading = true;
  String? _redemptionsError;

  List<Outlet> _nearbyOutlets = [];
  bool _nearbyLoading = true;
  String? _nearbyError;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadDriverStats(),
      _loadRewards(),
      _loadFuelHistory(),
      _loadRedemptions(),
      _loadNearbyOutlets(),
    ]);
  }

  Future<void> _loadDriverStats() async {
    setState(() => _statsLoading = true);
    // Use fetchDriverProfile — same proven endpoint used by Profile screen.
    // /driver-stats returns different field names (total_volume etc.) and is unreliable.
    final r = await DriverService.instance.fetchDriverProfile();
    if (!mounted) return;
    final stats = r.success ? r.data?.driver : null;
    if (stats != null) {
      UserSession.instance.update(
        redeemableLiters: stats.redeemableLiters,
        totalLiters: stats.totalLitersFueled,
        totalTransactions: stats.totalTransactions,
        driverName: stats.name ?? '',
        driverPhone: stats.phone,
        currentLevel: stats.currentLevel,
        truckNumber: stats.truckNumber ?? 'N/A',
        memberSince: stats.memberSince != null
            ? _memberSinceFmt(stats.memberSince!)
            : '—',
      );
    }
    setState(() {
      _stats = stats;
      _statsLoading = false;
    });
  }

  Future<void> _loadRewards() async {
    setState(() {
      _rewardsLoading = true;
      _rewardsError = null;
    });
    final r = await RewardsService.instance.fetchCatalog();
    if (!mounted) return;
    setState(() {
      _rewards = r.success && r.data != null
          ? r.data!.map((x) => x.toMap()).toList()
          : [];
      _rewardsError = r.success ? null : r.errorMessage;
      _rewardsLoading = false;
    });
  }

  Future<void> _loadFuelHistory() async {
    setState(() {
      _fuelLoading = true;
      _fuelError = null;
    });
    final r = await DriverService.instance.fetchFuelClaimHistory();
    if (!mounted) return;
    setState(() {
      _fuelHistory = r.success ? r.data : null;
      _fuelError = r.success ? null : r.errorMessage;
      _fuelLoading = false;
    });
  }

  Future<void> _loadRedemptions() async {
    setState(() {
      _redemptionsLoading = true;
      _redemptionsError = null;
    });
    final r = await RedemptionService.instance.fetchMyRedemptions();
    if (!mounted) return;
    setState(() {
      _redemptions = r.success && r.data != null ? r.data! : [];
      _redemptionsError = r.success ? null : r.errorMessage;
      _redemptionsLoading = false;
    });
  }

  Future<void> _loadNearbyOutlets() async {
    setState(() {
      _nearbyLoading = true;
      _nearbyError = null;
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _nearbyError = 'लोकेशन सेवा बंद है';
        _nearbyLoading = false;
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        _nearbyError = 'लोकेशन अनुमति नहीं मिली';
        _nearbyLoading = false;
      });
      return;
    }

    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      setState(() {
        _nearbyError = 'लोकेशन नहीं मिली';
        _nearbyLoading = false;
      });
      return;
    }

    final r = await OutletService.instance.fetchNearbyOutlets(
      lat: position.latitude,
      lng: position.longitude,
    );
    if (!mounted) return;
    setState(() {
      _nearbyOutlets = r.success && r.data != null ? r.data! : [];
      _nearbyError = r.success ? null : r.errorMessage;
      _nearbyLoading = false;
    });
  }

  // ── Formatters ─────────────────────────────────────────────────────────────

  String _fmt(double n) {
    // Round to nearest whole number: 21.05 → 21, 21.54 → 22
    return n.round().toString();
  }

  String _fmtAmount(double amount) {
    final s = amount.toStringAsFixed(0);
    if (s.length == 5) return '${s.substring(0, 2)},${s.substring(2)}';
    if (s.length == 6) return '${s.substring(0, 3)},${s.substring(3)}';
    return s;
  }

  String _formatDt(DateTime? dt) {
    if (dt == null) return '—';
    const months = [
      '',
      'जन',
      'फ़र',
      'मार्च',
      'अप्रैल',
      'मई',
      'जून',
      'जुलाई',
      'अग',
      'सित',
      'अक्टू',
      'नव',
      'दिसं',
    ];
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = h >= 12 ? 'pm' : 'am';
    final h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '${dt.day} ${months[dt.month]} ${dt.year} • $h12:$m $ampm';
  }

  String _memberSinceFmt(DateTime dt) {
    const months = [
      '',
      'जनवरी',
      'फ़रवरी',
      'मार्च',
      'अप्रैल',
      'मई',
      'जून',
      'जुलाई',
      'अगस्त',
      'सितंबर',
      'अक्टूबर',
      'नवंबर',
      'दिसंबर',
    ];
    return '${months[dt.month]} ${dt.year}';
  }

  // ── Derived values — 100% from live API / UserSession, zero MockData ───────

  double get _totalLiters => _stats?.totalLitersFueled ?? 0;
  double get _redeemableLiters => _stats?.redeemableLiters ?? 0;
  int get _transactions => _stats?.totalTransactions ?? 0;
  String get _driverName => _stats?.name ?? '';

  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      backgroundColor: Colors.white,
      color: AppColors.primary,
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // ── GRADIENT HEADER STACK ──────────────────────────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
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
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  padding: const EdgeInsets.only(
                    top: 52,
                    left: 16,
                    right: 16,
                    bottom: 56,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/sarathi-sakha-logo.png',
                            height: 36,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'सारथी सखा',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white24,
                            child: Text(
                              _driverName.isNotEmpty ? _driverName[0] : 'D',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: _statsLoading
                            ? _statsShimmer()
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(
                                        Icons.local_gas_station,
                                        color: Colors.amber,
                                        size: 18,
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        'बैलेंस रिवॉर्ड पॉइंट्स',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _fmt(_redeemableLiters),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          height: 1.1,
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.only(
                                          left: 6,
                                          bottom: 5,
                                        ),
                                        child: Text(
                                          'L',
                                          style: TextStyle(
                                            color: Colors.white60,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'कुल डीज़ल (लीटर)',
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '${_fmt(_totalLiters)} L',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: _totalLiters > 0
                                          ? (_redeemableLiters / _totalLiters)
                                                .clamp(0.0, 1.0)
                                          : 0,
                                      backgroundColor: Colors.white.withValues(
                                        alpha: 0.15,
                                      ),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            Color(0xFFFF4444),
                                          ),
                                      minHeight: 5,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: -76,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          Icons.local_gas_station,
                          _statsLoading ? '—' : _fmt(_totalLiters),
                          'कुल डीज़ल (L)',
                          const Color(0xFF000000),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          Icons.emoji_events,
                          _statsLoading ? '—' : '$_transactions',
                          'लेन-देन',
                          const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 85),

            // ── NEARBY OUTLETS ─────────────────────────────────────────────
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.location_on,
                            color: AppColors.textDark,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'नज़दीकी पंप',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: _loadNearbyOutlets,
                        child: const Icon(
                          Icons.refresh,
                          color: AppColors.textGrey,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_nearbyLoading)
                    SizedBox(
                      height: 88,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 3,
                        itemBuilder: (_, __x) => _shimmerNearbyCard(),
                      ),
                    )
                  else if (_nearbyError != null)
                    _nearbyErrorWidget()
                  else if (_nearbyOutlets.isEmpty)
                    _emptyBox(
                      Icons.local_gas_station,
                      'नज़दीक कोई पंप नहीं मिला',
                    )
                  else
                    SizedBox(
                      height: 92,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _nearbyOutlets.length,
                        itemBuilder: (_, i) =>
                            _nearbyOutletCard(_nearbyOutlets[i]),
                      ),
                    ),
                ],
              ),
            ),

            // ── REWARDS CATALOG ────────────────────────────────────────────
            _sectionCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.card_giftcard,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'रिवॉर्ड्स कैटलॉग',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          if (widget.onSwitchTab != null) {
                            widget.onSwitchTab!(1);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RewardsCatalogScreen(
                                  redeemableLiters:
                                      UserSession.instance.redeemableLiters,
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'सभी देखें >',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_rewardsError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.wifi_off,
                            size: 12,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'नेटवर्क समस्या',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _loadRewards,
                            child: const Text(
                              '↻ रिफ्रेश',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    height: 95,
                    child: _rewardsLoading
                        ? ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 5,
                            itemBuilder: (_, __x) => _shimmerRewardCard(),
                          )
                        : _rewards.isEmpty
                        ? _emptyBox(
                            Icons.card_giftcard_outlined,
                            'कोई रिवॉर्ड उपलब्ध नहीं',
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _rewards.length,
                            itemBuilder: (_, i) {
                              final r = _rewards[i];
                              final int pts = r['points'] as int;
                              final bool canRedeem = _redeemableLiters >= pts;

                              return GestureDetector(
                                onTap: () {
                                  if (canRedeem) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            OutletSelectionScreen(reward: r),
                                      ),
                                    );
                                  } else {
                                    final needed = pts - _redeemableLiters;
                                    ScaffoldMessenger.of(context)
                                      ..clearSnackBars()
                                      ..showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(
                                                Icons.info_outline,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'रिडीम के लिए $needed L और चाहिए',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: const Color(
                                            0xFF1A1A4E,
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          margin: const EdgeInsets.all(16),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                  }
                                },
                                child: Container(
                                  width: 74,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: canRedeem
                                          ? Colors.green.shade300
                                          : Colors.grey.shade100,
                                      width: canRedeem ? 1.5 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: canRedeem
                                            ? Colors.green.withValues(
                                                alpha: 0.12,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.06,
                                              ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.03,
                                        ),
                                        blurRadius: 3,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (canRedeem)
                                        Container(
                                          width: 6,
                                          height: 6,
                                          margin: const EdgeInsets.only(
                                            bottom: 2,
                                          ),
                                          decoration: const BoxDecoration(
                                            color: AppColors.redeemGreen,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      if (r['image_url'] != null &&
                                          (r['image_url'] as String).isNotEmpty)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: Image.network(
                                            r['image_url'] as String,
                                            width: 36,
                                            height: 36,
                                            fit: BoxFit.cover,
                                            errorBuilder: (ctx, err, stack) =>
                                                Image.asset(
                                                  r['icon'] as String? ??
                                                      'assets/images/default_gift.png',
                                                  width: 36,
                                                  height: 36,
                                                ),
                                          ),
                                        )
                                      else
                                        Image.asset(
                                          r['icon'] as String? ??
                                              'assets/images/default_gift.png',
                                          width: 36,
                                          height: 36,
                                        ),
                                      const SizedBox(height: 4),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: Text(
                                          r['name_hi'] as String? ??
                                              r['name'] as String,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '${r['points']}L',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: canRedeem
                                              ? AppColors.redeemGreen
                                              : AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),

            // ── REDEMPTIONS ────────────────────────────────────────────────
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.card_giftcard_outlined,
                        color: AppColors.textDark,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'आपने जिन पुरस्कारों के लिए अनुरोध किया है',
                          style: TextStyle(
                            fontFamily: "NotoSansDevanagari",
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _loadRedemptions,
                        child: const Icon(
                          Icons.refresh,
                          color: AppColors.textGrey,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_redemptionsLoading) ...[
                    _shimmerRedemptionCard(),
                    _shimmerRedemptionCard(),
                  ] else if (_redemptions.isEmpty && _redemptionsError != null)
                    _errorWidget(_redemptionsError!, _loadRedemptions)
                  else if (_redemptions.isEmpty)
                    _emptyBox(
                      Icons.card_giftcard_outlined,
                      'पिछले 10 दिनों में कोई रिक्वेस्ट नहीं',
                      subtitle:
                          'पूरा हिसाब देखने के लिए प्रोफ़ाइल → लेन-देन पर जाएँ',
                    )
                  else
                    ..._redemptions.take(5).map(_redemptionCard),
                ],
              ),
            ),

            // ── FUEL CLAIM HISTORY ─────────────────────────────────────────
            _sectionCard(
              bottomMargin: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.local_gas_station,
                        color: AppColors.textDark,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'अब तक आपके द्वारा लिया गया डीज़ल',
                          style: TextStyle(
                            fontFamily: "NotoSansDevanagari",
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _loadFuelHistory,
                        child: const Icon(
                          Icons.refresh,
                          color: AppColors.textGrey,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_fuelLoading) ...[
                    _shimmerFuelCard(),
                    _shimmerFuelCard(),
                    _shimmerFuelCard(),
                  ] else if (_fuelError != null &&
                      (_fuelHistory == null || _fuelHistory!.isEmpty))
                    _errorWidget(_fuelError!, _loadFuelHistory)
                  else if (_fuelHistory == null || _fuelHistory!.isEmpty)
                    _emptyBox(
                      Icons.local_gas_station,
                      'पिछले 10 दिनों में कोई क्लेम नहीं',
                      subtitle:
                          'पूरा हिसाब देखने के लिए प्रोफ़ाइल → लेन-देन पर जाएँ',
                    )
                  else ...[
                    _fuelSummaryBanner(_fuelHistory!.summary),
                    const SizedBox(height: 10),
                    ..._fuelHistory!.claims.map(_fuelClaimCard),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── REDEMPTION CARD ────────────────────────────────────────────────────────

  Widget _redemptionCard(Redemption r) {
    Color statusBg, statusFg;
    if (r.isDelivered) {
      statusBg = Colors.green.shade50;
      statusFg = Colors.green;
    } else if (r.isRejected) {
      statusBg = Colors.red.shade50;
      statusFg = Colors.red;
    } else if (r.isDispatched || r.isApproved) {
      statusBg = Colors.green.shade50;
      statusFg = Colors.green;
    } else {
      statusBg = Colors.orange.shade50;
      statusFg = Colors.orange.shade700;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(r.iconPath, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.rewardNameHi,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  r.rewardNameEn,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatDt(r.requestedAt)} • ${r.rewardPoints}L',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                ),
                if (r.redemptionNumber != null &&
                    r.redemptionNumber!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                        fontFamily: DefaultTextStyle.of(
                          context,
                        ).style.fontFamily,
                      ),
                      children: [
                        const TextSpan(text: 'रिक्वेस्ट नं: '),
                        TextSpan(
                          text: r.redemptionNumber!,
                          style: TextStyle(
                            color: Colors.grey.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if ((r.deliveryAddress != null &&
                        r.deliveryAddress!.isNotEmpty) ||
                    (r.deliveryPhone != null &&
                        r.deliveryPhone!.isNotEmpty)) ...[
                  const SizedBox(height: 5),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (r.deliveryAddress != null &&
                          r.deliveryAddress!.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: AppColors.textGrey,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                r.deliveryAddress!,
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
                      if (r.deliveryPhone != null &&
                          r.deliveryPhone!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        GestureDetector(
                          onTap: () async {
                            final uri = Uri(
                              scheme: 'tel',
                              path: r.deliveryPhone,
                            );
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          child: Row(
                            children: [
                              const Icon(
                                Icons.phone,
                                size: 14,
                                color: Color(0xFFE05C6A),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                r.deliveryPhone!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFE05C6A),
                                  decoration: TextDecoration.underline,
                                  decorationColor: Color(0xFFE05C6A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            constraints: const BoxConstraints(maxWidth: 110),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              r.statusHi,
              style: TextStyle(
                fontSize: 12,
                color: statusFg,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ── FUEL SUMMARY BANNER ────────────────────────────────────────────────────

  Widget _fuelSummaryBanner(FuelClaimSummary s) {
    // Only shows stats row — section title is already in the parent header
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '${s.totalClaims} क्लेम',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 6),
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${s.totalLitersClaimed.toStringAsFixed(1)} L कुल',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  // ── FUEL CLAIM CARD ────────────────────────────────────────────────────────

  Widget _fuelClaimCard(FuelClaim c) {
    final isVerified = c.status == 'verified';
    final isRejected = c.status == 'rejected';
    final Color statusColor = isVerified
        ? const Color.fromARGB(255, 68, 86, 69)
        : isRejected
        ? Colors.red
        : Colors.orange.shade700;
    final Color statusBg = isVerified
        ? const Color.fromARGB(255, 221, 225, 221)
        : isRejected
        ? Colors.red.shade50
        : const Color(0xFFFFF3E0);
    final String statusLabel = isVerified
        ? 'verified'
        : isRejected
        ? 'rejected'
        : 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.local_gas_station,
              color: Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        '${c.fuelType ?? 'डीज़ल'} • ${c.liters.toStringAsFixed(2)} लीटर',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                if (c.outletDisplayName.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 13,
                        color: Colors.red.shade500,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          c.outletDisplayName,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        _formatDt(c.claimDate),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                    Builder(
                      builder: (_) {
                        final amt = c.totalAmount;
                        if (amt == null) return const SizedBox.shrink();
                        return Text(
                          '₹ ${_fmtAmount(amt)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_gas_station,
                          size: 13,
                          color: Color.fromARGB(255, 240, 70, 70),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '+${c.liters.toStringAsFixed(2)} L',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 240, 70, 70),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── NEARBY OUTLET CARD ────────────────────────────────────────────────────

  Future<void> _launchMaps(Outlet o) async {
    if (o.latitude == null || o.longitude == null) return;
    final lat = o.latitude!;
    final lng = o.longitude!;
    final label = Uri.encodeComponent(o.name);
    final googleMapsApp = Uri.parse('comgooglemaps://?q=$lat,$lng&zoom=16');
    final googleMapsBrowser = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=$label',
    );
    final appleMaps = Uri.parse('maps://?q=$lat,$lng');

    if (await canLaunchUrl(googleMapsApp)) {
      await launchUrl(googleMapsApp);
    } else if (await canLaunchUrl(appleMaps)) {
      await launchUrl(appleMaps);
    } else {
      await launchUrl(googleMapsBrowser, mode: LaunchMode.externalApplication);
    }
  }

  Widget _nearbyOutletCard(Outlet o) {
    final side = o.roadSide == 'right' ? '→ दाएं' : '← बाएं';
    return GestureDetector(
      onTap: () => _launchMaps(o),
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    o.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _launchMaps(o),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.navigation,
                      size: 12,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              o.highway,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  o.distanceKm != null
                      ? '${o.distanceKm!.toStringAsFixed(1)} km'
                      : '',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    side,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _nearbyErrorWidget() {
    final isPermission = _nearbyError?.contains('अनुमति') ?? false;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Row(
        children: [
          Icon(
            isPermission ? Icons.location_off : Icons.wifi_off,
            size: 18,
            color: Colors.orange.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _nearbyError ?? '',
              style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
            ),
          ),
          if (isPermission)
            GestureDetector(
              onTap: () => Geolocator.openAppSettings(),
              child: const Text(
                'सेटिंग',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            GestureDetector(
              onTap: _loadNearbyOutlets,
              child: const Text(
                '↻ रिफ्रेश',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _shimmerNearbyCard() => Container(
    width: 130,
    margin: const EdgeInsets.only(right: 8),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade200),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 120, height: 12, color: Colors.grey.shade200),
        const SizedBox(height: 6),
        Container(width: 60, height: 10, color: Colors.grey.shade200),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(width: 50, height: 10, color: Colors.grey.shade200),
            Container(
              width: 36,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  // ── Shared helpers ─────────────────────────────────────────────────────────

  Widget _sectionCard({required Widget child, double bottomMargin = 8}) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade100, width: 1),
          ),
        ),
        margin: EdgeInsets.only(bottom: bottomMargin),
        padding: const EdgeInsets.all(16),
        child: child,
      );

  Widget _statCard(IconData icon, String value, String label, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
          ),
        ],
      ),
    );
  }

  Widget _emptyBox(IconData icon, String msg, {String? subtitle}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(
      children: [
        Icon(icon, size: 40, color: Colors.grey.shade300),
        const SizedBox(height: 10),
        Text(
          msg,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    ),
  );

  Widget _errorWidget(String msg, VoidCallback retry) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 14, color: Colors.orange),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                msg,
                style: const TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: retry,
          child: const Text(
            'पुनः प्रयास करें',
            style: TextStyle(color: AppColors.primary),
          ),
        ),
      ],
    ),
  );

  // ── Shimmer placeholders ───────────────────────────────────────────────────

  Widget _statsShimmer() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sBox(80, 14),
      const SizedBox(height: 8),
      _sBox(140, 36),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [_sBox(100, 12), _sBox(80, 12)],
      ),
      const SizedBox(height: 8),
      _sBox(double.infinity, 5),
    ],
  );

  Widget _sBox(double w, double h) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: Colors.white24,
      borderRadius: BorderRadius.circular(4),
    ),
  );

  Widget _shimmerRewardCard() => Container(
    width: 74,
    margin: const EdgeInsets.only(right: 8),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade200),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Container(width: 50, height: 8, color: Colors.grey.shade200),
        const SizedBox(height: 4),
        Container(width: 30, height: 8, color: Colors.grey.shade200),
      ],
    ),
  );

  Widget _shimmerRedemptionCard() => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade200),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 140, height: 12, color: Colors.grey.shade200),
              const SizedBox(height: 5),
              Container(width: 100, height: 10, color: Colors.grey.shade200),
              const SizedBox(height: 5),
              Container(width: 120, height: 10, color: Colors.grey.shade200),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 70,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    ),
  );

  Widget _shimmerFuelCard() => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade200),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 160, height: 12, color: Colors.grey.shade200),
              const SizedBox(height: 6),
              Container(width: 120, height: 10, color: Colors.grey.shade200),
              const SizedBox(height: 6),
              Container(width: 90, height: 10, color: Colors.grey.shade200),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 48,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    ),
  );
}
