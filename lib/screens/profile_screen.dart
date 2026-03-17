import 'package:flutter/material.dart';
import 'package:highway_rewards/screens/phone_verification_screen.dart';
import '../theme/app_theme.dart';
import '../services/services.dart';
import 'len_den_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  DriverProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await DriverService.instance.fetchDriverProfile();
    if (!mounted) return;
    if (r.success && r.data != null) {
      final d = r.data!.driver;
      UserSession.instance.update(
        redeemableLiters: d.redeemableLiters,
        totalLiters: d.totalLitersFueled,
        totalTransactions: d.totalTransactions,
        driverName: d.name ?? '',
        driverPhone: d.phone,
        currentLevel: d.currentLevel,
        truckNumber: d.truckNumber ?? 'N/A',
        memberSince: d.memberSince != null ? _fmtSince(d.memberSince!) : '—',
      );
    }
    setState(() {
      _profile = r.data;
      _loading = false;
    });
  }

  String _fmtSince(DateTime dt) {
    const m = [
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
    return '${m[dt.month]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final sess = UserSession.instance;
    final driver = _profile?.driver;

    final name = driver?.name?.isNotEmpty == true
        ? driver!.name!
        : sess.driverName.isNotEmpty
        ? sess.driverName
        : 'ड्राइवर';
    final phone = driver?.phone ?? sess.driverPhone;
    final truck =
        driver?.truckNumber ??
        (sess.truckNumber.isNotEmpty ? sess.truckNumber : null);
    final since = driver?.memberSince != null
        ? _fmtSince(driver!.memberSince!)
        : sess.memberSince.isNotEmpty
        ? sess.memberSince
        : '—';
    final totalRaw = driver?.totalLitersFueled ?? sess.totalLiters;
    final redeemRaw = driver?.redeemableLiters ?? sess.redeemableLiters;
    final txns = driver?.totalTransactions ?? sess.totalTransactions;
    // Format with 2 decimals to show 221.05, 21.05 etc.
    // Round to nearest whole: 21.05 → 21, 21.54 → 22
    final total = (totalRaw is double ? totalRaw : (totalRaw as num).toDouble())
        .round()
        .toString();
    final redeem =
        (redeemRaw is double ? redeemRaw : (redeemRaw as num).toDouble())
            .round()
            .toString();
    final level = driver?.levelLabel ?? sess.levelLabel;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'D';
    final vehicles = _profile?.vehicles ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: Colors.white,
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // ── GRADIENT HEADER ────────────────────────────────────────
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
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
                      left: 20,
                      right: 20,
                      bottom: 60,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Close button (when pushed as modal)
                        if (Navigator.of(context).canPop())
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.phone,
                                        color: Colors.white60,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        phone,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.amber.withOpacity(0.4),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 13,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          level,
                                          style: const TextStyle(
                                            color: Colors.amber,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Stat cards ──────────────────────────────────────────
                  Positioned(
                    bottom: -46,
                    left: 16,
                    right: 16,
                    child: _loading
                        ? _statsShimmer()
                        : Row(
                            children: [
                              Expanded(
                                child: _statCard(
                                  icon: Icons.local_gas_station,
                                  iconColor: const Color(0xFFE53935),
                                  value: total.toString(),
                                  label: 'कुल लीटर',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _statCard(
                                  icon: Icons.local_gas_station,
                                  iconColor: const Color(0xFF2563EB),
                                  value: redeem.toString(),
                                  label: 'रिडीम योग्य',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _statCard(
                                  icon: Icons.swap_horiz,
                                  iconColor: const Color(0xFFE53935),
                                  value: txns.toString(),
                                  label: 'लेन-देन',
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),

              const SizedBox(height: 62),

              // ── PERSONAL INFO ───────────────────────────────────────────
              _section(
                icon: Icons.person_outline,
                title: 'व्यक्तिगत जानकारी',
                child: _loading
                    ? _infoShimmer(4)
                    : Column(
                        children: [
                          _infoRow(Icons.person, 'नाम', name),
                          _divider(),
                          _infoRow(Icons.phone, 'फ़ोन नंबर', phone),
                          _divider(),
                          _infoRow(Icons.calendar_today, 'सदस्य बने', since),
                        ],
                      ),
              ),

              // ── VEHICLES ────────────────────────────────────────────────
              _section(
                icon: Icons.local_shipping,
                title: 'मेरे वाहन (${_loading ? '…' : vehicles.length})',
                child: _loading
                    ? _infoShimmer(2)
                    : vehicles.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'कोई वाहन नहीं जुड़ा है। '
                                'बिल क्लेम करने पर वाहन अपने-आप जुड़ जाएगा।',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: vehicles
                            .asMap()
                            .entries
                            .expand(
                              (e) => [
                                if (e.key > 0) _divider(),
                                _vehicleRow(e.value),
                              ],
                            )
                            .toList(),
                      ),
              ),

              // ── ACCOUNT OPTIONS ─────────────────────────────────────────
              _section(
                icon: Icons.settings_outlined,
                title: 'अकाउंट',
                child: Column(
                  children: [
                    _menuItem(Icons.receipt_long_outlined, 'लेन-देन', null, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LenDenScreen()),
                      );
                    }),
                    _divider(),
                    _menuItem(
                      Icons.card_giftcard_outlined,
                      'मेरी रिडीम रिक्वेस्ट',
                      null,
                      () {},
                    ),
                    _divider(),
                    _menuItem(
                      Icons.help_outline,
                      'सहायता / हेल्प',
                      null,
                      () {},
                    ),
                    _divider(),
                    _menuItem(Icons.logout, 'लॉग आउट', AppColors.primary, () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('लॉग आउट'),
                          content: const Text(
                            'क्या आप वाकई लॉग आउट करना चाहते हैं?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('रद्द करें'),
                            ),
                            TextButton(
                              onPressed: () {
                                UserSession.instance.clear();
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const PhoneVerificationScreen(),
                                  ),
                                  (route) => false,
                                );
                              },
                              child: const Text(
                                'हाँ',
                                style: TextStyle(color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Text(
                '• Sarathi Sakha v1.0 • HPCL',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _vehicleRow(DriverVehicle v) {
    final idx = (_profile?.vehicles ?? []).indexOf(v);
    final label = 'वाहन ${idx + 1}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 20,
            color: AppColors.textGrey,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                    if (v.isPrimary) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          'प्राथमिक',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  v.vehicleNumber,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade300, size: 20),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.10),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _section({
    required IconData icon,
    required String title,
    required Widget child,
  }) => Container(
    color: Colors.white,
    margin: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textGrey),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: child,
        ),
      ],
    ),
  );

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textGrey),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
            ),
            const SizedBox(height: 1),
            Text(
              value.isNotEmpty ? value : '—',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _menuItem(
    IconData icon,
    String label,
    Color? color,
    VoidCallback onTap,
  ) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? AppColors.textDark),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: color ?? AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: color ?? AppColors.textGrey),
        ],
      ),
    ),
  );

  Widget _divider() => Divider(height: 1, color: Colors.grey.shade100);

  Widget _statsShimmer() => Row(
    children: List.generate(
      3,
      (i) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
          height: 76,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 6),
              Container(width: 40, height: 10, color: Colors.grey.shade200),
              const SizedBox(height: 4),
              Container(width: 30, height: 8, color: Colors.grey.shade100),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _infoShimmer(int rows) => Column(
    children: List.generate(
      rows,
      (i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 60, height: 9, color: Colors.grey.shade200),
                const SizedBox(height: 5),
                Container(width: 120, height: 12, color: Colors.grey.shade200),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
