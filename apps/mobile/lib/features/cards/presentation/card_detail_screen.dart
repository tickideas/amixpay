import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/providers/transaction_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../wallet/presentation/wallet_screen.dart' show walletCurrenciesProvider;
import '../data/user_cards_provider.dart';
import 'add_card_screen.dart' show kCardGradientOptions, cardGradientFor;

class CardDetailScreen extends ConsumerStatefulWidget {
  final String cardId;
  const CardDetailScreen({super.key, required this.cardId});
  @override
  ConsumerState<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends ConsumerState<CardDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _showNumber = false;
  bool _cardDetailsExpanded = false;
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(userCardsProvider);
    final card = cards.where((c) => c.id == widget.cardId).firstOrNull;

    if (card == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Card Details')),
        body: const Center(child: Text('Card not found')),
      );
    }

    final frozen = card.holder.startsWith('[FROZEN] ');
    final authState = ref.watch(authProvider);
    final user = authState.value?.user;
    final displayName = frozen
        ? card.holder.substring('[FROZEN] '.length)
        : card.holder;
    final holderDisplay = displayName.isNotEmpty
        ? displayName
        : (user != null ? '${user.firstName} ${user.lastName}'.trim() : 'AmixPay User');

    final gradient = frozen
        ? const LinearGradient(colors: [Color(0xFF9CA3AF), Color(0xFF6B7280)])
        : card.gradient;

    final allTxns = ref.watch(transactionProvider);
    final cardTxns = allTxns.where((t) => t.currency == card.currency).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    // Wallet balance for this card currency
    final wallets = ref.watch(walletCurrenciesProvider);
    final wallet = wallets.where((w) => w.code == card.currency).firstOrNull;
    final balanceStr = wallet != null
        ? '${wallet.symbol}${wallet.balance.toStringAsFixed(2)}'
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          '${card.type == 'virtual' ? 'Virtual' : 'Physical'} ····${card.last4}',
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 16),
        ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'Overview'), Tab(text: 'History')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // ── Tab 1: Overview ─────────────────────────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── Card visual ──────────────────────────────────────────────────
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Text('VISA', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 2)),
                    const Spacer(),
                    if (frozen)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                        child: const Text('FROZEN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                        child: Text(card.type.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                      ),
                  ]),
                  const Spacer(),
                  if (balanceStr != null) ...[
                    Text(balanceStr, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    _showNumber ? '4532  1234  5678  ${card.last4}' : '••••  ••••  ••••  ${card.last4}',
                    style: const TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 2),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('EXPIRES', style: TextStyle(color: Colors.white54, fontSize: 9)),
                      Text(card.expiry, style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ]),
                    const SizedBox(width: 20),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('CVC', style: TextStyle(color: Colors.white54, fontSize: 9)),
                      Text(_showNumber ? '456' : '•••', style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ]),
                    const Spacer(),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      const Text('HOLDER', style: TextStyle(color: Colors.white54, fontSize: 9)),
                      Text(
                        holderDisplay.length > 16 ? holderDisplay.substring(0, 16) : holderDisplay,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ]),
                  ]),
                ]),
              ),

              const SizedBox(height: 16),

              // ── Card Unlocked toggle (Starling-style) ────────────────────────
              _SectionCard(children: [
                _UnlockTile(
                  frozen: frozen,
                  onToggle: () {
                    ref.read(userCardsProvider.notifier).toggleFreeze(card.id);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(frozen ? 'Card unlocked. Transactions enabled.' : 'Card locked. All transactions blocked.'),
                      backgroundColor: frozen ? AppColors.primary : const Color(0xFF1565C0),
                    ));
                  },
                ),
              ]),

              const SizedBox(height: 12),

              // ── Mobile Wallet ────────────────────────────────────────────────
              _SectionCard(children: [
                _WalletHeader(),
                const Divider(height: 1, indent: 16, endIndent: 16),
                if (defaultTargetPlatform == TargetPlatform.iOS) ...[
                  _WalletTile(
                    icon: Icons.apple_rounded,
                    iconColor: Colors.black,
                    title: 'Add to Apple Wallet',
                    subtitle: 'Pay with Face ID or Touch ID',
                    onTap: () async {
                      final uri = Uri.parse('shoebox://');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Apple Wallet not available on this device'),
                            backgroundColor: AppColors.primary,
                          ));
                        }
                      }
                    },
                  ),
                ] else ...[
                  _WalletTile(
                    icon: Icons.g_mobiledata_rounded,
                    iconColor: const Color(0xFF4285F4),
                    title: 'Add to Google Pay',
                    subtitle: 'Tap and pay at millions of stores',
                    onTap: () async {
                      final uri = Uri.parse('https://pay.google.com/');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  _WalletTile(
                    icon: Icons.smartphone_rounded,
                    iconColor: const Color(0xFF1428A0),
                    title: 'Add to Samsung Pay',
                    subtitle: 'Works with Samsung Galaxy devices',
                    onTap: () async {
                      final uri = Uri.parse('samsungpay://');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        final web = Uri.parse('https://www.samsung.com/global/galaxy/apps/samsung-pay/');
                        await launchUrl(web, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ],
              ]),

              const SizedBox(height: 12),

              // ── Card Details expandable ──────────────────────────────────────
              _SectionCard(children: [
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() => _cardDetailsExpanded = !_cardDetailsExpanded),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.credit_card_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Card Details', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                        Text('Card number, expiry, CVC', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ])),
                      Icon(_cardDetailsExpanded ? Icons.keyboard_arrow_up_rounded : Icons.chevron_right_rounded, color: AppColors.textSecondary),
                    ]),
                  ),
                ),
                if (_cardDetailsExpanded) ...[
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('CARD NUMBER', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, letterSpacing: 0.8)),
                          const SizedBox(height: 4),
                          Text(
                            _showNumber ? '4532 1234 5678 ${card.last4}' : '•••• •••• •••• ${card.last4}',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 1.5),
                          ),
                        ])),
                        IconButton(
                          onPressed: () => setState(() => _showNumber = !_showNumber),
                          icon: Icon(_showNumber ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.primary, size: 20),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('EXPIRY', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, letterSpacing: 0.8)),
                          const SizedBox(height: 4),
                          Text(card.expiry, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ])),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('CVC', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, letterSpacing: 0.8)),
                          const SizedBox(height: 4),
                          Text(_showNumber ? '456' : '•••', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ])),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('CURRENCY', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, letterSpacing: 0.8)),
                          const SizedBox(height: 4),
                          Text(card.currency, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ])),
                      ]),
                      if (_showNumber) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(const ClipboardData(text: '4532123456789982'));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Card number copied'), backgroundColor: AppColors.primary));
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('Copy Card Number'),
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary)),
                        ),
                      ],
                    ]),
                  ),
                ],
              ]),

              const SizedBox(height: 20),

              // ── Card Controls header ─────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 10),
                child: Text('CARD CONTROLS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
              ),

              _SectionCard(children: [
                _ControlTile(
                  icon: Icons.dialpad_rounded,
                  color: AppColors.primary,
                  title: 'Set / Change PIN',
                  subtitle: 'Manage your card PIN',
                  onTap: () => _showPinDialog(context, card.id),
                ),
                _Divider(),
                _ControlTile(
                  icon: Icons.tune_rounded,
                  color: AppColors.info,
                  title: 'Spending Limits',
                  subtitle: 'Set daily and monthly caps',
                  onTap: () => _showSpendingLimitsSheet(context, card.id),
                ),
                _Divider(),
                _ControlTile(
                  icon: Icons.notifications_outlined,
                  color: const Color(0xFF7C3AED),
                  title: 'Transaction Alerts',
                  subtitle: 'Get notified on every transaction',
                  onTap: () => context.push(AppRoutes.notificationSettings),
                ),
                _Divider(),
                _ControlTile(
                  icon: Icons.palette_outlined,
                  color: AppColors.primary,
                  title: 'Customize Card',
                  subtitle: 'Change card color and name',
                  onTap: () => _showCustomizeSheet(context, ref, card),
                ),
                _Divider(),
                _ControlTile(
                  icon: Icons.report_problem_outlined,
                  color: AppColors.warning,
                  title: 'Report Lost / Stolen',
                  subtitle: 'Block card and request replacement',
                  onTap: () => _showReportLostSheet(context, ref, card),
                ),
                if (!card.isFree) ...[
                  _Divider(),
                  _ControlTile(
                    icon: Icons.delete_outline_rounded,
                    color: AppColors.error,
                    title: 'Cancel Card',
                    subtitle: 'Permanently deactivate this card',
                    onTap: () => _confirmCancel(context, ref, card.id),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.error, size: 18),
                  ),
                ],
              ]),

              const SizedBox(height: 30),
            ]),
          ),

          // ── Tab 2: Transaction History ─────────────────────────────────────
          cardTxns.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('No ${card.currency} transactions yet',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    const Text('Transactions will appear here after use.',
                        style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                  ]),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: cardTxns.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final t = cardTxns[i];
                    final isSent = t.type == AppTxType.sent;
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
                      child: Row(children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: (isSent ? Colors.red : Colors.green).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(isSent ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: isSent ? Colors.red : Colors.green, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(t.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          Text(t.subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text(
                            '${isSent ? '-' : '+'}${t.symbol}${t.amount.toStringAsFixed(2)}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isSent ? Colors.red : Colors.green),
                          ),
                          Text('${t.date.day}/${t.date.month}/${t.date.year}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                        ]),
                      ]),
                    );
                  },
                ),
        ],
      ),
    );
  }

  // ── Spending limits sheet ───────────────────────────────────────────────────

  void _showSpendingLimitsSheet(BuildContext context, String cardId) {
    final dailyCtrl = TextEditingController(text: '500');
    final monthlyCtrl = TextEditingController(text: '2000');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.tune_rounded, color: AppColors.info, size: 20)),
            const SizedBox(width: 12),
            const Text('Spending Limits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 6),
          const Text('Limits reset at midnight UTC each day / first of month.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          const Text('Daily limit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextField(
            controller: dailyCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              prefixText: '\$ ',
              hintText: '500.00',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            ),
          ),
          const SizedBox(height: 14),
          const Text('Monthly limit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextField(
            controller: monthlyCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              prefixText: '\$ ',
              hintText: '2000.00',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Limits saved: \$${dailyCtrl.text}/day · \$${monthlyCtrl.text}/month'),
                  backgroundColor: AppColors.success,
                ));
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: const Text('Save Limits', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
    );
  }

  // ── PIN dialog ──────────────────────────────────────────────────────────────

  void _showPinDialog(BuildContext context, String cardId) {
    final pinCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.dialpad_rounded, color: AppColors.primary, size: 22),
          SizedBox(width: 8),
          Text('Set Card PIN'),
        ]),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Choose a 4-digit PIN for your card.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            TextFormField(
              controller: pinCtrl,
              obscureText: true,
              maxLength: 4,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'New PIN', counterText: '', prefixIcon: Icon(Icons.lock_outline_rounded)),
              validator: (v) => (v == null || v.length < 4) ? 'PIN must be 4 digits' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: confirmCtrl,
              obscureText: true,
              maxLength: 4,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Confirm PIN', counterText: '', prefixIcon: Icon(Icons.lock_rounded)),
              validator: (v) => v != pinCtrl.text ? 'PINs do not match' : null,
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Card PIN set successfully!'),
                  backgroundColor: AppColors.primary,
                ));
              }
            },
            child: const Text('Set PIN'),
          ),
        ],
      ),
    );
  }

  // ── Report Lost/Stolen ──────────────────────────────────────────────────────

  void _showReportLostSheet(BuildContext context, WidgetRef ref, IssuedCard card) {
    final frozen = card.holder.startsWith('[FROZEN] ');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.report_problem_rounded, color: Color(0xFFF59E0B), size: 22),
          SizedBox(width: 8),
          Text('Report Card Lost or Stolen?'),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withValues(alpha: 0.2))),
            child: const Row(children: [
              Icon(Icons.shield_outlined, color: Colors.red, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('Your card will be frozen immediately and all transactions blocked.', style: TextStyle(fontSize: 12, color: Colors.red))),
            ]),
          ),
          const SizedBox(height: 12),
          const Text('A replacement card will be issued and delivered within 5-7 business days.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (!frozen) {
                ref.read(userCardsProvider.notifier).toggleFreeze(card.id);
              }
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Card blocked. Replacement will arrive in 5-7 business days.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 4),
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Report & Block Card'),
          ),
        ],
      ),
    );
  }

  // ── Customize sheet ─────────────────────────────────────────────────────────

  void _showCustomizeSheet(BuildContext context, WidgetRef ref, IssuedCard card) {
    String selectedGradKey = card.gradientKey;
    final nameCtrl = TextEditingController(
        text: card.holder.startsWith('[FROZEN] ') ? card.holder.substring(9) : card.holder);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Customize Card', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Change card color and display name', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            Container(
              height: 90,
              decoration: BoxDecoration(gradient: cardGradientFor(selectedGradKey), borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                const Text('VISA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 2)),
                const Spacer(),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('•••• ${card.last4}', style: const TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 2)),
                  const SizedBox(height: 4),
                  Text(nameCtrl.text.isEmpty ? 'YOUR NAME' : nameCtrl.text.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
              ]),
            ),
            const SizedBox(height: 16),
            const Text('Card Color', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: kCardGradientOptions.map((opt) {
                  final sel = selectedGradKey == opt.key;
                  return GestureDetector(
                    onTap: () => setSheetState(() => selectedGradKey = opt.key),
                    child: Container(
                      width: 44, height: 44,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        gradient: opt.gradient,
                        shape: BoxShape.circle,
                        border: Border.all(color: sel ? AppColors.primary : Colors.transparent, width: 3),
                      ),
                      child: sel ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Display Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Name on card', prefixIcon: Icon(Icons.person_outline_rounded)),
              onChanged: (_) => setSheetState(() {}),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final frozenPrefix = card.holder.startsWith('[FROZEN] ') ? '[FROZEN] ' : '';
                ref.read(userCardsProvider.notifier).updateCard(card.id,
                    holder: '$frozenPrefix${nameCtrl.text.trim()}', gradientKey: selectedGradKey);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Card updated!'), backgroundColor: AppColors.primary));
              },
              child: const Text('Save Changes'),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Cancel card ─────────────────────────────────────────────────────────────

  void _confirmCancel(BuildContext context, WidgetRef ref, String cardId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Card?'),
        content: const Text('This action is permanent. The card will be deactivated immediately.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Keep Card')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(userCardsProvider.notifier).removeCard(cardId);
              context.pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Cancel Card'),
          ),
        ],
      ),
    );
  }
}

