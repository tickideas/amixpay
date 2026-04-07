import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/providers/wallet_provider.dart';
import '../../../shared/providers/transaction_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/locale_utils.dart';
import '../../wallet/presentation/wallet_screen.dart' show walletCurrenciesProvider, WalletCurrency;
import '../../../core/services/exchange_rate_service.dart';
import '../data/payment_repository.dart';

const _teal = Color(0xFF0D6B5E);
const _bg = Color(0xFFF5F7FA);
const _indigo = Color(0xFF6366F1);

class ZelleTransferScreen extends ConsumerStatefulWidget {
  final String? initialCurrency;
  const ZelleTransferScreen({super.key, this.initialCurrency});

  @override
  ConsumerState<ZelleTransferScreen> createState() => _ZelleTransferScreenState();
}

class _ZelleTransferScreenState extends ConsumerState<ZelleTransferScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _identifierController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isSearching = false;
  bool _isSending = false;
  _ResolvedRecipient? _resolved;
  late String _currency;     // wallet to DEBIT
  String _sendCurrency = 'USD'; // currency user enters amount in (recipient currency)
  double _amount = 0;



  // All global currencies for amount picker
  static const _globalCurrencies = [
    'USD','EUR','GBP','CAD','AUD','NZD','CHF','JPY','CNY','HKD','SGD',
    'INR','KRW','MXN','BRL','ARS','CLP','COP','PEN',
    'NGN','GHS','KES','ZAR','UGX','TZS','ETB','RWF','ZMW','MAD','EGP','XAF','XOF',
    'AED','SAR','QAR','TRY','ILS',
    'SEK','NOK','DKK','PLN','CZK','HUF','RON',
    'MYR','THB','PHP','IDR','VND','BDT','PKR','USDT',
  ];

  // Compute debit amount: how much of _currency wallet to deduct when sending _amount in _sendCurrency
  double _debitAmountWith(Map<String, double> rates) {
    if (_sendCurrency == _currency) return _amount;
    final sendRate = rates[_sendCurrency] ?? 1.0;
    final debitRate = rates[_currency] ?? 1.0;
    if (sendRate == 0) return _amount;
    return (_amount / sendRate) * debitRate;
  }

  @override
  void initState() {
    super.initState();
    _currency = widget.initialCurrency ?? 'USD';
    _sendCurrency = 'USD';
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _identifierController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _lookupRecipient(String value) async {
    final query = value.trim();
    if (query.isEmpty) {
      setState(() { _resolved = null; });
      return;
    }
    setState(() => _isSearching = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    // Search for real AmixPay users via API
    try {
      final results = await ref.read(paymentRepositoryProvider).searchUsers(query);
      _ResolvedRecipient? found;
      if (results.isNotEmpty) {
        final u = results.first;
        found = _ResolvedRecipient(
          id: u['id'] ?? '',
          username: '@${u['username'] ?? ''}',
          firstName: u['first_name'] ?? u['firstName'] ?? '',
          lastName: u['last_name'] ?? u['lastName'] ?? '',
          isVerified: u['email_verified'] == true || u['emailVerified'] == true,
        );
      }
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _resolved = found;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _resolved = null;
      });
    }
  }

  Future<void> _send() async {
    if (_resolved == null) return;
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    // Compute how much to debit from wallet
    final rates = ref.read(exchangeRatesProvider).valueOrNull?.rates ?? fallbackRates;
    final debit = _debitAmountWith(rates);
    final walletCurrencies = ref.read(walletCurrenciesProvider);
    final walletBalance = walletCurrencies
        .firstWhere((w) => w.code == _currency, orElse: () => const WalletCurrency(flag: '', code: '', name: '', balance: 0, available: 0, symbol: ''))
        .balance;

    if (debit > walletBalance) {
      final sym = CurrencyFormatter.symbolFor(_currency);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Insufficient balance. Need $sym${debit.toStringAsFixed(2)} $_currency')),
      );
      return;
    }

    setState(() => _isSending = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    // Debit wallet
    ref.read(walletProvider.notifier).addFunds(_currency, -debit);
    ref.read(walletCurrenciesProvider.notifier).addFunds(_currency, -debit);

    // Record transaction in the send currency
    const uuid = Uuid();
    ref.read(transactionProvider.notifier).add(AppTransaction(
      id: uuid.v4(),
      title: 'Sent to ${_resolved!.firstName} ${_resolved!.lastName}',
      subtitle: _resolved!.username,
      amount: _amount,
      currency: _sendCurrency,
      symbol: CurrencyFormatter.symbolFor(_sendCurrency),
      type: AppTxType.sent,
      status: AppTxStatus.paid,
      date: DateTime.now(),
    ));

    setState(() => _isSending = false);

    context.pushReplacement('/payments/success', extra: {
      'recipient': '${_resolved!.firstName} ${_resolved!.lastName}',
      'recipientHandle': _resolved!.username,
      'amount': _amount,
      'currency': _sendCurrency,
      'fee': 0.0,
      'symbol': CurrencyFormatter.symbolFor(_sendCurrency),
      'note': _noteController.text,
      'via': 'AmixCash Transfer',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        title: const Text('Send Money', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'AmixPay Users'),
            Tab(text: 'External (US Zelle)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInNetworkTab(),
          _buildExternalZelleTab(),
        ],
      ),
    );
  }

  Widget _buildInNetworkTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _teal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _teal.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.bolt_rounded, color: _teal, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Instant AmixCash transfers worldwide. No fees.',
                    style: TextStyle(fontSize: 12, color: _teal, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Recipient search
          const Text('Send to', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 8),
          TextField(
            controller: _identifierController,
            onChanged: _lookupRecipient,
            decoration: InputDecoration(
              hintText: 'Username, email, or phone',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: _teal),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _teal)),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _teal, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),

          // Recipient card
          if (_resolved != null) ...[
            const SizedBox(height: 12),
            _RecipientCard(recipient: _resolved!),
          ] else if (_identifierController.text.isNotEmpty && !_isSearching) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('No AmixPay user found. Try a different username, email, or phone.',
                        style: TextStyle(fontSize: 12, color: Colors.black87)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ── Pay with wallet selector ───────────────────────────────────────
          const Text('Pay with', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 8),
          Consumer(builder: (context, ref, _) {
            final wallets = ref.watch(walletCurrenciesProvider);
            if (wallets.isEmpty) return const SizedBox.shrink();
            return SizedBox(
              height: 68,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: wallets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final w = wallets[i];
                  final sel = w.code == _currency;
                  return GestureDetector(
                    onTap: () => setState(() => _currency = w.code),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? _teal : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: sel ? _teal : Colors.grey.shade300, width: sel ? 2 : 1),
                        boxShadow: sel ? [BoxShadow(color: _teal.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))] : [],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${w.flag} ${w.code}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: sel ? Colors.white : Colors.black87)),
                          const SizedBox(height: 2),
                          Text('${w.symbol}${w.balance.toStringAsFixed(2)}', style: TextStyle(fontSize: 11, color: sel ? Colors.white70 : Colors.grey.shade500)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }),
          const SizedBox(height: 14),

          // Amount with global currency picker
          const Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
                    decoration: const InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onChanged: (v) => setState(() => _amount = double.tryParse(v) ?? 0),
                  ),
                ),
                // Global currency dropdown (right side)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: _teal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sendCurrency,
                      isDense: true,
                      style: const TextStyle(fontWeight: FontWeight.w800, color: _teal, fontSize: 14),
                      icon: const Icon(Icons.expand_more, color: _teal, size: 16),
                      items: _globalCurrencies.map((c) => DropdownMenuItem(
                        value: c,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(currencyFlag(c), style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(c, style: const TextStyle(fontWeight: FontWeight.w700, color: _teal, fontSize: 13)),
                        ]),
                      )).toList(),
                      onChanged: (v) => setState(() => _sendCurrency = v!),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Balance + FX conversion
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Consumer(builder: (context, ref, _) {
              final wallets = ref.watch(walletCurrenciesProvider);
              final wallet = wallets.firstWhere((w) => w.code == _currency,
                  orElse: () => const WalletCurrency(flag: '', code: '', name: '', balance: 0, available: 0, symbol: ''));
              final debitSym = CurrencyFormatter.symbolFor(_currency);
              final showConversion = _sendCurrency != _currency && _amount > 0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Debit wallet: $debitSym${wallet.balance.toStringAsFixed(2)} $_currency available',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  if (showConversion) ...[
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.currency_exchange_rounded, size: 13, color: _teal),
                      const SizedBox(width: 4),
                      Text(
                        '${CurrencyFormatter.symbolFor(_sendCurrency)}${_amount.toStringAsFixed(2)} $_sendCurrency  =  $debitSym${_debitAmountWith(ref.read(exchangeRatesProvider).valueOrNull?.rates ?? fallbackRates).toStringAsFixed(2)} $_currency deducted',
                        style: const TextStyle(fontSize: 12, color: _teal, fontWeight: FontWeight.w600),
                      ),
                    ]),
                  ],
                ],
              );
            }),
          ),

          const SizedBox(height: 16),

          // Quick amounts
          Row(
            children: ['10', '25', '50', '100'].map((a) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() {
                  _amountController.text = a;
                  _amount = double.parse(a);
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text('+$a', style: const TextStyle(fontWeight: FontWeight.w600, color: _teal, fontSize: 13)),
                ),
              ),
            )).toList(),
          ),

          const SizedBox(height: 16),

          // Note
          TextField(
            controller: _noteController,
            maxLines: 2,
            maxLength: 100,
            decoration: InputDecoration(
              hintText: 'Add a note (optional)',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _teal, width: 1.5)),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_resolved != null && _amount > 0 && !_isSending) ? _send : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSending
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text(
                      _resolved != null && _amount > 0
                          ? 'Send ${CurrencyFormatter.symbolFor(_sendCurrency)}${_amount.toStringAsFixed(2)} $_sendCurrency to ${_resolved!.firstName}'
                          : 'Send Money',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExternalZelleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF6D28D9).withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF6D28D9).withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: const Color(0xFF6D28D9), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('External US Zelle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF6D28D9))),
                        Text('US accounts only · USD only', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Send to any Zelle-enrolled US bank account using their email or phone number. Transfers are processed through your US banking partner.',
                  style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _ExternalZelleForm(),
        ],
      ),
    );
  }
}

