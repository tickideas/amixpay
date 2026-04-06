import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/locale_utils.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../crypto/presentation/usdt_wallet_screen.dart' show usdtBalanceProvider;

const _teal = Color(0xFF0D6B5E);
const _bg = Color(0xFFF5F7FA);

// ── Rates (USD base) ──────────────────────────────────────────────────────────
const _usdRates = {
  'USD': 1.0, 'USDT': 1.0, 'EUR': 1.08, 'GBP': 1.27, 'NGN': 0.00065,
  'GHS': 0.067, 'KES': 0.0077, 'ZAR': 0.054, 'INR': 0.012,
  'AED': 0.272, 'SAR': 0.267, 'CAD': 0.74, 'AUD': 0.65, 'CHF': 1.13,
  'JPY': 0.0067, 'CNY': 0.138, 'SGD': 0.74, 'HKD': 0.128,
  'MXN': 0.059, 'BRL': 0.20, 'TRY': 0.031,
};

class WalletCurrency {
  final String flag;
  final String code;
  final String name;
  final double balance;
  final double available;
  final String symbol;
  // Persisted portfolio color index (0-7) — stable across reorders & DB syncs
  final int? colorIndex;

  const WalletCurrency({
    required this.flag,
    required this.code,
    required this.name,
    required this.balance,
    required this.available,
    required this.symbol,
    this.colorIndex,
  });

  Map<String, dynamic> toJson() => {
    'flag': flag, 'code': code, 'name': name,
    'balance': balance, 'available': available, 'symbol': symbol,
    'colorIndex': colorIndex,
  };

  factory WalletCurrency.fromJson(Map<String, dynamic> json) => WalletCurrency(
    flag: json['flag'] as String,
    code: json['code'] as String,
    name: json['name'] as String,
    balance: (json['balance'] as num).toDouble(),
    available: (json['available'] as num).toDouble(),
    symbol: json['symbol'] as String,
    colorIndex: json['colorIndex'] as int?,
  );

  WalletCurrency copyWith({double? balance, double? available, int? colorIndex}) => WalletCurrency(
    flag: flag, code: code, name: name,
    balance: balance ?? this.balance,
    available: available ?? this.available,
    symbol: symbol,
    colorIndex: colorIndex ?? this.colorIndex,
  );
}

// ── Persistent StateNotifier ──────────────────────────────────────────────────

class WalletCurrenciesNotifier extends StateNotifier<List<WalletCurrency>> {
  WalletCurrenciesNotifier() : super(_localeDefault()) {
    _loadFromStorage();
  }

  /// Build a single-currency default list based on device locale.
  static List<WalletCurrency> _localeDefault() {
    final code = detectLocaleCurrency();
    return [
      WalletCurrency(
        flag: currencyToFlag(code),
        code: code,
        name: currencyToName(code),
        balance: 0.00,
        available: 0.00,
        symbol: currencyToSymbol(code),
        colorIndex: 0, // teal — primary currency always gets index 0
      ),
    ];
  }

