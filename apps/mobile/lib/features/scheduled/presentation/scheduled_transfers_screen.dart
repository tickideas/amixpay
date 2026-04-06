import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';

enum Frequency { once, daily, weekly, monthly }

class ScheduledTransfer {
  final String id, recipient, currency, description;
  final double amount;
  final Frequency frequency;
  final DateTime nextDate;
  final bool active;

  const ScheduledTransfer({
    required this.id, required this.recipient, required this.currency,
    required this.amount, required this.frequency, required this.nextDate,
    required this.description, required this.active,
  });

  String get frequencyLabel {
    switch (frequency) {
      case Frequency.once: return 'One-time';
      case Frequency.daily: return 'Daily';
      case Frequency.weekly: return 'Weekly';
      case Frequency.monthly: return 'Monthly';
    }
  }
}

final _demoScheduled = <ScheduledTransfer>[];

class ScheduledTransfersScreen extends StatefulWidget {
  const ScheduledTransfersScreen({super.key});

  @override
  State<ScheduledTransfersScreen> createState() => _ScheduledTransfersScreenState();
}

class _ScheduledTransfersScreenState extends State<ScheduledTransfersScreen> {
  final List<ScheduledTransfer> _transfers = List.from(_demoScheduled);

  @override
  Widget build(BuildContext context) {
    final active = _transfers.where((t) => t.active).toList();
    final inactive = _transfers.where((t) => !t.active).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: BackButton(color: AppColors.textPrimary),
        title: const Text('Scheduled Transfers', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: () => _showNewScheduleSheet(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.schedule_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Scheduled transfers run automatically at the set time using your wallet balance.',
                      style: TextStyle(color: AppColors.primary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (active.isNotEmpty) ...[
              const Text('Active Schedules', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              ...active.map((t) => _ScheduleCard(transfer: t, onToggle: () => setState(() {
                final idx = _transfers.indexOf(t);
                _transfers[idx] = ScheduledTransfer(
                  id: t.id, recipient: t.recipient, currency: t.currency, amount: t.amount,
                  frequency: t.frequency, nextDate: t.nextDate, description: t.description, active: !t.active,
                );
              }))),
            ],

            if (inactive.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Paused', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              ...inactive.map((t) => _ScheduleCard(transfer: t, onToggle: () => setState(() {
                final idx = _transfers.indexOf(t);
                _transfers[idx] = ScheduledTransfer(
                  id: t.id, recipient: t.recipient, currency: t.currency, amount: t.amount,
                  frequency: t.frequency, nextDate: t.nextDate, description: t.description, active: !t.active,
                );
              }))),
            ],

            const SizedBox(height: 20),

            OutlinedButton.icon(
              onPressed: () => _showNewScheduleSheet(),
              icon: const Icon(Icons.add_rounded, color: AppColors.primary),
              label: const Text('Add Schedule', style: TextStyle(color: AppColors.primary)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showNewScheduleSheet() {
    final recipientCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    Frequency selectedFreq = Frequency.monthly;
    String selectedCurrency = 'USD';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('New Scheduled Transfer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              TextField(controller: recipientCtrl, decoration: const InputDecoration(hintText: 'Recipient email / username', prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textSecondary, size: 20))),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextField(controller: amtCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(hintText: 'Amount'))),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: selectedCurrency,
                    items: ['USD', 'EUR', 'GBP', 'NGN', 'GHS'].map((c) => DropdownMenuItem(value: c, child: Row(mainAxisSize: MainAxisSize.min, children: [Text(currencyFlag(c), style: const TextStyle(fontSize: 16)), const SizedBox(width: 6), Text(c)]))).toList(),
                    onChanged: (v) => setSt(() => selectedCurrency = v!),
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(controller: descCtrl, decoration: const InputDecoration(hintText: 'Description (optional)')),
              const SizedBox(height: 14),
              // Frequency
              const Text('Frequency', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: Frequency.values.map((f) => GestureDetector(
                  onTap: () => setSt(() => selectedFreq = f),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selectedFreq == f ? AppColors.primary : AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selectedFreq == f ? AppColors.primary : AppColors.border),
                    ),
                    child: Text(
                      f == Frequency.once ? 'One-time' : f.name[0].toUpperCase() + f.name.substring(1),
                      style: TextStyle(color: selectedFreq == f ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 14),
              // Start date
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (c, child) => Theme(
                      data: Theme.of(c).copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.primary)),
                      child: child!,
                    ),
                  );
                  if (picked != null) setSt(() => selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'Start: ${DateFormat('MMM d, yyyy').format(selectedDate)}',
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (recipientCtrl.text.isEmpty || amtCtrl.text.isEmpty) return;
                    final amt = double.tryParse(amtCtrl.text) ?? 0;
                    if (amt <= 0) return;
                    Navigator.pop(ctx);
                    setState(() {
                      _transfers.add(ScheduledTransfer(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        recipient: recipientCtrl.text,
                        currency: selectedCurrency,
                        amount: amt,
                        frequency: selectedFreq,
                        nextDate: selectedDate,
                        description: descCtrl.text.isEmpty ? 'Scheduled transfer' : descCtrl.text,
                        active: true,
                      ));
                    });
                  },
                  child: const Text('Schedule Transfer'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final ScheduledTransfer transfer;
  final VoidCallback onToggle;
  const _ScheduleCard({required this.transfer, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: transfer.active ? AppColors.border : AppColors.textHint.withOpacity(0.3)),
        boxShadow: transfer.active ? [BoxShadow(color: AppColors.primary.withOpacity(0.05), blurRadius: 8)] : [],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: transfer.active ? AppColors.primary.withOpacity(0.1) : AppColors.textHint.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  transfer.frequency == Frequency.once ? Icons.send_rounded : Icons.repeat_rounded,
                  color: transfer.active ? AppColors.primary : AppColors.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(transfer.description, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                    Text(transfer.recipient, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${transfer.currency} ${fmt.format(transfer.amount)}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                  ),
                  Text(transfer.frequencyLabel, style: TextStyle(fontSize: 11, color: transfer.active ? AppColors.primary : AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.event_rounded, color: AppColors.textSecondary, size: 14),
              const SizedBox(width: 6),
              Text(
                'Next: ${DateFormat('MMM d, yyyy').format(transfer.nextDate)}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: transfer.active ? const Color(0xFFEF4444).withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    transfer.active ? 'Pause' : 'Resume',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: transfer.active ? const Color(0xFFEF4444) : AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
