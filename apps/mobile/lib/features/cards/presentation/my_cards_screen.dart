import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../wallet/presentation/wallet_screen.dart' show walletCurrenciesProvider, WalletCurrency;
import '../data/user_cards_provider.dart';

// ── Screen ───────────────────────────────────────────────────────────────────

class MyCardsScreen extends ConsumerStatefulWidget {
  const MyCardsScreen({super.key});
  @override
  ConsumerState<MyCardsScreen> createState() => _MyCardsScreenState();
}

class _MyCardsScreenState extends ConsumerState<MyCardsScreen> {
  final _pageController = PageController(viewportFraction: 0.92);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.value?.user;
    final fullName = user != null ? '${user.firstName} ${user.lastName}'.trim() : 'AmixPay User';

    final cards = ref.watch(userCardsProvider);
    final currencies = ref.watch(walletCurrenciesProvider);
    final primaryCurrency = currencies.isNotEmpty ? currencies.first : null;
    final balance = primaryCurrency != null
        ? '${primaryCurrency.symbol}${primaryCurrency.balance.toStringAsFixed(2)} ${primaryCurrency.code}'
        : '\$0.00 USD';

    // Keep primary card holder and currency in sync
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userCardsProvider.notifier).updatePrimaryHolder(
        fullName,
        currency: primaryCurrency?.code,
      );
    });

    final extraCount = cards.where((c) => !c.isFree).length;
    final monthlyFee = extraCount * cardExtraFee;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('My Cards',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_card_rounded, color: AppColors.primary),
            tooltip: 'Add Card',
            onPressed: () => context.push(AppRoutes.addCard),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 4),

          // ── Card Carousel (cards + Add Card slot) ─────────────────────────
          SizedBox(
            height: 210,
            child: PageView.builder(
              controller: _pageController,
              itemCount: cards.length + 1, // +1 for the Add Card slot
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, i) {
                if (i == cards.length) {
                  // ── Add Card slot ──────────────────────────────────────
                  return GestureDetector(
                    onTap: () => context.push(AppRoutes.addCard),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 2, strokeAlign: BorderSide.strokeAlignInside),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.add_card_rounded, color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(height: 14),
                        const Text('Add New Card', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.primary)),
                        const SizedBox(height: 4),
                        const Text('Virtual · Disposable · Physical', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ]),
                    ),
                  );
                }
                final card = cards[i];
                final displayName = card.holder.isNotEmpty ? card.holder : fullName;
                return _buildCardWidget(context, card, displayName, balance, i, currencies);
              },
            ),
          ),

          // ── Page indicator dots ────────────────────────────────────────────
          const SizedBox(height: 12),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(cards.length + 1, (i) {
                final active = i == _currentPage;
                final isAddSlot = i == cards.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isAddSlot
                        ? (active ? AppColors.primary : AppColors.primary.withValues(alpha: 0.3))
                        : (active ? AppColors.primary : AppColors.border),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 16),

          // ── Connected wallet balance badge ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Text('Wallet balance: $balance',
                    style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                const Spacer(),
                const Icon(Icons.link_rounded, color: AppColors.primary, size: 16),
              ]),
            ),
          ),

          // ── Monthly fee notice (when extra cards exist) ──────────────────
          if (extraCount > 0) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$extraCount extra ${extraCount == 1 ? 'card' : 'cards'} · '
                      '\$${monthlyFee.toStringAsFixed(2)}/month fee applies. '
                      'Your first card is always free.',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                    ),
                  ),
                ]),
              ),
            ),
          ],

          // ── Quick actions ──────────────────────────────────────────────────
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              _QuickAction(icon: Icons.add_circle_outline_rounded, label: 'Add Money',
                  onTap: () => context.push(AppRoutes.addFunds)),
              const SizedBox(width: 12),
              _QuickAction(icon: Icons.send_rounded, label: 'Pay',
                  onTap: () => context.push(AppRoutes.sendMoney)),
              const SizedBox(width: 12),
              _QuickAction(icon: Icons.history_rounded, label: 'History',
                  onTap: () => context.push(AppRoutes.transactionHistory)),
              const SizedBox(width: 12),
              _QuickAction(
                icon: _currentPage < cards.length && !cards[_currentPage].isFree
                    ? Icons.delete_outline_rounded
                    : Icons.ac_unit_rounded,
                label: _currentPage < cards.length && !cards[_currentPage].isFree
                    ? 'Remove'
                    : 'Freeze',
                onTap: () {
                  if (_currentPage >= cards.length) return; // Add Card slot
                  if (!cards[_currentPage].isFree) {
                    _confirmRemoveCard(context, ref, cards[_currentPage]);
                  } else {
                    ref.read(userCardsProvider.notifier).toggleFreeze(cards[_currentPage].id);
                  }
                },
              ),
            ]),
          ),

          // ── Add card CTA ───────────────────────────────────────────────────
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.addCard),
              icon: const Icon(Icons.add_card_rounded),
              label: const Text('Get Another Card  ·  \$3.99/month'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Cards list (compact) ───────────────────────────────────────────
          if (cards.length > 1) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('All Cards (${cards.length})',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ),
            const SizedBox(height: 10),
            ...cards.map((card) => _CardListTile(
                  card: card,
                  holderName: card.holder.isNotEmpty ? card.holder : fullName,
                  onRemove: card.isFree
                      ? null
                      : () => _confirmRemoveCard(context, ref, card),
                )),
          ],

          // ── Security note ──────────────────────────────────────────────────
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
              ),
              child: const Row(children: [
                Icon(Icons.security_rounded, color: AppColors.success, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'All cards secured with 256-bit encryption. Details never shared.',
                    style: TextStyle(fontSize: 12, color: AppColors.success),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _buildCardWidget(BuildContext context, IssuedCard card,
      String displayName, String balance, int index, List<WalletCurrency> currencies) {
    return GestureDetector(
      onTap: () => context.push('/cards/${card.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          gradient: card.gradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('AmixPay',
                style: TextStyle(color: Colors.white, fontSize: 17,
                    fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            const Spacer(),
            Row(children: [
              _CardBadge(
                label: card.type == 'disposable' ? 'DISPOSABLE' : card.type == 'virtual' ? 'VIRTUAL' : 'PHYSICAL',
                color: card.type == 'disposable'
                    ? Colors.orange.withValues(alpha: 0.55)
                    : Colors.white.withValues(alpha: 0.25),
              ),
              if (!card.isFree && card.type != 'disposable') ...[
                const SizedBox(width: 6),
                _CardBadge(label: '\$3.99/mo', color: Colors.amber.withValues(alpha: 0.35)),
              ],
              if (card.isDisposable && card.isExpired) ...[
                const SizedBox(width: 6),
                _CardBadge(label: 'USED', color: Colors.red.withValues(alpha: 0.55)),
              ],
            ]),
          ]),
          const Spacer(),
          if (card.isFree)
            Text(balance,
                style: const TextStyle(color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.w800))
          else if (card.isDisposable)
            Text(
              card.isExpired ? 'USED · Auto-frozen' : 'Single-use · Tap to pay once',
              style: TextStyle(
                color: card.isExpired ? Colors.white38 : Colors.white70,
                fontSize: 13, fontWeight: FontWeight.w600,
              ),
            )
          else
            Builder(builder: (_) {
              final wallet = currencies.where((w) => w.code == card.currency).firstOrNull;
              final cardBalStr = wallet != null
                  ? '${wallet.symbol}${wallet.balance.toStringAsFixed(2)} ${card.currency}'
                  : '${card.currency} Card';
              return Text(cardBalStr,
                  style: const TextStyle(color: Colors.white, fontSize: 14,
                      fontWeight: FontWeight.w700));
            }),
          const SizedBox(height: 10),
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('CARD NUMBER', style: TextStyle(color: Colors.white54, fontSize: 9)),
              const SizedBox(height: 2),
              Text('•••• •••• •••• ${card.last4}',
                  style: const TextStyle(color: Colors.white, fontSize: 13, letterSpacing: 1.5)),
            ]),
            const Spacer(),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('HOLDER', style: TextStyle(color: Colors.white54, fontSize: 9)),
              const SizedBox(height: 2),
              Text(
                displayName.length > 16 ? displayName.substring(0, 16) : displayName,
                style: const TextStyle(color: Colors.white, fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ]),
          ]),
        ]),
      ),
    );
  }

  void _confirmRemoveCard(BuildContext context, WidgetRef ref, IssuedCard card) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Card?'),
        content: Text(
            'Remove the ${card.type} card ending in ${card.last4}?\n\n'
            'The \$${cardExtraFee.toStringAsFixed(2)}/month fee will stop immediately.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(userCardsProvider.notifier).removeCard(card.id);
              if (_currentPage >= ref.read(userCardsProvider).length) {
                _pageController.previousPage(
                    duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

// ── Card badge ─────────────────────────────────────────────────────────────────

class _CardBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _CardBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
        child: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 9,
                fontWeight: FontWeight.w700, letterSpacing: 0.8)),
      );
}

// ── Compact card list tile ─────────────────────────────────────────────────────

class _CardListTile extends StatelessWidget {
  final IssuedCard card;
  final String holderName;
  final VoidCallback? onRemove;
  const _CardListTile({required this.card, required this.holderName, this.onRemove});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 30,
            decoration: BoxDecoration(
              gradient: card.gradient,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: const Text('VISA',
                style: TextStyle(color: Colors.white, fontSize: 9,
                    fontWeight: FontWeight.w800, letterSpacing: 1)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${card.type == 'disposable' ? 'Disposable' : card.type == 'virtual' ? 'Virtual' : 'Physical'} •••• ${card.last4}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
                      color: AppColors.textPrimary)),
              Text(holderName, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ]),
          ),
          if (!card.isFree && card.type == 'disposable')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                card.isExpired ? 'USED' : '1 USE',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.orange),
              ),
            )
          else if (!card.isFree)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('\$3.99/mo',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                      color: Color(0xFFD97706))),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('FREE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                      color: AppColors.success)),
            ),
          if (onRemove != null) ...[
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 16, color: Colors.red),
              onPressed: onRemove,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          ],
        ]),
      );
}

// ── Quick Action Button ───────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
            ]),
          ),
        ),
      );
}