  Future<void> _loadFromStorage() async {
    try {
      final raw = await SecureStorage.getWalletCurrencies();
      if (raw != null) {
        final list = (jsonDecode(raw) as List)
            .map((e) => WalletCurrency.fromJson(e as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) state = list;
      }
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      await SecureStorage.saveWalletCurrencies(
        jsonEncode(state.map((c) => c.toJson()).toList()),
      );
    } catch (_) {}
  }

  void add(WalletCurrency currency) {
    if (state.any((c) => c.code == currency.code)) return;
    // Assign next sequential color index if not already set
    final idx = currency.colorIndex ?? state.length;
    state = [...state, currency.copyWith(colorIndex: idx)];
    _persist();
  }

  void remove(String code) {
    state = state.where((c) => c.code != code).toList();
    _persist();
  }

  void addFunds(String code, double amount) {
    final exists = state.any((c) => c.code == code);
    if (exists) {
      state = state.map((c) {
        if (c.code != code) return c;
        final newBalance = (c.balance + amount).clamp(0.0, double.infinity);
        return c.copyWith(balance: newBalance, available: newBalance);
      }).toList();
    } else if (amount > 0) {
      final flag = currencyToFlag(code);
      final name = currencyToName(code);
      final symbol = currencyToSymbol(code);
      state = [...state, WalletCurrency(flag: flag, code: code, name: name,
          balance: amount, available: amount, symbol: symbol, colorIndex: state.length)];
    }
    _persist();
  }
}

final walletCurrenciesProvider =
    StateNotifierProvider<WalletCurrenciesNotifier, List<WalletCurrency>>(
        (_) => WalletCurrenciesNotifier());

// ── Screen ────────────────────────────────────────────────────────────────────

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _balanceHidden = false;
  bool _walletFrozen = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    final currencies = ref.watch(walletCurrenciesProvider);
    final totalUSD = currencies.fold<double>(
        0, (sum, c) => sum + c.balance * (_usdRates[c.code] ?? 1.0));
    // Show total in primary wallet currency, not hardcoded USD
    final primaryCode = currencies.isNotEmpty ? currencies.first.code : 'USD';
    final primarySymbol = currencies.isNotEmpty ? currencies.first.symbol : r'$';
    final primaryUsdRate = _usdRates[primaryCode] ?? 1.0;
    final totalInPrimary = primaryUsdRate > 0 ? totalUSD / primaryUsdRate : totalUSD;