// ── Section card wrapper ───────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))],
    ),
    child: Column(children: children),
  );
}

// ── Card unlock toggle tile ────────────────────────────────────────────────────

class _UnlockTile extends StatelessWidget {
  final bool frozen;
  final VoidCallback onToggle;
  const _UnlockTile({required this.frozen, required this.onToggle});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: frozen ? const Color(0xFF1565C0).withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(frozen ? Icons.lock_rounded : Icons.lock_open_rounded,
            color: frozen ? const Color(0xFF1565C0) : AppColors.primary, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(frozen ? 'Card locked' : 'Card unlocked',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
        Text(frozen ? 'Tap to unlock card' : 'Tap to freeze all transactions',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ])),
      Switch(
        value: !frozen,
        onChanged: (_) => onToggle(),
        activeColor: AppColors.primary,
      ),
    ]),
  );
}

// ── Mobile Wallet header ───────────────────────────────────────────────────────

class _WalletHeader extends StatelessWidget {
  const _WalletHeader();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
    child: Row(children: [
      Icon(Icons.wallet_rounded, color: AppColors.primary, size: 20),
      SizedBox(width: 8),
      Text('Mobile Wallet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
    ]),
  );
}

// ── Wallet tile ────────────────────────────────────────────────────────────────

class _WalletTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _WalletTile({required this.icon, required this.iconColor, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ])),
        const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 18),
      ]),
    ),
  );
}

// ── Control tile ───────────────────────────────────────────────────────────────

class _ControlTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  const _ControlTile({required this.icon, required this.color, required this.title, required this.subtitle, required this.onTap, this.trailing});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ])),
        trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 18),
      ]),
    ),
  );
}

// ── Divider helper ─────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF0F0F0));
}
