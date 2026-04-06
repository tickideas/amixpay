import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Transfer status model
// ---------------------------------------------------------------------------
enum TransferStage { quote, processing, sent, received }

extension TransferStageExt on TransferStage {
  String get label {
    switch (this) {
      case TransferStage.quote:
        return 'Quoted';
      case TransferStage.processing:
        return 'Processing';
      case TransferStage.sent:
        return 'Sent';
      case TransferStage.received:
        return 'Received';
    }
  }

  String get description {
    switch (this) {
      case TransferStage.quote:
        return 'Transfer initiated and rate locked';
      case TransferStage.processing:
        return 'Your funds are being processed';
      case TransferStage.sent:
        return 'Funds sent to recipient\'s bank';
      case TransferStage.received:
        return 'Recipient has received funds';
    }
  }

  IconData get icon {
    switch (this) {
      case TransferStage.quote:
        return Icons.receipt_long_rounded;
      case TransferStage.processing:
        return Icons.sync_rounded;
      case TransferStage.sent:
        return Icons.send_rounded;
      case TransferStage.received:
        return Icons.check_circle_rounded;
    }
  }

  Color get activeColor {
    switch (this) {
      case TransferStage.quote:
        return Colors.blue;
      case TransferStage.processing:
        return Colors.orange;
      case TransferStage.sent:
        return Colors.purple;
      case TransferStage.received:
        return Colors.green;
    }
  }
}

class _TransferInfo {
  final String id;
  final TransferStage currentStage;
  final String amount;
  final String currency;
  final String recipientAmount;
  final String recipientCurrency;
  final String recipientName;
  final String bankName;
  final DateTime createdAt;

  const _TransferInfo({
    required this.id,
    required this.currentStage,
    required this.amount,
    required this.currency,
    required this.recipientAmount,
    required this.recipientCurrency,
    required this.recipientName,
    required this.bankName,
    required this.createdAt,
  });
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------
final _transferStatusProvider =
    FutureProvider.autoDispose.family<_TransferInfo, String>(
  (ref, transferId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // Simulate different statuses based on time
    final stage = TransferStage.processing;
    return _TransferInfo(
      id: transferId,
      currentStage: stage,
      amount: '500.00',
      currency: 'USD',
      recipientAmount: '394.60',
      recipientCurrency: 'GBP',
      recipientName: 'John Smith',
      bankName: 'Barclays Bank',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    );
  },
);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class TransferStatusScreen extends ConsumerStatefulWidget {
  final String transferId;
  const TransferStatusScreen({super.key, required this.transferId});

  @override
  ConsumerState<TransferStatusScreen> createState() =>
      _TransferStatusScreenState();
}

class _TransferStatusScreenState
    extends ConsumerState<TransferStatusScreen> {
  static const Color _teal = Color(0xFF0D6B5E);
  static const Color _bg = Color(0xFFF5F7FA);

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.invalidate(
          _transferStatusProvider(widget.transferId));
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync =
        ref.watch(_transferStatusProvider(widget.transferId));

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transfer Status',
              style: TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '#${widget.transferId}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1A1A2E)),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0D6B5E)),
            onPressed: () => ref
                .invalidate(_transferStatusProvider(widget.transferId)),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: statusAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: _teal),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(
                'Unable to load transfer: $e',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(
                    _transferStatusProvider(widget.transferId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (info) => _StatusBody(info: info, teal: _teal),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body widget
// ---------------------------------------------------------------------------
class _StatusBody extends StatelessWidget {
  final _TransferInfo info;
  final Color teal;

  const _StatusBody({required this.info, required this.teal});

  @override
  Widget build(BuildContext context) {
    final stages = TransferStage.values;
    final currentIndex = stages.indexOf(info.currentStage);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // ---- Status header ----
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  info.currentStage.activeColor,
                  info.currentStage.activeColor.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    info.currentStage.icon,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  info.currentStage.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  info.currentStage.description,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8), fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  color: Colors.white.withOpacity(0.2),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatChip(
                        label: 'Sent',
                        value: '${info.amount} ${info.currency}'),
                    Container(
                        width: 1,
                        height: 32,
                        color: Colors.white.withOpacity(0.3)),
                    _StatChip(
                        label: 'Receives',
                        value:
                            '${info.recipientAmount} ${info.recipientCurrency}'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ---- Timeline ----
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Transfer Timeline',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 20),
                ...stages.asMap().entries.map((entry) {
                  final i = entry.key;
                  final stage = entry.value;
                  final isCompleted = i <= currentIndex;
                  final isActive = i == currentIndex;
                  final isLast = i == stages.length - 1;

                  return _TimelineItem(
                    stage: stage,
                    isCompleted: isCompleted,
                    isActive: isActive,
                    isLast: isLast,
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ---- Recipient details ----
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: Colors.blue, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Recipient Details',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _Row(label: 'Name', value: info.recipientName),
                const SizedBox(height: 8),
                _Row(label: 'Bank', value: info.bankName),
                const SizedBox(height: 8),
                _Row(
                  label: 'Transfer ID',
                  value: info.id,
                  mono: true,
                ),
                const SizedBox(height: 8),
                _Row(
                  label: 'Initiated',
                  value: _formatDate(info.createdAt),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ---- Auto-refresh notice ----
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: teal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.autorenew_rounded, size: 15, color: teal),
                const SizedBox(width: 8),
                Text(
                  'Auto-refreshing every 30 seconds',
                  style: TextStyle(
                      fontSize: 12,
                      color: teal,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ---- Actions ----
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/transfers/international'),
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: const Text('Send Again'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: teal,
                    side: const BorderSide(color: Color(0xFF0D6B5E)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Receipt copied to clipboard'), backgroundColor: Color(0xFF0D6B5E)),
                    );
                  },
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Share Receipt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6B5E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/home'),
            child: const Text(
              'Back to Home',
              style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month]} ${dt.day}, ${dt.year} · $h:$m';
  }
}

// ---------------------------------------------------------------------------
// Timeline item
// ---------------------------------------------------------------------------
class _TimelineItem extends StatelessWidget {
  final TransferStage stage;
  final bool isCompleted;
  final bool isActive;
  final bool isLast;

  const _TimelineItem({
    required this.stage,
    required this.isCompleted,
    required this.isActive,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isCompleted
        ? (isActive ? stage.activeColor : Colors.green)
        : Colors.grey[300]!;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: dot + line
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? color.withOpacity(0.15)
                        : Colors.grey[100],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color,
                      width: isActive ? 2.5 : 1.5,
                    ),
                  ),
                  child: Icon(
                    isCompleted && !isActive
                        ? Icons.check_rounded
                        : stage.icon,
                    color: color,
                    size: 16,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted ? Colors.green : Colors.grey[200],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Right: labels
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        stage.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isCompleted
                              ? const Color(0xFF1A1A2E)
                              : Colors.grey,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: stage.activeColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Current',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: stage.activeColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stage.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isCompleted
                          ? Colors.grey[500]
                          : Colors.grey[400],
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
}

// ---------------------------------------------------------------------------
// Small helper widgets
// ---------------------------------------------------------------------------
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;
  const _Row({required this.label, required this.value, this.mono = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A2E),
            fontFamily: mono ? 'monospace' : null,
          ),
        ),
      ],
    );
  }
}
