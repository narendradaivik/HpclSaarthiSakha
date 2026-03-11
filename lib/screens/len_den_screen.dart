import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/services.dart';

class LenDenScreen extends StatefulWidget {
  const LenDenScreen({super.key});
  @override
  State<LenDenScreen> createState() => _LenDenScreenState();
}

class _LenDenScreenState extends State<LenDenScreen> {
  List<LedgerEntry> _entries = [];
  bool _loading = true;
  String? _error;
  double _balance = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final r = await DriverService.instance.fetchDriverProfile();
    if (!mounted) return;
    if (r.success && r.data != null) {
      setState(() {
        _entries = r.data!.ledger;
        _balance = r.data!.driver.redeemableLiters; // double now
        _loading = false;
      });
    } else {
      setState(() {
        _error = r.errorMessage;
        _loading = false;
      });
    }
  }

  // "6 मार्च 2026 • 03:03 pm"
  String _fmtDt(DateTime? dt) {
    if (dt == null) return '';
    const months = [
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
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = h >= 12 ? 'pm' : 'am';
    final h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '${dt.day} ${months[dt.month]} ${dt.year} • $h12:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // ── Gradient header ────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1A4E),
                  Color(0xFF7B1A3A),
                  Color(0xFFCC0000),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              bottom: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 14),

                // Title
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.amber.shade600,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Center(
                        child: Text(
                          '₹',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'लेन-देन',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'पॉइंट्स का पूरा हिसाब',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Balance card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'मौजूदा बैलेंस',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _loading ? '—' : _balance.round().toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(left: 5, bottom: 4),
                                child: Text(
                                  'L',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      Icon(
                        Icons.local_gas_station,
                        color: Colors.amber.shade400,
                        size: 36,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Transaction list ──────────────────────────────────────────
          Expanded(
            child: _loading
                ? _shimmer()
                : _error != null
                ? _errorView()
                : _entries.isEmpty
                ? _emptyView()
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 80),
                      itemCount: _entries.length,
                      itemBuilder: (_, i) => _entryCard(_entries[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _entryCard(LedgerEntry e) {
    final isCredit = e.isCredit;

    // ── Title ──────────────────────────────────────────────────────────
    // Credit → "फ्यूल क्लेम"   Debit → "रिडीम"
    final title = isCredit ? 'फ्यूल क्लेम' : 'रिडीम';

    // ── Sub-line: API provides formatted description directly ───────────
    final String subLine = e.description.isNotEmpty
        ? e.description
        : (isCredit
              ? 'Fuel claim: ${e.liters.toStringAsFixed(2)}L'
              : 'Redeem: ${e.liters.toStringAsFixed(2)}L');

    // ── Amount string ──────────────────────────────────────────────────
    // Credit → "+50.82L" in red/primary   Debit → "−100L" in blue
    final amtStr = isCredit
        ? '+${e.liters.toStringAsFixed(2)}L'
        : '−${e.liters.toStringAsFixed(0)}L';
    final amtColor = isCredit ? AppColors.primary : Colors.blue.shade600;

    // ── Running balance ────────────────────────────────────────────────
    final balStr = 'बैलेंस: ${e.balanceAfter.toStringAsFixed(2)}L';

    // ── Icon bg & icon ─────────────────────────────────────────────────
    final iconBg = isCredit ? Colors.red.shade50 : Colors.blue.shade50;
    final iconColor = isCredit ? AppColors.primary : Colors.blue.shade400;
    final iconData = isCredit ? Icons.local_gas_station : Icons.card_giftcard;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(iconData, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),

          // Centre
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subLine,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                if (e.createdAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _fmtDt(e.createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Right: amount + running balance
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amtStr,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: amtColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                balStr,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Empty / Error / Shimmer ─────────────────────────────────────────────

  Widget _emptyView() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        const Text(
          'अभी तक कोई लेन-देन नहीं',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'फ्यूल क्लेम या रिडीम करने पर यहाँ दिखेगा',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        ),
      ],
    ),
  );

  Widget _errorView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            _error ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textGrey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('फिर से कोशिश करें'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _shimmer() => ListView.builder(
    padding: const EdgeInsets.all(12),
    itemCount: 5,
    itemBuilder: (_, __) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 74,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 130, height: 12, color: Colors.grey.shade200),
                const SizedBox(height: 5),
                Container(width: 100, height: 10, color: Colors.grey.shade100),
                const SizedBox(height: 4),
                Container(width: 80, height: 9, color: Colors.grey.shade100),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(width: 60, height: 13, color: Colors.grey.shade200),
              const SizedBox(height: 5),
              Container(width: 45, height: 10, color: Colors.grey.shade100),
            ],
          ),
          const SizedBox(width: 14),
        ],
      ),
    ),
  );
}
