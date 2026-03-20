import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/services.dart';
import 'bill_details_screen.dart';
import 'bill_rejected_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 2 — "AI बिल को पढ़ रहा है..."
// Receives the image file, calls BillService.extractBill(),
// animates progress bar, then pushes BillDetailsScreen with the result.
// ─────────────────────────────────────────────────────────────────────────────

class BillProcessingScreen extends StatefulWidget {
  final File imageFile;
  final double? driverLat; // GPS latitude  — null if permission denied
  final double? driverLng; // GPS longitude — null if permission denied

  const BillProcessingScreen({
    super.key,
    required this.imageFile,
    this.driverLat,
    this.driverLng,
  });

  @override
  State<BillProcessingScreen> createState() => _BillProcessingScreenState();
}

class _BillProcessingScreenState extends State<BillProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;
  double _progress = 0.0;
  String _statusText = 'AI बिल को पढ़ रहा है...';
  String _subText = 'बिल की जानकारी निकाली जा रही है...';
  bool _hasError = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _runExtraction();
  }

  Future<void> _runExtraction() async {
    // ── Animate progress to 30% while API call happens ─────────────────────
    _animateTo(0.15, 'AI बिल को पढ़ रहा है...', 'बिल स्कैन हो रहा है...');
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    _animateTo(0.35, 'AI बिल को पढ़ रहा है...', 'डेटा निकाला जा रहा है...');

    // ── Make the real API call ──────────────────────────────────────────────
    final result = await BillService.instance.extractBill(
      widget.imageFile,
      TokenStore.instance.driverId ?? '',
      driverLat: widget.driverLat,
      driverLng: widget.driverLng,
    );

    if (!mounted) return;

    // ── CASE 1: Rejection (NOT_HPCL / DUPLICATE) ────────────────────────────
    // API returns success=false but includes bill data — show rejection screen.
    if (result.isRejection && result.data != null) {
      _animateTo(1.0, 'जाँच पूरी हुई', '');
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BillRejectedScreen(
            billData: result.data!,
            imageFile: widget.imageFile,
            errorCode: result.errorCode ?? 'REJECTED',
            errorMessage: result.errorMessage ?? 'बिल स्वीकार नहीं हुआ।',
          ),
        ),
      );
      return;
    }

    // ── CASE 2: Success ──────────────────────────────────────────────────────
    if (result.success && result.data != null) {
      _animateTo(0.70, 'AI बिल को पढ़ रहा है...', 'लगभग पूरा हो गया!');
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;

      _animateTo(1.0, 'बिल पढ़ा गया! ✓', 'पूरा हो गया');
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BillDetailsScreen(
            billData: result.data!,
            imageFile: widget.imageFile,
          ),
        ),
      );
      return;
    }

    // ── CASE 3: Hard error (network / server) ────────────────────────────────
    setState(() {
      _hasError = true;
      _errorMsg = result.errorMessage ?? 'बिल पढ़ने में समस्या हुई।';
      _progress = 0;
      _statusText = 'कुछ गड़बड़ हुई';
      _subText = '';
    });
    _spinController.stop();
  }

  void _animateTo(double val, String status, String sub) {
    if (!mounted) return;
    setState(() {
      _progress = val;
      _statusText = status;
      _subText = sub;
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── HEADER ──────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: AppGradients.headerGradient,
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
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
                      'रिवॉर्ड क्लेम करें',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'बिल प्रोसेस हो रहा है...',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── BODY ────────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _hasError ? _errorView() : _processingView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _processingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Bill image preview (real image from camera)
        Container(
          width: 200,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.13),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(widget.imageFile, fit: BoxFit.cover),
          ),
        ),

        const SizedBox(height: 36),

        // Spinning loader (matches screenshot 2)
        RotationTransition(
          turns: _spinController,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 3.5),
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 2),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        Text(
          _statusText,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),

        const SizedBox(height: 18),

        // Progress bar (red, matches screenshot 2)
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
              minHeight: 5,
            ),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          _subText,
          style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _errorView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.error_outline, color: Colors.red, size: 40),
        ),
        const SizedBox(height: 20),
        const Text(
          'बिल पढ़ने में समस्या हुई',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _errorMsg ?? '',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            // Retry
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _errorMsg = null;
                    _progress = 0;
                    _statusText = 'AI बिल को पढ़ रहा है...';
                    _subText = 'बिल की जानकारी निकाली जा रही है...';
                  });
                  _spinController.repeat();
                  _runExtraction();
                },
                icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                label: const Text(
                  'पुनः प्रयास',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Go back to retake
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('दोबारा लें'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
