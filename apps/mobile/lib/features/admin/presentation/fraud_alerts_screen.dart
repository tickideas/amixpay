import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class FraudAlertsScreen extends StatefulWidget {
  const FraudAlertsScreen({super.key});
  @override
  State<FraudAlertsScreen> createState() => _FraudAlertsScreenState();
}

class _FraudAlertsScreenState extends State<FraudAlertsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _severityFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final List<_FraudAlert> _alerts = [
    _FraudAlert(id: 'FA001', user: 'john.doe@email.com', userId: 'u-1234', type: 'VELOCITY_1HR', severity: 'HIGH', status: 'open', amount: 8500.00, currency: 'USD', createdAt: '2 min ago', transactionId: 'tx-abc123'),
    _FraudAlert(id: 'FA002', user: 'mary.jane@email.com', userId: 'u-5678', type: 'LARGE_AMOUNT', severity: 'HIGH', status: 'open', amount: 12000.00, currency: 'USD', createdAt: '15 min ago', transactionId: 'tx-def456'),
    _FraudAlert(id: 'FA003', user: 'bob.smith@email.com', userId: 'u-9012', type: 'NEW_RECIPIENT', severity: 'MEDIUM', status: 'reviewing', amount: 950.00, currency: 'EUR', createdAt: '1 hr ago', transactionId: 'tx-ghi789'),
    _FraudAlert(id: 'FA004', user: 'alice.w@email.com', userId: 'u-3456', type: 'VELOCITY_5MIN', severity: 'HIGH', status: 'open', amount: 4200.00, currency: 'GBP', createdAt: '3 hr ago', transactionId: 'tx-jkl012'),
    _FraudAlert(id: 'FA005', user: 'charlie.b@email.com', userId: 'u-7890', type: 'NEW_RECIPIENT', severity: 'LOW', status: 'dismissed', amount: 120.00, currency: 'USD', createdAt: '1 day ago', transactionId: 'tx-mno345'),
    _FraudAlert(id: 'FA006', user: 'diana.p@email.com', userId: 'u-2345', type: 'LARGE_AMOUNT', severity: 'MEDIUM', status: 'blocked', amount: 6500.00, currency: 'USD', createdAt: '2 days ago', transactionId: 'tx-pqr678'),
  ];

  List<_FraudAlert> get _filtered {
    final tab = _tabController.index;
    return _alerts.where((a) {
      final statusMatch = tab == 0 || (tab == 1 && (a.status == 'open' || a.status == 'reviewing')) || (tab == 2 && (a.status == 'dismissed' || a.status == 'blocked'));
      final sevMatch = _severityFilter == 'All' || a.severity == _severityFilter.toUpperCase();
      return statusMatch && sevMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fraud Alerts'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'Resolved'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) => setState(() => _severityFilter = v),
            itemBuilder: (_) => ['All', 'High', 'Medium', 'Low']
                .map((s) => PopupMenuItem(value: s, child: Text(s)))
                .toList(),
          ),
        ],
      ),
      body: Column(children: [
        // Stats bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: const Color(0xFFF9FAFB),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _StatChip(label: 'Open', count: _alerts.where((a) => a.status == 'open').length, color: AppColors.error),
            _StatChip(label: 'Reviewing', count: _alerts.where((a) => a.status == 'reviewing').length, color: AppColors.warning),
            _StatChip(label: 'Blocked', count: _alerts.where((a) => a.status == 'blocked').length, color: AppColors.textSecondary),
            _StatChip(label: 'Dismissed', count: _alerts.where((a) => a.status == 'dismissed').length, color: AppColors.success),
          ]),
        ),
        Expanded(
          child: _filtered.isEmpty
              ? const Center(child: Text('No alerts found', style: TextStyle(color: AppColors.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filtered.length,
                  itemBuilder: (ctx, i) => _AlertCard(
                    alert: _filtered[i],
                    onReview: () => _showReviewSheet(_filtered[i]),
                  ),
                ),
        ),
      ]),
    );
  }

  void _showReviewSheet(_FraudAlert alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _ReviewSheet(
        alert: alert,
        onAction: (action, notes) {
          setState(() {
            final idx = _alerts.indexWhere((a) => a.id == alert.id);
            if (idx != -1) {
              _alerts[idx] = _alerts[idx].copyWith(
                status: action == 'block' ? 'blocked' : action == 'dismiss' ? 'dismissed' : 'reviewing',
              );
            }
          });
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Alert ${alert.id} marked as $action'), backgroundColor: AppColors.primary),
          );
        },
      ),
    );
  }
}

class _FraudAlert {
  final String id;
  final String user;
  final String userId;
  final String type;
  final String severity;
  final String status;
  final double amount;
  final String currency;
  final String createdAt;
  final String transactionId;

  const _FraudAlert({
    required this.id, required this.user, required this.userId,
    required this.type, required this.severity, required this.status,
    required this.amount, required this.currency, required this.createdAt,
    required this.transactionId,
  });

  _FraudAlert copyWith({String? status}) => _FraudAlert(
    id: id, user: user, userId: userId, type: type, severity: severity,
    status: status ?? this.status, amount: amount, currency: currency,
    createdAt: createdAt, transactionId: transactionId,
  );
}

class _AlertCard extends StatelessWidget {
  final _FraudAlert alert;
  final VoidCallback onReview;
  const _AlertCard({required this.alert, required this.onReview});

  Color get _severityColor {
    switch (alert.severity) {
      case 'HIGH': return AppColors.error;
      case 'MEDIUM': return AppColors.warning;
      default: return AppColors.textSecondary;
    }
  }

  Color get _statusColor {
    switch (alert.status) {
      case 'open': return AppColors.error;
      case 'reviewing': return AppColors.warning;
      case 'blocked': return AppColors.textSecondary;
      default: return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onReview,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: alert.status == 'open' ? _severityColor.withOpacity(0.3) : const Color(0xFFE5E7EB)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: _severityColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(alert.severity, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _severityColor)),
            ),
            const SizedBox(width: 8),
            Text(alert.type, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: _statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(alert.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor)),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(alert.user, style: const TextStyle(fontSize: 13)),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.receipt_outlined, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(alert.transactionId, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const Spacer(),
            Text('${alert.currency} ${alert.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.access_time, size: 12, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(alert.createdAt, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const Spacer(),
            if (alert.status == 'open')
              const Text('Tap to review →', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500)),
          ]),
        ]),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]);
  }
}

class _ReviewSheet extends StatefulWidget {
  final _FraudAlert alert;
  final Function(String action, String notes) onAction;
  const _ReviewSheet({required this.alert, required this.onAction});

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  final _notesCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Review Alert', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const Spacer(),
          Text(alert.id, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            _DetailRow(label: 'User', value: alert.user),
            const SizedBox(height: 8),
            _DetailRow(label: 'Rule', value: alert.type),
            const SizedBox(height: 8),
            _DetailRow(label: 'Amount', value: '${alert.currency} ${alert.amount.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _DetailRow(label: 'Severity', value: alert.severity),
          ]),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _notesCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Add review notes (optional)...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => widget.onAction('dismiss', _notesCtrl.text),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Dismiss'),
          )),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton(
            onPressed: () => widget.onAction('review', _notesCtrl.text),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.warning,
              side: const BorderSide(color: AppColors.warning),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Flag'),
          )),
          const SizedBox(width: 8),
          Expanded(child: ElevatedButton(
            onPressed: () => widget.onAction('block', _notesCtrl.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Block User'),
          )),
        ]),
      ]),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      const Spacer(),
      Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    ]);
  }
}