    final authAsync = ref.watch(authProvider);
    final user = authAsync.valueOrNull?.user;
    final fullName = user != null ? '${user.firstName} ${user.lastName}'.trim() : 'AmixPay User';
    final primaryCurrency = currencies.isNotEmpty ? currencies.first : null;
    final cardBalance = primaryCurrency != null
        ? '${primaryCurrency.symbol}${primaryCurrency.balance.toStringAsFixed(2)} ${primaryCurrency.code}'
        : '\$0.00 USD';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        title: const Text('My Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Currencies'),
            Tab(text: 'My Card'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (v) {
              if (v == 'hide_balance') {
                setState(() => _balanceHidden = !_balanceHidden);
              } else if (v == 'freeze') {
                setState(() => _walletFrozen = !_walletFrozen);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(_walletFrozen
                      ? 'Wallet frozen. All transactions blocked.'
                      : 'Wallet unfrozen. Transactions re-enabled.'),
                  backgroundColor: _walletFrozen ? Colors.orange : const Color(0xFF0D6B5E),
                ));
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'hide_balance',
                child: Row(children: [
                  Icon(_balanceHidden ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      color: const Color(0xFF0D6B5E), size: 18),
                  const SizedBox(width: 10),
                  Text(_balanceHidden ? 'Show Balance' : 'Hide Balance'),
                ]),
              ),
              PopupMenuItem(
                value: 'freeze',
                child: Row(children: [
                  Icon(_walletFrozen ? Icons.lock_open_rounded : Icons.lock_rounded,
                      color: _walletFrozen ? Colors.orange : Colors.red, size: 18),
                  const SizedBox(width: 10),
                  Text(_walletFrozen ? 'Unfreeze Wallet' : 'Freeze Wallet',
                      style: TextStyle(color: _walletFrozen ? Colors.orange : Colors.red)),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // ── Tab 1: Currencies ────────────────────────────────────────────
          RefreshIndicator(
            color: _teal,
            onRefresh: _onRefresh,
            child: CustomScrollView(
              slivers: [
                // ── Balance hero ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    color: _teal,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(children: [
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('Total Balance (${primaryCode})',
                            style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        if (_walletFrozen) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(6)),
                            child: const Text('FROZEN', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 4),
                      Text(
                        _balanceHidden ? '••••••' : '$primarySymbol${totalInPrimary.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      // ── Quick action row (Wise-style) ──────────────────
                      Row(
                        children: [
                          _WalletQuickBtn(
                            icon: Icons.add_rounded,
                            label: 'Add Money',
                            onTap: () => context.push(AppRoutes.addFunds, extra: primaryCode),
                          ),
                          const SizedBox(width: 10),
                          _WalletQuickBtn(
                            icon: Icons.send_rounded,
                            label: 'Send',
                            onTap: () => context.push(AppRoutes.zelleTransfer, extra: primaryCode),
                          ),
                          const SizedBox(width: 10),
                          _WalletQuickBtn(
                            icon: Icons.flight_takeoff_rounded,
                            label: 'Transfer',
                            onTap: () => context.push(AppRoutes.internationalTransfer),
                          ),
                          const SizedBox(width: 10),
                          _WalletQuickBtn(
                            icon: Icons.account_balance_wallet_rounded,
                            label: 'Withdraw',
                            onTap: () => context.push(AppRoutes.withdraw),
                          ),
                        ],
                      ),
                    ]),
                  ),
                ),

                // ── Portfolio allocation strip ───────────────────────────
                if (currencies.length > 1)
                  SliverToBoxAdapter(
                    child: _PortfolioBar(currencies: currencies, totalUSD: totalUSD),
                  ),

                // ── Trust badge strip ────────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _TrustBadge(icon: Icons.security_rounded, label: 'AES-256'),
                        _divider(),
                        _TrustBadge(icon: Icons.verified_rounded, label: 'Licensed'),
                        _divider(),
                        _TrustBadge(icon: Icons.language_rounded, label: '50+ currencies'),
                      ],
                    ),
                  ),
                ),

                // ── Section header ───────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Your ${currencies.length} ${currencies.length == 1 ? 'Currency' : 'Currencies'}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                        TextButton.icon(
                          onPressed: () => context.push('/wallet/add-currency'),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add'),
                          style: TextButton.styleFrom(foregroundColor: _teal),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Currency cards ───────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _CurrencyCard(
                        currency: currencies[index],
                        totalUSD: totalUSD,
                        index: index,
                        hideBalance: _balanceHidden,
                        frozen: _walletFrozen,
                      ),
                      childCount: currencies.length,
                    ),
                  ),
                ),

                // ── USDT / Crypto wallet card ────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _UsdtCard(),
                  ),
                ),

                // ── "Zero fees to Africa" banner ─────────────────────────
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _AfricaBanner(),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),

          // ── Tab 2: My Card ───────────────────────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('AmixPay Virtual Card',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 10),
              _VirtualCard(holderName: fullName, balance: cardBalance),
              const SizedBox(height: 8),
              // Balance link badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _teal.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _teal.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.account_balance_wallet_rounded, color: _teal, size: 16),
                  const SizedBox(width: 8),
                  Text('Connected wallet balance: $cardBalance',
                      style: const TextStyle(fontSize: 12, color: _teal, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  const Icon(Icons.link_rounded, color: _teal, size: 16),
                ]),
              ),
              const SizedBox(height: 20),
              // Card quick actions
              Row(children: [
                _CardAction(icon: Icons.add_circle_outline_rounded, label: 'Add Money',
                    onTap: () => context.push(AppRoutes.addFunds, extra: primaryCode)),
                const SizedBox(width: 12),
                _CardAction(icon: Icons.send_rounded, label: 'Pay',
                    onTap: () => context.push(AppRoutes.zelleTransfer, extra: primaryCode)),
                const SizedBox(width: 12),
                _CardAction(icon: Icons.history_rounded, label: 'History',
                    onTap: () => context.push(AppRoutes.transactionHistory)),
                const SizedBox(width: 12),
                _CardAction(icon: Icons.credit_card_rounded, label: 'Details',
                    onTap: () => context.push('/cards/primary-virtual')),
              ]),
              const SizedBox(height: 28),
              Row(children: [
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Linked Bank Cards',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                    SizedBox(height: 2),
                    Text('Cards linked for easy wallet funding',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ]),
                ),
                TextButton.icon(
                  onPressed: () => context.push(AppRoutes.addCard),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Link Card'),
                  style: TextButton.styleFrom(foregroundColor: _teal),
                ),
              ]),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Row(children: [
                  Icon(Icons.credit_card_off_rounded, color: Colors.grey, size: 22),
                  SizedBox(width: 12),
                  Expanded(child: Text('No linked cards yet. Tap "Link Card" to add one.',
                      style: TextStyle(fontSize: 13, color: Colors.grey))),
                ]),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.addCard),
                icon: const Icon(Icons.add_card_rounded),
                label: const Text('Link a New Card'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  foregroundColor: const Color(0xFF1A1A2E),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: const Row(children: [
                  Icon(Icons.security_rounded, color: Colors.green, size: 18),
                  SizedBox(width: 10),
                  Expanded(child: Text('All cards are secured with 256-bit encryption.',
                      style: TextStyle(fontSize: 12, color: Colors.green))),
                ]),
              ),
              const SizedBox(height: 40),
            ]),
          ),
        ],
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _tabController,
        builder: (_, __) => _tabController.index == 0
            ? FloatingActionButton.extended(
                onPressed: () => context.push('/wallet/add-currency'),
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text('Add Currency'),
              )
            : const SizedBox.shrink(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

Widget _divider() => Container(height: 24, width: 1, color: Colors.grey.shade200);

// ── Wallet Quick Button (Wise-style circular) ─────────────────────────────────

class _WalletQuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _WalletQuickBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

// ── Portfolio allocation bar ──────────────────────────────────────────────────

class _PortfolioBar extends StatelessWidget {
  final List<WalletCurrency> currencies;
  final double totalUSD;
  const _PortfolioBar({required this.currencies, required this.totalUSD});

  static const _barColors = [
    Color(0xFF0D6B5E), Color(0xFF0284C7), Color(0xFF7C3AED),
    Color(0xFFDB2777), Color(0xFFEA580C), Color(0xFF059669),
  ];

  @override
  Widget build(BuildContext context) {
    if (totalUSD == 0) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Portfolio Allocation',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          // Segmented bar — colors match _CurrencyCard (stable colorIndex)
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: currencies.asMap().entries.map((entry) {
                final c = entry.value;
                final pct = c.balance * (_usdRates[c.code] ?? 1.0) / totalUSD;
                final colorIdx = (c.colorIndex ?? entry.key) % _barColors.length;
                return Flexible(
                  flex: (pct * 1000).round().clamp(1, 1000),
                  child: Container(height: 10, color: _barColors[colorIdx]),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: currencies.asMap().entries.map((entry) {
              final c = entry.value;
              final pct = totalUSD > 0
                  ? (c.balance * (_usdRates[c.code] ?? 1.0) / totalUSD * 100)
                  : 0.0;
              final colorIdx = (c.colorIndex ?? entry.key) % _barColors.length;
              return Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 10, height: 10,
                    decoration: BoxDecoration(
                        color: _barColors[colorIdx],
                        shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('${c.code} ${pct.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ]);
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Trust badge ───────────────────────────────────────────────────────────────

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 18, color: _teal),
      const SizedBox(height: 3),
      Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey)),
    ],
  );
}

// ── Africa zero-fee banner ────────────────────────────────────────────────────

class _AfricaBanner extends StatelessWidget {
  const _AfricaBanner();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFF0FDF4),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.green.shade200),
    ),
    child: Row(children: [
      const Text('🌍', style: TextStyle(fontSize: 22)),
      const SizedBox(width: 12),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('0% Transfer Fee to Africa', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.green)),
        SizedBox(height: 2),
        Text('Send to 15+ African countries with zero fees — always.',
            style: TextStyle(fontSize: 11, color: Colors.green)),
      ])),
      TextButton(
        onPressed: () => context.push(AppRoutes.internationalTransfer),
        style: TextButton.styleFrom(
          foregroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        child: const Text('Send Now'),
      ),
    ]),
  );
}

