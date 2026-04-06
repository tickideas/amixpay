import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../wallet/presentation/wallet_screen.dart' show walletCurrenciesProvider;

class MyQrScreen extends ConsumerStatefulWidget {
  const MyQrScreen({super.key});

  @override
  ConsumerState<MyQrScreen> createState() => _MyQrScreenState();
}

class _MyQrScreenState extends ConsumerState<MyQrScreen> {
  static const Color _teal = Color(0xFF0D6B5E);
  static const Color _bg = Color(0xFFF5F7FA);

  bool _includeAmount = false;
  final TextEditingController _amountCtrl = TextEditingController();

  String _qrData(String username) {
    if (_includeAmount && _amountCtrl.text.trim().isNotEmpty) {
      return 'amixpay://pay?to=$username&amount=${_amountCtrl.text.trim()}';
    }
    return 'amixpay://pay?to=$username';
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _shareQr() async {
    final authState = ref.read(authProvider);
    final user = authState.value?.user;
    final username = user?.username ?? '';
    final link = username.isNotEmpty
        ? 'https://amixpay.app/@$username'
        : 'https://amixpay.app';
    final message = username.isNotEmpty
        ? 'Pay me on AmixPay 💸\n@$username\n$link'
        : 'Pay me on AmixPay 💸\n$link';
    await Share.share(message);
  }

  Future<void> _saveQr() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR code saved to gallery')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.value?.user;
    final username = user?.username ?? '';
    final displayName = user != null
        ? '${user.firstName} ${user.lastName}'.trim()
        : '';
    final walletCurrencies = ref.watch(walletCurrenciesProvider);
    final primarySymbol = walletCurrencies.isNotEmpty ? walletCurrencies.first.symbol : r'$';
    final primaryCode = walletCurrencies.isNotEmpty ? walletCurrencies.first.code : 'USD';
    final initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A';

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          // ── Teal Header ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: _teal,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0D6B5E), Color(0xFF0A5548)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const SizedBox(height: 48),
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        backgroundImage: (user?.avatarUrl != null &&
                                user!.avatarUrl!.isNotEmpty)
                            ? NetworkImage(user.avatarUrl!)
                            : null,
                        child: (user?.avatarUrl == null ||
                                user!.avatarUrl!.isEmpty)
                            ? Text(
                                initial,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        displayName.isNotEmpty ? displayName : 'My QR Code',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (username.isNotEmpty)
                        Text(
                          '@$username',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
            title: const Text(
              'My QR Code',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // QR Card
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: _teal,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.bolt_rounded,
                                  color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'AmixPay',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0D6B5E),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Show spinner while user loads, QR once ready
                        username.isEmpty
                            ? const SizedBox(
                                height: 220,
                                child: Center(
                                  child: CircularProgressIndicator(
                                      color: _teal),
                                ),
                              )
                            : StatefulBuilder(
                                builder: (context, _) => QrImageView(
                                  data: _qrData(username),
                                  version: QrVersions.auto,
                                  size: 220,
                                  backgroundColor: Colors.white,
                                  eyeStyle: const QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: Color(0xFF0D6B5E),
                                  ),
                                  dataModuleStyle: const QrDataModuleStyle(
                                    dataModuleShape:
                                        QrDataModuleShape.square,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                              ),
                        const SizedBox(height: 16),
                        if (username.isNotEmpty)
                          Text(
                            '@$username',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          'Scan to pay me with AmixPay',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Amount Toggle Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _teal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.attach_money_rounded,
                                  color: _teal, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Request specific amount',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1A1A2E),
                                ),
                              ),
                            ),
                            Switch.adaptive(
                              value: _includeAmount,
                              onChanged: (v) =>
                                  setState(() => _includeAmount = v),
                              activeColor: _teal,
                            ),
                          ],
                        ),
                        if (_includeAmount) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: _amountCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Amount ($primaryCode)',
                              prefixText: '$primarySymbol ',
                              prefixStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1A1A2E)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: _teal, width: 2),
                              ),
                              filled: true,
                              fillColor: _bg,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _saveQr,
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Save'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _teal,
                            side: const BorderSide(
                                color: _teal, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _shareQr,
                          icon: const Icon(Icons.share_rounded),
                          label: const Text('Share'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _teal,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
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
}
