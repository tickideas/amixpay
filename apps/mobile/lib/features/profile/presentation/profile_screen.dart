import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authProvider);
    final user = authAsync.valueOrNull?.user;
    final firstName = user?.firstName ?? 'Your';
    final lastName = user?.lastName ?? 'Account';
    final fullName = '$firstName $lastName'.trim();
    final email = user?.email ?? 'your@email.com';
    final phone = user?.phone ?? 'Not added';
    final username = user?.username ?? 'username';
    final kycStatus = user?.kycStatus ?? 'none';
    final isVerified = kycStatus == 'approved';
    final initials = '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero header ─────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: const SizedBox(),
            leadingWidth: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.cardGradient),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      // Avatar
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.avatarUpload),
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 86,
                              height: 86,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.2),
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                              child: Center(
                                child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 30)),
                              ),
                            ),
                            Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.primary, width: 2)),
                              child: const Icon(Icons.camera_alt_rounded, size: 14, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(fullName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: '@$username'));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username copied!'), backgroundColor: AppColors.primary));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('@$username', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                              const SizedBox(width: 6),
                              const Icon(Icons.copy_rounded, color: Colors.white70, size: 14),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // KYC badge
                      _KycBadge(status: kycStatus, isVerified: isVerified),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── AmixPay tag / receiving details ──────────────────────
                  _Section(
                    title: 'Your AmixPay Details',
                    children: [
                      _DetailRow(
                        icon: Icons.alternate_email_rounded,
                        label: 'AmixPay Tag',
                        value: '@$username',
                        trailing: IconButton(
                          icon: const Icon(Icons.share_rounded, size: 18, color: AppColors.primary),
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sharing profile link...'))),
                        ),
                      ),
                      const _Divider(),
                      _DetailRow(
                        icon: Icons.account_balance_rounded,
                        label: 'Account Number',
                        value: '2048 5512 34',
                        subtitle: 'AmixPay Bank · Use to receive transfers',
                        trailing: IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
                          onPressed: () {
                            Clipboard.setData(const ClipboardData(text: '2048551234'));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account number copied!'), backgroundColor: AppColors.primary));
                          },
                        ),
                      ),
                      const _Divider(),
                      _DetailRow(
                        icon: Icons.route_rounded,
                        label: 'Routing Number',
                        value: '021 000 021',
                        subtitle: 'For US bank transfers',
                        trailing: IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
                          onPressed: () {
                            Clipboard.setData(const ClipboardData(text: '021000021'));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Routing number copied!'), backgroundColor: AppColors.primary));
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Verification progress ────────────────────────────────
                  if (!isVerified) ...[
                    _VerificationCard(kycStatus: kycStatus, onTap: () => context.push(AppRoutes.kyc)),
                    const SizedBox(height: 16),
                  ],

                  // ── Personal details ─────────────────────────────────────
                  _Section(
                    title: 'Personal Details',
                    action: TextButton(
                      onPressed: () => context.push(AppRoutes.editProfile),
                      child: const Text('Edit', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                    children: [
                      _DetailRow(icon: Icons.person_outline_rounded, label: 'Full Name', value: fullName),
                      const _Divider(),
                      _DetailRow(icon: Icons.email_outlined, label: 'Email', value: email,
                        badge: _UnverifiedBadge(label: 'Verify')),
                      const _Divider(),
                      _DetailRow(icon: Icons.phone_outlined, label: 'Phone', value: phone),
                      const _Divider(),
                      _DetailRow(icon: Icons.cake_outlined, label: 'Date of Birth',
                        value: (user?.dateOfBirth ?? '').isNotEmpty ? user!.dateOfBirth! : 'Not set',
                        onTap: (user?.dateOfBirth ?? '').isEmpty ? () => context.push(AppRoutes.editProfile) : null),
                      const _Divider(),
                      _DetailRow(icon: Icons.flag_outlined, label: 'Country', value: _countryName(user?.countryCode ?? ''),
                        onTap: () => context.push(AppRoutes.editProfile)),
                      const _Divider(),
                      _DetailRow(icon: Icons.location_on_outlined, label: 'Address',
                        value: (user?.address ?? '').isNotEmpty ? user!.address! : 'Not added',
                        onTap: () => context.push(AppRoutes.editProfile)),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Identity verification ────────────────────────────────
                  _Section(
                    title: 'Identity Verification',
                    children: [
                      _DetailRow(
                        icon: Icons.verified_user_outlined,
                        label: 'Verification Level',
                        value: _kycLevelLabel(kycStatus),
                        badge: isVerified ? _VerifiedBadge() : _UnverifiedBadge(label: kycStatus == 'pending' ? 'Pending' : 'Verify Now'),
                        onTap: () => context.push(AppRoutes.kyc),
                      ),
                      const _Divider(),
                      _DetailRow(
                        icon: Icons.badge_outlined,
                        label: 'Government ID',
                        value: isVerified ? 'Passport · Verified' : 'Not uploaded',
                        onTap: () => context.push(AppRoutes.kyc),
                      ),
                      const _Divider(),
                      _DetailRow(
                        icon: Icons.face_outlined,
                        label: 'Selfie Check',
                        value: isVerified ? 'Completed' : 'Not done',
                        onTap: () => context.push(AppRoutes.kyc),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Limits & features unlocked ───────────────────────────
                  _Section(
                    title: 'Account Limits',
                    children: [
                      _LimitRow(label: 'Send per transaction', value: isVerified ? '\$10,000' : '\$500', isVerified: isVerified),
                      const _Divider(),
                      _LimitRow(label: 'Monthly send limit', value: isVerified ? '\$50,000' : '\$2,000', isVerified: isVerified),
                      const _Divider(),
                      _LimitRow(label: 'International transfers', value: isVerified ? 'Enabled' : 'Disabled', isVerified: isVerified),
                      const _Divider(),
                      _LimitRow(label: 'Virtual card', value: isVerified ? 'Up to 5 cards' : '1 card', isVerified: isVerified),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Activity ─────────────────────────────────────────────
                  _Section(
                    title: 'Activity',
                    children: [
                      _DetailRow(
                        icon: Icons.history_rounded,
                        label: 'Transaction History',
                        value: 'View all transactions',
                        onTap: () => context.go(AppRoutes.transactions),
                      ),
                      const _Divider(),
                      _DetailRow(
                        icon: Icons.schedule_rounded,
                        label: 'Scheduled Transfers',
                        value: '3 active',
                        onTap: () => context.push(AppRoutes.scheduledTransfers),
                      ),
                      const _Divider(),
                      _DetailRow(
                        icon: Icons.savings_outlined,
                        label: 'Savings Goals',
                        value: '2 goals in progress',
                        onTap: () => context.push(AppRoutes.savingsGoals),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _countryName(String code) {
    const map = {
      'NG': 'Nigeria', 'US': 'United States', 'GB': 'United Kingdom',
      'GH': 'Ghana', 'KE': 'Kenya', 'ZA': 'South Africa', 'CM': 'Cameroon',
      'UG': 'Uganda', 'TZ': 'Tanzania', 'SN': 'Senegal', 'CI': 'Côte d\'Ivoire',
      'ET': 'Ethiopia', 'IN': 'India', 'CN': 'China', 'BR': 'Brazil',
      'CA': 'Canada', 'AU': 'Australia', 'DE': 'Germany', 'FR': 'France',
    };
    return map[code] ?? code.toUpperCase();
  }

  String _kycLevelLabel(String status) {
    switch (status) {
      case 'approved': return 'Fully Verified';
      case 'pending': return 'Under Review';
      case 'rejected': return 'Rejected — Retry';
      default: return 'Not Started';
    }
  }
}

// ── Widgets ─────────────────────────────────────────────────────────────────

class _KycBadge extends StatelessWidget {
  final String status;
  final bool isVerified;
  const _KycBadge({required this.status, required this.isVerified});

  @override
  Widget build(BuildContext context) {
    final color = isVerified ? const Color(0xFF10B981) : status == 'pending' ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);
    final icon = isVerified ? Icons.verified_rounded : status == 'pending' ? Icons.hourglass_top_rounded : Icons.warning_amber_rounded;
    final label = isVerified ? 'Verified' : status == 'pending' ? 'Pending Review' : 'Unverified';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget? action;
  final List<Widget> children;
  const _Section({required this.title, this.action, required this.children});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.3)),
          if (action != null) action!,
        ],
      ),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(children: children),
      ),
    ],
  );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Divider(height: 1, indent: 52, endIndent: 16, color: Color(0xFFEEEEEE));
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final String? subtitle;
  final Widget? badge;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _DetailRow({required this.icon, required this.label, required this.value, this.subtitle, this.badge, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                    if (badge != null) ...[const SizedBox(width: 8), badge!],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
          trailing ?? (onTap != null ? const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 18) : const SizedBox(width: 18)),
        ],
      ),
    ),
  );
}

class _VerifiedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_rounded, color: AppColors.success, size: 11),
        SizedBox(width: 3),
        Text('Verified', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class _UnverifiedBadge extends StatelessWidget {
  final String label;
  const _UnverifiedBadge({required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
    child: Text(label, style: const TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.w700)),
  );
}

class _LimitRow extends StatelessWidget {
  final String label, value;
  final bool isVerified;
  const _LimitRow({required this.label, required this.value, required this.isVerified});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        Icon(
          isVerified ? Icons.check_circle_outline_rounded : Icons.lock_outline_rounded,
          size: 18,
          color: isVerified ? AppColors.success : AppColors.textSecondary,
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary))),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isVerified ? AppColors.success : AppColors.textSecondary)),
      ],
    ),
  );
}

