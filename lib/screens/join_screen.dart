import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  static const shareUrl =
      'https://play.google.com/store/apps/details?id=com.hpcl.highwayrewards';

  @override
  void initState() {
    super.initState();
    // Show bottom sheet after first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showShareBottomSheet();
    });
  }

  void _showShareBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (_) => _ShareBottomSheet(
        onCopy: () {
          Clipboard.setData(const ClipboardData(text: shareUrl));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('लिंक कॉपी हो गया!'),
              duration: Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = MockData.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with gradient
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
                  Image.asset(
                    'assets/images/sarathi-sakha-logo.png',
                    height: 36,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Highway Rewards',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white24,
                    child: Text(
                      (user['name'] as String)[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Points card
            Container(
              margin: const EdgeInsets.all(0),
              decoration: const BoxDecoration(
                gradient: AppGradients.headerGradient,
              ),
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'कुल पॉइंट्स',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${user['total_points']} pts',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'रिडीम योग्य',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${user['redeemable_points']} pts',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value:
                            (user['redeemable_points'] as int) /
                            (user['total_points'] as int),
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Stats Row
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.local_gas_station,
                          color: Colors.blue,
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${user['liters_filled']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'लीटर भरे',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 48, color: Colors.grey.shade200),
                  Expanded(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: Colors.orange,
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${user['transactions']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'लेन-देन',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Share invite card
            GestureDetector(
              onTap: _showShareBottomSheet,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.group_add,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'दोस्तों को जोड़ें',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'ऐप शेयर करें और साथ में पॉइंट्स कमाएं',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textGrey),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

// ─── SHARE BOTTOM SHEET ───────────────────────────────────────────────────────

class _ShareBottomSheet extends StatelessWidget {
  final VoidCallback onCopy;
  static const shareUrl =
      'https://play.google.com/store/apps/details?id=com.hpcl.highwayrewards';

  const _ShareBottomSheet({required this.onCopy});

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
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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

          // Title row
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

          const SizedBox(height: 8),

          Text(
            'अपने दोस्तों को Highway Rewards ऐप शेयर करें और साथ में पॉइंट्स कमाएं',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),

          const SizedBox(height: 18),

          // URL Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    shareUrl,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textGrey,
                    ),
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

          // Share buttons row
          Row(
            children: [
              _shareBtn(
                context,
                icon: Icons.chat_bubble_outline,
                label: 'WhatsApp',
                bg: Colors.grey.shade100,
                iconColor: Colors.green,
              ),
              const SizedBox(width: 10),
              _shareBtn(
                context,
                icon: Icons.sms_outlined,
                label: 'SMS',
                bg: Colors.grey.shade100,
                iconColor: Colors.blue,
              ),
              const SizedBox(width: 10),
              _shareBtn(
                context,
                icon: Icons.share,
                label: 'और शेयर',
                bg: AppColors.primary.withValues(alpha: 0.1),
                iconColor: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shareBtn(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color bg,
    required Color iconColor,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
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
                style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
