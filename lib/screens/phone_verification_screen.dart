import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/services.dart';
import 'dashboard_screen.dart';

// ─── PHONE VERIFICATION ───────────────────────────────────────────────────────

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key});
  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _phoneCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length != 10) {
      setState(() => _error = 'कृपया 10 अंकों का मोबाइल नंबर दर्ज करें');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await AuthService.instance.sendOtp('+91$phone');
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.data?.message ?? 'OTP भेजा गया!'),
          backgroundColor: AppColors.redeemGreen,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OTPVerificationScreen(phone: phone)),
      );
    } else {
      setState(() => _error = result.errorMessage ?? 'OTP भेजने में समस्या।');
    }
  }

  DateTime? _lastBackPress;

  Future<void> _onBackPressed() async {
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
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // PopScope intercepts back — shows "press again to exit" toast instead of blank screen
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _onBackPressed();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F4F4),
        body: Column(
          children: [
            // ── HEADER ──────────────────────────────────────────────────────
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
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                right: 16,
                bottom: 20,
              ),
              child: Row(
                children: [
                  // No back arrow — PhoneVerificationScreen is the root screen
                  const SizedBox(width: 36),
                  Image.asset(
                    'assets/images/sarathi-sakha-logo.png',
                    height: 36,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'पहचान सत्यापित करें',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'अपना मोबाइल नंबर डालें',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── BODY ─────────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const SizedBox(height: 52),

                    // Phone icon in circle
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.phone_outlined,
                        size: 30,
                        color: Color(0xFF6B7280),
                      ),
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      'मोबाइल नंबर',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'हम आपको एक वेरिफिकेशन कोड भेजेंगे',
                      style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                    ),

                    const SizedBox(height: 32),

                    // ── Input field ─────────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _error != null
                              ? AppColors.primary
                              : const Color(0xFFE5E7EB),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 15,
                            ),
                            child: Text(
                              '+91',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 22,
                            color: const Color(0xFFE5E7EB),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                counterText: '',
                                hintText: 'मोबाइल नंबर डालें',
                                hintStyle: TextStyle(
                                  color: Color(0xFFD1D5DB),
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 15,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF111827),
                              ),
                              onChanged: (_) => setState(() => _error = null),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 13,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _error!,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ── OTP button ──────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _sendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE05C6A),
                          disabledBackgroundColor: const Color(
                            0xFFE05C6A,
                          ).withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'OTP भेजें',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 14),
                    Text(
                      'डेमो OTP: 123456',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ), // Scaffold
    ); // PopScope
  }
}

// ─── OTP VERIFICATION ─────────────────────────────────────────────────────────

class OTPVerificationScreen extends StatefulWidget {
  final String phone;
  const OTPVerificationScreen({super.key, required this.phone});
  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  // Single controller captures all 6 digits reliably — avoids focus-race
  // issues that cause dropped digits on fast input and broken backspace.
  final TextEditingController _otpCtrl = TextEditingController();
  final FocusNode _otpFocus = FocusNode();
  bool _loading = false;
  bool _resending = false;
  String? _error;

  // Derived display list — always exactly 6 entries (empty string if not typed yet)
  List<String> get _digits {
    final raw = _otpCtrl.text;
    return List.generate(6, (i) => i < raw.length ? raw[i] : '');
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  String get _otpValue => _otpCtrl.text;

  Future<void> _verifyOtp() async {
    final otp = _otpValue;
    if (otp.length != 6) {
      setState(() => _error = 'कृपया 6 अंकों का OTP दर्ज करें');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await AuthService.instance.verifyOtp(
      phone: '+91${widget.phone}',
      otp: otp,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (r) => false,
      );
    } else {
      setState(() => _error = result.errorMessage ?? 'OTP गलत है।');
      _otpCtrl.clear();
      _otpFocus.requestFocus();
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _resending = true;
      _error = null;
    });
    final result = await AuthService.instance.sendOtp('+91${widget.phone}');
    if (!mounted) return;
    setState(() => _resending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? result.data?.message ?? 'OTP दोबारा भेजा गया!'
              : result.errorMessage ?? 'समस्या हुई।',
        ),
        backgroundColor: result.success
            ? AppColors.redeemGreen
            : AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: Column(
        children: [
          // ── HEADER ──────────────────────────────────────────────────────
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
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
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
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Image.asset(
                  'assets/images/hpcl_logo.png',
                  height: 36,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'पहचान सत्यापित करें',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'अपना मोबाइल नंबर डालें',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── BODY ─────────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 52),

                  // Shield icon in circle
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.verified_user_outlined,
                      size: 30,
                      color: Color(0xFF6B7280),
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    'OTP डालें',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '+91 ${widget.phone} पर भेजा गया',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── 6 OTP boxes (display only) + hidden single TextField ──
                  // A single hidden TextField captures all input reliably.
                  // This prevents dropped digits on fast typing and fixes
                  // backspace not working on empty boxes.
                  GestureDetector(
                    onTap: () => _otpFocus.requestFocus(),
                    child: Stack(
                      children: [
                        // Invisible real TextField — sits behind the boxes
                        Opacity(
                          opacity: 0,
                          child: SizedBox(
                            height: 52,
                            child: TextField(
                              controller: _otpCtrl,
                              focusNode: _otpFocus,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (val) {
                                setState(() => _error = null);
                                if (val.length == 6) _verifyOtp();
                              },
                              decoration: const InputDecoration(
                                counterText: '',
                              ),
                            ),
                          ),
                        ),
                        // Visual display boxes — purely decorative, not editable
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _otpCtrl,
                          builder: (context, value, _) {
                            final digits = List.generate(
                              6,
                              (i) => i < value.text.length ? value.text[i] : '',
                            );
                            final activebox = value.text.length < 6
                                ? value.text.length
                                : 5;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(6, (i) {
                                final isFilled = digits[i].isNotEmpty;
                                final isActive =
                                    i == activebox && _otpFocus.hasFocus;
                                return Container(
                                  width: 44,
                                  height: 52,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _error != null
                                          ? AppColors.primary
                                          : isActive
                                          ? const Color(0xFFE05C6A)
                                          : const Color(0xFFE5E7EB),
                                      width: isActive ? 2 : 1.2,
                                    ),
                                  ),
                                  child: isFilled
                                      ? Text(
                                          digits[i],
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF111827),
                                          ),
                                        )
                                      : null,
                                );
                              }),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // ── Verify button ────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE05C6A),
                        disabledBackgroundColor: const Color(
                          0xFFE05C6A,
                        ).withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'OTP सत्यापित करें',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Change number + resend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'नंबर बदलें',
                          style: TextStyle(
                            color: Color(0xFFE05C6A),
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFFE05C6A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
