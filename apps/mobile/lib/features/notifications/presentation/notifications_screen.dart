import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_theme.dart';
import '../data/notifications_repository.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncNotifs = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationsRepositoryProvider).markAllRead();
              ref.invalidate(notificationsProvider);
            },
            child: const Text('Mark all read', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: asyncNotifs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text('Could not load notifications', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              TextButton(onPressed: () => ref.invalidate(notificationsProvider), child: const Text('Retry')),
            ],
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 48, color: AppColors.textSecondary.withOpacity(0.4)),
                  const SizedBox(height: 12),
                  const Text('No notifications yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (_, i) {
                final n = notifications[i];
                final createdAt = DateTime.tryParse(n.createdAt);
                final timeStr = createdAt != null ? timeago.format(createdAt) : '';
                return Dismissible(
                  key: Key(n.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: AppColors.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    // Could add delete endpoint if available
                  },
                  child: InkWell(
                    onTap: () async {
                      if (!n.read) {
                        await ref.read(notificationsRepositoryProvider).markRead(n.id);
                        ref.invalidate(notificationsProvider);
                      }
                    },
                    child: Container(
                      color: n.read ? null : AppColors.primary.withOpacity(0.04),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _NotifIcon(type: n.type),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(n.title, style: n.read ? AppTextStyles.bodyBold : AppTextStyles.bodyBold.copyWith(color: AppColors.primary))),
                            Text(timeStr, style: AppTextStyles.caption),
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
