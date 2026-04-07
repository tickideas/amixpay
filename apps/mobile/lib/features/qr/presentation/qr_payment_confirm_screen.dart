import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../payments/data/payment_repository.dart';

// ---------------------------------------------------------------------------
// QR Payload Parser
// ---------------------------------------------------------------------------
class _QrPayload {
  final String username;
  final double? fixedAmount;

  const _QrPayload({required this.username, this.fixedAmount});

  /// Parses amixpay://pay?to=USERNAME&amount=X.XX
  /// Falls back gracefully for plain username strings.
  factory _QrPayload.fromRaw(String raw) {
    try {
      final uri = Uri.parse(raw);
      if (uri.scheme == 'amixpay' && uri.host == 'pay') {
        final to = uri.queryParameters['to'] ?? raw;
        final amtStr = uri.queryParameters['amount'];
        final amt = amtStr != null ? double.tryParse(amtStr) : null;
        return _QrPayload(username: to, fixedAmount: amt);
      }
    } catch (_) {}
    // Treat the raw string as a username
    return _QrPayload(username: raw);
  }
}

// ---------------------------------------------------------------------------
// Payment state
// ---------------------------------------------------------------------------
enum _PaymentStatus { idle, loading, success, error }

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class QrPaymentConfirmScreen extends ConsumerStatefulWidget {
  final String payload;
  const QrPaymentConfirmScreen({super.key, required this.payload});

  @override
  ConsumerState<QrPaymentConfirmScreen> createState() =>
      _QrPaymentConfirmScreenState();
}

class _QrPaymentConfirmScreenState
    extends ConsumerState<QrPaymentConfirmScreen> {
  static const Color _teal = Color(0xFF0D6B5E);
  static const Color _bg = Color(0xFFF5F7FA);

  late final _QrPayload _qr;
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  _PaymentStatus _status = _PaymentStatus.idle;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _qr = _QrPayload.fromRaw(widget.payload);
    if (_qr.fixedAmount != null) {
      _amountCtrl.text = _qr.fixedAmount!.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmPayment() async {
    final amtText = _amountCtrl.text.trim();
    if (amtText.isEmpty) {
      setState(() => _errorMsg = 'Please enter an amount');
      return;
    }
    final amount = double.tryParse(amtText);
    if (amount == null || amount <= 0) {
      setState(() => _errorMsg = 'Please enter a valid amount');
      return;
    }

    setState(() {
      _status = _PaymentStatus.loading;
      _errorMsg = null;
    });

    try {
      final repo = ref.read(paymentRepositoryProvider);
      await repo.send(
        recipient: _qr.username,
        amount: amount,
        currencyCode: 'USD',
        note: _noteCtrl.text.trim().isNotEmpty ? _noteCtrl.text.trim() : null,
      );
      if (!mounted) return;
      setState(() => _status = _PaymentStatus.success);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      setState(() {
        _status = _PaymentStatus.error;
        _errorMsg = msg.contains('message')
            ? msg
            : 'Payment failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_status == _PaymentStatus.success) {
      return _SuccessView(
        username: _qr.username,
        amount: double.tryParse(_amountCtrl.text) ?? 0,
        onDone: () => context.go('/home'),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Confirm Payment',
          style: TextStyle(
              color: Color(0xFF1A1A2E),
              fontSize: 18,
              fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1A2E)),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Recipient card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0D6B5E), Color(0xFF0A9E8A)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        _qr.username.isNotEmpty
                            ? _qr.username[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pay to',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${_qr.username}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'AmixPay verified',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.green),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.green, size: 28),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Amount input
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Amount',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      if (_qr.fixedAmount != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _teal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Fixed',
                            style: TextStyle(
                              fontSize: 11,
                              color: _teal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amountCtrl,
                    enabled: _qr.fixedAmount == null,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                    decoration: InputDecoration(
                      prefixText: '\$ ',
                      prefixStyle: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                      hintText: '0.00',
                      hintStyle: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[300],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: _teal, width: 2),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      filled: true,
                      fillColor: _qr.fixedAmount != null
                          ? Colors.grey[50]
                          : _bg,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                  ),
                  if (_errorMsg != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorMsg!,
                      style: const TextStyle(
                          color: Colors.red, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Note field
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _noteCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Add a note (optional)',
                  hintText: 'e.g. Dinner split, Rent contribution...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _teal, width: 2),
                  ),
                  filled: true,
                  fillColor: _bg,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Confirm button
            ElevatedButton(
              onPressed: _status == _PaymentStatus.loading
                  ? null
                  : _confirmPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _teal.withOpacity(0.6),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
              child: _status == _PaymentStatus.loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text('Confirm Pay'),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () => context.pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Success view
// ---------------------------------------------------------------------------
class _SuccessView extends StatelessWidget {
  final String username;
  final double amount;
  final VoidCallback onDone;

  const _SuccessView({
    required this.username,
    required this.amount,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, v, child) =>
                    Transform.scale(scale: v, child: child),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0D6B5E), Color(0xFF0A9E8A)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 52),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Payment Sent!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '\$${amount.toStringAsFixed(2)} sent to @$username',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onDone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6B5E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Back to Home'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