// ── USDT Card ────────────────────────────────────────────────────────────────

class _UsdtCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usdtBalance = ref.watch(usdtBalanceProvider);
    return GestureDetector(
      onTap: () => context.push(AppRoutes.usdtWallet),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF0D9488)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('💲', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('USDT Wallet',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              Text('\$${usdtBalance.toStringAsFixed(2)} USDT',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12)),
            ]),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Open',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }
}

// ── Virtual Card Widget ───────────────────────────────────────────────────────

class _VirtualCard extends StatelessWidget {
  final String holderName;
  final String balance;
  const _VirtualCard({required this.holderName, required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('AmixPay', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
            child: const Text('VIRTUAL', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
          ),
        ]),
        const Spacer(),
        const Text('Card Balance', style: TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 2),
        Text(balance, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('CARD NUMBER', style: TextStyle(color: Colors.white54, fontSize: 9)),
            const SizedBox(height: 2),
            const Text('•••• •••• •••• 9982', style: TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 1.5)),
          ]),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text('CARD HOLDER', style: TextStyle(color: Colors.white54, fontSize: 9)),
            const SizedBox(height: 2),
            Text(
              holderName.length > 18 ? holderName.substring(0, 18) : holderName,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ]),
        ]),
      ]),
    );
  }
}

// ── Card Tab Quick Action ─────────────────────────────────────────────────────

