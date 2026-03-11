import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../services/services.dart';
import 'dashboard_screen.dart';
import 'redeem_success_screen.dart';

class RedeemConfirmScreen extends StatefulWidget {
  final Map<String, dynamic> reward;
  final Map<String, dynamic> outlet;

  const RedeemConfirmScreen({
    super.key,
    required this.reward,
    required this.outlet,
  });

  @override
  State<RedeemConfirmScreen> createState() => _RedeemConfirmScreenState();
}

class _RedeemConfirmScreenState extends State<RedeemConfirmScreen> {
  bool _checkingLocation = false;
  bool _submitting = false;

  // ── Points from UserSession (populated by dashboard driver_stats API) ──────
  double get _userPoints => UserSession.instance.redeemableLiters;
  int get _rewardPoints => (widget.reward['points'] as num).toInt();
  num get _remainingPoints => (_userPoints - _rewardPoints).clamp(0, 999999);

  Future<void> _onConfirmPressed() async {
    // ── Check server setting: is geo-fencing enabled for redemptions? ────────
    final geoEnabled = AppSettings.instance.geoRedemptionEnabled;

    if (!geoEnabled) {
      // Server has geo_redemption_enabled = false → skip location check entirely
      await _doRedeem();
      return;
    }

    // ── Geo-fencing is enabled — check outlet coordinates ───────────────────
    setState(() => _checkingLocation = true);

    final outletLat = widget.outlet['lat'] as double?;
    final outletLng = widget.outlet['lng'] as double?;

    if (outletLat == null || outletLng == null) {
      // No coordinates for this outlet — skip check
      setState(() => _checkingLocation = false);
      await _doRedeem();
      return;
    }

    final result = await GeoService.checkProximity(
      outletLat: outletLat,
      outletLng: outletLng,
    );
    setState(() => _checkingLocation = false);

    if (!mounted) return;

    if (result.allowed) {
      await _doRedeem();
    } else {
      _showLocationError(result);
    }
  }

