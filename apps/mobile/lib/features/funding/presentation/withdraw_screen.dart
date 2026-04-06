import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/locale_utils.dart';
import '../../wallet/presentation/wallet_screen.dart' show walletCurrenciesProvider, WalletCurrency;

// ── Banking system enum ───────────────────────────────────────────────────────

enum _BankSystem { uk, us, sepa, india, australia, canada, china, japan, africa, latam, generic }

_BankSystem _bankSystemFor(String currency) {
  switch (currency) {
    case 'GBP': return _BankSystem.uk;
    case 'USD': return _BankSystem.us;
    case 'CAD': return _BankSystem.canada;
    case 'EUR': case 'CHF': case 'SEK': case 'NOK': case 'DKK':
    case 'PLN': case 'CZK': case 'HUF': case 'RON': case 'BGN':
      return _BankSystem.sepa;
    case 'INR': case 'PKR': case 'BDT': case 'LKR': case 'NPR':
      return _BankSystem.india;
    case 'AUD': case 'NZD': return _BankSystem.australia;
    case 'CNY': return _BankSystem.china;
    case 'JPY': case 'KRW': case 'SGD': case 'HKD': case 'THB':
    case 'MYR': case 'PHP': case 'IDR': case 'VND': case 'TWD':
      return _BankSystem.generic;
    case 'NGN': case 'GHS': case 'KES': case 'ZAR': case 'UGX':
    case 'TZS': case 'XAF': case 'XOF': case 'ETB': case 'RWF':
    case 'ZMW': case 'MAD': case 'EGP': case 'AED': case 'SAR': case 'QAR':
      return _BankSystem.africa;
    case 'BRL': case 'ARS': case 'CLP': case 'COP': case 'PEN':
    case 'MXN': case 'UYU': case 'BOB': case 'VES':
      return _BankSystem.latam;
    default: return _BankSystem.generic;
  }
}

// ── UK Sort Code → Bank lookup ────────────────────────────────────────────────

class _UKBank {
  final String name;
  final Color color;
  final String initial;
  const _UKBank(this.name, this.color, this.initial);
}

const _ukBanks = <String, _UKBank>{
  '04': _UKBank('Clydesdale Bank', Color(0xFF1B5E8A), 'C'),
  '08': _UKBank('Co-operative Bank', Color(0xFF00967E), 'C'),
  '09': _UKBank('Nationwide', Color(0xFF005A9C), 'N'),
  '11': _UKBank('Halifax', Color(0xFF004B87), 'H'),
  '12': _UKBank('Bank of Scotland', Color(0xFF003087), 'B'),
  '14': _UKBank('Santander', Color(0xFFEC0000), 'S'),
  '16': _UKBank('Halifax', Color(0xFF004B87), 'H'),
  '18': _UKBank('Virgin Money', Color(0xFFE10A0A), 'V'),
  '20': _UKBank('Barclays', Color(0xFF00AEEF), 'B'),
  '23': _UKBank('Barclays', Color(0xFF00AEEF), 'B'),
  '26': _UKBank('Barclays', Color(0xFF00AEEF), 'B'),
  '30': _UKBank('Lloyds Bank', Color(0xFF006A4E), 'L'),
  '31': _UKBank('Lloyds Bank', Color(0xFF006A4E), 'L'),
  '32': _UKBank('Lloyds Bank', Color(0xFF006A4E), 'L'),
  '40': _UKBank('HSBC', Color(0xFFDB0011), 'H'),
  '41': _UKBank('HSBC', Color(0xFFDB0011), 'H'),
  '55': _UKBank('Metro Bank', Color(0xFFD50032), 'M'),
  '56': _UKBank('Metro Bank', Color(0xFFD50032), 'M'),
  '60': _UKBank('NatWest', Color(0xFF5B0C7D), 'N'),
  '61': _UKBank('NatWest', Color(0xFF5B0C7D), 'N'),
  '62': _UKBank('NatWest', Color(0xFF5B0C7D), 'N'),
  '63': _UKBank('NatWest', Color(0xFF5B0C7D), 'N'),
  '72': _UKBank('Monzo', Color(0xFFFF6B35), 'M'),
  '77': _UKBank('Santander', Color(0xFFEC0000), 'S'),
  '83': _UKBank('TSB', Color(0xFF006BB0), 'T'),
  '85': _UKBank('Nationwide', Color(0xFF005A9C), 'N'),
  '93': _UKBank('Starling Bank', Color(0xFF4D1078), 'S'),
};