class _CardAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _CardAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
        child: Column(children: [
          Icon(icon, color: _teal, size: 22),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
        ]),
      ),
    ),
  );
}

class _CurrencyCard extends ConsumerWidget {
  final WalletCurrency currency;
  final double totalUSD;
  final int index; // fallback only — colorIndex from model is preferred
  final bool hideBalance;
  final bool frozen;
  const _CurrencyCard({required this.currency, required this.totalUSD, required this.index,
    this.hideBalance = false, this.frozen = false});

  static const _portfolioColors = [
    Color(0xFF0D6B5E), Color(0xFF0284C7), Color(0xFF7C3AED),
    Color(0xFFDB2777), Color(0xFFEA580C), Color(0xFF059669),
    Color(0xFFD97706), Color(0xFF0891B2),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usdValue = currency.balance * (_usdRates[currency.code] ?? 1.0);
    final pct = totalUSD > 0 ? (usdValue / totalUSD * 100) : 0.0;
    // Use DB-persisted colorIndex; fall back to position index for legacy/offline
    final colorIdx = (currency.colorIndex ?? index) % _portfolioColors.length;
    final portfolioColor = _portfolioColors[colorIdx];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: portfolioColor.withValues(alpha: 0.2)),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/wallet/transactions?currency=${currency.code}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            // Color-coded icon container
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: portfolioColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: portfolioColor.withValues(alpha: 0.2)),
              ),
              alignment: Alignment.center,
              child: Text(currency.flag, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(currency.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  hideBalance ? 'Available: ••••••' : 'Available: ${currency.symbol}${currency.available.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
                if (totalUSD > 0) ...[
                  const SizedBox(height: 5),
                  Row(children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct / 100,
                          backgroundColor: Colors.grey.shade100,
                          color: portfolioColor,
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('${pct.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                            color: portfolioColor)),
                  ]),
                ],
              ]),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                hideBalance ? '••••••' : '${currency.symbol}${currency.balance.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _teal),
              ),
              if (frozen)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4)),
                  child: const Text('FROZEN', style: TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.w800)),
                ),
            ]),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (v) {
                if (v == 'send') context.push(AppRoutes.zelleTransfer, extra: currency.code);
                if (v == 'add') context.push(AppRoutes.addFunds, extra: currency.code);
                if (v == 'remove') {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('Remove ${currency.code}?'),
                      content: Text('Remove ${currency.name} from your wallet?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () {
                            Navigator.pop(ctx);
                            ref.read(walletCurrenciesProvider.notifier).remove(currency.code);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('${currency.code} removed'),
                              backgroundColor: Colors.orange,
                            ));
                          },
                          child: const Text('Remove', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'send',
                    child: Row(children: [Icon(Icons.send_rounded, color: _teal, size: 18), SizedBox(width: 8), Text('Send')])),
                const PopupMenuItem(value: 'add',
                    child: Row(children: [Icon(Icons.add_circle_outline, color: _teal, size: 18), SizedBox(width: 8), Text('Add Funds')])),
                const PopupMenuItem(value: 'remove',
                    child: Row(children: [Icon(Icons.delete_outline, color: Colors.red, size: 18), SizedBox(width: 8), Text('Remove', style: TextStyle(color: Colors.red))])),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}
