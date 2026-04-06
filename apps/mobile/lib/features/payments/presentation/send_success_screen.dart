import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _teal = Color(0xFF0D6B5E);
const _bg = Color(0xFFF5F7FA);

class SendSuccessScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> args;
  const SendSuccessScreen({super.key, required this.args});

  @override
  ConsumerState<SendSuccessScreen> createState() => _SendSuccessScreenState();
}

class _SendSuccessScreenState extends ConsumerState<SendSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _checkAnim;

  String get _recipient => widget.args['recipient'] as String? ?? 'Unknown';
  double get _amount => (widget.args['amount'] as num?)?.toDouble() ?? 0;
  String get _currency => widget.args['currency'] as String? ?? 'USD';
  String get _symbol => widget.args['symbol'] as String? ?? '\$';
  String get _note => widget.args['note'] as String? ?? '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0, curve: Curves.easeIn));
    _checkAnim = CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.9, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.green.withOpacity(0.25), blurRadius: 30, spreadRadius: 5),
                    ],
                  ),
                  child: AnimatedBuilder(
                    animation: _checkAnim,
                    builder: (_, __) => CustomPaint(
                      painter: _CheckPainter(_checkAnim.value),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    const Text('Payment Sent!',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 8),
                    Text('Your transfer was completed successfully',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: _fadeAnim,
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text('$_symbol${_amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: _teal)),
                        Text(_currency, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.person_outline, color: Colors.grey, size: 18),
                            const SizedBox(width: 6),
                            Text('Sent to ', style: TextStyle(color: Colors.grey.shade600)),
                            Text(_recipient, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        if (_note.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.notes, color: Colors.grey, size: 16),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(_note,
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                    textAlign: TextAlign.center),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green, size: 16),
                              const SizedBox(width: 6),
                              const Text('Completed', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 2),
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: const Text('Receipt shared!'), backgroundColor: _teal,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                margin: const EdgeInsets.all(16)),
                          );
                        },
                        icon: const Icon(Icons.share_outlined),
                        label: const Text('Share Receipt', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _teal, foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.go('/home'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _teal),
                          foregroundColor: _teal,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Back to Home', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;
  _CheckPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;
    final cy = size.height / 2;

    final path = Path()
      ..moveTo(cx - 22, cy)
      ..lineTo(cx - 6, cy + 16)
      ..lineTo(cx + 22, cy - 16);

    final metrics = path.computeMetrics().first;
    final drawn = metrics.extractPath(0, metrics.length * progress);
    canvas.drawPath(drawn, paint);
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) => oldDelegate.progress != progress;
}
