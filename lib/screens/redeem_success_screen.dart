import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../theme/app_theme.dart';
import '../services/services.dart';
import 'dashboard_screen.dart';

class RedeemSuccessScreen extends StatefulWidget {
  final Map<String, dynamic> reward;
  final Map<String, dynamic> outlet;

  /// Real API response — contains redemption_number, remaining_volume, etc.
  final RedeemRewardResult redeemResult;

  const RedeemSuccessScreen({
    super.key,
    required this.reward,
    required this.outlet,
    required this.redeemResult,
  });

  @override
  State<RedeemSuccessScreen> createState() => _RedeemSuccessScreenState();
}

class _RedeemSuccessScreenState extends State<RedeemSuccessScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _ttsPlaying = false;
  bool _ttsReady = false;

  static const String _msgOperator = 'कृपया यह रिक्वेस्ट नंबर ऑपरेटर को बताएं';
  static const String _msgNote =
      'आप अपना रिवॉर्ड HPCL ऑपरेटर से प्राप्त कर सकते हैं। '
      'यदि रिवॉर्ड अभी उपलब्ध नहीं है, '
      'तो इसके उपलब्ध होते ही आपको सूचित कर दिया जाएगा।';

  String get _requestNumber => widget.redeemResult.redemptionNumber;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      if (Platform.isAndroid) {
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.ambient,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
          IosTextToSpeechAudioMode.voicePrompt,
        );
      }
      if (Platform.isIOS) {
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
          ],
          IosTextToSpeechAudioMode.voicePrompt,
        );
      }

      final langs = await _tts.getLanguages as List<dynamic>?;
      String lang = 'en-IN';
      if (langs != null) {
        final hiIn = langs
            .map((l) => l.toString())
            .firstWhere((l) => l.toLowerCase() == 'hi-in', orElse: () => '');
        final hi = langs
            .map((l) => l.toString())
            .firstWhere((l) => l.toLowerCase() == 'hi', orElse: () => '');
        if (hiIn.isNotEmpty) {
          lang = hiIn;
        } else if (hi.isNotEmpty) {
          lang = hi;
        }
      }
      await _tts.setLanguage(lang);
      await _tts.setSpeechRate(0.42);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);

      _tts.setStartHandler(() {
        if (mounted) setState(() => _ttsPlaying = true);
      });
      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _ttsPlaying = false);
      });
      _tts.setCancelHandler(() {
        if (mounted) setState(() => _ttsPlaying = false);
      });
      _tts.setErrorHandler((m) {
        debugPrint('TTS: $m');
        if (mounted) setState(() => _ttsPlaying = false);
      });

      if (mounted) setState(() => _ttsReady = true);
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) _speak();
    } catch (e) {
      debugPrint('TTS init: $e');
    }
  }

  Future<void> _speak() async {
    if (!_ttsReady) return;
    if (_ttsPlaying) {
      await _tts.stop();
      if (mounted) setState(() => _ttsPlaying = false);
      return;
    }
    setState(() => _ttsPlaying = true);
    await _tts.speak(_msgOperator);
    await Future.delayed(const Duration(milliseconds: 400));
    await _tts.speak(_spellOut(_requestNumber));
    await Future.delayed(const Duration(milliseconds: 600));
    await _tts.speak(_msgNote);
    if (mounted) setState(() => _ttsPlaying = false);
  }

  String _spellOut(String rq) {
    const map = {
      'R': 'आर',
      'Q': 'क्यू',
      'D': 'डी',
      'M': 'एम',
      'A': 'ए',
      'B': 'बी',
      'C': 'सी',
      'E': 'ई',
      'F': 'एफ',
      'G': 'जी',
      'H': 'एच',
      'I': 'आई',
      'J': 'जे',
      'K': 'के',
      'L': 'एल',
      'N': 'एन',
      'O': 'ओ',
      'P': 'पी',
      'S': 'एस',
      'T': 'टी',
      'U': 'यू',
      'V': 'वी',
      'W': 'डबल यू',
      'X': 'एक्स',
      'Y': 'वाय',
      'Z': 'ज़ेड',
    };
    return rq.toUpperCase().split('').map((c) => map[c] ?? c).join(',  ');
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.redeemResult;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── SUCCESS HEADER ─────────────────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppGradients.headerGradient,
              ),
              padding: const EdgeInsets.only(
                top: 80,
                left: 16,
                right: 16,
                bottom: 40,
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'रिडीम रिक्वेस्ट सफल! 🎉',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'आपकी रिक्वेस्ट दर्ज हो गई है',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ── REQUEST NUMBER CARD ────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'रिक्वेस्ट नंबर',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textGrey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _requestNumber,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Copy
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(text: _requestNumber),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('कॉपी हो गया!'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.copy,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // TTS
                            GestureDetector(
                              onTap: _speak,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _ttsPlaying
                                      ? AppColors.primary
                                      : AppColors.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  _ttsPlaying
                                      ? Icons.stop_rounded
                                      : Icons.volume_up_rounded,
                                  color: _ttsPlaying
                                      ? Colors.white
                                      : AppColors.primary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.touch_app_outlined,
                              size: 12,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _ttsPlaying
                                  ? 'बोल रहा है... (रोकने के लिए टैप करें)'
                                  : 'सुनने के लिए 🔊 दबाएं',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.info_outline,
                        size: 13,
                        color: AppColors.textGrey,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'कृपया यह रिक्वेस्ट नंबर ऑपरेटर को बताएं',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── VOLUME DEDUCTED SUMMARY ────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _summaryTile(
                          'कटौती',
                          '${result.volumeDeducted.round()} L',
                          AppColors.primary,
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: Colors.green.shade200,
                        ),
                        _summaryTile(
                          'शेष बैलेंस',
                          '${result.remainingVolume.round()} L',
                          Colors.green.shade700,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── IMPORTANT NOTE ─────────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9E6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.amber,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'ज़रूरी सूचना (Note)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'आप अपना रिवॉर्ड HPCL ऑपरेटर से प्राप्त कर सकते हैं। '
                          'यदि रिवॉर्ड अभी उपलब्ध नहीं है, तो इसके उपलब्ध होते ही '
                          'आपको सूचित कर दिया जाएगा।',
                          style: TextStyle(fontSize: 13, height: 1.5),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '(You can collect your reward from HPCL operator. '
                          'If not available, you will be notified when it is back in stock.)',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textGrey,
                            height: 1.4,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── PRODUCT INFO ───────────────────────────────────────────────
                  _infoCard(
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Image.asset(
                              widget.reward['icon'] as String? ??
                                  'assets/images/default_gift.png',
                              width: 40,
                              height: 40,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                result.rewardNameHi.isNotEmpty
                                    ? result.rewardNameHi
                                    : widget.reward['name_hi'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                result.rewardName.isNotEmpty
                                    ? result.rewardName
                                    : widget.reward['name'] as String,
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
                                    size: 12,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${widget.reward['points']} L',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── OUTLET INFO ────────────────────────────────────────────────
                  _infoCard(
                    label: 'पिकअप आउटलेट',
                    icon: Icons.local_gas_station,
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
                  const SizedBox(height: 10),

                  // ── DRIVER INFO ────────────────────────────────────────────────
                  _infoCard(
                    label: 'ड्राइवर',
                    icon: Icons.person,
                    child: Text(
                      result.driverName.isNotEmpty
                          ? result.driverName
                          : UserSession.instance.driverName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── NOTIFICATION ───────────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.notifications_outlined,
                          color: Colors.blue,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'जब ऑपरेटर आपकी रिक्वेस्ट प्रोसेस करेगा, तो आपको ऐप पर '
                            'नोटिफिकेशन मिलेगा और स्टेटस अपडेट हो जाएगा।',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── DASHBOARD BUTTON ───────────────────────────────────────────
                  ElevatedButton(
                    onPressed: () {
                      _tts.stop();
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
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'डैशबोर्ड पर वापस जाएं',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _infoCard({String? label, IconData? icon, required Widget child}) {
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
          if (label != null && icon != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(icon, size: 14, color: AppColors.textGrey),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
          child,
        ],
      ),
    );
  }
}
