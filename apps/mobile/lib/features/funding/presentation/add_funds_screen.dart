import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:plaid_flutter/plaid_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/locale_utils.dart';
import '../../../core/services/flutterwave_service.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/wallet_provider.dart';
import '../../../shared/providers/transaction_provider.dart';
import '../../wallet/presentation/wallet_screen.dart' show walletCurrenciesProvider;
import '../data/funding_repository.dart';
import '../data/saved_cards_provider.dart';

// African currencies that Flutterwave handles better than Stripe
const _flutterwaveCurrencies = {
  'NGN', 'GHS', 'KES', 'UGX', 'RWF', 'ZMW', 'TZS', 'XAF', 'XOF', 'EGP', 'ZAR',
};

class AddFundsScreen extends ConsumerStatefulWidget {
  final String? initialCurrency;
  const AddFundsScreen({super.key, this.initialCurrency});
  @override
  ConsumerState<AddFundsScreen> createState() => _AddFundsScreenState();
}

class _AddFundsScreenState extends ConsumerState<AddFundsScreen> {
  int _selectedMethod = 0;
  SavedPaymentCard? _selectedSavedCard; // selected saved card for quick pay
  bool _loading = false;
  bool _plaidLinked = false;
  List<dynamic> _linkedAccounts = [];
  final _amountController = TextEditingController();

  static const _currencies = [
    'USD', 'EUR', 'GBP', 'CAD', 'AUD', 'NZD', 'CHF', 'SGD', 'HKD',
    'NGN', 'GHS', 'KES', 'ZAR', 'UGX', 'TZS', 'RWF', 'ETB', 'EGP',
    'MAD', 'ZMW', 'XAF', 'XOF',
    'INR', 'CNY', 'JPY', 'KRW', 'MYR', 'PHP', 'THB', 'IDR', 'VND',
    'PKR', 'BDT', 'LKR', 'NPR', 'TWD',
    'AED', 'SAR', 'QAR', 'KWD', 'BHD', 'ILS', 'TRY',
    'BRL', 'ARS', 'CLP', 'COP', 'PEN', 'MXN', 'UYU', 'BOB', 'VES',
    'SEK', 'NOK', 'DKK', 'PLN', 'CZK', 'HUF', 'RON',
  ];

  // Default currency from initial param or device locale, validated against supported list
  late String _currency;

  static String _validatedLocaleCurrency() {
    final detected = detectLocaleCurrency();
    const supported = {
      'USD', 'EUR', 'GBP', 'CAD', 'AUD', 'NZD', 'CHF', 'SGD', 'HKD',
      'NGN', 'GHS', 'KES', 'ZAR', 'UGX', 'TZS', 'RWF', 'ETB', 'EGP',
      'MAD', 'ZMW', 'XAF', 'XOF',
      'INR', 'CNY', 'JPY', 'KRW', 'MYR', 'PHP', 'THB', 'IDR', 'VND',
      'PKR', 'BDT', 'LKR', 'NPR', 'TWD',
      'AED', 'SAR', 'QAR', 'KWD', 'BHD', 'ILS', 'TRY',
      'BRL', 'ARS', 'CLP', 'COP', 'PEN', 'MXN', 'UYU', 'BOB', 'VES',
      'SEK', 'NOK', 'DKK', 'PLN', 'CZK', 'HUF', 'RON',
    };
    return supported.contains(detected) ? detected : 'USD';
  }

  StreamSubscription<LinkSuccess>? _plaidSuccess;
  StreamSubscription<LinkExit>? _plaidExit;

  @override
  void initState() {
    super.initState();
    final init = widget.initialCurrency;
    _currency = (init != null && _currencies.contains(init))
        ? init
        : _validatedLocaleCurrency();
    _plaidSuccess = PlaidLink.onSuccess.listen(_onPlaidSuccess);
    _plaidExit = PlaidLink.onExit.listen(_onPlaidExit);
  }

