import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/amix_button.dart';

class SplitDetailScreen extends StatelessWidget {
  final String splitId;
  const SplitDetailScreen({super.key, required this.splitId});

  @override
  Widget build(BuildContext context) {
    // Mock data
    const title = 'Dinner at Sakura';
    const total = 22.18;
    const currency = 'USD';
    final shares = [
      _Share(name: 'Alice (You)', username: '@alice', amount: 5.55, paid: true, isYou: true),
      _Share(name: 'Bob Smith', username: '@bob', amount: 5.55, paid: true, isYou: false),
      _Share(name: 'Charlie Brown', username: '@charlie', amount: 5.55, paid: false, isYou: false),
      _Share(name: 'Diana Prince', username: '@diana', amount: 5.53, paid: false, isYou: false),
    ];
    final paidCount = shares.where((s) => s.paid).length;
    final paidAmount = shares.where((s) => s.paid).fold(0.0, (s, e) => s + e.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.cardGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Split Bill', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              const Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 16),
              Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Total', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  Text('$currency ${total.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(width: 32),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Per Person', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  Text('$currency ${(total / shares.length).toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(width: 32),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Participants', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  Text('${shares.length}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ]),
              ]),
            ]),
          ),
          const SizedBox(height: 20),

          // Progress
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('Collection Progress', style: AppTextStyles.bodyBold),
                const Spacer(),
                Text('$paidCount/${shares.length} paid', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ]),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: paidAmount / total,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Text('Collected: $currency ${paidAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w500)),
                const Spacer(),
                Text('Pending: $currency ${(total - paidAmount).toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w500)),
              ]),
            ]),
          ),
          const SizedBox(height: 20),

          const Text('Participants', style: AppTextStyles.bodyBold),
          const SizedBox(height: 12),

          ...shares.map((share) => _ShareTile(share: share, currency: currency)),

          const SizedBox(height: 24),

          // Remind button for unpaid
          if (shares.any((s) => !s.paid))
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reminders sent to unpaid members'), backgroundColor: AppColors.primary),
                );
              },
              icon: const Icon(Icons.notifications_outlined),
              label: const Text('Remind Unpaid Members'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          const SizedBox(height: 12),
          AmixButton(
            label: 'Delete Split',
            onPressed: () => _confirmDelete(context),
            isOutlined: true,
          ),
        ]),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Split?'),
        content: const Text('This will cancel all pending payment requests for this split.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _Share {
  final String name;
  final String username;
  final double amount;
  final bool paid;
  final bool isYou;
  const _Share({required this.name, required this.username, required this.amount, required this.paid, required this.isYou});
}

class _ShareTile extends StatelessWidget {
  final _Share share;
  final String currency;
  const _ShareTile({super.key, required this.share, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: share.paid ? AppColors.success.withOpacity(0.15) : const Color(0xFFF3F4F6),
          child: Text(share.name[0], style: TextStyle(fontWeight: FontWeight.bold, color: share.paid ? AppColors.success : AppColors.textSecondary)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(share.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            if (share.isYou) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(6)),
                child: const Text('You', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ]),
          Text(share.username, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$currency ${share.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: share.paid ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              share.paid ? 'Paid' : 'Pending',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: share.paid ? AppColors.success : AppColors.warning,
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}