  Future<void> _doRedeem() async {
    setState(() => _submitting = true);

    final rewardId = widget.reward['id'] as String? ?? '';
    final phone = TokenStore.instance.phone ?? '';
    final address = widget.outlet['name'] as String? ?? 'Outlet Pickup';

    final result = await RedemptionService.instance.redeemReward(
      rewardId: rewardId,
      deliveryPhone: phone,
      deliveryAddress: address,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.success && result.data != null) {
      // Update UserSession remaining volume so dashboard reflects deduction
      UserSession.instance.update(
        redeemableLiters: result.data!.remainingVolume,
        totalLiters: UserSession.instance.totalLiters,
        totalTransactions: UserSession.instance.totalTransactions,
        driverName: UserSession.instance.driverName,
        driverPhone: UserSession.instance.driverPhone,
        currentLevel: UserSession.instance.currentLevel,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RedeemSuccessScreen(
            reward: widget.reward,
            outlet: widget.outlet,
            redeemResult: result.data!,
          ),
        ),
      );
    } else {
      // Show rich error dialog — goes back to dashboard on dismiss
      _showRedeemErrorDialog(result);
    }
  }

  void _showRedeemErrorDialog(ApiResponse<RedeemRewardResult> result) {
    final isInsufficient = result.errorCode == 'INSUFFICIENT_VOLUME';
    final available = (result.errorData?['available'] as num?)?.toDouble();
    final required_ = (result.errorData?['required'] as num?)?.toDouble();

    showDialog(
      context: context,
      barrierDismissible: false, // force user to tap a button
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isInsufficient
                      ? Icons.account_balance_wallet_outlined
                      : Icons.error_outline,
                  color: AppColors.primary,
                  size: 38,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                isInsufficient ? 'पर्याप्त बैलेंस नहीं' : 'रिडीम नहीं हो सका',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // Message
              Text(
                isInsufficient
                    ? 'इस रिवॉर्ड को रिडीम करने के लिए पर्याप्त लीटर नहीं हैं।'
                    : (result.errorMessage ??
                          'कुछ गड़बड़ हुई। कृपया दोबारा कोशिश करें।'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),

              // Available vs Required (only for insufficient volume)
              if (isInsufficient && available != null && required_ != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Column(
                    children: [
                      _dialogRow(
                        'आपके पास उपलब्ध:',
                        '${available.toStringAsFixed(2)} L',
                        Colors.grey.shade700,
                      ),
                      const SizedBox(height: 8),
                      _dialogRow(
                        'इस रिवॉर्ड के लिए चाहिए:',
                        '${required_.toStringAsFixed(0)} L',
                        AppColors.primary,
                      ),
                      const Divider(height: 16),
                      _dialogRow(
                        'और चाहिए:',
                        '${(required_ - available).toStringAsFixed(2)} L',
                        Colors.red,
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Buttons
              Column(
                children: [
                  // Retry (only for non-insufficient errors)
                  if (!isInsufficient)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _doRedeem();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: const Text(
                          'पुनः प्रयास करें',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  if (!isInsufficient) const SizedBox(height: 10),

                  // Go to dashboard
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop(); // close dialog
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DashboardScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.home_outlined, size: 18),
                      label: const Text('डैशबोर्ड पर जाएं'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                          color: AppColors.primary.withOpacity(0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogRow(
    String label,
    String value,
    Color valueColor, {
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: valueColor,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showLocationError(LocationCheckResult result) {
    showDialog(
      context: context,
      builder: (_) =>
          _LocationErrorDialog(result: result, outlet: widget.outlet),
    );
  }

  @override
  Widget build(BuildContext context) {
    final outletLat = widget.outlet['lat'] as double?;
    final outletLng = widget.outlet['lng'] as double?;
    final hasGeoFence = outletLat != null && outletLng != null;
    final bool busy = _checkingLocation || _submitting;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── HEADER ───────────────────────────────────────────────────────────
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
                      'रिडीम कन्फ़र्म करें',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'जानकारी जाँचें और कन्फ़र्म करें',
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── PRODUCT ──────────────────────────────────────────────────
                  _card(
                    icon: Icons.card_giftcard,
                    label: 'प्रोडक्ट',
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child:
                                widget.reward['image_url'] != null &&
                                    (widget.reward['image_url'] as String)
                                        .isNotEmpty
                                ? Image.network(
                                    widget.reward['image_url'] as String,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Image.asset(
                                      widget.reward['icon'] as String? ??
                                          'assets/images/default_gift.png',
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.contain,
                                    ),
                                  )
                                : Image.asset(
                                    widget.reward['icon'] as String? ??
                                        'assets/images/default_gift.png',
                                    width: 44,
                                    height: 44,
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
                                fontSize: 13,
                                color: AppColors.textGrey,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '$_rewardPoints L',
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

                  const SizedBox(height: 12),

                  // ── POINTS SUMMARY ────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        _pts(
                          'आपके रिडीम योग्य L',
                          '${_userPoints.round()} L',
                          Colors.black87,
                        ),
                        const Divider(height: 16),
                        _pts('कटौती', '-$_rewardPoints L', AppColors.primary),
                        const Divider(height: 16),
                        _pts(
                          'शेष L',
                          '${(_remainingPoints is double ? (_remainingPoints as double).round() : _remainingPoints.toInt())} L',
                          AppColors.primary,
                          bold: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── PICKUP OUTLET ─────────────────────────────────────────────
                  _card(
                    icon: Icons.local_gas_station,
                    label: 'पिकअप आउटलेट',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.outlet['name'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '${widget.outlet['highway'] ?? ''}, ${widget.outlet['km'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── DRIVER INFO ───────────────────────────────────────────────
                  _card(
                    icon: Icons.person,
                    label: 'ड्राइवर जानकारी',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          UserSession.instance.driverName.isNotEmpty
                              ? UserSession.instance.driverName
                              : 'Driver',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          UserSession.instance.driverPhone,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── GEO-FENCE NOTICE (only when server has geo_redemption_enabled=true) ──
                  if (AppSettings.instance.geoRedemptionEnabled &&
                      hasGeoFence) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.amber,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'रिडीम करने के लिए आपको इस HPCL आउटलेट के ${AppSettings.instance.geoDistanceMeters.toStringAsFixed(0)} मीटर के अंदर होना चाहिए।',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.orange,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── CONFIRM BUTTON ────────────────────────────────────────────
                  ElevatedButton.icon(
                    onPressed: busy ? null : _onConfirmPressed,
                    icon: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                          ),
                    label: Text(
                      _checkingLocation
                          ? 'लोकेशन जाँच रहे हैं...'
                          : _submitting
                          ? 'प्रोसेस हो रहा है...'
                          : 'रिडीम कन्फ़र्म करें',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.primary.withOpacity(
                        0.5,
                      ),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textGrey),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _pts(
    String label,
    String value,
    Color valueColor, {
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: valueColor,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// ─── LOCATION ERROR DIALOG ────────────────────────────────────────────────────

class _LocationErrorDialog extends StatelessWidget {
  final LocationCheckResult result;
  final Map<String, dynamic> outlet;
  const _LocationErrorDialog({required this.result, required this.outlet});

  @override
  Widget build(BuildContext context) {
    final isPermDenied = result.reason == LocationDenyReason.permissionDenied;
    final dist = result.distanceMeters;
    final distText = dist != null
        ? '${dist.toStringAsFixed(0)} मीटर'
        : 'अज्ञात';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPermDenied
                    ? Icons.location_off
                    : Icons.wrong_location_outlined,
                color: AppColors.primary,
                size: 38,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isPermDenied ? 'लोकेशन अनुमति नहीं है' : 'आप आउटलेट से दूर हैं',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            if (isPermDenied)
              Text(
                'रिडीम करने के लिए कृपया ऐप सेटिंग में जाकर लोकेशन अनुमति दें।',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              )
            else ...[
              Text(
                "रिडीम करने के लिए आपको \"${outlet['name']}\" के ${GeoService.allowedRadiusMeters.toStringAsFixed(0)} मीटर के अंदर होना चाहिए।",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'आपकी दूरी:',
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                          distText,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'जरूरी सीमा:',
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                          '${GeoService.allowedRadiusMeters.toStringAsFixed(0)} मीटर',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'बंद करें',
                      style: TextStyle(color: AppColors.textDark),
                    ),
                  ),
                ),
                if (isPermDenied) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Geolocator.openAppSettings();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'सेटिंग खोलें',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
