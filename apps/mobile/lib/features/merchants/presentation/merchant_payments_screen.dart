import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class MerchantPaymentsScreen extends StatefulWidget {
  const MerchantPaymentsScreen({super.key});
  @override
  State<MerchantPaymentsScreen> createState() => _MerchantPaymentsScreenState();
}

class _MerchantPaymentsScreenState extends State<MerchantPaymentsScreen> {
  String _filter = 'All';
  final _searchCtrl = TextEditingController();
  final _filters = ['All', 'Completed', 'Pending', 'Refunded'];

  final _payments = [
    {'name': 'Alice Johnson', 'amount': '\$45.80', 'date': 'Today, 10:23 AM', 'status': 'Completed'},
    {'name': 'Bob Smith', 'amount': '\$12.00', 'date': 'Today, 09:05 AM', 'status': 'Completed'},
    {'name': 'Carol White', 'amount': '\$89.99', 'date': 'Yesterday', 'status': 'Pending'},
    {'name': 'David Lee', 'amount': '\$200.00', 'date': 'Yesterday', 'status': 'Completed'},
    {'name': 'Emma Davis', 'amount': '\$33.50', 'date': 'Dec 10', 'status': 'Refunded'},
    {'name': 'Frank Wilson', 'amount': '\$18.00', 'date': 'Dec 9', 'status': 'Completed'},
  ];

  List<Map<String, String>> get _filtered {
    return _payments.where((p) {
      final matchFilter = _filter == 'All' || p['status'] == _filter;
      final matchSearch = p['name']!.toLowerCase().contains(_searchCtrl.text.toLowerCase());
      return matchFilter && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by payer name...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filters.length,
            itemBuilder: (_, i) {
              final f = _filters[i];
              final selected = _filter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(f),
                  selected: selected,
                  onSelected: (_) => setState(() => _filter = f),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textSecondary, fontSize: 13),
                  backgroundColor: const Color(0xFFF3F4F6),
                  side: BorderSide.none,
                  checkmarkColor: Colors.white,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final p = _filtered[i];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primarySurface,
                    child: Text(p['name']![0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p['name']!, style: AppTextStyles.bodyBold),
                    Text(p['date']!, style: AppTextStyles.caption),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(p['amount']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 4),
                    _StatusBadge(status: p['status']!),
                  ]),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Completed' => AppColors.success,
      'Pending' => AppColors.warning,
      'Refunded' => AppColors.info,
      _ => AppColors.error,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
