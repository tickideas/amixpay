import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../data/payment_repository.dart';
import '../domain/payment_models.dart';

final _incomingProvider = FutureProvider.autoDispose<List<PaymentRequestModel>>((ref) {
  return ref.read(paymentRepositoryProvider).getRequests(role: 'payer');
});

final _outgoingProvider = FutureProvider.autoDispose<List<PaymentRequestModel>>((ref) {
  return ref.read(paymentRepositoryProvider).getRequests(role: 'requester');
});

class PaymentRequestsScreen extends ConsumerStatefulWidget {
  const PaymentRequestsScreen({super.key});
  @override
  ConsumerState<PaymentRequestsScreen> createState() => _PaymentRequestsScreenState();
}

class _PaymentRequestsScreenState extends ConsumerState<PaymentRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  @override
  void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Requests'),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.primary,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'Incoming'), Tab(text: 'Outgoing')],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _RequestList(provider: _incomingProvider, incoming: true),
          _RequestList(provider: _outgoingProvider, incoming: false),
        ],
      ),
    );
  }
}

class _RequestList extends ConsumerWidget {
  final AutoDisposeFutureProvider<List<PaymentRequestModel>> provider;
  final bool incoming;
  const _RequestList({required this.provider, required this.incoming});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(provider);
    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load: $e', style: const TextStyle(color: AppColors.textSecondary))),
      data: (requests) {
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_rounded, size: 48, color: AppColors.textSecondary.withOpacity(0.4)),
                const SizedBox(height: 12),
                Text(
                  incoming ? 'No incoming requests' : 'No outgoing requests',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(provider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (_, i) => _RequestCard(request: requests[i], incoming: incoming, ref: ref),
          ),
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  final PaymentRequestModel request;
  final bool incoming;
  final WidgetRef ref;
  const _RequestCard({required this.request, required this.incoming, required this.ref});

  @override
  Widget build(BuildContext context) {
    final displayName = incoming
        ? (request.requesterUsername ?? request.requesterId)
        : (request.payerUsername ?? request.payerId);
    final initials = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final name = displayName.startsWith('@') ? displayName : '@$displayName';
    final amount = '\$${request.amount.toStringAsFixed(2)} ${request.currencyCode}';
    final isPending = request.status == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(backgroundColor: AppColors.primarySurface, child: Text(initials, style: const TextStyle(color: AppColors.primary))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: AppTextStyles.bodyBold),
                Text(incoming ? 'Requesting from you' : 'You requested', style: AppTextStyles.caption),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
              ]),
            ]),
            if (request.note != null && request.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(request.note!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
            if (incoming && isPending) ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () async {
                    await ref.read(paymentRepositoryProvider).declineRequest(request.id);
                    ref.invalidate(_incomingProvider);
                  },
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error), minimumSize: const Size(0, 38)),
                  child: const Text('Decline'),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () async {
                    await ref.read(paymentRepositoryProvider).acceptRequest(request.id);
                    ref.invalidate(_incomingProvider);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(0, 38)),
                  child: const Text('Accept'),
                )),
              ]),
            ] else if (!incoming && isPending) ...[
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text('Pending', style: TextStyle(color: AppColors.warning, fontSize: 12)),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: request.status == 'accepted' ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  request.status == 'accepted' ? 'Accepted' : 'Declined',
                  style: TextStyle(color: request.status == 'accepted' ? AppColors.success : AppColors.error, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