  // All payment methods — restored with new design
  final _methods = [
    _FundMethod('Debit / Credit Card', 'Visa, Mastercard, Amex', Icons.credit_card_rounded, Color(0xFF7C3AED), 'FREE · Instant'),
    _FundMethod('Bank Transfer', 'Direct bank debit (ACH/SEPA)', Icons.account_balance_rounded, Color(0xFF0D6B5E), 'FREE · Instant'),
    _FundMethod('Apple Pay', 'Face ID / Touch ID', Icons.apple_rounded, Color(0xFF1A1A1A), 'FREE · Instant'),
    _FundMethod('Google Pay', 'Pay with Google account', Icons.g_mobiledata_rounded, Color(0xFF4285F4), 'FREE · Instant'),
    _FundMethod('Mobile Money', 'MTN, Airtel, M-Pesa & more', Icons.phone_android_rounded, Color(0xFFEA580C), 'FREE · Instant'),
    _FundMethod('Crypto (USDT)', 'USDT, BTC, ETH & more', Icons.currency_bitcoin_rounded, Color(0xFF10B981), 'FREE · ~15 min'),
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _plaidSuccess?.cancel();
    _plaidExit?.cancel();
    super.dispose();
  }

  Future<void> _onPlaidSuccess(LinkSuccess success) async {
    final repo = ref.read(fundingRepositoryProvider);
    try {
      final accounts = await repo.exchangePlaidToken(success.publicToken);
      if (!mounted) return;
      setState(() {
        _plaidLinked = true;
        _linkedAccounts = accounts;
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Bank account linked successfully!'),
        backgroundColor: AppColors.success,
      ));
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _onPlaidExit(LinkExit exit) {
    if (!mounted) return;
    setState(() => _loading = false);
    if (exit.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Bank connection failed. Please try again.'),
        backgroundColor: AppColors.error,
        duration: Duration(seconds: 3),
      ));
    }
  }

