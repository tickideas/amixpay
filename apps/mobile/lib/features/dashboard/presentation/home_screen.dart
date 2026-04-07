import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/exchange_rate_service.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/providers/wallet_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/transaction_provider.dart';
import '../../../core/services/recipients_service.dart';
import '../../wallet/presentation/wallet_screen.dart' show walletCurrenciesProvider, WalletCurrency;

class _QuickAction {
  final IconData icon;
  final String label;
  final String route;
  final Color color;
  const _QuickAction(this.icon, this.label, this.route, this.color);
}

class _TrustItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _TrustItem(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(height: 3),
      Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600, height: 1.2), textAlign: TextAlign.center),
    ],
  );
}

// ─────────────────────────────────────────────
// Home Screen
// ─────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

// Map of ISO currency codes to symbols
const _currencySymbols = {
  'USD': '\$', 'GBP': '£', 'EUR': '€', 'NGN': '₦', 'GHS': '₵',
  'KES': 'KSh', 'ZAR': 'R', 'CAD': 'C\$', 'AUD': 'A\$', 'INR': '₹',
  'JPY': '¥', 'CNY': '¥', 'AED': 'AED', 'SAR': 'SAR', 'MXN': 'MX\$',
  'BRL': 'R\$', 'SGD': 'S\$', 'CHF': 'Fr', 'SEK': 'kr', 'NOK': 'kr',
  'DKK': 'kr', 'UGX': 'USh', 'TZS': 'TSh', 'ETB': 'Br', 'RWF': 'RF',
  'EGP': 'E£', 'MAD': 'MAD', 'PKR': '₨', 'BDT': '৳', 'PHP': '₱',
  'IDR': 'Rp', 'MYR': 'RM', 'THB': '฿', 'VND': '₫', 'KRW': '₩',
  'TRY': '₺', 'ILS': '₪', 'QAR': 'QR', 'KWD': 'KD', 'NZD': 'NZ\$',
};

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _balanceVisible = true;
  String _regionCurrencyCode = 'USD';
  String _regionSymbol = '\$';
  final PageController _cardPageCtrl = PageController();
  int _cardPage = 0;

  @override
  void initState() {
    super.initState();
    // Instant locale-based detection (no network needed)
    _tryLocaleDetection();
    // Then override with more accurate IP-based detection
    _detectRegionCurrency();
  }

  @override
  void dispose() {
    _cardPageCtrl.dispose();
    super.dispose();
  }

  /// Instantly detect region currency from device locale (e.g. en_NG → NGN).
  void _tryLocaleDetection() {
    try {
      if (kIsWeb) return;
      final locale = Platform.localeName; // e.g. 'en_NG', 'en_GB', 'fr_FR'
      final parts = locale.split('_');
      if (parts.length >= 2) {
        final cc = parts.last.toUpperCase();
        final currency = _countryToCurrency(cc);
        setState(() {
          _regionCurrencyCode = currency;
          _regionSymbol = _currencySymbols[currency] ?? currency;
        });
      }
    } catch (_) {}
  }

  Future<void> _detectRegionCurrency() async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      final response = await dio.get('https://ip-api.com/json');
      final data = response.data as Map<String, dynamic>?;
      if (data != null && data['status'] == 'success') {
        final cc = data['countryCode'] as String? ?? '';
        final currency = _countryToCurrency(cc);
        if (mounted) {
          setState(() {
            _regionCurrencyCode = currency;
            _regionSymbol = _currencySymbols[currency] ?? currency;
          });
        }
      }
    } catch (_) {}
  }

  String _countryToCurrency(String countryCode) {
    const map = {
      'US': 'USD', 'GB': 'GBP', 'DE': 'EUR', 'FR': 'EUR', 'IT': 'EUR',
      'ES': 'EUR', 'NL': 'EUR', 'NG': 'NGN', 'GH': 'GHS', 'KE': 'KES',
      'ZA': 'ZAR', 'CA': 'CAD', 'AU': 'AUD', 'IN': 'INR', 'JP': 'JPY',
      'CN': 'CNY', 'AE': 'AED', 'SA': 'SAR', 'MX': 'MXN', 'BR': 'BRL',
      'SG': 'SGD', 'CH': 'CHF', 'SE': 'SEK', 'NO': 'NOK', 'DK': 'DKK',
      'UG': 'UGX', 'TZ': 'TZS', 'ET': 'ETB', 'RW': 'RWF', 'EG': 'EGP',
      'MA': 'MAD', 'PK': 'PKR', 'BD': 'BDT', 'PH': 'PHP', 'ID': 'IDR',
    };
    return map[countryCode] ?? 'USD';
  }

  String _formatBalance(double amount, [String? overrideSym]) {
    final sym = overrideSym ?? _regionSymbol;
    if (amount >= 1000000) return '$sym${(amount / 1000000).toStringAsFixed(2)}M';
    if (amount >= 1000) {
      final parts = amount.toStringAsFixed(2).split('.');
      final whole = parts[0].replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
      return '$sym$whole.${parts[1]}';
    }
    return '$sym${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);
    final authAsync = ref.watch(authProvider);
    final userName = authAsync.valueOrNull?.user?.firstName ?? 'there';
    final walletCurrencies = ref.watch(walletCurrenciesProvider);
    final recentTxs = ref.watch(transactionProvider).take(5).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 20),
                          _buildSwipeableBalanceCard(walletCurrencies),
                          const SizedBox(height: 20),
                          _buildRateWidget(),
                          const SizedBox(height: 20),
                          _buildQuickActions(),
                          const SizedBox(height: 16),
                          _buildTrustBanner(),
                          const SizedBox(height: 20),
                          _buildQuickSendSection(),
                          const SizedBox(height: 24),
                          _buildTransactionHeader(),
                        ],
                      ),
                    ),
                  ),
                  if (recentTxs.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        child: Column(
                          children: [
                            Container(
                              width: 64, height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.receipt_long_rounded,
                                  color: AppColors.primary, size: 30),
                            ),
                            const SizedBox(height: 12),
                            const Text('No transactions yet',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 4),
                            const Text('Add funds or send money to get started',
                                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildTransactionItem(recentTxs[index]),
                        ),
                        childCount: recentTxs.length,
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  // ── Header ──────────────────────────────────
  Widget _buildHeader() {
    final authAsync = ref.watch(authProvider);
    final user = authAsync.valueOrNull?.user;
    final firstName = user?.firstName ?? 'there';
    final lastName = user?.lastName ?? '';
    final initials = '${firstName.isNotEmpty ? firstName[0] : '?'}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();

    return Row(
      children: [
        // Avatar — tappable → profile settings
        GestureDetector(
          onTap: () => context.push(AppRoutes.editProfile),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.cardGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '$firstName 👋',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        // Notification bell
        Stack(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
                onPressed: () => context.go(AppRoutes.notifications),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Balance Card ─────────────────────────────
  Widget _buildBalanceCard() {
    final walletAsync = ref.watch(walletProvider);
    final primaryBalance = walletAsync.valueOrNull?.balanceFor(_regionCurrencyCode) ?? 0.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.30),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Balance',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(
                      () => _balanceVisible = !_balanceVisible,
                    ),
                    child: Icon(
                      _balanceVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Visa logo placeholder
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'VISA',
                      style: TextStyle(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Balance amount
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _balanceVisible ? _formatBalance(primaryBalance) : '••••••••',
              key: ValueKey(_balanceVisible),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: AppColors.onPrimary,
                letterSpacing: -0.5,
                fontFamily: 'Inter',
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Wallet info row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AmixPay Wallet',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  letterSpacing: 0.5,
                  fontFamily: 'Inter',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Portfolio color palette — mirrors wallet_screen.dart ─────────────────
  static const _portfolioColors = [
    Color(0xFF0D6B5E), // 0 teal      — default / region primary
    Color(0xFF0284C7), // 1 blue
    Color(0xFF7C3AED), // 2 purple
    Color(0xFFDB2777), // 3 pink
    Color(0xFFEA580C), // 4 orange
    Color(0xFF059669), // 5 green
    Color(0xFFD97706), // 6 amber
    Color(0xFF0891B2), // 7 cyan
  ];

  // Slightly lighter accent for gradient end, keeps the card vibrant.
  static const _portfolioColorLight = [
    Color(0xFF14A58B), // teal light
    Color(0xFF38BDF8), // blue light
    Color(0xFFA855F7), // purple light
    Color(0xFFF472B6), // pink light
    Color(0xFFFB923C), // orange light
    Color(0xFF34D399), // green light
    Color(0xFFFBBF24), // amber light
    Color(0xFF22D3EE), // cyan light
  ];

  LinearGradient _cardGradient(int colorIndex) {
    final idx = colorIndex % _portfolioColors.length;
    return LinearGradient(
      colors: [_portfolioColors[idx], _portfolioColorLight[idx]],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // ── Swipeable balance card (one page per wallet currency) ────────────────
  Widget _buildSwipeableBalanceCard(List<WalletCurrency> currencies) {
    if (currencies.isEmpty) {
      return _buildSingleCard(
        WalletCurrency(flag: '🇺🇸', code: 'USD', name: 'US Dollar',
            balance: 0.0, available: 0.0, symbol: '\$', colorIndex: 0),
        isDefault: true,
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _cardPageCtrl,
            onPageChanged: (p) => setState(() => _cardPage = p),
            itemCount: currencies.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _buildSingleCard(currencies[i], isDefault: i == 0),
            ),
          ),
        ),
        if (currencies.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(currencies.length, (i) {
              final cardColor = _portfolioColors[
                  (currencies[i].colorIndex ?? i) % _portfolioColors.length];
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _cardPage == i ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  // Active dot matches that card's color; inactive is grey
                  color: _cardPage == i ? cardColor : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildSingleCard(WalletCurrency w, {required bool isDefault}) {
    // Default (first / region-detected) wallet keeps colorIndex 0 = teal.
    // All others use their persisted colorIndex for full differentiation.
    final colorIdx = (w.colorIndex ?? 0) % _portfolioColors.length;
    final baseColor = _portfolioColors[colorIdx];
    final gradient = _cardGradient(colorIdx);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: baseColor.withOpacity(0.35), blurRadius: 22, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Text(w.flag, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text('${w.code} Balance',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
              ]),
              Row(children: [
                GestureDetector(
                  onTap: () => setState(() => _balanceVisible = !_balanceVisible),
                  child: Icon(_balanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: Colors.white70, size: 20),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(w.code,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1)),
                ),
              ]),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _balanceVisible ? _formatBalance(w.balance, w.symbol) : '••••••••',
              key: ValueKey(_balanceVisible),
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800,
                  color: Colors.white, letterSpacing: -0.5, fontFamily: 'Inter'),
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isDefault ? '${w.name} · Default' : w.name,
                style: const TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 0.3),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6)),
                child: const Text('ACTIVE',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Quick Actions ─────────────────────────────
  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(Icons.flight_takeoff_rounded, 'Transfer', AppRoutes.internationalTransfer, const Color(0xFF0284C7)),
      _QuickAction(Icons.add_circle_outline_rounded, 'Add Money', AppRoutes.addFunds, const Color(0xFF059669)),
      _QuickAction(Icons.send_rounded, 'AmixPay', AppRoutes.zelleTransfer, AppColors.primary),
      _QuickAction(Icons.request_page_rounded, 'Request', AppRoutes.requestMoney, const Color(0xFF7C3AED)),
      _QuickAction(Icons.account_balance_wallet_rounded, 'Withdraw', AppRoutes.withdraw, const Color(0xFF0891B2)),
      _QuickAction(Icons.currency_exchange_rounded, 'Convert', AppRoutes.currencyConverter, const Color(0xFFEA580C)),
      _QuickAction(Icons.schedule_rounded, 'Schedule', AppRoutes.scheduledTransfers, const Color(0xFF0D6B5E)),
      _QuickAction(Icons.qr_code_scanner_rounded, 'Scan QR', AppRoutes.qrScanner, const Color(0xFFDB2777)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            GestureDetector(
              onTap: () => context.go(AppRoutes.wallet),
              child: const Text('See all', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.85,
          ),
          itemCount: actions.length,
          itemBuilder: (_, i) {
            final a = actions[i];
            return GestureDetector(
              onTap: () => context.push(a.route),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: a.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(a.icon, color: a.color, size: 24),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    a.label,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Quick Send Section ───────────────────────
  Widget _buildQuickSendSection() {
    final recipients = ref.watch(savedRecipientsProvider);
    final recent = recipients.isEmpty
        ? <SavedRecipient>[]
        : (RecipientsNotifier()..state = recipients).recentSix;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quick Send',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            if (recipients.isNotEmpty)
              GestureDetector(
                onTap: () => context.push(AppRoutes.sendMoney),
                child: const Text('Send New',
                    style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // New send button always first
              _QuickSendAvatar(
                label: 'New',
                child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 26),
                isNew: true,
                onTap: () => context.push(AppRoutes.sendMoney),
              ),
              const SizedBox(width: 16),
              if (recent.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'Recipients you send to\nwill appear here',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                )
              else
                ...recent.map((r) => Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: _QuickSendAvatar(
                        label: r.name.split(' ').first,
                        flag: r.flag,
                        initials: r.initials,
                        onTap: () => context.push(AppRoutes.sendMoney),
                      ),
                    )),
            ],
          ),
        ),
      ],
    );
  }

  // ── Transaction Header ───────────────────────
  Widget _buildTransactionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Transaction History',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        GestureDetector(
          onTap: () => context.go(AppRoutes.transactions),
          child: const Text(
            'View all',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ── Live Rate Widget (Wise-style) ─────────────
  static const _ratePairs = [
    ('🇺🇸', 'USD', '🇬🇧', 'GBP'),
    ('🇺🇸', 'USD', '🇳🇬', 'NGN'),
    ('🇺🇸', 'USD', '🇪🇺', 'EUR'),
    ('🇺🇸', 'USD', '🇮🇳', 'INR'),
    ('🇺🇸', 'USD', '🇰🇪', 'KES'),
    ('🇺🇸', 'USD', '🇨🇦', 'CAD'),
  ];

  static double _computeRate(Map<String, double> rateMap, String from, String to) {
    final fromRate = rateMap[from] ?? 1.0;
    final toRate = rateMap[to] ?? 1.0;
    return toRate / fromRate;
  }

  Widget _buildRateWidget() {
    final ratesAsync = ref.watch(exchangeRatesProvider);
    final rates = ratesAsync.valueOrNull;
    final rateMap = rates?.rates ?? fallbackRates;
    final isLive = rates?.isLive ?? false;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.currency_exchange_rounded, color: AppColors.primary, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text('Live Rates', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 7, height: 7,
                    decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  Text(isLive ? 'Mid-market · live' : 'Mid-market · cached', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _ratePairs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final p = _ratePairs[i];
                final rate = _computeRate(rateMap, p.$2, p.$4);
                final r = (p.$1, p.$2, p.$3, p.$4, rate);
                final rateStr = rate >= 100
                    ? rate.toStringAsFixed(0)
                    : rate >= 1
                        ? rate.toStringAsFixed(4)
                        : rate.toStringAsFixed(4);
                return GestureDetector(
                  onTap: () => context.push(AppRoutes.internationalTransfer),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${r.$1}${r.$3}  ${r.$2}→${r.$4}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '1 ${r.$2} = $rateStr ${r.$4}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => context.push(AppRoutes.currencyConverter),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Calculate exactly how much they receive', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Trust Banner ─────────────────────────────
  Widget _buildTrustBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.08), Colors.blue.withOpacity(0.05)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _TrustItem(Icons.verified_user_rounded, 'Licensed\n& Regulated', Colors.green),
          _divider(),
          _TrustItem(Icons.lock_rounded, 'AES-256\nEncrypted', Colors.blue),
          _divider(),
          _TrustItem(Icons.speed_rounded, 'Instant\nTransfers', AppColors.primary),
          _divider(),
          _TrustItem(Icons.currency_exchange_rounded, '0% Markup\nRate', Colors.orange),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 28, color: AppColors.primary.withOpacity(0.15));

  // ── Transaction Item ─────────────────────────
  Widget _buildTransactionItem(AppTransaction tx) {
    final isPositive = tx.type == AppTxType.received || tx.type == AppTxType.funded;
    final Color iconBg = isPositive
        ? const Color(0xFFD1FAE5)
        : tx.type == AppTxType.transfer
            ? const Color(0xFFEFF6FF)
            : const Color(0xFFFFEEEE);
    final Color iconColor = isPositive
        ? AppColors.success
        : tx.type == AppTxType.transfer
            ? const Color(0xFF3B82F6)
            : AppColors.error;
    final IconData icon = tx.type == AppTxType.received
        ? Icons.arrow_downward_rounded
        : tx.type == AppTxType.funded
            ? Icons.account_balance_wallet_rounded
            : tx.type == AppTxType.transfer
                ? Icons.swap_horiz_rounded
                : Icons.arrow_upward_rounded;

    final hour = tx.date.hour.toString().padLeft(2, '0');
    final minute = tx.date.minute.toString().padLeft(2, '0');
    final dateLabel = '${tx.date.day}/${tx.date.month}/${tx.date.year}  $hour:$minute';

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                Text(dateLabel, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? '+' : '-'}${tx.symbol}${tx.amount.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                    color: isPositive ? AppColors.success : AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tx.status == AppTxStatus.paid
                      ? AppColors.success.withOpacity(0.12)
                      : tx.status == AppTxStatus.pending
                          ? Colors.orange.withOpacity(0.12)
                          : AppColors.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tx.status.name[0].toUpperCase() + tx.status.name.substring(1),
                  style: TextStyle(
                    color: tx.status == AppTxStatus.paid
                        ? AppColors.success
                        : tx.status == AppTxStatus.pending
                            ? Colors.orange
                            : AppColors.error,
                    fontSize: 11, fontWeight: FontWeight.w600,
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

// ── Quick Send Avatar Widget ───────────────────
class _QuickSendAvatar extends StatelessWidget {
  final String label;
  final String? flag;
  final String? initials;
  final Widget? child;
  final bool isNew;
  final VoidCallback onTap;

  const _QuickSendAvatar({
    required this.label,
    this.flag,
    this.initials,
    this.child,
    this.isNew = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isNew ? AppColors.surface : AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: isNew ? AppColors.primary : AppColors.primary.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
            ),
            child: Center(
              child: child ??
                  (flag != null
                      ? Text(flag!, style: const TextStyle(fontSize: 24))
                      : Text(
                          initials ?? '?',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        )),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
