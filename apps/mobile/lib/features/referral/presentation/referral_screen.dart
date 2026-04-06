import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/locale_utils.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../wallet/presentation/wallet_screen.dart' show walletCurrenciesProvider;

class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authProvider);
    final user = authAsync.valueOrNull?.user;
    // Generate a deterministic referral code from user ID or name
    final rawId = user?.id ?? 'AMIX';
    final code = 'AMIX-${rawId.substring(rawId.length > 6 ? rawId.length - 6 : 0).toUpperCase()}';
    final referralLink = 'https://amixpay.app/join/$code';
    // Use primary wallet currency symbol for reward amounts
    final currencies = ref.watch(walletCurrenciesProvider);
    final sym = currencies.isNotEmpty ? currencies.first.symbol : currencyToSymbol('USD');

    const friends = <_FriendRef>[];
    const totalEarned = 0.0;
    const completed = 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: BackButton(color: AppColors.textPrimary),
        title: const Text('Refer & Earn', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Hero card ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(
                children: [
                  const Text('🎁', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text(
                    'Earn ${sym}15 for every friend',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Share your code. When they make their first transfer, you both get ${sym}5 instantly. When they send ${sym}100+, you earn another ${sym}10!',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Your code', style: TextStyle(color: Colors.white60, fontSize: 12)),
                        Text(code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 2)),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: code));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Code copied!'), backgroundColor: AppColors.primary),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.copy_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: referralLink));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Link copied!'), backgroundColor: AppColors.primary),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white54),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.link_rounded, size: 16),
                          label: const Text('Copy Link'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary),
                          icon: const Icon(Icons.share_rounded, size: 16),
                          label: const Text('Share', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Stats row ──────────────────────────────────────────────
            Row(
              children: [
                Expanded(child: _StatBox(label: 'Total Earned', value: '$sym${totalEarned.toStringAsFixed(0)}', emoji: '💰')),
                const SizedBox(width: 12),
                Expanded(child: _StatBox(label: 'Friends Invited', value: '${friends.length}', emoji: '👥')),
                const SizedBox(width: 12),
                Expanded(child: _StatBox(label: 'Completed', value: '$completed', emoji: '✅')),
              ],
            ),

            const SizedBox(height: 24),

            // ── How it works ───────────────────────────────────────────
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('How It Works', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ),
            const SizedBox(height: 12),
            ...[
              ['1', 'Share your code', 'Send your unique referral code to friends via WhatsApp, SMS, or social media.', '📲'],
              ['2', 'Friend signs up', 'They register on AmixPay using your code. You both get ${sym}5 immediately!', '🎉'],
              ['3', 'Earn ${sym}10 more', 'When they send their first ${sym}100+ transfer, you earn another ${sym}10 bonus.', '💸'],
            ].map((step) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                    child: Center(child: Text(step[0], style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step[1], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                        Text(step[2], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Text(step[3], style: const TextStyle(fontSize: 24)),
                ],
              ),
            )).toList(),

            const SizedBox(height: 24),

            // ── Referral history ───────────────────────────────────────
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Referral History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ),
            const SizedBox(height: 12),
            if (friends.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.people_outline_rounded, size: 40, color: AppColors.textSecondary),
                    SizedBox(height: 8),
                    Text('No referrals yet', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    SizedBox(height: 4),
                    Text('Share your code to start earning rewards', style: TextStyle(fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center),
                  ],
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _FriendRef {
  final String name, status, date;
  final double earned;
  const _FriendRef({required this.name, required this.status, required this.date, required this.earned});
}

class _StatBox extends StatelessWidget {
  final String label, value, emoji;
  const _StatBox({required this.label, required this.value, required this.emoji});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), textAlign: TextAlign.center),
      ],
    ),
  );
}
