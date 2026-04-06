import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class PaymentRequestsScreen extends StatefulWidget {
  const PaymentRequestsScreen({super.key});
  @override
  State<PaymentRequestsScreen> createState() => _PaymentRequestsScreenState();
}

class _PaymentRequestsScreenState extends State<PaymentRequestsScreen> with SingleTickerProviderStateMixin {
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
          _buildList(incoming: true),
          _buildList(incoming: false),
        ],
      ),
    );
  }

  Widget _buildList({required bool incoming}) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (_, i) => _RequestCard(incoming: incoming),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final bool incoming;
  const _RequestCard({required this.incoming});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(backgroundColor: AppColors.primarySurface, child: Text(incoming ? 'B' : 'A', style: const TextStyle(color: AppColors.primary))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(incoming ? 'Bob Smith' : 'Alice Johnson', style: AppTextStyles.bodyBold),
                Text(incoming ? 'Requesting from you' : 'You requested', style: AppTextStyles.caption),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('\$50.00', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                Text('2h ago', style: AppTextStyles.caption),
              ]),
            ]),
            const SizedBox(height: 8),
            const Text('Coffee split', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            if (incoming) ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error), minimumSize: const Size(0, 38)),
                  child: const Text('Decline'),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(0, 38)),
                  child: const Text('Accept'),
                )),
              ]),
            ] else ...[
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text('Pending', style: TextStyle(color: AppColors.warning, fontSize: 12)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
