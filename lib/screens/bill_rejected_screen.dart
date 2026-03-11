import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/bill_service.dart';
import 'reward_claim_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BILL REJECTED SCREEN
// Shown when /extract-bill returns success:false.
// Handles two primary error codes:
//   NOT_HPCL  → "यह बिल HPCL का नहीं है"
//   DUPLICATE → "यह बिल पहले से क्लेम किया जा चुका है"
//   <other>   → generic rejection using API error message
//
// Layout (matches screenshot):
//   Header (gradient) with ⚠ subtitle
//   Warning icon circle
//   "बिल अस्वीकृत" title
//   Red reason box
//   Detail rows: रसीद नंबर / मात्रा / आउटलेट
//   Bill image thumbnail
//   Fixed bottom button: "दूसरा बिल अपलोड करें"
// ─────────────────────────────────────────────────────────────────────────────

class BillRejectedScreen extends StatelessWidget {
  final BillExtractResult billData;
  final File imageFile;
  final String errorCode; // "NOT_HPCL" | "DUPLICATE" | …
  final String errorMessage; // Hindi message from API

  const BillRejectedScreen({
    super.key,
    required this.billData,
    required this.imageFile,
    required this.errorCode,
    required this.errorMessage,
  });

  String get _reasonText {
    switch (errorCode.toUpperCase()) {
      case 'NOT_HPCL':
        return errorMessage.isNotEmpty
            ? errorMessage
            : 'यह बिल HPCL का नहीं है। केवल HPCL के बिल स्वीकार किए जाते हैं।';
      case 'DUPLICATE':
        return errorMessage.isNotEmpty
            ? errorMessage
            : 'यह बिल पहले से क्लेम किया जा चुका है। डुप्लीकेट बिल स्वीकार नहीं होते।';
      default:
        return errorMessage.isNotEmpty
            ? errorMessage
            : 'यह बिल स्वीकार नहीं किया जा सका। कृपया दूसरा बिल अपलोड करें।';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDetails =
        billData.billNumber.isNotEmpty ||
        billData.quantity > 0 ||
        billData.outlet.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'रिवॉर्ड क्लेम करें',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    // ⚠ subtitle matching screenshot
                    Row(
                      children: const [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.amber,
                          size: 13,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'बिल स्वीकार नहीं हुआ',
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── SCROLLABLE BODY ──────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Warning icon
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red.shade400,
                      size: 48,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Title
                  const Text(
                    'बिल अस्वीकृत',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Reason box — red tint, matches screenshot
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _reasonText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.red.shade700,
                        height: 1.55,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Bill detail rows — only shown when data is available
                  if (hasDetails)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          if (billData.billNumber.isNotEmpty) ...[
                            _detailRow('रसीद नंबर:', billData.billNumber),
                          ],
                          if (billData.quantity > 0) ...[
                            if (billData.billNumber.isNotEmpty)
                              Divider(height: 1, color: Colors.grey.shade100),
                            _detailRow('मात्रा:', billData.quantityFormatted),
                          ],
                          if (billData.outlet.isNotEmpty) ...[
                            if (billData.quantity > 0 ||
                                billData.billNumber.isNotEmpty)
                              Divider(height: 1, color: Colors.grey.shade100),
                            _detailRow('आउटलेट:', billData.outlet),
                          ],
                        ],
                      ),
                    ),

                  if (hasDetails) const SizedBox(height: 20),

                  // Bill image thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      imageFile,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),

                  // Extra space so content isn't hidden by the bottom button
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ── FIXED BOTTOM BUTTON ──────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Pop back to RewardClaimScreen (clear processing screen too)
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RewardClaimScreen(),
                    ),
                    (route) => route.isFirst,
                  );
                },
                icon: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                label: const Text(
                  'दूसरा बिल अपलोड करें',
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
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: AppColors.textGrey),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
