import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../services/services.dart';
import 'claim_success_screen.dart';
import 'dashboard_screen.dart';

class BillDetailsScreen extends StatefulWidget {
  /// Extracted bill data from /extract-bill (contains invoiceUrl).
  final BillExtractResult billData;

  /// Original image file — kept here (not on BillExtractResult).
  /// Used as fallback if invoiceUrl is null.
  final File imageFile;

  const BillDetailsScreen({
    super.key,
    required this.billData,
    required this.imageFile,
  });

  @override
  State<BillDetailsScreen> createState() => _BillDetailsScreenState();
}

class _BillDetailsScreenState extends State<BillDetailsScreen> {
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkZeroFields());
  }

  // ── Blocking popup when any critical field is 0 ───────────────────────────
  void _checkZeroFields() {
    final bill = widget.billData;
    final List<String> zeroFields = [];
    if (bill.quantity <= 0) zeroFields.add('मात्रा (लीटर)');
    if (bill.ratePerLitre <= 0) zeroFields.add('दर (प्रति लीटर)');
    if (bill.totalAmount <= 0) zeroFields.add('कुल राशि');
    if (zeroFields.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
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
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.orange.shade700,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'बिल स्कैन अधूरा',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'नीचे दी गई जानकारी बिल से नहीं पढ़ी जा सकी:',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: zeroFields
                    .map(
                      (f) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cancel_outlined,
                              size: 14,
                              color: Colors.red.shade600,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              f,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),
              Text(
                'बिल की फ़ोटो साफ़ और सही रोशनी में दोबारा लें।',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop(); // close dialog
                    // Pop back to RewardClaimScreen (past BillDetailsScreen + BillProcessingScreen)
                    int count = 0;
                    Navigator.of(context).popUntil((_) => count++ >= 2);
                  },
                  icon: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Text(
                    'दोबारा फ़ोटो लें',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitClaim() async {
    final outletId =
        widget.billData.outletId ?? UserSession.instance.selectedOutletId;

    if (outletId == null || outletId.isEmpty) {
      _showError('आउटलेट नहीं मिला। कृपया सहायता से संपर्क करें।');
      return;
    }

    setState(() => _submitting = true);

    // ── Get driver GPS (best-effort — submit proceeds even if denied) ──────
    double? driverLat;
    double? driverLng;
    try {
      if (await Geolocator.isLocationServiceEnabled()) {
        LocationPermission perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm != LocationPermission.denied &&
            perm != LocationPermission.deniedForever) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
          ).timeout(const Duration(seconds: 10));
          driverLat = pos.latitude;
          driverLng = pos.longitude;
        }
      }
    } catch (_) {
      // Location unavailable — continue without it
    }

    final bytes = await widget.imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final result = await BillService.instance.submitClaim(
      bill: widget.billData,
      outletId: outletId,
      imageBase64: base64Image,
      driverLat: driverLat,
      driverLng: driverLng,
    );

    if (!mounted) return;

    if (result.success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ClaimSuccessScreen(pointsEarned: widget.billData.points),
        ),
      );
    } else {
      setState(() => _submitting = false);
      _showError(
        result.errorMessage ??
            'क्लेम सबमिट नहीं हो सका। कृपया दोबारा कोशिश करें।',
      );
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                msg,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text(
                    'ठीक है',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bill = widget.billData;
    final points = bill.points;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── HEADER ──────────────────────────────────────────────────────────
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
                  'assets/images/hpcl_logo.png',
                  height: 36,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'रिवॉर्ड क्लेम करें',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'बिल की जानकारी जाँचें',
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── SCROLLABLE BODY ─────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                children: [
                  // Bill image preview (real image from camera)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(
                            widget.imageFile,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'बिल की फ़ोटो',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: const [
                                  Text(
                                    'AI द्वारा डेटा निकाला गया ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textGrey,
                                    ),
                                  ),
                                  Text('✅', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                              // Show invoice_url status
                              if (bill.invoiceUrl != null)
                                Text(
                                  'अपलोड हो गया ✓',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.close,
                            color: AppColors.textGrey,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── BILL INFO CARD ─────────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.receipt_long,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'बिल की जानकारी',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        _row(
                          Icons.local_gas_station,
                          'ईंधन प्रकार',
                          bill.fuelType.isNotEmpty ? bill.fuelType : '—',
                        ),
                        _div(),
                        _row(
                          Icons.tag,
                          'मात्रा (लीटर)',
                          bill.quantityFormatted,
                          bold: true,
                          color: bill.quantity <= 0
                              ? Colors.red
                              : AppColors.primary,
                          isZero: bill.quantity <= 0,
                        ),
                        _div(),
                        _row(
                          Icons.currency_rupee,
                          'दर (प्रति लीटर)',
                          bill.rateFormatted,
                          color: bill.ratePerLitre <= 0
                              ? Colors.red
                              : AppColors.primary,
                          isZero: bill.ratePerLitre <= 0,
                        ),
                        _div(),
                        _row(
                          Icons.currency_rupee,
                          'कुल राशि',
                          bill.totalFormatted,
                          bold: true,
                          color: bill.totalAmount <= 0
                              ? Colors.red
                              : AppColors.primary,
                          isZero: bill.totalAmount <= 0,
                        ),
                        _div(),
                        _row(
                          Icons.location_on_outlined,
                          'आउटलेट',
                          bill.displayOutletName.isNotEmpty
                              ? bill.displayOutletName
                              : '—',
                        ),
                        _div(),
                        _row(
                          Icons.calendar_today_outlined,
                          'तारीख',
                          bill.date.isNotEmpty ? bill.date : '—',
                        ),
                        _div(),
                        _row(
                          Icons.directions_car_outlined,
                          'वाहन नंबर',
                          bill.vehicleNumber.isNotEmpty
                              ? bill.vehicleNumber
                              : '—',
                        ),
                        _div(),
                        _row(
                          Icons.receipt_outlined,
                          'बिल नंबर',
                          bill.billNumber.isNotEmpty ? bill.billNumber : '—',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── POINTS SUMMARY ─────────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'इस बिल से मिलेंगे',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textGrey,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 22,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$points पॉइंट्स',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '1 लीटर = 1 पॉइंट',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── SUBMIT BUTTON ──────────────────────────────────────────────
                  ElevatedButton.icon(
                    onPressed: _submitting ? null : _submitClaim,
                    icon: _submitting
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
                            size: 20,
                          ),
                    label: Text(
                      _submitting ? 'सबमिट हो रहा है...' : 'क्लेम सबमिट करें',
                      style: TextStyle(
                        color: _submitting ? Colors.white70 : Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary.withValues(
                        alpha: 0.85,
                      ),
                      disabledBackgroundColor: AppColors.primary.withValues(
                        alpha: 0.5,
                      ),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'दोबारा फ़ोटो लें',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textDark,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    IconData icon,
    String label,
    String value, {
    Color color = AppColors.textDark,
    bool bold = false,
    bool isZero = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: isZero ? 8 : 0),
      decoration: isZero
          ? BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade100),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: isZero ? Colors.red.shade400 : AppColors.textGrey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isZero ? Colors.red.shade400 : AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        color: color,
                        fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    if (isZero) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'नहीं पढ़ा',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _div() => Divider(height: 1, color: Colors.grey.shade100);
}
