import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/locale_utils.dart';
import '../../../shared/widgets/amix_button.dart';

class SplitBillScreen extends StatefulWidget {
  const SplitBillScreen({super.key});
  @override
  State<SplitBillScreen> createState() => _SplitBillScreenState();
}

class _SplitBillScreenState extends State<SplitBillScreen> {
  // Instant locale detection — no network call needed
  String _currencySymbol = currencyToSymbol(detectLocaleCurrency());
  final List<_BillItem> _items = [
    _BillItem(name: 'Beef Teriyaki Bowl', price: 4.50, qty: 1),
    _BillItem(name: 'Salmon Sashimi Plate', price: 4.80, qty: 1),
    _BillItem(name: 'Green Tea x2', price: 3.00, qty: 2),
    _BillItem(name: 'Edamame', price: 2.50, qty: 1),
  ];

  double _taxAmount = 2.38;
  double _discountAmount = 2.00;
  final List<String> _participants = ['@alice', '@bob', '@charlie'];

  double get _subtotal => _items.fold(0, (s, i) => s + (i.price * i.qty));
  double get _total => _subtotal + _taxAmount - _discountAmount;
  double get _perPerson => _participants.isEmpty ? _total : _total / _participants.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Details'),
        actions: [
          TextButton(
            onPressed: () => _addParticipantDialog(),
            child: const Text('+ Add'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Participants row
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _participants.length + 1,
              itemBuilder: (ctx, i) {
                if (i == _participants.length) {
                  return GestureDetector(
                    onTap: _addParticipantDialog,
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary, width: 1.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.add, color: AppColors.primary, size: 18),
                    ),
                  );
                }
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Chip(
                    label: Text(_participants[i], style: const TextStyle(fontSize: 12)),
                    backgroundColor: AppColors.primarySurface,
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => setState(() => _participants.removeAt(i)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Items table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  const Expanded(flex: 5, child: Text('Item', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary))),
                  const Expanded(flex: 2, child: Text('Price', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center)),
                  const Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center)),
                  const Expanded(flex: 2, child: Text('Total', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.right)),
                ]),
              ),
              const Divider(height: 1),
              ...List.generate(_items.length, (i) {
                final item = _items[i];
                return Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(children: [
                      Expanded(flex: 5, child: Text(item.name, style: const TextStyle(fontSize: 13))),
                      Expanded(flex: 2, child: Text('$_currencySymbol${item.price.toStringAsFixed(2)}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13))),
                      Expanded(flex: 1, child: Text('${item.qty}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
                      Expanded(flex: 2, child: Text('$_currencySymbol${(item.price * item.qty).toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                    ]),
                  ),
                  if (i < _items.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
                ]);
              }),
            ]),
          ),

          const SizedBox(height: 20),

          // Summary card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(children: [
              _SummaryRow(label: 'Subtotal', value: '$_currencySymbol${_subtotal.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              _SummaryRow(
                label: 'Tax',
                value: '+$_currencySymbol${_taxAmount.toStringAsFixed(2)}',
                valueColor: AppColors.textPrimary,
              ),
              const SizedBox(height: 8),
              _SummaryRow(
                label: 'Discount',
                value: '-$_currencySymbol${_discountAmount.toStringAsFixed(2)}',
                valueColor: AppColors.success,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              Row(children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const Spacer(),
                Text('$_currencySymbol${_total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.primary)),
              ]),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.people_outline, color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${_participants.length} people · $_currencySymbol${_perPerson.toStringAsFixed(2)} each',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ]),
              ),
            ]),
          ),

          const SizedBox(height: 32),

          AmixButton(
            label: 'Confirm Split',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Split bill created! Requests sent to participants.'), backgroundColor: AppColors.success),
              );
              context.push('/splits/split-abc123');
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _editBillDialog,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Edit Bill'),
          ),
        ]),
      ),
    );
  }

  void _addParticipantDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Participant'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Username or email'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) setState(() => _participants.add(ctrl.text));
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editBillDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _EditBillSheet(
          items: _items,
          taxAmount: _taxAmount,
          discountAmount: _discountAmount,
          onSave: (items, tax, discount) {
            setState(() {
              _items.clear();
              _items.addAll(items);
              _taxAmount = tax;
              _discountAmount = discount;
            });
          },
        ),
      ),
    );
  }
}

class _BillItem {
  String name;
  double price;
  int qty;
  _BillItem({required this.name, required this.price, required this.qty});
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _SummaryRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      const Spacer(),
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: valueColor ?? AppColors.textSecondary)),
    ]);
  }
}

class _EditBillSheet extends StatefulWidget {
  final List<_BillItem> items;
  final double taxAmount;
  final double discountAmount;
  final Function(List<_BillItem>, double, double) onSave;
  const _EditBillSheet({required this.items, required this.taxAmount, required this.discountAmount, required this.onSave});

  @override
  State<_EditBillSheet> createState() => _EditBillSheetState();
}

class _EditBillSheetState extends State<_EditBillSheet> {
  late List<_BillItem> _items;
  late TextEditingController _taxCtrl;
  late TextEditingController _discountCtrl;

  @override
  void initState() {
    super.initState();
    _items = widget.items.map((i) => _BillItem(name: i.name, price: i.price, qty: i.qty)).toList();
    _taxCtrl = TextEditingController(text: widget.taxAmount.toStringAsFixed(2));
    _discountCtrl = TextEditingController(text: widget.discountAmount.toStringAsFixed(2));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Edit Bill', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        ..._items.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Expanded(child: Text(item.name, style: const TextStyle(fontSize: 13))),
              const SizedBox(width: 8),
              SizedBox(
                width: 70,
                child: TextFormField(
                  initialValue: item.price.toStringAsFixed(2),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(prefixText: '\$', isDense: true, contentPadding: EdgeInsets.all(8)),
                  onChanged: (v) => _items[i].price = double.tryParse(v) ?? item.price,
                ),
              ),
              const SizedBox(width: 8),
              Row(children: [
                GestureDetector(
                  onTap: () => setState(() { if (item.qty > 1) item.qty--; }),
                  child: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                ),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('${item.qty}')),
                GestureDetector(
                  onTap: () => setState(() => item.qty++),
                  child: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                ),
              ]),
            ]),
          );
        }),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(controller: _taxCtrl, decoration: const InputDecoration(labelText: 'Tax', prefixText: '\$'), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
          const SizedBox(width: 16),
          Expanded(child: TextField(controller: _discountCtrl, decoration: const InputDecoration(labelText: 'Discount', prefixText: '\$'), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              widget.onSave(_items, double.tryParse(_taxCtrl.text) ?? 0, double.tryParse(_discountCtrl.text) ?? 0);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
          ),
        ),
      ]),
    );
  }
}