_UKBank? _lookupSortCode(String sortCode) {
  final digits = sortCode.replaceAll('-', '').replaceAll(' ', '');
  if (digits.length < 2) return null;
  return _ukBanks[digits.substring(0, 2)];
}

// ── Withdraw Screen ───────────────────────────────────────────────────────────

class WithdrawScreen extends ConsumerStatefulWidget {
  const WithdrawScreen({super.key});
  @override
  ConsumerState<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends ConsumerState<WithdrawScreen> {
  int _selectedMethod = 0;
  bool _loading = false;
  final _amountCtrl = TextEditingController();
  late String _currency;

  @override
  void initState() {
    super.initState();
    _currency = detectLocaleCurrency();
  }
  String _mobileNetwork = 'M-Pesa';

  // Bank transfer field controllers
  final _nameCtrl       = TextEditingController();
  final _accountCtrl    = TextEditingController();
  final _sortCodeCtrl   = TextEditingController();
  final _routingCtrl    = TextEditingController();
  final _ibanCtrl       = TextEditingController();
  final _bicCtrl        = TextEditingController();
  final _ifscCtrl       = TextEditingController();
  final _bsbCtrl        = TextEditingController();
  final _transitCtrl    = TextEditingController();
  final _institutionCtrl= TextEditingController();
  final _bankNameCtrl   = TextEditingController();
  final _swiftCtrl      = TextEditingController();
  // Mobile Money
  final _phoneCtrl      = TextEditingController();
  // PayPal
  final _paypalCtrl     = TextEditingController();

  _UKBank? _detectedBank;

  static const _currencies = [
    'GBP', 'USD', 'EUR', 'CAD', 'AUD', 'NZD', 'CHF', 'JPY',
    'NGN', 'GHS', 'KES', 'ZAR', 'UGX', 'TZS', 'XAF', 'XOF', 'ETB', 'RWF', 'ZMW', 'MAD', 'EGP',
    'BRL', 'ARS', 'CLP', 'COP', 'PEN', 'MXN', 'UYU', 'BOB', 'VES',
    'INR', 'CNY', 'AED', 'SAR', 'QAR', 'PKR', 'BDT', 'PHP', 'IDR', 'MYR', 'SGD', 'THB', 'KRW', 'VND',
    'SEK', 'NOK', 'DKK', 'PLN', 'CZK', 'HUF', 'RON',
  ];

  final _methods = [
    _WMethod('Bank Transfer', Icons.account_balance_rounded, const Color(0xFF3B82F6)),
    _WMethod('Mobile Money',  Icons.phone_android_rounded,   const Color(0xFF10B981)),
    _WMethod('PayPal',        Icons.payment_rounded,          const Color(0xFF003087)),
  ];

  @override
  void dispose() {
    for (final c in [_amountCtrl, _nameCtrl, _accountCtrl, _sortCodeCtrl, _routingCtrl,
        _ibanCtrl, _bicCtrl, _ifscCtrl, _bsbCtrl, _transitCtrl, _institutionCtrl,
        _bankNameCtrl, _swiftCtrl, _phoneCtrl, _paypalCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: BackButton(color: AppColors.textPrimary),
        title: const Text('Withdraw Funds',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Withdraw from wallet selector ─────────────────────────────────
          const Text('Withdraw from', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          Consumer(builder: (context, ref, _) {
            final wallets = ref.watch(walletCurrenciesProvider);
            if (wallets.isEmpty) return const SizedBox.shrink();
            return SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: wallets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final w = wallets[i];
                  final sel = w.code == _currency;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _currency = w.code;
                      _detectedBank = null;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: sel ? AppColors.primary : AppColors.border,
                          width: sel ? 2 : 1,
                        ),
                        boxShadow: sel
                            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2),
                                blurRadius: 8, offset: const Offset(0, 2))]
                            : [],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${w.flag} ${w.code}',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                  color: sel ? Colors.white : AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          Text('${w.symbol}${w.balance.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 11,
                                  color: sel ? Colors.white70 : AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }),
          const SizedBox(height: 20),

          // Amount
          const Text('Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _amountCtrl,
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
                  items: _currencies.map((c) => DropdownMenuItem(
                    value: c,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(currencyFlag(c), style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(c, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ]),
                  )).toList(),
                  onChanged: (v) => setState(() { _currency = v!; _detectedBank = null; }),
                ),
              ),
            ]),
          ),

          // Quick amounts
          const SizedBox(height: 12),
          Row(children: ['50', '100', '250', '500'].map((a) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _amountCtrl.text = a),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface, borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text('+$a', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
              ),
            ),
          )).toList()),

          const SizedBox(height: 24),
          const Text('Withdraw to', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),

          // Method tabs
          Row(children: List.generate(_methods.length, (i) {
            final m = _methods[i];
            final sel = i == _selectedMethod;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedMethod = i),
                child: Container(
                  margin: EdgeInsets.only(right: i < _methods.length - 1 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary.withValues(alpha: 0.08) : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sel ? AppColors.primary : AppColors.border, width: sel ? 2 : 1),
                  ),
                  child: Column(children: [
                    Icon(m.icon, color: sel ? AppColors.primary : AppColors.textSecondary, size: 22),
                    const SizedBox(height: 4),
                    Text(m.name, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                        color: sel ? AppColors.primary : AppColors.textSecondary), textAlign: TextAlign.center),
                  ]),
                ),
              ),
            );
          })),

          const SizedBox(height: 20),

          // Dynamic form
          if (_selectedMethod == 0) _buildBankTransferForm()
          else if (_selectedMethod == 1) _buildMobileMoneyForm()
          else _buildPayPalForm(),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                : const Text('Withdraw Instantly'),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  // ── Bank transfer form — dynamic by currency ────────────────────────────────

  Widget _buildBankTransferForm() {
    final system = _bankSystemFor(_currency);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Banking system label
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: Text(_bankSystemLabel(system),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
      ),

      // Always show account holder name
      _field('Account Holder Name', 'Full legal name', _nameCtrl, Icons.person_outline_rounded),
      const SizedBox(height: 12),

      // System-specific fields
      if (system == _BankSystem.uk) ..._buildUKFields()
      else if (system == _BankSystem.us) ..._buildUSFields()
      else if (system == _BankSystem.sepa) ..._buildSEPAFields()
      else if (system == _BankSystem.india) ..._buildIndiaFields()
      else if (system == _BankSystem.australia) ..._buildAustraliaFields()
      else if (system == _BankSystem.canada) ..._buildCanadaFields()
      else if (system == _BankSystem.china) ..._buildChinaFields()
      else ..._buildGenericFields(),

      const SizedBox(height: 12),
      _instantBadge('Withdrawals are processed instantly via secure bank transfer.'),
    ]);
  }

  List<Widget> _buildUKFields() => [
    _field('Account Number', '8-digit account number', _accountCtrl, Icons.numbers_rounded,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
        keyboardType: TextInputType.number),
    const SizedBox(height: 12),
    // Sort code with bank detection
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Sort Code', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      const SizedBox(height: 6),
      TextField(
        controller: _sortCodeCtrl,
        keyboardType: TextInputType.number,
        inputFormatters: [_SortCodeFormatter()],
        maxLength: 8, // "XX-XX-XX"
        decoration: const InputDecoration(
          hintText: 'XX-XX-XX',
          prefixIcon: Icon(Icons.tag_rounded, color: AppColors.textSecondary, size: 20),
          counterText: '',
        ),
        onChanged: (v) {
          setState(() => _detectedBank = _lookupSortCode(v));
        },
      ),
      if (_detectedBank != null) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _detectedBank!.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _detectedBank!.color.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: _detectedBank!.color, borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: Text(_detectedBank!.initial,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_detectedBank!.name,
                  style: TextStyle(fontWeight: FontWeight.w700, color: _detectedBank!.color, fontSize: 13)),
              const Text('Bank detected from sort code',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ])),
            Icon(Icons.check_circle_rounded, color: _detectedBank!.color, size: 20),
          ]),
        ),
      ],
    ]),
  ];

  List<Widget> _buildUSFields() => [
    _field('Routing Number (ABA)', '9-digit routing number', _routingCtrl, Icons.route_rounded,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
        keyboardType: TextInputType.number),
    const SizedBox(height: 12),
    _field('Account Number', 'Checking or savings account', _accountCtrl, Icons.numbers_rounded,
        keyboardType: TextInputType.number),
  ];

  List<Widget> _buildSEPAFields() => [
    _field('IBAN', 'e.g. GB29 NWBK 6016 1331 9268 19', _ibanCtrl, Icons.credit_card_rounded),
    const SizedBox(height: 12),
    _field('BIC / SWIFT Code', 'e.g. NWBKGB2L', _bicCtrl, Icons.code_rounded),
  ];

  List<Widget> _buildIndiaFields() => [
    _field('IFSC Code', 'e.g. SBIN0001234', _ifscCtrl, Icons.code_rounded,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')), LengthLimitingTextInputFormatter(11)]),
    const SizedBox(height: 12),
    _field('Account Number', 'Bank account number', _accountCtrl, Icons.numbers_rounded,
        keyboardType: TextInputType.number),
  ];

  List<Widget> _buildAustraliaFields() => [
    _field('BSB Number', 'XXX-XXX', _bsbCtrl, Icons.route_rounded,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
        keyboardType: TextInputType.number),
    const SizedBox(height: 12),
    _field('Account Number', 'Bank account number', _accountCtrl, Icons.numbers_rounded,
        keyboardType: TextInputType.number),
  ];

  List<Widget> _buildCanadaFields() => [
    _field('Transit Number', '5-digit transit number', _transitCtrl, Icons.route_rounded,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)],
        keyboardType: TextInputType.number),
    const SizedBox(height: 12),
    _field('Institution Number', '3-digit bank code', _institutionCtrl, Icons.account_balance_outlined,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
        keyboardType: TextInputType.number),
    const SizedBox(height: 12),
    _field('Account Number', 'Bank account number', _accountCtrl, Icons.numbers_rounded,
        keyboardType: TextInputType.number),
  ];

  List<Widget> _buildChinaFields() => [
    _field('Bank Name', 'e.g. Industrial and Commercial Bank', _bankNameCtrl, Icons.account_balance_outlined),
    const SizedBox(height: 12),
    _field('Card / Account Number', '16–19 digit card number', _accountCtrl, Icons.numbers_rounded,
        keyboardType: TextInputType.number),
  ];

  List<Widget> _buildGenericFields() => [
    _field('Bank Name', 'Full name of bank', _bankNameCtrl, Icons.account_balance_outlined),
    const SizedBox(height: 12),
    _field('Account Number', 'Bank account number', _accountCtrl, Icons.numbers_rounded,
        keyboardType: TextInputType.number),
    const SizedBox(height: 12),
    _field('SWIFT / BIC Code (optional)', 'e.g. GTBINGLA', _swiftCtrl, Icons.code_rounded),
  ];

  // ── Mobile Money form ────────────────────────────────────────────────────────

  Widget _buildMobileMoneyForm() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Network', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
    const SizedBox(height: 8),
    Wrap(spacing: 8, children: ['M-Pesa', 'MTN MoMo', 'Airtel Money', 'Tigo Cash', 'Orange Money', 'Wave', 'EcoCash', 'Paga'].map((n) =>
      GestureDetector(
        onTap: () => setState(() => _mobileNetwork = n),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _mobileNetwork == n ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _mobileNetwork == n ? AppColors.primary : AppColors.border),
          ),
          child: Text(n, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: _mobileNetwork == n ? Colors.white : AppColors.textPrimary)),
        ),
      ),
    ).toList()),
    const SizedBox(height: 12),
    _field('Phone Number', '+254 7XX XXX XXX', _phoneCtrl, Icons.phone_outlined,
        keyboardType: TextInputType.phone),
    const SizedBox(height: 12),
    _instantBadge('Mobile money is delivered instantly. Available in 30+ countries.'),
  ]);

  // ── PayPal form ──────────────────────────────────────────────────────────────

  Widget _buildPayPalForm() => Column(children: [
    _field('PayPal Email', 'your@paypal.com', _paypalCtrl, Icons.email_outlined,
        keyboardType: TextInputType.emailAddress),
    const SizedBox(height: 12),
    _instantBadge('PayPal withdrawals appear in your balance immediately.'),
  ]);

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _bankSystemLabel(_BankSystem s) {
    switch (s) {
      case _BankSystem.uk:        return '🇬🇧 UK Faster Payments (Sort Code)';
      case _BankSystem.us:        return '🇺🇸 US ACH Transfer (Routing + Account)';
      case _BankSystem.sepa:      return '🇪🇺 SEPA Transfer (IBAN + BIC)';
      case _BankSystem.india:     return '🇮🇳 NEFT / IMPS (IFSC)';
      case _BankSystem.australia: return '🇦🇺 BECS Transfer (BSB)';
      case _BankSystem.canada:    return '🇨🇦 EFT Transfer (Transit + Institution)';
      case _BankSystem.china:     return '🇨🇳 UnionPay / CNAPS';
      case _BankSystem.africa:    return '🌍 Local Bank Transfer';
      case _BankSystem.latam:     return '🌎 Local Bank Transfer';
      case _BankSystem.generic:   return '🌐 International Bank Transfer';
      default:                    return '🌐 Bank Transfer';
    }
  }

  Widget _instantBadge(String msg) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.success.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.bolt_rounded, color: AppColors.success, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: const TextStyle(fontSize: 12, color: AppColors.success))),
    ]),
  );

  Widget _field(String label, String hint, TextEditingController ctrl, IconData icon, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        ),
      ),
    ]);

  void _submit() {
    final amt = double.tryParse(_amountCtrl.text);
    if (amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Withdrawal', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _ReviewRow('Amount', '$_currency ${_amountCtrl.text}'),
          _ReviewRow('Method', _methods[_selectedMethod].name),
          if (_selectedMethod == 0 && _detectedBank != null)
            _ReviewRow('Bank', _detectedBank!.name),
          _ReviewRow('Fee', 'Free'),
          _ReviewRow('Processing', 'Instant ⚡'),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _loading = true);
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (!mounted) return;
                setState(() => _loading = false);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('$_currency ${_amountCtrl.text} withdrawn instantly! ⚡'),
                  backgroundColor: AppColors.success,
                ));
                Navigator.pop(context);
              });
            },
            child: const Text('Confirm & Withdraw'),
          ),
        ],
      ),
    );
  }
}

// ── Sort Code Formatter ───────────────────────────────────────────────────────

class _SortCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 6) return old;
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 2 || i == 4) buf.write('-');
      buf.write(digits[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

// ── Models ────────────────────────────────────────────────────────────────────

class _ReviewRow extends StatelessWidget {
  final String label, value;
  const _ReviewRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
    ]),
  );
}

class _WMethod {
  final String name;
  final IconData icon;
  final Color color;
  const _WMethod(this.name, this.icon, this.color);
}