  Future<void> _launchPlaidLink() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(fundingRepositoryProvider);
      final linkToken = await repo.createPlaidLinkToken();
      await PlaidLink.create(configuration: LinkTokenConfiguration(token: linkToken));
      await PlaidLink.open();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Unable to connect your bank. Please try again later.'),
        backgroundColor: AppColors.error,
        duration: Duration(seconds: 3),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value?.user;
    final registeredName = '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: BackButton(color: AppColors.textPrimary),
        title: const Text('Add Funds', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How much?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: '0.00',
                        hintStyle: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textHint),
                        border: InputBorder.none, contentPadding: EdgeInsets.zero, filled: false,
                      ),
                    ),
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _currency,
                      items: _currencies.map((c) => DropdownMenuItem(value: c, child: Row(mainAxisSize: MainAxisSize.min, children: [Text(currencyFlag(c), style: const TextStyle(fontSize: 16)), const SizedBox(width: 6), Text(c, style: const TextStyle(fontWeight: FontWeight.w700))]))).toList(),
                      onChanged: (v) => setState(() => _currency = v!),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Quick amounts
            Row(
              children: ['50', '100', '200', '500'].map((a) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _amountController.text = a),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
                    child: Text('+$a', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 24),

            // ── Saved cards section ──────────────────────────────────────────
            Consumer(builder: (ctx, r, _) {
              final saved = r.watch(savedCardsProvider);
              if (saved.isEmpty) return const SizedBox.shrink();
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Text('Saved Cards', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _showManageSavedCards(ctx, r),
                    child: const Text('Manage', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                  ),
                ]),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: saved.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (ctx, i) {
                      final c = saved[i];
                      final isSelected = _selectedSavedCard?.id == c.id;
                      final brandIcon = _brandIcon(c.brand);
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedSavedCard = isSelected ? null : c;
                          _selectedMethod = 0;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primarySurface : AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))]
                                : [],
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                            Row(children: [
                              Icon(brandIcon, size: 18, color: isSelected ? AppColors.primary : AppColors.textPrimary),
                              const SizedBox(width: 6),
                              Text('···· ${c.last4}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isSelected ? AppColors.primary : AppColors.textPrimary)),
                              if (isSelected) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primary),
                              ],
                            ]),
                            const SizedBox(height: 3),
                            Text(
                              c.nickname.isNotEmpty ? c.nickname : 'Expires ${c.expiry}',
                              style: TextStyle(fontSize: 11, color: isSelected ? AppColors.primary : AppColors.textSecondary),
                            ),
                            if (isSelected)
                              const Text('Tap Pay to use this card', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ]);
            }),

            const Text('Payment Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.55,
              children: List.generate(_methods.length, (i) {
                final m = _methods[i];
                final sel = i == _selectedMethod;
                return GestureDetector(
                  onTap: () => setState(() { _selectedMethod = i; if (i != 0) _selectedSavedCard = null; }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: sel ? m.color.withValues(alpha: 0.08) : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: sel ? m.color : AppColors.border,
                          width: sel ? 2 : 1),
                      boxShadow: sel
                          ? [BoxShadow(color: m.color.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))]
                          : [],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                  color: m.color.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(11)),
                              child: Icon(m.icon, color: m.color, size: 20),
                            ),
                            if (sel)
                              Icon(Icons.check_circle_rounded, color: m.color, size: 18),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: AppColors.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: m.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(m.fee,
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: m.color,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 8),

            // ── Method-specific info notices ─────────────────────────────
            if (_selectedMethod == 0) ...[
              _InfoNotice(
                icon: Icons.credit_card_rounded,
                color: const Color(0xFF7C3AED),
                title: _flutterwaveCurrencies.contains(_currency)
                    ? 'Card — Powered by Flutterwave'
                    : 'Card — Powered by Stripe',
                body: _flutterwaveCurrencies.contains(_currency)
                    ? 'Your $_currency card payment is processed securely by Flutterwave. 3D Secure authentication may be required.'
                    : 'Your card is processed securely by Stripe. Your bank may send an OTP or prompt authentication via your banking app.',
              ),
            ] else if (_selectedMethod == 1) ...[
              _InfoNotice(
                icon: Icons.account_balance_rounded,
                color: const Color(0xFF0D6B5E),
                title: 'Bank Transfer',
                body: 'Connect your bank account via Plaid. Funds are credited to your wallet instantly.',
              ),
            ] else if (_selectedMethod == 2) ...[
              _InfoNotice(
                icon: Icons.apple_rounded,
                color: Colors.black,
                title: 'Apple Pay',
                body: 'You\'ll be prompted to authenticate with Face ID or Touch ID. Funds are instant.',
              ),
            ] else if (_selectedMethod == 3) ...[
              _InfoNotice(
                icon: Icons.g_mobiledata_rounded,
                color: const Color(0xFF4285F4),
                title: 'Google Pay',
                body: 'Securely pay using your Google account. Instant and free.',
              ),
            ] else if (_selectedMethod == 4) ...[
              _InfoNotice(
                icon: Icons.phone_android_rounded,
                color: const Color(0xFFEA580C),
                title: 'Mobile Money — Powered by Flutterwave',
                body: 'Supports MTN MoMo, Airtel Money, M-Pesa, Orange Money, USSD & more across Africa. Instant.',
              ),
            ] else if (_selectedMethod == 5) ...[
              _InfoNotice(
                icon: Icons.currency_bitcoin_rounded,
                color: const Color(0xFF10B981),
                title: 'Crypto Deposit (USDT)',
                body: 'Send USDT (TRC-20/ERC-20), BTC, or ETH to your AmixPay wallet address. ~15 min confirmation.',
              ),
            ],
            const SizedBox(height: 16),

            // ── Name must match Government ID ────────────────────────────
            if (registeredName.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D6B5E).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF0D6B5E).withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: Color(0xFF0D6B5E), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Account name must match your ID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0D6B5E))),
                          const SizedBox(height: 2),
                          Text(registeredName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          const Text('Your card, bank account, or mobile money must be registered in this exact name as on your approved Government ID.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            ElevatedButton(
              onPressed: _loading ? null : () => _handleAdd(registeredName),
              child: _loading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : Text(_buttonLabel),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String get _buttonLabel {
    final amt = _amountController.text.isEmpty ? '' : '$_currency ${_amountController.text} ';
    if (_selectedMethod == 0 && _selectedSavedCard != null) {
      final c = _selectedSavedCard!;
      return 'Pay ${amt}with ${c.brand.toUpperCase()} ···· ${c.last4}';
    }
    return switch (_selectedMethod) {
      0 => 'Add ${amt}Funds via Card',
      1 => _plaidLinked ? 'Add ${amt}Funds via Bank' : 'Connect Bank Account',
      2 => 'Pay ${amt}with Apple Pay',
      3 => 'Pay ${amt}with Google Pay',
      4 => 'Pay ${amt}via Mobile Money',
      5 => 'Deposit ${amt}Crypto (USDT)',
      _ => 'Add ${amt}Funds',
    };
  }

  void _handleAdd(String registeredName) {
    // Bank Transfer — launch Plaid if not yet linked
    if (_selectedMethod == 1 && !_plaidLinked) {
      _launchPlaidLink();
      return;
    }

    final amt = double.tryParse(_amountController.text);
    if (amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }

    if (registeredName.isNotEmpty) {
      _showNameConfirmDialog(registeredName, () => _routePayment(amt, registeredName));
      return;
    }

    _routePayment(amt, registeredName);
  }

  void _routePayment(double amt, String registeredName) {
    switch (_selectedMethod) {
      case 0:
        // If a saved card is already selected, skip the entry sheet
        if (_selectedSavedCard != null) {
          _creditWallet(amt, offerSave: false);
          return;
        }
        // Card: use Flutterwave for African currencies, card sheet otherwise
        if (_flutterwaveCurrencies.contains(_currency)) {
          _payWithFlutterwave(
            amt: amt,
            name: registeredName,
            paymentOptions: 'card',
          );
        } else {
          _showCardPaymentSheet(amt);
        }
      case 4:
        // Mobile Money — always Flutterwave
        _payWithFlutterwave(
          amt: amt,
          name: registeredName,
          paymentOptions: FlutterwaveService.paymentOptionsFor(_currency),
        );
      default:
        _creditWallet(amt);
    }
  }

  Future<void> _payWithFlutterwave({
    required double amt,
    required String name,
    required String paymentOptions,
  }) async {
    setState(() => _loading = true);
    try {
      final user = ref.read(authProvider).value?.user;
      final email = user?.email ?? 'user@amixpay.com';
      final phone = user?.phone ?? '';

      final success = await FlutterwaveService.charge(
        context: context,
        amount: amt,
        currency: _currency,
        email: email,
        name: name.isNotEmpty ? name : 'AmixPay User',
        phone: phone,
        paymentOptions: paymentOptions,
      );

      if (!mounted) return;

      if (success) {
        _creditWallet(amt);
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Payment was cancelled or failed. No charge was made.'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 4),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Unable to process payment. Please try again.'),
        backgroundColor: AppColors.error,
        duration: Duration(seconds: 4),
      ));
    }
  }

  void _showNameConfirmDialog(String name, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.verified_user_rounded, color: Color(0xFF0D6B5E), size: 22),
            SizedBox(width: 8),
            Text('Confirm Your Name'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your payment source must be registered in exactly this name:'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 15))),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text('This must match your approved Government ID as registered with AmixPay.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); onConfirm(); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D6B5E), foregroundColor: Colors.white),
            child: const Text('Confirm & Continue'),
          ),
        ],
      ),
    );
  }

  void _showCardPaymentSheet(double amt) {
    final cardCtrl = TextEditingController();
    final expiryCtrl = TextEditingController();
    final cvvCtrl = TextEditingController();
    String detectedBrand = 'visa';
    bool saveCard = false;

    String _detectBrand(String num) {
      if (num.startsWith('4')) return 'visa';
      if (num.startsWith('5') || num.startsWith('2')) return 'mastercard';
      if (num.startsWith('3')) return 'amex';
      return 'visa';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [
                const Icon(Icons.credit_card_rounded, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(
                  'Pay ${CurrencyFormatter.symbolFor(_currency)}${amt.toStringAsFixed(2)} $_currency',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ]),
              const SizedBox(height: 4),
              const Text('Secured with 256-bit encryption', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 20),

              // Card number
              TextField(
                controller: cardCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _CardNumberFormatter(),
                ],
                onChanged: (v) => setSt(() => detectedBrand = _detectBrand(v.replaceAll(' ', ''))),
                decoration: InputDecoration(
                  labelText: 'Card Number',
                  prefixIcon: const Icon(Icons.credit_card_rounded, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                  filled: true, fillColor: AppColors.surface,
                ),
              ),
              const SizedBox(height: 12),

              // Expiry + CVV
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: expiryCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [_ExpiryFormatter()],
                    decoration: InputDecoration(
                      labelText: 'MM / YY',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                      filled: true, fillColor: AppColors.surface,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: cvvCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'CVV',
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                      filled: true, fillColor: AppColors.surface,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              // Save card toggle
              GestureDetector(
                onTap: () => setSt(() => saveCard = !saveCard),
                child: Row(children: [
                  Checkbox(
                    value: saveCard,
                    onChanged: (v) => setSt(() => saveCard = v ?? false),
                    activeColor: AppColors.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const Text('Save card for faster checkout', style: TextStyle(fontSize: 13)),
                ]),
              ),
              const SizedBox(height: 16),

              // Pay button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final raw = cardCtrl.text.replaceAll(' ', '');
                    if (raw.length < 13) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid card number')));
                      return;
                    }
                    if (expiryCtrl.text.length < 4) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter card expiry')));
                      return;
                    }
                    if (cvvCtrl.text.length < 3) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter CVV')));
                      return;
                    }
                    final last4 = raw.substring(raw.length - 4);
                    var expiry = expiryCtrl.text;
                    if (!expiry.contains('/') && expiry.length >= 4) {
                      expiry = '${expiry.substring(0, 2)}/${expiry.substring(2)}';
                    }
                    Navigator.pop(ctx);
                    // Save card if requested
                    if (saveCard && last4.length == 4) {
                      ref.read(savedCardsProvider.notifier).addCard(SavedPaymentCard(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        last4: last4,
                        brand: detectedBrand,
                        expiry: expiry,
                        nickname: '',
                      ));
                    }
                    // Credit wallet (no second save sheet)
                    _creditWallet(amt, offerSave: false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Pay ${CurrencyFormatter.symbolFor(_currency)}${amt.toStringAsFixed(2)} $_currency',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _brandIcon(String brand) {
    switch (brand) {
      case 'amex': return Icons.credit_score_rounded;
      case 'mastercard': return Icons.credit_card_rounded;
      default: return Icons.credit_card_rounded;
    }
  }

  void _showManageSavedCards(BuildContext ctx, WidgetRef r) {
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (shCtx) => Consumer(builder: (_, ref2, __) {
        final cards = ref2.watch(savedCardsProvider);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Saved Cards', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (cards.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('No saved cards', style: TextStyle(color: AppColors.textSecondary))),
              )
            else
              ...cards.map((c) => ListTile(
                leading: Icon(_brandIcon(c.brand), color: AppColors.primary),
                title: Text('${c.brand.toUpperCase()} ···· ${c.last4}'),
                subtitle: Text(c.nickname.isNotEmpty ? '${c.nickname} · Exp ${c.expiry}' : 'Exp ${c.expiry}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  onPressed: () => ref2.read(savedCardsProvider.notifier).removeCard(c.id),
                ),
              )),
          ]),
        );
      }),
    );
  }

  void _offerSaveCard(double amt) {
    final last4Ctrl = TextEditingController();
    final expiryCtrl = TextEditingController();
    final nicknameCtrl = TextEditingController();
    String brand = 'visa';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.save_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              const Text('Save this card?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 4),
            const Text('Save for faster checkout next time.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            // Brand row
            Row(children: ['visa', 'mastercard', 'amex'].map((b) => GestureDetector(
              onTap: () => setSt(() => brand = b),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: brand == b ? AppColors.primarySurface : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: brand == b ? AppColors.primary : AppColors.border),
                ),
                child: Text(b.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: brand == b ? AppColors.primary : AppColors.textSecondary)),
              ),
            )).toList()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(
                controller: last4Ctrl,
                maxLength: 4,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Last 4 digits',
                  counterText: '',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )),
              const SizedBox(width: 12),
              Expanded(child: TextField(
                controller: expiryCtrl,
                maxLength: 5,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Expiry MM/YY',
                  counterText: '',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: nicknameCtrl,
              decoration: InputDecoration(
                labelText: 'Nickname (optional)',
                hintText: 'e.g. My Chase Visa',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Skip'),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () {
                  if (last4Ctrl.text.length == 4 && expiryCtrl.text.length == 5) {
                    ref.read(savedCardsProvider.notifier).addCard(SavedPaymentCard(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      last4: last4Ctrl.text,
                      brand: brand,
                      expiry: expiryCtrl.text,
                      nickname: nicknameCtrl.text.trim(),
                    ));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Card saved for future payments'),
                      backgroundColor: AppColors.success,
                    ));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: const Text('Save Card'),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  void _creditWallet(double amt, {bool offerSave = true}) {
    setState(() => _loading = true);
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      ref.read(walletProvider.notifier).addFunds(_currency, amt);
      ref.read(walletCurrenciesProvider.notifier).addFunds(_currency, amt);
      const uuid = Uuid();
      ref.read(transactionProvider.notifier).add(AppTransaction(
        id: uuid.v4(),
        title: 'Wallet Funded',
        subtitle: _methods[_selectedMethod].name,
        amount: amt,
        currency: _currency,
        symbol: CurrencyFormatter.symbolFor(_currency),
        type: AppTxType.funded,
        status: AppTxStatus.paid,
        date: DateTime.now(),
      ));
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${CurrencyFormatter.format(amt, _currency)} added successfully!'),
        backgroundColor: AppColors.success,
      ));
      Navigator.pop(context);
    });
  }
}

class _FundMethod {
  final String name, description, fee;
  final IconData icon;
  final Color color;
  const _FundMethod(this.name, this.description, this.icon, this.color, this.fee);
}

// ── Card number formatter (adds space every 4 digits) ────────────────────────
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(' ', '');
    if (digits.length > 16) return old;
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final str = buffer.toString();
    return next.copyWith(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}

// ── Expiry formatter (auto-inserts / after MM) ────────────────────────────────
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    var digits = next.text.replaceAll('/', '');
    if (digits.length > 4) digits = digits.substring(0, 4);
    String result = digits;
    if (digits.length >= 3) {
      result = '${digits.substring(0, 2)}/${digits.substring(2)}';
    } else if (digits.length == 2 && old.text.length == 1) {
      result = '$digits/';
    }
    return next.copyWith(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

class _InfoNotice extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, body;
  const _InfoNotice({required this.icon, required this.color, required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
              const SizedBox(height: 3),
              Text(body, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8))),
            ]),
          ),
        ]),
      );
}

