import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final authAsync = ref.watch(authProvider);
    final user = authAsync.valueOrNull?.user;
    final firstName = user?.firstName ?? 'Your';
    final lastName = user?.lastName ?? 'Account';
    final fullName = '$firstName $lastName'.trim();
    final email = user?.email ?? '';
    final initials = '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
    final kycStatus = user?.kycStatus ?? 'none';
    final isVerified = kycStatus == 'approved';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Settings', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.notificationSettings),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
                        child: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Profile card ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: GestureDetector(
                  onTap: () => context.push(AppRoutes.profile),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppColors.cardGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 58, height: 58,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2)),
                          child: Center(child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22))),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                              if (email.isNotEmpty) Text(email, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isVerified ? Colors.green.withValues(alpha: 0.25) : Colors.orange.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(isVerified ? Icons.verified_rounded : Icons.pending_rounded, size: 12, color: isVerified ? Colors.greenAccent : Colors.orangeAccent),
                                    const SizedBox(width: 4),
                                    Text(isVerified ? 'Fully Verified' : 'Complete Verification →', style: TextStyle(color: isVerified ? Colors.greenAccent : Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Quick action buttons ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    _QuickBtn(icon: Icons.add_card_rounded, label: 'Add Money', color: AppColors.success, onTap: () => context.push(AppRoutes.addFunds)),
                    const SizedBox(width: 10),
                    _QuickBtn(icon: Icons.account_balance_rounded, label: 'Withdraw', color: AppColors.info, onTap: () => context.push(AppRoutes.withdraw)),
                    const SizedBox(width: 10),
                    _QuickBtn(icon: Icons.qr_code_scanner_rounded, label: 'My QR', color: AppColors.primary, onTap: () => context.push(AppRoutes.myQr)),
                    const SizedBox(width: 10),
                    _QuickBtn(icon: Icons.share_rounded, label: 'Refer', color: const Color(0xFFDB2777), onTap: () => context.push(AppRoutes.referral)),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  children: [
                    _SettingsGroup(title: 'Account', items: [
                      _Item(Icons.person_outline_rounded, 'Personal Details', 'Name, email, phone, address', () => context.push(AppRoutes.profile)),
                      _Item(Icons.verified_user_outlined, 'Identity Verification', _kycLabel(kycStatus), () => context.push(AppRoutes.kyc), badge: _kycDot(kycStatus)),
                      _Item(Icons.language_rounded, 'Language & Region', '${settings.languageLabel} · ${settings.displayCurrency} · ${settings.countryCode}', () {}),
                    ]),
                    const SizedBox(height: 16),

                    _SettingsGroup(title: 'Security', items: [
                      _Item(Icons.lock_outline_rounded, 'Password', 'Change your login password', () => context.push(AppRoutes.changePassword)),
                      _Item(Icons.fingerprint_rounded, 'Biometrics & PIN', 'Face ID, fingerprint, quick PIN', () => context.push(AppRoutes.security)),
                      _Item(Icons.security_rounded, 'Two-Factor Auth', 'Add 2FA for extra security', () => context.push(AppRoutes.twoFactorSetup)),
                      _Item(Icons.devices_rounded, 'Active Sessions', 'Manage logged-in devices', () => context.push(AppRoutes.security)),
                    ]),
                    const SizedBox(height: 16),

                    _SettingsGroup(title: 'Cards & Payments', items: [
                      _Item(Icons.credit_card_rounded, 'My Cards', 'Virtual & physical cards', () => context.go(AppRoutes.myCards)),
                      _Item(Icons.add_card_rounded, 'Get a Card', 'Issue virtual or request ATM card', () => context.push(AppRoutes.addCard)),
                      _Item(Icons.account_balance_outlined, 'Linked Bank Accounts', 'Add banks for withdrawals', () => context.push(AppRoutes.withdraw)),
                      _Item(Icons.people_outline_rounded, 'Saved Recipients', 'Frequent contacts', () => context.push(AppRoutes.sendMoney)),
                    ]),
                    const SizedBox(height: 16),

                    _SettingsGroup(title: 'Money & Transfers', items: [
                      _Item(Icons.savings_outlined, 'Savings Goals', 'Track savings progress', () => context.push(AppRoutes.savingsGoals)),
                      _Item(Icons.schedule_outlined, 'Scheduled Transfers', 'Recurring payments', () => context.push(AppRoutes.scheduledTransfers)),
                      _Item(Icons.public_rounded, 'International Transfers', 'Send money globally', () => context.push(AppRoutes.internationalTransfer)),
                      _Item(Icons.currency_exchange_rounded, 'Currency Converter', 'Live exchange rates', () => context.push(AppRoutes.currencyConverter)),
                      _Item(Icons.bar_chart_rounded, 'Spending Analytics', 'Analyze your spending', () => context.push(AppRoutes.analytics)),
                    ]),
                    const SizedBox(height: 16),

                    _SettingsGroup(title: 'Notifications', items: [
                      _Item(Icons.notifications_outlined, 'Push Notifications', 'Transactions, promotions', () => context.push(AppRoutes.notificationSettings),
                          trailing: _Toggle(value: settings.pushNotifications, onChanged: (v) => ref.read(settingsProvider.notifier).setPushNotifications(v))),
                      _Item(Icons.sms_outlined, 'SMS Alerts', 'Text message alerts', () {},
                          trailing: _Toggle(value: settings.smsAlerts, onChanged: (v) => ref.read(settingsProvider.notifier).setSmsAlerts(v))),
                      _Item(Icons.email_outlined, 'Email Notifications', 'Monthly statements', () {},
                          trailing: _Toggle(value: settings.emailNotifications, onChanged: (v) => ref.read(settingsProvider.notifier).setEmailNotifications(v))),
                    ]),
                    const SizedBox(height: 16),

                    _SettingsGroup(title: 'Business', items: [
                      _Item(Icons.card_giftcard_rounded, 'Refer & Earn', 'Earn rewards per referral', () => context.push(AppRoutes.referral)),
                    ]),
                    const SizedBox(height: 16),

                    _SettingsGroup(title: 'Help & Legal', items: [
                      _Item(Icons.help_outline_rounded, 'Help Center', '24/7 support, FAQs', () async {
                        final uri = Uri.parse('https://amixpay.app/help');
                        if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                      }),
                      _Item(Icons.chat_outlined, 'Live Chat', 'Chat with support', () async {
                        final uri = Uri.parse('https://wa.me/12345678901?text=Hi%20AmixPay%20Support');
                        if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                      }),
                      _Item(Icons.privacy_tip_outlined, 'Privacy Policy', 'How we handle your data', () => context.push(AppRoutes.privacyPolicy)),
                      _Item(Icons.description_outlined, 'Terms of Service', 'Read our terms', () => context.push(AppRoutes.termsOfService)),
                      _Item(Icons.info_outline_rounded, 'About AmixPay', 'Version 1.2.0 · © 2026 AmixPay Ltd', () {}),
                    ]),
                    const SizedBox(height: 16),

                    // Logout
                    GestureDetector(
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w700)),
                            content: const Text('You\'ll need to log back in to access your account.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Log Out', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          await ref.read(authProvider.notifier).logout();
                          if (context.mounted) context.go(AppRoutes.login);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(11)),
                              child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 19),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Log Out', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.error)),
                                  Text('Sign out of your account', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.error, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Center(
                      child: Text('AmixPay v1.2.0 · © 2026 AmixPay Ltd', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _kycLabel(String status) {
    switch (status) {
      case 'approved': return 'Fully verified';
      case 'pending': return 'Under review';
      case 'rejected': return 'Action required';
      default: return 'Not verified · Tap to start';
    }
  }

  Widget? _kycDot(String status) {
    if (status == 'approved') return _Dot(color: AppColors.success);
    if (status == 'pending') return _Dot(color: AppColors.warning);
    if (status == 'none') return _Dot(color: AppColors.error);
    return null;
  }
}

// ── Reusable widgets ─────────────────────────────────────────────────────────

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 5),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color), textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<_Item> items;
  const _SettingsGroup({required this.title, required this.items});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
      ),
      Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: items.asMap().entries.map((e) {
            final isLast = e.key == items.length - 1;
            return Column(
              children: [
                _SettingTile(item: e.value),
                if (!isLast) const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF0F0F0)),
              ],
            );
          }).toList(),
        ),
      ),
    ],
  );
}

class _Item {
  final IconData icon;
  final String label, subtitle;
  final VoidCallback onTap;
  final Widget? badge;
  final Widget? trailing;
  const _Item(this.icon, this.label, this.subtitle, this.onTap, {this.badge, this.trailing});
}

class _SettingTile extends StatelessWidget {
  final _Item item;
  const _SettingTile({required this.item});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: item.onTap,
    borderRadius: BorderRadius.circular(18),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(11)),
            child: Icon(item.icon, color: AppColors.primary, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(item.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                    if (item.badge != null) ...[const SizedBox(width: 6), item.badge!],
                  ],
                ),
                Text(item.subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          item.trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 18),
        ],
      ),
    ),
  );
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: 8, height: 8,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _Toggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Toggle({required this.value, required this.onChanged});
  @override
  State<_Toggle> createState() => _ToggleState();
}

class _ToggleState extends State<_Toggle> {
  late bool _v;
  @override
  void initState() { super.initState(); _v = widget.value; }
  @override
  Widget build(BuildContext context) => Transform.scale(
    scale: 0.8,
    child: Switch(value: _v, onChanged: (v) { setState(() => _v = v); widget.onChanged(v); }, activeColor: AppColors.primary),
  );
}
