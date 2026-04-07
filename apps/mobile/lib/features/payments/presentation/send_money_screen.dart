import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/locale_utils.dart';
import '../../wallet/presentation/wallet_screen.dart' show walletCurrenciesProvider;
import '../../../core/services/exchange_rate_service.dart';

const _teal = Color(0xFF0D6B5E);
const _bg = Color(0xFFF5F7FA);

class _Contact {
  final String name;
  final String handle;
  final String initials;
  final Color color;
  const _Contact({required this.name, required this.handle, required this.initials, required this.color});
}

const _recentContacts = <_Contact>[];

const _currencies = [
  // Major
  'USD', 'EUR', 'GBP', 'CAD', 'AUD', 'CHF', 'JPY', 'NZD',
  // Africa
  'NGN', 'GHS', 'KES', 'ZAR', 'UGX', 'TZS', 'XAF', 'XOF', 'ETB', 'RWF', 'ZMW', 'MAD', 'EGP', 'MZN',
  // South America
  'BRL', 'ARS', 'CLP', 'COP', 'PEN', 'MXN', 'UYU', 'BOB', 'VES', 'PYG',
  // Asia
  'INR', 'CNY', 'AED', 'SAR', 'QAR', 'KRW', 'SGD', 'HKD', 'THB', 'MYR', 'PHP', 'IDR', 'VND', 'PKR', 'BDT', 'LKR', 'NPR', 'TRY', 'ILS',
  // Europe (non-euro)
  'SEK', 'NOK', 'DKK', 'PLN', 'CZK', 'HUF', 'RON',
];

class SendMoneyScreen extends ConsumerStatefulWidget {
  final String? initialCurrency;
  const SendMoneyScreen({super.key, this.initialCurrency});

  @override
  ConsumerState<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends ConsumerState<SendMoneyScreen> {
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();
  late String _selectedCurrency;
  String? _convertFromCode; // null = use matching wallet; set when cross-currency
  String _recipient = '';
  double _amount = 0;
  String _selectedRecipientName = '';

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.initialCurrency ?? 'USD';
  }

  bool get _hasCurrencyInWallet {
    final wallets = ref.read(walletCurrenciesProvider);
    return wallets.any((w) => w.code == _selectedCurrency);
  }

  // Same-currency transfers within AmixPay are always free
  bool get _isSameCurrencyTransfer => _hasCurrencyInWallet;

  double get _fee => _isSameCurrencyTransfer ? 0.0 : _amount * 0.005;
  bool get _canContinue {
    if (_recipient.isEmpty || _amount <= 0) return false;
    if (!_hasCurrencyInWallet && _convertFromCode == null) return false;
    return true;
  }

