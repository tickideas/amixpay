import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<_Notification> _items = [
    _Notification(id: '1', type: 'payment', title: 'Payment Received', body: 'Bob sent you \$50.00', time: '2 min ago', read: false),
    _Notification(id: '2', type: 'security', title: 'New Login Detected', body: 'New login from Chrome on Windows', time: '1 hr ago', read: false),
    _Notification(id: '3', type: 'payment', title: 'Payment Sent', body: 'You sent \$25.00 to Alice', time: '3 hrs ago', read: true),
    _Notification(id: '4', type: 'transfer', title: 'Transfer Update', body: 'Your international transfer is being processed', time: 'Yesterday', read: true),
    _Notification(id: '5', type: 'kyc', title: 'KYC Approved', body: 'Your identity has been verified. Level 2 unlocked!', time: 'Yesterday', read: true),
    _Notification(id: '6', type: 'payment', title: 'Payment Request', body: 'Charlie is requesting \$30.00', time: '2 days ago', read: true),
  ];

  @override
  Widget build(BuildContext context) {
    final unread = _items.where((n) => !n.read).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () => setState(() { for (final n in _items) n.read = true; }),
              child: const Text('Mark all read', style: TextStyle(color: AppColors.primary)),
            ),
        ],
      ),
      body: _items.isEmpty
          ? const Center(child: Text('No notifications yet', style: AppTextStyles.body))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (_, i) {
                final n = _items[i];
                return Dismissible(
                  key: Key(n.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: AppColors.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => setState(() => _items.remove(n)),
                  child: InkWell(
                    onTap: () => setState(() => n.read = true),
                    child: Container(
                      color: n.read ? null : AppColors.primary.withOpacity(0.04),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _NotifIcon(type: n.type),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(n.title, style: n.read ? AppTextStyles.bodyBold : AppTextStyles.bodyBold.copyWith(color: AppColors.primary))),
                            Text(n.time, style: AppTextStyles.caption),
                          ]),
                          const SizedBox(height: 4),
                          Text(n.body, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ])),
                        if (!n.read) ...[
                          const SizedBox(width: 8),
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                        ],
                      ]),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _NotifIcon extends StatelessWidget {
  final String type;
  const _NotifIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      'payment' => (Icons.account_balance_wallet, AppColors.success),
      'security' => (Icons.shield_outlined, AppColors.warning),
      'transfer' => (Icons.swap_horiz, AppColors.info),
      'kyc' => (Icons.verified_user_outlined, AppColors.primary),
      _ => (Icons.info_outline, AppColors.textSecondary),
    };
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _Notification {
  final String id, type, title, body, time;
  bool read;
  _Notification({required this.id, required this.type, required this.title, required this.body, required this.time, required this.read});
}
