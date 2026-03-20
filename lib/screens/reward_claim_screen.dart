import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';
import 'bill_processing_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 1 — Camera capture → Crop → BillProcessingScreen
// Flow: open screen → tap camera box → camera opens → crop screen →
//       "ठीक है" → cropped File stored → "बिल जमा करें" → Screen 2
// ─────────────────────────────────────────────────────────────────────────────

class RewardClaimScreen extends StatefulWidget {
  const RewardClaimScreen({super.key});
  @override
  State<RewardClaimScreen> createState() => _RewardClaimScreenState();
}

class _RewardClaimScreenState extends State<RewardClaimScreen> {
  File? _croppedFile; // final cropped image — sent to API
  final ImagePicker _picker = ImagePicker();

  // ── Location fields ────────────────────────────────────────────────────────
  double? _driverLat; // set after permission granted
  double? _driverLng;
  bool _locationGranted = false;
  bool _locationLoading = false;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission(); // ask immediately when screen opens
  }

  // ── Request permission then fetch position ─────────────────────────────────
  Future<void> _requestLocationPermission() async {
    setState(() => _locationLoading = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) {
          setState(() {
            _locationLoading = false;
            _locationGranted = false;
          });
          _showLocationServiceDialog();
        }
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationLoading = false;
            _locationGranted = false;
          });
          _showPermissionDeniedForeverDialog();
        }
        return;
      }

      if (perm == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _locationLoading = false;
            _locationGranted = false;
          });
        }
        return;
      }

      // Permission granted — get current position
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          _driverLat = pos.latitude;
          _driverLng = pos.longitude;
          _locationGranted = true;
          _locationLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  // ── Silently refresh position just before sending to API ──────────────────
  Future<void> _refreshLocation() async {
    if (!_locationGranted) return;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 8));
      _driverLat = pos.latitude;
      _driverLng = pos.longitude;
    } catch (_) {} // keep existing coords on failure
  }

  // ── Pick image then immediately open crop screen ───────────────────────────
  Future<void> _pickAndCrop(ImageSource source) async {
    // Silently update GPS coords in background while camera is opening
    _refreshLocation();
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (picked == null) return;

      if (!mounted) return;

      // Push crop screen — returns cropped File or null (if cancelled)
      final cropped = await Navigator.push<File>(
        context,
        MaterialPageRoute(
          builder: (_) => _CropScreen(imageFile: File(picked.path)),
        ),
      );

      if (cropped != null && mounted) {
        setState(() => _croppedFile = cropped);
      }
    } catch (e) {
      if (mounted) {
        _showError('फ़ोटो नहीं मिली। कृपया अनुमति दें और पुनः प्रयास करें।');
      }
    }
  }

  // ── Bottom sheet: Camera or Gallery (for retake) ───────────────────────────
  void _showSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'फ़ोटो चुनें',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _SourceTile(
                      icon: Icons.camera_alt_rounded,
                      label: 'कैमरा',
                      onTap: () {
                        Navigator.pop(ctx);
                        Future.delayed(
                          const Duration(milliseconds: 300),
                          () => _pickAndCrop(ImageSource.camera),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SourceTile(
                      icon: Icons.photo_library_rounded,
                      label: 'गैलरी',
                      onTap: () {
                        Navigator.pop(ctx);
                        Future.delayed(
                          const Duration(milliseconds: 300),
                          () => _pickAndCrop(ImageSource.gallery),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.location_off, color: Colors.orange, size: 22),
            SizedBox(width: 8),
            Text('लोकेशन बंद है', style: TextStyle(fontSize: 17)),
          ],
        ),
        content: const Text(
          'बिल सत्यापन के लिए लोकेशन ज़रूरी है। कृपया डिवाइस की लोकेशन चालू करें।',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'बाद में',
              style: TextStyle(color: AppColors.textGrey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'चालू करें',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedForeverDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.location_disabled, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text('लोकेशन अनुमति नहीं', style: TextStyle(fontSize: 17)),
          ],
        ),
        content: const Text(
          'लोकेशन अनुमति स्थायी रूप से अस्वीकार की गई है। '
          'बिल सत्यापन के लिए ऐप सेटिंग में जाकर लोकेशन अनुमति दें।',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'बाद में',
              style: TextStyle(color: AppColors.textGrey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'सेटिंग खोलें',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ── Navigate to Screen 2 with cropped image + GPS coords ──────────────────
  void _proceed() {
    if (_croppedFile == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BillProcessingScreen(
          imageFile: _croppedFile!,
          driverLat: _driverLat,
          driverLng: _driverLng,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // ── HEADER ────────────────────────────────────────────────────────
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
                const Expanded(
                  child: Column(
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
                        'बिल की फ़ोटो अपलोड करें',
                        style: TextStyle(fontSize: 15, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                // GPS status chip
                if (_locationLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                else
                  GestureDetector(
                    onTap: _locationGranted ? null : _requestLocationPermission,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _locationGranted
                              ? Icons.location_on
                              : Icons.location_off,
                          color: _locationGranted
                              ? Colors.greenAccent
                              : Colors.white54,
                          size: 15,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _locationGranted ? 'GPS ✓' : 'GPS',
                          style: TextStyle(
                            fontSize: 15,
                            color: _locationGranted
                                ? Colors.greenAccent
                                : Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ── BODY ──────────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),

                  // ── Location permission banner ──────────────────────────────
                  if (!_locationGranted && !_locationLoading) ...[
                    _LocationBanner(onTap: _requestLocationPermission),
                    const SizedBox(height: 12),
                  ],

                  // Camera box OR cropped preview
                  if (_croppedFile == null)
                    _CameraUploadBox(
                      onTap: () => _pickAndCrop(ImageSource.camera),
                    )
                  else
                    _CroppedPreview(
                      file: _croppedFile!,
                      onRetake: _showSourceSheet,
                    ),

                  const SizedBox(height: 20),

                  // Tips card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '📸 ज़रूरी बातें:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _tip('केवल HPCL के बिल स्वीकार होते हैं'),
                        const SizedBox(height: 10),
                        _tip('बिल पर रसीद नंबर साफ़ दिखना चाहिए'),
                        const SizedBox(height: 5),
                        _tip('एक बिल सिर्फ एक बार क्लेम होता है'),
                        const SizedBox(height: 5),
                        _tip('पूरा बिल फ़ोटो में दिखना चाहिए'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Submit button — only after crop
                  if (_croppedFile != null)
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _proceed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'ठीक है — बिल जमा करें',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tip(String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('• ', style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
      Expanded(
        child: Text(
          text,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Location permission banner — shown when GPS not yet granted
// ─────────────────────────────────────────────────────────────────────────────
class _LocationBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _LocationBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.location_off, color: Colors.orange.shade700, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'लोकेशन अनुमति ज़रूरी है',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  Text(
                    'बिल सत्यापन के लिए GPS आवश्यक है। यहाँ टैप करें।',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.orange.shade700, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Camera upload box — matches screenshot 1
// ─────────────────────────────────────────────────────────────────────────────
class _CameraUploadBox extends StatelessWidget {
  final VoidCallback onTap;
  const _CameraUploadBox({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(14),
        ),
        child: CustomPaint(
          painter: _DashedBorderPainter(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'कैमरे से बिल की फ़ोटो लें',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'सीधे कैमरा खुलेगा',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cropped image preview
// ─────────────────────────────────────────────────────────────────────────────
class _CroppedPreview extends StatelessWidget {
  final File file;
  final VoidCallback onRetake;
  const _CroppedPreview({required this.file, required this.onRetake});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            file,
            width: double.infinity,
            height: 240,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: onRetake,
          icon: const Icon(Icons.refresh, color: AppColors.primary, size: 18),
          label: const Text(
            'दोबारा फ़ोटो लें',
            style: TextStyle(color: AppColors.primary, fontSize: 15),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Source picker tile
// ─────────────────────────────────────────────────────────────────────────────
class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashed border painter
// ─────────────────────────────────────────────────────────────────────────────
class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(14),
        ),
      );
    final dash = Path();
    for (final m in path.computeMetrics()) {
      double d = 0;
      bool draw = true;
      while (d < m.length) {
        final len = draw ? 8.0 : 5.0;
        if (draw) dash.addPath(m.extractPath(d, d + len), Offset.zero);
        d += len;
        draw = !draw;
      }
    }
    canvas.drawPath(dash, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// CROP SCREEN
// Key design decisions that make it smooth:
//   1. Image is decoded once to ui.Image — pixel-perfect crop with no scaling bugs
//   2. Crop box state lives in a ValueNotifier — no setState during pan,
//      so the widget tree never rebuilds mid-gesture (eliminates dropped touches)
//   3. Raw pointer events (Listener) on each zone — no GestureArena fighting
//   4. Overlay redraws via AnimatedBuilder on the notifier — only the canvas repaints
//   5. Crop zones: 4 corners (resize), 4 edges (resize one axis), centre (move)
// ─────────────────────────────────────────────────────────────────────────────

class _CropScreen extends StatefulWidget {
  final File imageFile;
  const _CropScreen({required this.imageFile});

  @override
  State<_CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<_CropScreen> {
  // Decoded image — needed for pixel-accurate crop math
  ui.Image? _srcImage;
  bool _isSaving = false;

  // Crop rect in local screen coords — stored in ValueNotifier so the
  // overlay/handles repaint WITHOUT triggering a full widget-tree rebuild.
  final _cropNotifier = ValueNotifier<Rect>(Rect.zero);
  bool _cropInitialized = false;

  // Where the image is actually drawn (BoxFit.contain inside body area)
  Rect _imageDisplayRect = Rect.zero;

  static const double _minSide = 60.0;
  // How fat the corner / edge hit zones are (screen px)
  static const double _cornerZone = 52.0;
  static const double _edgeZone = 36.0;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  @override
  void dispose() {
    _cropNotifier.dispose();
    super.dispose();
  }

  // ── 1. Decode image bytes → ui.Image ─────────────────────────────────────

  Future<void> _decodeImage() async {
    final bytes = await widget.imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (mounted) setState(() => _srcImage = frame.image);
  }

  // ── 2. Compute BoxFit.contain display rect ────────────────────────────────

  Rect _computeImageRect(Size area) {
    if (_srcImage == null) return Rect.fromLTWH(0, 0, area.width, area.height);
    final iw = _srcImage!.width.toDouble();
    final ih = _srcImage!.height.toDouble();
    final s = (area.width / iw) < (area.height / ih)
        ? area.width / iw
        : area.height / ih;
    final fw = iw * s;
    final fh = ih * s;
    return Rect.fromLTWH((area.width - fw) / 2, (area.height - fh) / 2, fw, fh);
  }

  // ── 3. Initialise crop box (once) ─────────────────────────────────────────

  void _initCrop(Size area) {
    if (_cropInitialized) return;
    _cropInitialized = true;
    final ir = _computeImageRect(area);
    _imageDisplayRect = ir;
    final padX = ir.width * 0.07;
    final padY = ir.height * 0.07;
    _cropNotifier.value = Rect.fromLTRB(
      ir.left + padX,
      ir.top + padY,
      ir.right - padX,
      ir.bottom - padY,
    );
  }

  // ── 4. Gesture helpers ────────────────────────────────────────────────────

  // Clamp a rect so it stays inside _imageDisplayRect
  Rect _clampToImage(Rect r) {
    final ir = _imageDisplayRect;
    double l = r.left.clamp(ir.left, ir.right - _minSide);
    double t = r.top.clamp(ir.top, ir.bottom - _minSide);
    double ri = r.right.clamp(ir.left + _minSide, ir.right);
    double b = r.bottom.clamp(ir.top + _minSide, ir.bottom);
    if (ri - l < _minSide) ri = l + _minSide;
    if (b - t < _minSide) b = t + _minSide;
    return Rect.fromLTRB(l, t, ri, b);
  }

  // What zone does a pointer touch fall in?
  _Zone _hitZone(Offset p) {
    final r = _cropNotifier.value;
    final cz = _cornerZone;
    final ez = _edgeZone;

    // Corners first (largest priority)
    if ((p - r.topLeft).distance < cz) return _Zone.tl;
    if ((p - r.topRight).distance < cz) return _Zone.tr;
    if ((p - r.bottomLeft).distance < cz) return _Zone.bl;
    if ((p - r.bottomRight).distance < cz) return _Zone.br;

    // Edge midpoints
    final tMid = Offset((r.left + r.right) / 2, r.top);
    final bMid = Offset((r.left + r.right) / 2, r.bottom);
    final lMid = Offset(r.left, (r.top + r.bottom) / 2);
    final rMid = Offset(r.right, (r.top + r.bottom) / 2);
    if ((p - tMid).distance < ez) return _Zone.top;
    if ((p - bMid).distance < ez) return _Zone.bottom;
    if ((p - lMid).distance < ez) return _Zone.left;
    if ((p - rMid).distance < ez) return _Zone.right;

    // Interior = move
    if (r.contains(p)) return _Zone.move;

    return _Zone.none;
  }

  void _applyDelta(_Zone zone, Offset delta) {
    final r = _cropNotifier.value;
    final dx = delta.dx;
    final dy = delta.dy;
    Rect next;
    switch (zone) {
      case _Zone.move:
        next = r.translate(dx, dy);
        break;
      case _Zone.tl:
        next = Rect.fromLTRB(r.left + dx, r.top + dy, r.right, r.bottom);
        break;
      case _Zone.tr:
        next = Rect.fromLTRB(r.left, r.top + dy, r.right + dx, r.bottom);
        break;
      case _Zone.bl:
        next = Rect.fromLTRB(r.left + dx, r.top, r.right, r.bottom + dy);
        break;
      case _Zone.br:
        next = Rect.fromLTRB(r.left, r.top, r.right + dx, r.bottom + dy);
        break;
      case _Zone.top:
        next = Rect.fromLTRB(r.left, r.top + dy, r.right, r.bottom);
        break;
      case _Zone.bottom:
        next = Rect.fromLTRB(r.left, r.top, r.right, r.bottom + dy);
        break;
      case _Zone.left:
        next = Rect.fromLTRB(r.left + dx, r.top, r.right, r.bottom);
        break;
      case _Zone.right:
        next = Rect.fromLTRB(r.left, r.top, r.right + dx, r.bottom);
        break;
      case _Zone.none:
        return;
    }
    _cropNotifier.value = _clampToImage(next);
  }

  // ── 5. Crop & save ────────────────────────────────────────────────────────

  Future<void> _doCrop() async {
    if (_srcImage == null) return;
    setState(() => _isSaving = true);
    try {
      final crop = _cropNotifier.value;
      final ir = _imageDisplayRect;

      // Map screen crop rect → source image pixel rect
      final scaleX = _srcImage!.width / ir.width;
      final scaleY = _srcImage!.height / ir.height;

      final px = ((crop.left - ir.left) * scaleX).round().clamp(
        0,
        _srcImage!.width - 1,
      );
      final py = ((crop.top - ir.top) * scaleY).round().clamp(
        0,
        _srcImage!.height - 1,
      );
      final pw = (crop.width * scaleX).round().clamp(1, _srcImage!.width - px);
      final ph = (crop.height * scaleY).round().clamp(
        1,
        _srcImage!.height - py,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawImageRect(
        _srcImage!,
        Rect.fromLTWH(
          px.toDouble(),
          py.toDouble(),
          pw.toDouble(),
          ph.toDouble(),
        ),
        Rect.fromLTWH(0, 0, pw.toDouble(), ph.toDouble()),
        Paint(),
      );
      final picture = recorder.endRecording();
      final cropped = await picture.toImage(pw, ph);
      final byteData = await cropped.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('encode failed');

      final file = File(
        '${Directory.systemTemp.path}/bill_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(byteData.buffer.asUint8List());
      if (mounted) Navigator.pop(context, file);
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('क्रॉप करने में समस्या। पुनः प्रयास करें।'),
          ),
        );
      }
    }
  }

  // ── 6. Build ──────────────────────────────────────────────────────────────

  _Zone? _activeZone; // which zone the current pointer is dragging

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A4E),
        title: const Text(
          'बिल क्रॉप करें',
          style: TextStyle(color: Colors.white, fontSize: 17),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: (_isSaving || _srcImage == null) ? null : _doCrop,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'ठीक है',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: _srcImage == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : LayoutBuilder(
              builder: (ctx, bc) {
                final area = Size(bc.maxWidth, bc.maxHeight);
                _imageDisplayRect = _computeImageRect(area);
                _initCrop(area);

                return Listener(
                  // Raw pointer events — bypasses gesture arena entirely
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (e) {
                    _activeZone = _hitZone(e.localPosition);
                  },
                  onPointerMove: (e) {
                    if (_activeZone != null && _activeZone != _Zone.none) {
                      _applyDelta(_activeZone!, e.delta);
                    }
                  },
                  onPointerUp: (_) => _activeZone = null,
                  onPointerCancel: (_) => _activeZone = null,
                  child: Stack(
                    children: [
                      // Static image — no InteractiveViewer (that steals gestures)
                      Positioned.fill(
                        child: Image.file(
                          widget.imageFile,
                          fit: BoxFit.contain,
                        ),
                      ),
                      // Overlay + handles redrawn via ValueNotifier (no setState)
                      AnimatedBuilder(
                        animation: _cropNotifier,
                        builder: (_, i) => CustomPaint(
                          size: area,
                          painter: _CropOverlayPainter(
                            cropRect: _cropNotifier.value,
                            cornerZone: _cornerZone,
                            edgeZone: _edgeZone,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ── Drag zone enum ────────────────────────────────────────────────────────────
enum _Zone { none, move, tl, tr, bl, br, top, bottom, left, right }

// ── Overlay painter ───────────────────────────────────────────────────────────
// Draws: dark mask, bright border, thirds grid, corner L-handles, edge mid-dots
class _CropOverlayPainter extends CustomPainter {
  final Rect cropRect;
  final double cornerZone;
  final double edgeZone;
  const _CropOverlayPainter({
    required this.cropRect,
    required this.cornerZone,
    required this.edgeZone,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dark overlay with transparent hole
    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRect(cropRect)
        ..fillType = PathFillType.evenOdd,
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );

    // 2. Bright border
    canvas.drawRect(
      cropRect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // 3. Rule-of-thirds grid (subtle)
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.30)
      ..strokeWidth = 0.8;
    for (int i = 1; i < 3; i++) {
      final xOff = cropRect.width / 3 * i;
      final yOff = cropRect.height / 3 * i;
      canvas.drawLine(
        Offset(cropRect.left + xOff, cropRect.top),
        Offset(cropRect.left + xOff, cropRect.bottom),
        gridPaint,
      );
      canvas.drawLine(
        Offset(cropRect.left, cropRect.top + yOff),
        Offset(cropRect.right, cropRect.top + yOff),
        gridPaint,
      );
    }

    // 4. Bold L-shaped corner handles
    final cornerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    const armLen = 24.0;
    for (final pt in [
      cropRect.topLeft,
      cropRect.topRight,
      cropRect.bottomLeft,
      cropRect.bottomRight,
    ]) {
      final onRight = (pt.dx - cropRect.right).abs() < 1;
      final onBottom = (pt.dy - cropRect.bottom).abs() < 1;
      canvas.drawLine(
        pt,
        pt + Offset(onRight ? -armLen : armLen, 0),
        cornerPaint,
      );
      canvas.drawLine(
        pt,
        pt + Offset(0, onBottom ? -armLen : armLen),
        cornerPaint,
      );
    }

    // 5. Edge mid-point dots (visual affordance)
    final dotPaint = Paint()..color = Colors.white;
    const dotR = 5.0;
    final cx = (cropRect.left + cropRect.right) / 2;
    final cy = (cropRect.top + cropRect.bottom) / 2;
    for (final pt in [
      Offset(cx, cropRect.top),
      Offset(cx, cropRect.bottom),
      Offset(cropRect.left, cy),
      Offset(cropRect.right, cy),
    ]) {
      canvas.drawCircle(pt, dotR, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_CropOverlayPainter old) => old.cropRect != cropRect;
}