class _RecipientCard extends StatelessWidget {
  final _ResolvedRecipient recipient;
  const _RecipientCard({required this.recipient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _teal.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [BoxShadow(color: _teal.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: _indigo, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              recipient.firstName.isNotEmpty ? recipient.firstName[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('${recipient.firstName} ${recipient.lastName}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    if (recipient.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded, color: _teal, size: 16),
                    ],
                  ],
                ),
                Text(recipient.username, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
            child: const Text('Found', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _ExternalZelleForm extends ConsumerStatefulWidget {
  const _ExternalZelleForm();
  @override
  ConsumerState<_ExternalZelleForm> createState() => _ExternalZelleFormState();
}

class _ExternalZelleFormState extends ConsumerState<_ExternalZelleForm> {
  // FX: how many units of each currency per 1 USD
  static const _fromUsd = {
    'USD': 1.0,   'GBP': 0.787, 'EUR': 0.924,
    'CAD': 1.352, 'AUD': 1.538, 'NGN': 1538.0,
    'GHS': 14.9,  'KES': 129.5, 'ZAR': 18.5,
  };

  // Wallets eligible to fund Zelle (US + verified international currencies)
  static const _zelleEligible = ['USD', 'GBP', 'EUR', 'CAD', 'AUD'];

  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _useEmail = true;
  bool _sending = false;
  double _amount = 0;
  String _payFromCurrency = 'USD'; // which wallet to debit

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // Amount is always USD — deduction from wallet is in wallet's currency
  double get _walletDebit {
    if (_payFromCurrency == 'USD') return _amount;
    return _amount * (_fromUsd[_payFromCurrency] ?? 1.0);
  }

  void _submit() async {
    // Amount entered is always USD; max $2,500
    if (_amount <= 0 || _amount > 2500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount must be between \$0.01 and \$2,500 USD')),
      );
      return;
    }

    final debit = _walletDebit; // in wallet's currency
    final wallets = ref.read(walletCurrenciesProvider);
    final payWallet = wallets.where((w) => w.code == _payFromCurrency).firstOrNull;
    if (payWallet == null || payWallet.balance < debit) {
      final sym = CurrencyFormatter.symbolFor(_payFromCurrency);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Insufficient balance. Need $sym${debit.toStringAsFixed(2)} $_payFromCurrency')),
      );
      return;
    }

    setState(() => _sending = true);
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    // Debit wallet in wallet's own currency
    ref.read(walletCurrenciesProvider.notifier).addFunds(_payFromCurrency, -debit);

    setState(() => _sending = false);
    final sym = CurrencyFormatter.symbolFor(_payFromCurrency);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Zelle transfer submitted. '
          '\$${_amount.toStringAsFixed(2)} USD sent'
          '${_payFromCurrency != 'USD' ? ' · $sym${debit.toStringAsFixed(2)} $_payFromCurrency deducted' : ''}. '
          'Recipient will be notified.',
        ),
        backgroundColor: const Color(0xFF0D6B5E),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletCurrenciesProvider);
    final eligibleWallets = wallets.where((w) => _zelleEligible.contains(w.code)).toList();

    // If current wallet is no longer eligible, update after the frame
    if (eligibleWallets.isNotEmpty &&
        !eligibleWallets.any((w) => w.code == _payFromCurrency)) {
      final fallback = eligibleWallets.first.code;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _payFromCurrency = fallback);
      });
    }

