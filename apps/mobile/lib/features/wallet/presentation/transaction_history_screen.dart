import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/transaction_provider.dart';

export '../../../shared/providers/transaction_provider.dart' show AppTransaction, AppTxType, AppTxStatus;

const _teal = Color(0xFF0D6B5E);
const _bg = Color(0xFFF5F7FA);

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  final String? filterCurrency;
  const TransactionHistoryScreen({super.key, this.filterCurrency});

  @override
  ConsumerState<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends ConsumerState<TransactionHistoryScreen> {
  AppTxType? _selectedType;
  String _search = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppTransaction> _filtered(List<AppTransaction> all) {
    return all.where((t) {
      if (widget.filterCurrency != null && t.currency != widget.filterCurrency) return false;
      if (_selectedType != null && t.type != _selectedType) return false;
      if (_search.isNotEmpty && !t.title.toLowerCase().contains(_search.toLowerCase()) && !t.subtitle.toLowerCase().contains(_search.toLowerCase())) return false;
      return true;
    }).toList();
  }

  String _groupLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(txDay).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff <= 7) return 'This Week';
    return 'Earlier';
  }

  Map<String, List<AppTransaction>> _grouped(List<AppTransaction> txs) {
    final map = <String, List<AppTransaction>>{};
    for (final tx in txs) {
      final label = _groupLabel(tx.date);
      map.putIfAbsent(label, () => []).add(tx);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(transactionProvider);
    final filtered = _filtered(all);
    final grouped = _grouped(filtered);
    final groups = ['Today', 'Yesterday', 'This Week', 'Earlier'].where(grouped.containsKey).toList();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        title: Text(widget.filterCurrency != null ? '${widget.filterCurrency} Transactions' : 'Transaction History',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _search.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey), onPressed: () { _searchController.clear(); setState(() => _search = ''); }) : null,
                filled: true,
                fillColor: _bg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(label: 'All', selected: _selectedType == null, onTap: () => setState(() => _selectedType = null)),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Sent', selected: _selectedType == AppTxType.sent, onTap: () => setState(() => _selectedType = AppTxType.sent)),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Received', selected: _selectedType == AppTxType.received, onTap: () => setState(() => _selectedType = AppTxType.received)),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Transfers', selected: _selectedType == AppTxType.transfer, onTap: () => setState(() => _selectedType = AppTxType.transfer)),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Funded', selected: _selectedType == AppTxType.funded, onTap: () => setState(() => _selectedType = AppTxType.funded)),
                ],
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No transactions found', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: groups.fold<int>(0, (sum, g) => sum + grouped[g]!.length + 1),
                    itemBuilder: (context, index) {
                      int cursor = 0;
                      for (final group in groups) {
                        if (index == cursor) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 6),
                            child: Text(group, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13)),
                          );
                        }
                        cursor++;
                        final txs = grouped[group]!;
                        if (index < cursor + txs.length) {
                          return _TransactionTile(tx: txs[index - cursor]);
                        }
                        cursor += txs.length;
                      }
                      return const SizedBox.shrink();
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? _teal : _bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _teal : Colors.grey.shade300),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.w500, fontSize: 13)),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final AppTransaction tx;
  const _TransactionTile({required this.tx});

  Color get _iconBg => tx.type == AppTxType.received || tx.type == AppTxType.funded ? Colors.green.shade50 : tx.type == AppTxType.transfer ? Colors.blue.shade50 : Colors.red.shade50;
  Color get _iconColor => tx.type == AppTxType.received || tx.type == AppTxType.funded ? Colors.green : tx.type == AppTxType.transfer ? Colors.blue : Colors.red;
  IconData get _icon => tx.type == AppTxType.received ? Icons.arrow_downward : tx.type == AppTxType.funded ? Icons.account_balance_wallet : tx.type == AppTxType.transfer ? Icons.swap_horiz : Icons.arrow_upward;
  bool get _isPositive => tx.type == AppTxType.received || tx.type == AppTxType.funded;

  Color get _statusColor => tx.status == AppTxStatus.paid ? Colors.green : tx.status == AppTxStatus.pending ? Colors.orange : Colors.red;
  String get _statusLabel => tx.status.name[0].toUpperCase() + tx.status.name.substring(1);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/wallet/transaction/${tx.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: _iconBg, borderRadius: BorderRadius.circular(10)),
                child: Icon(_icon, color: _iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('${tx.date.hour.toString().padLeft(2,'0')}:${tx.date.minute.toString().padLeft(2,'0')}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${_isPositive ? '+' : '-'}${tx.symbol}${tx.amount.toStringAsFixed(2)}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: _isPositive ? Colors.green : Colors.red, fontSize: 14)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: _statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(_statusLabel, style: TextStyle(color: _statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