class _VerificationCard extends StatelessWidget {
  final String kycStatus;
  final VoidCallback onTap;
  const _VerificationCard({required this.kycStatus, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final steps = [
      _VStep('Email verified', true),
      _VStep('Phone added', true),
      _VStep('Upload ID', kycStatus == 'pending' || kycStatus == 'approved'),
      _VStep('Selfie check', kycStatus == 'approved'),
    ];
    final done = steps.where((s) => s.done).length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.warning.withValues(alpha: 0.08), AppColors.warning.withValues(alpha: 0.02)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_outlined, color: AppColors.warning, size: 20),
                const SizedBox(width: 8),
                const Expanded(child: Text('Complete Verification', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 15))),
                Text('$done/${steps.length}', style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Unlock higher limits and full features.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 12),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: done / steps.length,
                backgroundColor: AppColors.warning.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.warning),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: steps.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: s.done ? AppColors.success.withValues(alpha: 0.1) : AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: s.done ? AppColors.success.withValues(alpha: 0.3) : AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(s.done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      size: 12, color: s.done ? AppColors.success : AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(s.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: s.done ? AppColors.success : AppColors.textSecondary)),
                  ],
                ),
              )).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.warning, borderRadius: BorderRadius.circular(20)),
                  child: const Text('Continue Verification', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VStep {
  final String label;
  final bool done;
  const _VStep(this.label, this.done);
}