    final payWallet = wallets.where((w) => w.code == _payFromCurrency).firstOrNull;
    final isNonUsd = _payFromCurrency != 'USD';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Who can use this ─────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(children: [
            const Text('🇬🇧 🇪🇺 🇺🇸', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Available to US, UK, and EU verified users. Send to any Zelle-enrolled US bank account.',
                style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // ── Pay from wallet selector ─────────────────────────────────────────
        const Text('Pay from',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 8),
        if (eligibleWallets.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: const Text(
              'Add a USD, GBP, or EUR wallet to send via Zelle.',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          )
        else
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: eligibleWallets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final w = eligibleWallets[i];
                final sel = w.code == _payFromCurrency;
                return GestureDetector(
                  onTap: () => setState(() => _payFromCurrency = w.code),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFF6D28D9) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: sel ? const Color(0xFF6D28D9) : Colors.grey.shade300,
                          width: sel ? 2 : 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${w.flag} ${w.code}',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: sel ? Colors.white : Colors.black87)),
                        Text('${w.symbol}${w.balance.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 11,
                                color: sel ? Colors.white70 : Colors.grey.shade500)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 16),

        // ── Toggle email / phone ─────────────────────────────────────────────
        Row(
          children: [
            _ToggleBtn(label: 'Email', selected: _useEmail, onTap: () => setState(() => _useEmail = true)),
            const SizedBox(width: 8),
            _ToggleBtn(label: 'Phone', selected: !_useEmail, onTap: () => setState(() => _useEmail = false)),
          ],
        ),
        const SizedBox(height: 12),

        if (_useEmail)
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDec('Recipient Zelle email address', Icons.email_outlined),
          )
        else
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: _inputDec('Recipient US phone number', Icons.phone_outlined),
          ),

        const SizedBox(height: 12),

        // Amount always in USD
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(children: [
            Container(
              margin: const EdgeInsets.only(left: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6D28D9).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('\$ USD', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF6D28D9), fontSize: 14)),
            ),
            Expanded(
              child: TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                decoration: const InputDecoration(
                  hintText: '0.00  (max \$2,500)',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                onChanged: (v) => setState(() => _amount = double.tryParse(v) ?? 0),
              ),
            ),
          ]),
        ),
        // Wallet deduction line
        if (isNonUsd && _amount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(children: [
              const Icon(Icons.currency_exchange_rounded, size: 13, color: Color(0xFF6D28D9)),
              const SizedBox(width: 4),
              Text(
                '\$${_amount.toStringAsFixed(2)} USD  =  ${CurrencyFormatter.symbolFor(_payFromCurrency)}${_walletDebit.toStringAsFixed(2)} $_payFromCurrency deducted',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6D28D9), fontWeight: FontWeight.w600),
              ),
            ]),
          ),

        const SizedBox(height: 12),

        TextField(
          controller: _noteController,
          decoration: _inputDec('Note (optional)', Icons.note_outlined),
        ),

        const SizedBox(height: 8),
        Text(
          'No fee · Funds arrive within 1–3 business days\n'
          '${isNonUsd ? 'Your $_payFromCurrency wallet is debited at live rates. ' : ''}'
          'Max \$2,500 USD per transfer · \$5,000 daily limit',
          style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.5),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: (eligibleWallets.isEmpty || _sending) ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6D28D9),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _sending
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text(
                    _amount > 0
                        ? 'Send \$${_amount.toStringAsFixed(2)} USD via Zelle'
                        : 'Send via Zelle',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDec(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
    prefixIcon: Icon(icon, color: _teal, size: 20),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _teal, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? _teal : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? _teal : Colors.grey.shade300),
      ),
      child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
    ),
  );
}

@immutable
class _ResolvedRecipient {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final bool isVerified;
  const _ResolvedRecipient({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.isVerified,
  });
}