  // When sending cross-currency: the amount to debit in the source wallet
  double _convertedDebitAmountWith(Map<String, double> rates) {
    if (_convertFromCode == null) return _amount + _fee;
    final fromRate = rates[_convertFromCode!] ?? 1.0;
    final toRate = rates[_selectedCurrency] ?? 1.0;
    if (fromRate == 0) return _amount + _fee;
    return (_amount + _fee) * (toRate / fromRate);
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _selectContact(_Contact contact) {
    setState(() {
      _recipient = contact.handle;
      _selectedRecipientName = contact.name;
      _recipientController.text = contact.handle;
    });
  }

  void _onContinue() {
    if (!_canContinue) return;
    // When cross-currency: pass the source wallet info so confirm screen can debit it
    final effectiveCurrency = _convertFromCode ?? _selectedCurrency;
    final rates = ref.read(exchangeRatesProvider).valueOrNull?.rates ?? fallbackRates;
    final effectiveAmount = _convertFromCode != null ? _convertedDebitAmountWith(rates) : _amount;
    final effectiveFee = _convertFromCode != null ? 0.0 : _fee;
    context.push('/payments/confirm', extra: {
      'recipient': _selectedRecipientName.isNotEmpty ? _selectedRecipientName : _recipient,
      'recipientHandle': _recipient,
      'amount': effectiveAmount,
      'currency': effectiveCurrency,
      'fee': effectiveFee,
      'note': '',
      if (_convertFromCode != null) 'sendCurrency': _selectedCurrency,
      if (_convertFromCode != null) 'sendAmount': _amount,
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
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Send To', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
            const SizedBox(height: 10),
            TextField(
              controller: _recipientController,
              onChanged: (v) => setState(() { _recipient = v; _selectedRecipientName = ''; }),
              decoration: InputDecoration(
                hintText: 'Username, email or phone number',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _recipient.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () { _recipientController.clear(); setState(() { _recipient = ''; _selectedRecipientName = ''; }); })
                    : null,
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _teal, width: 2)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Recent Contacts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
            const SizedBox(height: 12),
            if (_recentContacts.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                child: const Row(children: [
                  Icon(Icons.person_add_outlined, color: Colors.grey, size: 20),
                  SizedBox(width: 10),
                  Text('Type an email, username or phone number above', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ]),
              )
            else
              SizedBox(
                height: 88,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _recentContacts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, i) {
                    final contact = _recentContacts[i];
                    final isSelected = _recipient == contact.handle;
                    return GestureDetector(
                      onTap: () => _selectContact(contact),
                      child: Column(
                        children: [
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              color: contact.color,
                              shape: BoxShape.circle,
                              border: isSelected ? Border.all(color: _teal, width: 3) : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(contact.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          const SizedBox(height: 6),
                          Text(contact.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),

            // ── Pay with wallet selector ───────────────────────────────────
            const Text('Pay with', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
            const SizedBox(height: 10),
            Consumer(builder: (context, ref, _) {
              final wallets = ref.watch(walletCurrenciesProvider);
              if (wallets.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 68,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: wallets.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final w = wallets[i];
                    final selected = w.code == _selectedCurrency;
                    return GestureDetector(
                      onTap: () => setState(() { _selectedCurrency = w.code; _convertFromCode = null; }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? _teal : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected ? _teal : Colors.grey.shade300,
                            width: selected ? 2 : 1,
                          ),
                          boxShadow: selected
                              ? [BoxShadow(color: _teal.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))]
                              : [],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${currencyFlag(w.code)} ${w.code}',
                              style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${w.symbol}${w.balance.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: selected ? Colors.white70 : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
            const SizedBox(height: 18),

            const Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) => setState(() => _amount = double.tryParse(v) ?? 0),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
                      filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _teal, width: 2)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade300)),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCurrency,
                      items: _currencies.map((c) => DropdownMenuItem(value: c, child: Row(mainAxisSize: MainAxisSize.min, children: [Text(currencyFlag(c), style: const TextStyle(fontSize: 16)), const SizedBox(width: 6), Text(c, style: const TextStyle(fontWeight: FontWeight.bold))]))).toList(),
                      onChanged: (v) => setState(() { _selectedCurrency = v!; _convertFromCode = null; }),
                      style: const TextStyle(color: _teal, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
            if (_amount > 0) ...[
              const SizedBox(height: 16),
              Consumer(builder: (context, ref, _) {
                final free = _isSameCurrencyTransfer;
                final sym = currencyToSymbol(_selectedCurrency);
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: free
                        ? Colors.green.withValues(alpha: 0.07)
                        : _teal.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: free
                            ? Colors.green.withValues(alpha: 0.3)
                            : _teal.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            free ? 'Fee' : 'Fee (0.5%)',
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          const Text('You will send',
                              style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          free
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('FREE',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          color: Colors.green)),
                                )
                              : Text('$sym${_fee.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(
                            '$sym${(_amount + _fee).toStringAsFixed(2)}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: free ? Colors.green : _teal),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
            // ── Cross-currency: show "Convert from" picker ────────────────
            Consumer(builder: (context, ref, _) {
              final wallets = ref.watch(walletCurrenciesProvider);
              final hasWallet = wallets.any((w) => w.code == _selectedCurrency);
              if (hasWallet || wallets.isEmpty || _amount <= 0) return const SizedBox.shrink();
              // User doesn't have this currency — let them pick which wallet to convert from
              final fromCode = _convertFromCode ?? wallets.first.code;
              if (_convertFromCode == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _convertFromCode = wallets.first.code);
                });
              }
              final fromSym = currencyToSymbol(fromCode);
              final rates = ref.read(exchangeRatesProvider).valueOrNull?.rates ?? fallbackRates;
              final debit = _convertedDebitAmountWith(rates);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text('Convert from', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Column(children: [
                      Row(children: [
                        const Icon(Icons.swap_horiz_rounded, color: Colors.orange, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          'You don\'t have a $_selectedCurrency wallet. Select a wallet to auto-convert from:',
                          style: const TextStyle(color: Colors.orange, fontSize: 12),
                        )),
                      ]),
                      const SizedBox(height: 10),
                      DropdownButtonHideUnderline(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                          ),
                          child: DropdownButton<String>(
                            value: fromCode,
                            isExpanded: true,
                            items: wallets.map((w) => DropdownMenuItem(
                              value: w.code,
                              child: Row(children: [
                                Text(currencyFlag(w.code), style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Text('${w.code} — ${w.symbol}${w.balance.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                              ]),
                            )).toList(),
                            onChanged: (v) => setState(() => _convertFromCode = v),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('You will be debited:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        Text('$fromSym${debit.toStringAsFixed(2)} $fromCode',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange)),
                      ]),
                    ]),
                  ),
                ],
              );
            }),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canContinue ? _onContinue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
