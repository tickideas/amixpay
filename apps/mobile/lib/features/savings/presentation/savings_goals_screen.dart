import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/utils/locale_utils.dart';
import '../../wallet/presentation/wallet_screen.dart' show walletCurrenciesProvider;

// ── Model ─────────────────────────────────────────────────────────────────────

class SavingsGoal {
  final String id;
  final String name;
  final String emoji;
  final double target;
  final double saved;
  final String currency;
  final DateTime targetDate;
  final Color color;

  const SavingsGoal({
    required this.id, required this.name, required this.emoji, required this.target,
    required this.saved, required this.currency, required this.targetDate, required this.color,
  });

  double get progress => target > 0 ? (saved / target).clamp(0.0, 1.0) : 0;
  double get remaining => (target - saved).clamp(0, double.infinity);
  bool get isCompleted => saved >= target;

  SavingsGoal copyWith({double? saved}) => SavingsGoal(
    id: id, name: name, emoji: emoji, target: target,
    saved: saved ?? this.saved, currency: currency,
    targetDate: targetDate, color: color,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'emoji': emoji, 'target': target, 'saved': saved,
    'currency': currency, 'targetDate': targetDate.toIso8601String(),
    'colorValue': color.value,
  };

  factory SavingsGoal.fromJson(Map<String, dynamic> j) => SavingsGoal(
    id: j['id'] as String,
    name: j['name'] as String,
    emoji: j['emoji'] as String? ?? '🎯',
    target: (j['target'] as num).toDouble(),
    saved: (j['saved'] as num? ?? 0).toDouble(),
    currency: j['currency'] as String? ?? 'USD',
    targetDate: DateTime.parse(j['targetDate'] as String),
    color: Color(j['colorValue'] as int? ?? AppColors.primary.value),
  );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class SavingsGoalsNotifier extends StateNotifier<List<SavingsGoal>> {
  SavingsGoalsNotifier() : super(const []) {
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await SecureStorage.getSavingsGoals();
      if (raw != null) {
        final list = (jsonDecode(raw) as List)
            .map((e) => SavingsGoal.fromJson(e as Map<String, dynamic>))
            .toList();
        state = list;
      }
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      await SecureStorage.saveSavingsGoals(jsonEncode(state.map((g) => g.toJson()).toList()));
    } catch (_) {}
  }

  void addGoal(SavingsGoal goal) {
    state = [...state, goal];
    _persist();
  }

  void addFunds(String id, double amount) {
    state = state.map((g) {
      if (g.id != id) return g;
      return g.copyWith(saved: g.saved + amount);
    }).toList();
    _persist();
  }

  void removeGoal(String id) {
    state = state.where((g) => g.id != id).toList();
    _persist();
  }
}

final savingsGoalsProvider = StateNotifierProvider<SavingsGoalsNotifier, List<SavingsGoal>>(
    (_) => SavingsGoalsNotifier());

// ── Screen ────────────────────────────────────────────────────────────────────

class SavingsGoalsScreen extends ConsumerStatefulWidget {
  const SavingsGoalsScreen({super.key});

