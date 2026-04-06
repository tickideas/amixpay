import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _teal = Color(0xFF0D6B5E);
const _bg = Color(0xFFF5F7FA);

class _TxDetail {
  final String id;
  final String title;
  final String type;
  final String status;
  final double amount;
  final String symbol;
  final String currency;
  final String counterparty;
  final String counterpartyHandle;
  final DateTime date;
  final double fee;
  final double? exchangeRate;
  final String? exchangePair;
  final String referenceId;
  final bool isPositive;

  const _TxDetail({
    required this.id, required this.title, required this.type, required this.status,
    required this.amount, required this.symbol, required this.currency,
    required this.counterparty, required this.counterpartyHandle, required this.date,
    required this.fee, required this.referenceId, required this.isPositive,
    this.exchangeRate, this.exchangePair,
  });
}

// Mock detail removed — screen builds detail inline from transactionId

class TransactionDetailScreen extends ConsumerWidget {
  final String transactionId;
  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final tx = _TxDetail(
      id: transactionId,
      title: transactionId == 't1' ? 'Payment Received' : 'Payment Sent',
      type: transactionId == 't1' ? 'Received' : 'Sent',
      status: 'Paid',
      amount: 250.00,
      symbol: '\$',
      currency: 'USD',
      counterparty: 'John Smith',
      counterpartyHandle: 'john@amixpay.com',
      date: now.subtract(const Duration(hours: 2)),
      fee: 1.25,
      referenceId: 'AMX-${transactionId.toUpperCase()}-${now.millisecondsSinceEpoch % 100000}',
      isPositive: transactionId == 't1',
      exchangeRate: transactionId == 't4' ? 1.085 : null,
      exchangePair: transactionId == 't4' ? 'EUR/USD' : null,
    );

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        title: const Text('Transaction Details', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (v) {
              if (v == 'report') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text('Issue reported. Our team will review it.'),
                      backgroundColor: _teal, behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.all(16)),
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'report', child: Row(children: [Icon(Icons.flag_outlined, color: Colors.red, size: 18), SizedBox(width: 8), Text('Report Issue')])),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AmountCard(tx: tx),
            const SizedBox(height: 16),
            _DetailCard(tx: tx),
            const SizedBox(height: 16),
            _CounterpartyCard(tx: tx),
            if (tx.exchangeRate != null) ...[
              const SizedBox(height: 16),
              _ExchangeCard(tx: tx),
            ],
            const SizedBox(height: 16),
            _ReferenceCard(tx: tx),
            const SizedBox(height: 24),
            ElevatedButton.icon(
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
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text('Issue reported. Our team will review it.'),
                      backgroundColor: Colors.red, behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.all(16)),
                );
              },
              icon: const Icon(Icons.flag_outlined, color: Colors.red),
              label: const Text('Report Issue', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 15)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  final _TxDetail tx;
  const _AmountCard({required this.tx});

  Color get _statusColor => tx.status == 'Paid' ? Colors.green : tx.status == 'Pending' ? Colors.orange : Colors.red;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: (tx.isPositive ? Colors.green : Colors.red).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(tx.type,
                  style: TextStyle(color: tx.isPositive ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            const SizedBox(height: 12),
            Text(
              '${tx.isPositive ? '+' : '-'}${tx.symbol}${tx.amount.toStringAsFixed(2)}',
              style: TextStyle(
                  fontSize: 40, fontWeight: FontWeight.bold,
                  color: tx.isPositive ? Colors.green : Colors.red),
            ),
            const SizedBox(height: 4),
            Text(tx.currency, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, color: _statusColor, size: 14),
                  const SizedBox(width: 4),
                  Text(tx.status, style: TextStyle(color: _statusColor, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final _TxDetail tx;
  const _DetailCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    final dt = tx.date;
    final formatted = '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    return _InfoCard(title: 'Transaction Info', rows: [
      _InfoRow(label: 'Date & Time', value: formatted),
      _InfoRow(label: 'Amount', value: '${tx.symbol}${tx.amount.toStringAsFixed(2)}'),
      _InfoRow(label: 'Fee', value: tx.fee == 0 ? 'Free' : '${tx.symbol}${tx.fee.toStringAsFixed(2)}'),
      _InfoRow(label: 'Total', value: '${tx.symbol}${(tx.amount + tx.fee).toStringAsFixed(2)}', bold: true),
    ]);
  }
}

class _CounterpartyCard extends StatelessWidget {
  final _TxDetail tx;
  const _CounterpartyCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(title: tx.isPositive ? 'Received From' : 'Sent To', rows: [
      _InfoRow(label: 'Name', value: tx.counterparty),
      _InfoRow(label: 'Account', value: tx.counterpartyHandle),
    ]);
  }
}

class _ExchangeCard extends StatelessWidget {
  final _TxDetail tx;
  const _ExchangeCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(title: 'Exchange Info', rows: [
      _InfoRow(label: 'Pair', value: tx.exchangePair ?? ''),
      _InfoRow(label: 'Rate', value: '1 : ${tx.exchangeRate?.toStringAsFixed(4)}'),
    ]);
  }
}

class _ReferenceCard extends StatelessWidget {
  final _TxDetail tx;
  const _ReferenceCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Reference ID', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(tx.referenceId, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy_outlined, color: _teal),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: tx.referenceId));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text('Reference ID copied!'), backgroundColor: _teal,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.all(16), duration: const Duration(seconds: 2)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<_InfoRow> rows;
  const _InfoCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _teal)),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...rows.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(r.label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  Text(r.value, style: TextStyle(fontWeight: r.bold ? FontWeight.bold : FontWeight.w500, fontSize: 13)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;
  final bool bold;
  const _InfoRow({required this.label, required this.value, this.bold = false});
}
