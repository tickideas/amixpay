import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/transaction_provider.dart';

class TransactionsHubScreen extends ConsumerStatefulWidget {
  final String? currencyFilter; // optional — from /wallet/transactions?currency=X
  const TransactionsHubScreen({super.key, this.currencyFilter});
  @override
  ConsumerState<TransactionsHubScreen> createState() => _TransactionsHubScreenState();
}

class _TransactionsHubScreenState extends ConsumerState<TransactionsHubScreen> {
  String _filter = 'All';
  final _filters = ['All', 'Sent', 'Received', 'Bills', 'Cards'];

  final _txns = [
    _Txn(
      id: 'txn_001',
      title: 'Send to Amara',
      date: 'Mar 14 · 2:30 PM',
      amount: -120.00,
      currency: 'USD',
      icon: Icons.send_rounded,
      color: Color(0xFFEF4444),
      category: 'Sent',
      recipient: 'Amara Johnson',
      reference: 'AMX-20260314-001',
      note: 'Rent contribution',
      status: 'Completed',
      paymentMethod: 'AmixPay Wallet',
    ),
    _Txn(
      id: 'txn_002',
      title: 'Salary Deposit',
      date: 'Mar 14 · 9:00 AM',
      amount: 4500.00,
      currency: 'USD',
      icon: Icons.account_balance_rounded,
      color: Color(0xFF10B981),
      category: 'Received',
      recipient: 'You',
      reference: 'AMX-20260314-002',
      note: 'Monthly salary',
      status: 'Completed',
      paymentMethod: 'Bank Transfer',
    ),
    _Txn(
      id: 'txn_003',
      title: 'Netflix',
      date: 'Mar 13 · 8:14 PM',
      amount: -15.49,
      currency: 'USD',
      icon: Icons.movie_rounded,
      color: Color(0xFFE50914),
      category: 'Bills',
      recipient: 'Netflix Inc.',
      reference: 'AMX-20260313-003',
      note: 'Monthly subscription',
      status: 'Completed',
      paymentMethod: 'Virtual Card',
    ),
    _Txn(
      id: 'txn_004',
      title: 'Airtel Airtime',
      date: 'Mar 13 · 3:00 PM',
      amount: -500.00,
      currency: 'NGN',
      icon: Icons.phone_android_rounded,
      color: Color(0xFFF59E0B),
      category: 'Bills',
      recipient: 'Airtel Nigeria',
      reference: 'AMX-20260313-004',
      note: '+234 803 000 0000',
      status: 'Completed',
      paymentMethod: 'NGN Wallet',
    ),
    _Txn(
      id: 'txn_005',
      title: 'Received from Mike',
      date: 'Mar 12 · 11:20 AM',
      amount: 200.00,
      currency: 'USD',
      icon: Icons.call_received_rounded,
      color: Color(0xFF10B981),
      category: 'Received',
      recipient: 'You',
      reference: 'AMX-20260312-005',
      note: 'Thanks for dinner!',
      status: 'Completed',
      paymentMethod: 'AmixPay Wallet',
    ),
    _Txn(
      id: 'txn_006',
      title: 'Virtual Card · Amazon',
      date: 'Mar 12 · 9:45 AM',
      amount: -89.99,
      currency: 'USD',
      icon: Icons.credit_card_rounded,
      color: Color(0xFF3B82F6),
      category: 'Cards',
      recipient: 'Amazon.com',
      reference: 'AMX-20260312-006',
      note: 'Online purchase',
      status: 'Completed',
      paymentMethod: 'AmixPay Virtual Card',
    ),
    _Txn(
      id: 'txn_007',
      title: 'International to UK',
      date: 'Mar 11 · 4:15 PM',
      amount: -350.00,
      currency: 'GBP',
      icon: Icons.public_rounded,
      color: Color(0xFF7C3AED),
      category: 'Sent',
      recipient: 'Thomas Williams',
      reference: 'AMX-20260311-007',
      note: 'International transfer',
      status: 'Completed',
      paymentMethod: 'USD Wallet → GBP',
    ),
    _Txn(
      id: 'txn_008',
      title: 'Apple Music',
      date: 'Mar 11 · 2:14 PM',
      amount: -9.99,
      currency: 'USD',
      icon: Icons.music_note_rounded,
      color: Color(0xFFFC3C44),
      category: 'Bills',
      recipient: 'Apple Inc.',
      reference: 'AMX-20260311-008',
      note: 'Monthly subscription',
      status: 'Completed',
      paymentMethod: 'Virtual Card',
    ),
    _Txn(
      id: 'txn_009',
      title: 'Freelance Payment',
      date: 'Mar 10 · 5:30 PM',
      amount: 750.00,
      currency: 'USD',
      icon: Icons.work_rounded,
      color: Color(0xFF3B82F6),
      category: 'Received',
      recipient: 'You',
      reference: 'AMX-20260310-009',
      note: 'Web design project',
      status: 'Completed',
      paymentMethod: 'AmixPay Wallet',
    ),
    _Txn(
      id: 'txn_010',
      title: 'Electricity Bill',
      date: 'Mar 10 · 10:00 AM',
      amount: -8500.00,
      currency: 'NGN',
      icon: Icons.bolt_rounded,
      color: Color(0xFFF59E0B),
      category: 'Bills',
      recipient: 'EKEDC',
      reference: 'AMX-20260310-010',
      note: 'Meter No: 1234567890',
      status: 'Completed',
      paymentMethod: 'NGN Wallet',
    ),
    _Txn(
      id: 'txn_011',
      title: 'Card Top-up',
      date: 'Mar 9 · 6:00 PM',
      amount: 500.00,
      currency: 'USD',
      icon: Icons.add_card_rounded,
      color: Color(0xFF10B981),
      category: 'Received',
      recipient: 'You',
      reference: 'AMX-20260309-011',
      note: 'Wallet funding',
      status: 'Completed',
      paymentMethod: 'Debit Card',
    ),
    _Txn(
      id: 'txn_012',
      title: 'Split · Dinner',
      date: 'Mar 8 · 9:30 PM',
      amount: -45.00,
      currency: 'USD',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFEA580C),
      category: 'Sent',
      recipient: 'Group · 4 people',
      reference: 'AMX-20260308-012',
      note: 'Team dinner split',
      status: 'Completed',
      paymentMethod: 'AmixPay Wallet',
    ),
  ];

  static const _currencySymbols = {
    'USD': '\$', 'GBP': '£', 'EUR': '€', 'NGN': '₦', 'GHS': '₵',
    'KES': 'KSh', 'ZAR': 'R', 'CAD': 'C\$', 'AUD': 'A\$', 'INR': '₹',
    'JPY': '¥', 'CNY': '¥', 'AED': 'AED', 'SAR': 'SAR', 'MXN': 'MX\$',
    'BRL': 'R\$', 'SGD': 'S\$', 'CHF': 'Fr', 'SEK': 'kr', 'NOK': 'kr',
    'UGX': 'USh', 'TZS': 'TSh', 'EGP': 'E£', 'PKR': '₨', 'PHP': '₱',
    'IDR': 'Rp', 'MYR': 'RM', 'THB': '฿', 'VND': '₫', 'KRW': '₩',
  };

  String _symFor(String code) => _currencySymbols[code] ?? code;

  static _Txn _fromAppTx(AppTransaction t) {
    final isSent = t.type == AppTxType.sent || t.type == AppTxType.transfer;
    final cat = isSent ? 'Sent' : 'Received';
    final icon = isSent ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
    final color = isSent ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    return _Txn(
      id: t.id,
      title: t.title,
      date: DateFormat('MMM d · h:mm a').format(t.date),
      amount: isSent ? -t.amount : t.amount,
      currency: t.currency,
      icon: icon,
      color: color,
      category: cat,
      recipient: t.subtitle,
      reference: 'AMX-${t.id.substring(0, 8).toUpperCase()}',
      note: '',
      status: t.status == AppTxStatus.paid
          ? 'Completed'
          : t.status == AppTxStatus.pending
              ? 'Pending'
              : 'Failed',
      paymentMethod: 'AmixPay Wallet',
    );
  }

  List<_Txn> get _merged {
    final realTxns = ref.read(transactionProvider);
    final converted = realTxns.map(_fromAppTx).toList();
    // Append demo transactions that don't share an ID with real ones
    final realIds = converted.map((t) => t.id).toSet();
    final demo = _txns.where((t) => !realIds.contains(t.id)).toList();
    return [...converted, ...demo];
  }

  List<_Txn> get _filtered {
    final all = _merged;
    var list = _filter == 'All' ? all : all.where((t) => t.category == _filter).toList();
    if (widget.currencyFilter != null && widget.currencyFilter!.isNotEmpty) {
      list = list.where((t) => t.currency == widget.currencyFilter).toList();
    }
    return list;
  }

  final _fmt = NumberFormat('#,##0.00');

  void _showDetail(BuildContext context, _Txn t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TxDetailSheet(txn: t, fmt: _fmt),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch real transactions so list rebuilds when new ones are added
    ref.watch(transactionProvider);
    final filtered = _filtered;
    final totalIn =
        filtered.where((t) => t.amount > 0).fold(0.0, (s, t) => s + t.amount);
    final totalOut = filtered
        .where((t) => t.amount < 0)
        .fold(0.0, (s, t) => s + t.amount.abs());

    // Use currency symbol when filtering a single currency, else generic
    final sym = widget.currencyFilter != null
        ? _symFor(widget.currencyFilter!)
        : '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.currencyFilter != null
                          ? '${widget.currencyFilter} Transactions'
                          : 'Transactions',
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                          child: _SummaryBox(
                              label: 'Money In',
                              amount: '+$sym${_fmt.format(totalIn)}',
                              color: AppColors.success)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _SummaryBox(
                              label: 'Money Out',
                              amount: '-$sym${_fmt.format(totalOut)}',
                              color: AppColors.error)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final f = _filters[i];
                        final sel = f == _filter;
                        return GestureDetector(
                          onTap: () => setState(() => _filter = f),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.primary
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: sel
                                      ? AppColors.primary
                                      : AppColors.border),
                            ),
                            child: Text(f,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: sel
                                        ? Colors.white
                                        : AppColors.textPrimary)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text('No transactions',
                          style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final t = filtered[i];
                        final isCredit = t.amount > 0;
                        return GestureDetector(
                          onTap: () => _showDetail(context, t),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                      color: t.color.withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                  child: Icon(t.icon,
                                      color: t.color, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(t.title,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color:
                                                  AppColors.textPrimary)),
                                      Text(t.date,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color:
                                                  AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${isCredit ? '+' : '-'}${t.currency} ${_fmt.format(t.amount.abs())}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: isCredit
                                              ? AppColors.success
                                              : AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (isCredit
                                                ? AppColors.success
                                                : AppColors.error)
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(t.category,
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: isCredit
                                                  ? AppColors.success
                                                  : AppColors.error)),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right_rounded,
                                    color: AppColors.textSecondary, size: 18),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Transaction Detail Bottom Sheet
// ---------------------------------------------------------------------------

class _TxDetailSheet extends StatelessWidget {
  final _Txn txn;
  final NumberFormat fmt;
  const _TxDetailSheet({required this.txn, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final isCredit = txn.amount > 0;
    final amountColor = isCredit ? AppColors.success : AppColors.error;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                children: [
                  // ── Icon + Title ────────────────────────────────────────
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: txn.color.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(txn.icon, color: txn.color, size: 30),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      '${isCredit ? '+' : '-'}${txn.currency} ${fmt.format(txn.amount.abs())}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: amountColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(txn.title,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: _StatusBadge(status: txn.status),
                  ),
                  const SizedBox(height: 24),

                  // ── Details card ─────────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _DetailRow(
                            label: 'Date & Time', value: txn.date),
                        _DetailRow(
                            label: isCredit ? 'From' : 'To',
                            value: txn.recipient),
                        _DetailRow(
                            label: 'Payment Method',
                            value: txn.paymentMethod),
                        _DetailRow(label: 'Category', value: txn.category),
                        if (txn.note.isNotEmpty)
                          _DetailRow(label: 'Note', value: txn.note),
                        _DetailRow(
                            label: 'Reference',
                            value: txn.reference,
                            copyable: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Action buttons ───────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _shareReceipt(context),
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: const Text('Share'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Close'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ── Report issue link ────────────────────────────────────
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Dispute submitted to support'),
                              behavior: SnackBarBehavior.floating),
                        );
                      },
                      icon: const Icon(Icons.flag_outlined, size: 16),
                      label: const Text('Report an issue'),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareReceipt(BuildContext context) async {
    final isCredit = txn.amount > 0;
    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a5,
      build: (pw.Context ctx) => pw.Container(
        padding: const pw.EdgeInsets.all(32),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Column(children: [
                pw.Text('AmixPay',
                    style: pw.TextStyle(
                        fontSize: 26, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('Transaction Receipt',
                    style: const pw.TextStyle(
                        fontSize: 13, color: PdfColors.grey600)),
              ]),
            ),
            pw.SizedBox(height: 16),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text(
                '${isCredit ? '+' : '-'}${txn.currency} ${fmt.format(txn.amount.abs())}',
                style: pw.TextStyle(
                  fontSize: 30,
                  fontWeight: pw.FontWeight.bold,
                  color: isCredit ? PdfColors.green700 : PdfColors.red700,
                ),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.Text(txn.title,
                  style: pw.TextStyle(
                      fontSize: 15, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 12),
            _pdfRow('Status', txn.status),
            _pdfRow('Date & Time', txn.date),
            _pdfRow(isCredit ? 'From' : 'To', txn.recipient),
            _pdfRow('Payment Method', txn.paymentMethod),
            _pdfRow('Category', txn.category),
            if (txn.note.isNotEmpty) _pdfRow('Note', txn.note),
            _pdfRow('Reference', txn.reference),
            pw.SizedBox(height: 20),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                'AmixPay · Global Digital Wallet',
                style: const pw.TextStyle(
                    fontSize: 10, color: PdfColors.grey500),
              ),
            ),
          ],
        ),
      ),
    ));
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'receipt_${txn.reference}.pdf',
    );
  }

  pw.Widget _pdfRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 6),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style: const pw.TextStyle(color: PdfColors.grey600)),
            pw.Text(value,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ],
        ),
      );
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (status.toLowerCase()) {
      case 'completed':
        color = AppColors.success;
        icon = Icons.check_circle_rounded;
        break;
      case 'pending':
        color = Colors.orange;
        icon = Icons.schedule_rounded;
        break;
      case 'failed':
        color = AppColors.error;
        icon = Icons.cancel_rounded;
        break;
      default:
        color = AppColors.textSecondary;
        icon = Icons.info_outline_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 5),
        Text(status,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  final bool copyable;
  const _DetailRow(
      {required this.label, required this.value, this.copyable = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: copyable
            ? () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('$label copied'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 1)),
                );
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
              const Spacer(),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: copyable
                            ? AppColors.primary
                            : AppColors.textPrimary)),
                if (copyable) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.copy_rounded,
                      size: 13, color: AppColors.primary),
                ],
              ]),
            ],
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class _Txn {
  final String id, title, date, currency, category;
  final String recipient, reference, note, status, paymentMethod;
  final double amount;
  final IconData icon;
  final Color color;
  const _Txn({
    required this.id,
    required this.title,
    required this.date,
    required this.amount,
    required this.currency,
    required this.icon,
    required this.color,
    required this.category,
    required this.recipient,
    required this.reference,
    required this.note,
    required this.status,
    required this.paymentMethod,
  });
}

class _SummaryBox extends StatelessWidget {
  final String label, amount;
  final Color color;
  const _SummaryBox(
      {required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(amount,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      );
}