  @override
  ConsumerState<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends ConsumerState<SavingsGoalsScreen> {
  @override
  Widget build(BuildContext context) {
    final goals = ref.watch(savingsGoalsProvider);
    final fmt = NumberFormat('#,##0.00');
    final totalSaved = goals.fold(0.0, (s, g) => s + g.saved);
    final totalTarget = goals.fold(0.0, (s, g) => s + g.target);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: BackButton(color: AppColors.textPrimary),
        title: const Text('Savings Goals', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: () => _showNewGoalSheet(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Summary card ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(
                children: [
                  const Text('Total Saved', style: TextStyle(color: Colors.white60, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    '\$${fmt.format(totalSaved)}',
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'of \$${fmt.format(totalTarget)} target',
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        totalTarget > 0 ? '${(totalSaved / totalTarget * 100).toStringAsFixed(1)}% achieved' : '0% achieved',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text('${goals.length} goals', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (goals.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(children: [
                  const Text('🎯', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  const Text('No savings goals yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  const Text('Create your first goal to start saving', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _showNewGoalSheet,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create a Goal'),
                  ),
                ]),
              )
            else ...[
              ...goals.map((goal) => _GoalCard(
                goal: goal,
                onAdd: () => _showTopUpSheet(goal),
              )),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _showNewGoalSheet,
                icon: const Icon(Icons.add_rounded, color: AppColors.primary),
                label: const Text('Create New Goal', style: TextStyle(color: AppColors.primary)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showTopUpSheet(SavingsGoal goal) {
    final amtCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(goal.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Text('Add to ${goal.name}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.textPrimary)),
            ]),
            const SizedBox(height: 8),
            // Show available wallet balance
            Consumer(builder: (ctx, r, _) {
              final currencies = r.watch(walletCurrenciesProvider);
              final match = currencies.where((c) => c.code == goal.currency).firstOrNull;
              final sym = currencyToSymbol(goal.currency);
              final available = match?.balance ?? 0.0;
              return Text(
                'Available: $sym${available.toStringAsFixed(2)} ${goal.currency}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              );
            }),
            const SizedBox(height: 16),
            TextField(
              controller: amtCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Amount',
                prefixText: '${currencyToSymbol(goal.currency)} ',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amtCtrl.text);
                if (amount == null || amount <= 0) return;

                final currencies = ref.read(walletCurrenciesProvider);
                final match = currencies.where((c) => c.code == goal.currency).firstOrNull;
                final available = match?.balance ?? 0.0;
                final sym = currencyToSymbol(goal.currency);

                if (available < amount) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Insufficient balance. Available: $sym${available.toStringAsFixed(2)}'),
                    backgroundColor: AppColors.error,
                  ));
                  return;
                }

                // Deduct from wallet and credit the goal
                ref.read(walletCurrenciesProvider.notifier).addFunds(goal.currency, -amount);
                ref.read(savingsGoalsProvider.notifier).addFunds(goal.id, amount);

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('$sym${amount.toStringAsFixed(2)} added to ${goal.name}!'),
                  backgroundColor: AppColors.primary,
                ));
              },
              child: const Text('Add Funds'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewGoalSheet() {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    String selectedEmoji = '🎯';
    String selectedCurrency = 'USD';
    final emojis = ['🎯', '✈️', '🏠', '💻', '🚗', '💍', '🎓', '🛡️', '💰', '🏖️', '🎮', '📱'];
    final goalColors = [AppColors.primary, const Color(0xFF7C3AED), const Color(0xFFB8860B),
                        const Color(0xFFBE185D), const Color(0xFF1D4ED8), const Color(0xFF059669)];
    var selectedColor = AppColors.primary;

    // Pre-select primary wallet currency
    final currencies = ref.read(walletCurrenciesProvider);
    if (currencies.isNotEmpty) selectedCurrency = currencies.first.code;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('New Savings Goal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: emojis.map((e) => GestureDetector(
                  onTap: () => setSt(() => selectedEmoji = e),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: selectedEmoji == e ? AppColors.primary.withOpacity(0.15) : AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: selectedEmoji == e ? Border.all(color: AppColors.primary) : null,
                    ),
                    child: Center(child: Text(e, style: const TextStyle(fontSize: 22))),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'Goal name (e.g. Dream House)')),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(
                  controller: targetCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(hintText: 'Target amount'),
                )),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: selectedCurrency,
                  underline: const SizedBox(),
                  items: ['USD', 'EUR', 'GBP', 'NGN', 'KES', 'GHS', 'ZAR'].map((c) =>
                    DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setSt(() => selectedCurrency = v!),
                ),
              ]),
              const SizedBox(height: 12),
              // Color picker
              Row(children: goalColors.map((c) => GestureDetector(
                onTap: () => setSt(() => selectedColor = c),
                child: Container(
                  width: 28, height: 28,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: selectedColor == c ? Border.all(color: Colors.black38, width: 2) : null,
                  ),
                  child: selectedColor == c ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                ),
              )).toList()),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  final target = double.tryParse(targetCtrl.text);
                  if (name.isNotEmpty && target != null && target > 0) {
                    ref.read(savingsGoalsProvider.notifier).addGoal(SavingsGoal(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name, emoji: selectedEmoji, target: target, saved: 0,
                      currency: selectedCurrency,
                      targetDate: DateTime.now().add(const Duration(days: 365)),
                      color: selectedColor,
                    ));
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Create Goal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Goal card widget ──────────────────────────────────────────────────────────

class _GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final VoidCallback onAdd;
  const _GoalCard({required this.goal, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final sym = currencyToSymbol(goal.currency);
    final daysLeft = goal.targetDate.difference(DateTime.now()).inDays;
    final pct = (goal.progress * 100).clamp(0.0, 100.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: goal.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Text(goal.emoji, style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      goal.isCompleted ? '🎉 Goal reached!' : '$daysLeft days left',
                      style: TextStyle(fontSize: 12, color: goal.isCompleted ? AppColors.primary : AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: goal.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('+ Add', style: TextStyle(color: goal.color, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: goal.progress,
              backgroundColor: goal.color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(goal.color),
              minHeight: 7,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$sym${fmt.format(goal.saved)} saved',
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
              ),
              Text(
                '${pct.toStringAsFixed(1)}% of $sym${fmt.format(goal.target)}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
