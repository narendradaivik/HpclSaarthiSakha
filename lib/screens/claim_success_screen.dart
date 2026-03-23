import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';

class ClaimSuccessScreen extends StatefulWidget {
  final int pointsEarned;
  const ClaimSuccessScreen({super.key, this.pointsEarned = 10});

  @override
  State<ClaimSuccessScreen> createState() => _ClaimSuccessScreenState();
}

class _ClaimSuccessScreenState extends State<ClaimSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pts = widget.pointsEarned;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // ── Animated check icon ──────────────────────────────────
                ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_outline,
                        color: AppColors.primary, size: 46),
                  ),
                ),
                const SizedBox(height: 22),

                // ── Headline ─────────────────────────────────────────────
                const Text(
                  'लीटर जुड़ गए! 🎉',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold,
                      color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                Text(
                  'आपका फ्यूल बिल प्रोसेस हो गया',
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 28),

                // ── Detail card ───────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Big litre amount
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Icon(Icons.local_gas_station,
                              color: AppColors.primary, size: 28),
                          const SizedBox(width: 6),
                          Text(
                            '+$pts',
                            style: const TextStyle(
                                fontSize: 40, fontWeight: FontWeight.bold,
                                color: AppColors.primary, height: 1.0),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(left: 3, bottom: 5),
                            child: Text('L',
                                style: TextStyle(fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('लीटर आपके अकाउंट में जोड़े गए',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade500)),

                      const SizedBox(height: 18),
                      _divider(),
                      const SizedBox(height: 14),

                      // ईंधन मात्रा row
                      _row('ईंधन मात्रा', '$pts लीटर',
                          valueColor: AppColors.textDark),
                      const SizedBox(height: 10),

                      // स्टेटस row
                      _row('स्टेटस', 'सबमिट हो गया ✓',
                          valueColor: AppColors.primary,
                          valueBold: true),

                      const SizedBox(height: 16),
                      _divider(),
                      const SizedBox(height: 12),

                      // Footer note
                      Text(
                        'अप्रूवल के बाद लीटर आपके अकाउंट में कन्फर्म होंगे',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // ── CTA Button ───────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _toDashboard,
                    icon: const Icon(Icons.arrow_forward,
                        color: Colors.white, size: 18),
                    iconAlignment: IconAlignment.end,
                    label: const Text(
                      'डैशबोर्ड पर वापस जाएं',
                      style: TextStyle(
                          color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A4E),
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value,
      {Color valueColor = AppColors.textDark, bool valueBold = false}) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  color: valueColor,
                  fontWeight:
                      valueBold ? FontWeight.bold : FontWeight.w500)),
        ],
      );

  Widget _divider() =>
      Divider(height: 1, thickness: 1, color: Colors.grey.shade100);
}
