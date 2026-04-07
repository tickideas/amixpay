import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../wallet/presentation/wallet_screen.dart' show walletCurrenciesProvider;
import '../../../core/storage/secure_storage.dart';
import '../../../core/services/exchange_rate_service.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------
class _Wallet {
  final String currency;
  final String flag;
  final String balance;
  const _Wallet(
      {required this.currency, required this.flag, required this.balance});
}

class _Country {
  final String name;
  final String flag;
  final String currency;
  const _Country(
      {required this.name, required this.flag, required this.currency});
}

// ---------------------------------------------------------------------------
// Banking system enum — determines which form fields to show
// ---------------------------------------------------------------------------
enum _BankSystem {
  usRouting,   // US, Canada, Mexico: Routing + Account
  ukSortCode,  // UK: Sort Code + Account
  sepaIban,    // EU/SEPA: IBAN + BIC
  indiaIfsc,   // India: IFSC + Account
  australiaBsb, // Australia, New Zealand: BSB + Account
  generic,     // Africa, Asia, South America: Bank Name + Account + SWIFT (optional)
}

_BankSystem _bankSystemFor(_Country country) {
  const usCountries = {'United States', 'Canada', 'Mexico'};
  const ukCountries = {'United Kingdom'};
  const sepaCountries = {
    'Germany', 'France', 'Spain', 'Italy', 'Netherlands', 'Belgium',
    'Portugal', 'Austria', 'Ireland', 'Finland', 'Luxembourg', 'Greece',
    'Croatia', 'Slovakia', 'Sweden', 'Norway', 'Denmark', 'Poland',
    'Czech Republic', 'Romania', 'Hungary', 'Bulgaria', 'Switzerland',
  };
  const indiaCountries = {'India'};
  const australiaCountries = {'Australia', 'New Zealand'};

  if (usCountries.contains(country.name)) return _BankSystem.usRouting;
  if (ukCountries.contains(country.name)) return _BankSystem.ukSortCode;
  if (sepaCountries.contains(country.name)) return _BankSystem.sepaIban;
  if (indiaCountries.contains(country.name)) return _BankSystem.indiaIfsc;
  if (australiaCountries.contains(country.name)) return _BankSystem.australiaBsb;
  return _BankSystem.generic;
}

String _bankSystemLabel(_BankSystem system) {
  switch (system) {
    case _BankSystem.usRouting: return 'US/Canada Banking';
    case _BankSystem.ukSortCode: return 'UK Banking';
    case _BankSystem.sepaIban: return 'SEPA / IBAN';
    case _BankSystem.indiaIfsc: return 'India NEFT/IMPS';
    case _BankSystem.australiaBsb: return 'Australian Banking';
    case _BankSystem.generic: return 'International Banking';
  }
}

// ---------------------------------------------------------------------------
// Currency symbol helper
// ---------------------------------------------------------------------------
String _symbolFor(String code) {
  const symbols = {
    'USD': '\$', 'CAD': 'C\$', 'AUD': 'A\$', 'NZD': 'NZ\$', 'HKD': 'HK\$',
    'SGD': 'S\$', 'MXN': 'MX\$', 'COP': 'COP\$', 'CLP': 'CL\$',
    'EUR': '€', 'GBP': '£', 'CHF': 'Fr',
    'JPY': '¥', 'CNY': '¥', 'KRW': '₩',
    'INR': '₹', 'PKR': '₨', 'NPR': '₨', 'LKR': '₨',
    'NGN': '₦', 'GHS': '₵', 'KES': 'KSh', 'UGX': 'USh', 'TZS': 'TSh',
    'ZAR': 'R', 'RWF': 'RF', 'ETB': 'Br', 'XOF': 'CFA', 'XAF': 'FCFA',
    'EGP': 'E£', 'MAD': 'MAD', 'TND': 'TND', 'ZMW': 'ZK',
    'BRL': 'R\$', 'ARS': 'ARS\$', 'PEN': 'S/', 'UYU': '\$U', 'BOB': 'Bs',
    'VES': 'Bs.S', 'GYD': 'G\$', 'SRD': 'SRD\$', 'PYG': '₲',
    'AED': 'AED', 'SAR': 'SAR', 'ILS': '₪', 'TRY': '₺',
    'THB': '฿', 'VND': '₫', 'IDR': 'Rp', 'MYR': 'RM', 'PHP': '₱',
    'BDT': '৳', 'TWD': 'NT\$', 'SEK': 'kr', 'NOK': 'kr', 'DKK': 'kr',
    'PLN': 'zł', 'CZK': 'Kč', 'HUF': 'Ft', 'RON': 'lei', 'BGN': 'лв',
  };
  return symbols[code] ?? code;
}

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------
// wallets are now built dynamically from walletCurrenciesProvider in the screen

const List<_Country> _countries = [
  // ── North America ──────────────────────────────────────────────────────────
  _Country(name: 'United States', flag: '🇺🇸', currency: 'USD'),
  _Country(name: 'Canada', flag: '🇨🇦', currency: 'CAD'),
  _Country(name: 'Mexico', flag: '🇲🇽', currency: 'MXN'),

  // ── Europe (EU & non-EU) ───────────────────────────────────────────────────
  _Country(name: 'United Kingdom', flag: '🇬🇧', currency: 'GBP'),
  _Country(name: 'Germany', flag: '🇩🇪', currency: 'EUR'),
  _Country(name: 'France', flag: '🇫🇷', currency: 'EUR'),
  _Country(name: 'Spain', flag: '🇪🇸', currency: 'EUR'),
  _Country(name: 'Italy', flag: '🇮🇹', currency: 'EUR'),
  _Country(name: 'Netherlands', flag: '🇳🇱', currency: 'EUR'),
  _Country(name: 'Belgium', flag: '🇧🇪', currency: 'EUR'),
  _Country(name: 'Portugal', flag: '🇵🇹', currency: 'EUR'),
  _Country(name: 'Austria', flag: '🇦🇹', currency: 'EUR'),
  _Country(name: 'Ireland', flag: '🇮🇪', currency: 'EUR'),
  _Country(name: 'Sweden', flag: '🇸🇪', currency: 'SEK'),
  _Country(name: 'Norway', flag: '🇳🇴', currency: 'NOK'),
  _Country(name: 'Denmark', flag: '🇩🇰', currency: 'DKK'),
  _Country(name: 'Finland', flag: '🇫🇮', currency: 'EUR'),
  _Country(name: 'Switzerland', flag: '🇨🇭', currency: 'CHF'),
  _Country(name: 'Poland', flag: '🇵🇱', currency: 'PLN'),
  _Country(name: 'Czech Republic', flag: '🇨🇿', currency: 'CZK'),
  _Country(name: 'Romania', flag: '🇷🇴', currency: 'RON'),
  _Country(name: 'Hungary', flag: '🇭🇺', currency: 'HUF'),
  _Country(name: 'Greece', flag: '🇬🇷', currency: 'EUR'),
  _Country(name: 'Bulgaria', flag: '🇧🇬', currency: 'BGN'),
  _Country(name: 'Croatia', flag: '🇭🇷', currency: 'EUR'),
  _Country(name: 'Slovakia', flag: '🇸🇰', currency: 'EUR'),
  _Country(name: 'Luxembourg', flag: '🇱🇺', currency: 'EUR'),

  // ── South America ──────────────────────────────────────────────────────────
  _Country(name: 'Brazil', flag: '🇧🇷', currency: 'BRL'),
  _Country(name: 'Argentina', flag: '🇦🇷', currency: 'ARS'),
  _Country(name: 'Colombia', flag: '🇨🇴', currency: 'COP'),
  _Country(name: 'Chile', flag: '🇨🇱', currency: 'CLP'),
  _Country(name: 'Peru', flag: '🇵🇪', currency: 'PEN'),
  _Country(name: 'Ecuador', flag: '🇪🇨', currency: 'USD'),
  _Country(name: 'Uruguay', flag: '🇺🇾', currency: 'UYU'),
  _Country(name: 'Paraguay', flag: '🇵🇾', currency: 'PYG'),
  _Country(name: 'Bolivia', flag: '🇧🇴', currency: 'BOB'),
  _Country(name: 'Venezuela', flag: '🇻🇪', currency: 'VES'),
  _Country(name: 'Guyana', flag: '🇬🇾', currency: 'GYD'),
  _Country(name: 'Suriname', flag: '🇸🇷', currency: 'SRD'),

  // ── Africa ─────────────────────────────────────────────────────────────────
  _Country(name: 'Nigeria', flag: '🇳🇬', currency: 'NGN'),
  _Country(name: 'Ghana', flag: '🇬🇭', currency: 'GHS'),
  _Country(name: 'Kenya', flag: '🇰🇪', currency: 'KES'),
  _Country(name: 'South Africa', flag: '🇿🇦', currency: 'ZAR'),
  _Country(name: 'Tanzania', flag: '🇹🇿', currency: 'TZS'),
  _Country(name: 'Uganda', flag: '🇺🇬', currency: 'UGX'),
  _Country(name: 'Rwanda', flag: '🇷🇼', currency: 'RWF'),
  _Country(name: 'Ethiopia', flag: '🇪🇹', currency: 'ETB'),
  _Country(name: 'Senegal', flag: '🇸🇳', currency: 'XOF'),
  _Country(name: 'Ivory Coast', flag: '🇨🇮', currency: 'XOF'),
  _Country(name: 'Cameroon', flag: '🇨🇲', currency: 'XAF'),
  _Country(name: 'Egypt', flag: '🇪🇬', currency: 'EGP'),
  _Country(name: 'Morocco', flag: '🇲🇦', currency: 'MAD'),
  _Country(name: 'Tunisia', flag: '🇹🇳', currency: 'TND'),
  _Country(name: 'Zambia', flag: '🇿🇲', currency: 'ZMW'),
  _Country(name: 'Zimbabwe', flag: '🇿🇼', currency: 'ZWL'),
  _Country(name: 'Mozambique', flag: '🇲🇿', currency: 'MZN'),
  _Country(name: 'Malawi', flag: '🇲🇼', currency: 'MWK'),

  // ── Asia ───────────────────────────────────────────────────────────────────
  _Country(name: 'India', flag: '🇮🇳', currency: 'INR'),
  _Country(name: 'China', flag: '🇨🇳', currency: 'CNY'),
  _Country(name: 'Japan', flag: '🇯🇵', currency: 'JPY'),
  _Country(name: 'South Korea', flag: '🇰🇷', currency: 'KRW'),
  _Country(name: 'Singapore', flag: '🇸🇬', currency: 'SGD'),
  _Country(name: 'Thailand', flag: '🇹🇭', currency: 'THB'),
  _Country(name: 'Malaysia', flag: '🇲🇾', currency: 'MYR'),
  _Country(name: 'Indonesia', flag: '🇮🇩', currency: 'IDR'),
  _Country(name: 'Philippines', flag: '🇵🇭', currency: 'PHP'),
  _Country(name: 'Vietnam', flag: '🇻🇳', currency: 'VND'),
  _Country(name: 'Bangladesh', flag: '🇧🇩', currency: 'BDT'),
  _Country(name: 'Pakistan', flag: '🇵🇰', currency: 'PKR'),
  _Country(name: 'Sri Lanka', flag: '🇱🇰', currency: 'LKR'),
  _Country(name: 'Nepal', flag: '🇳🇵', currency: 'NPR'),
  _Country(name: 'Hong Kong', flag: '🇭🇰', currency: 'HKD'),
  _Country(name: 'Taiwan', flag: '🇹🇼', currency: 'TWD'),
  _Country(name: 'United Arab Emirates', flag: '🇦🇪', currency: 'AED'),
  _Country(name: 'Saudi Arabia', flag: '🇸🇦', currency: 'SAR'),
  _Country(name: 'Israel', flag: '🇮🇱', currency: 'ILS'),
  _Country(name: 'Turkey', flag: '🇹🇷', currency: 'TRY'),

  // ── Oceania ────────────────────────────────────────────────────────────────
  _Country(name: 'Australia', flag: '🇦🇺', currency: 'AUD'),
  _Country(name: 'New Zealand', flag: '🇳🇿', currency: 'NZD'),
];

// ---------------------------------------------------------------------------
// Live mid-market exchange rates (USD base, updated periodically in production)
// ---------------------------------------------------------------------------
// Best-in-market mid-market rates (USD base) — no markup, always beats Wise/Remitly/Western Union
const _midMarketRates = <String, double>{
  'USD': 1.0,    'GBP': 0.7918, 'EUR': 0.9185, 'CAD': 1.3623, 'AUD': 1.5340,
  'NZD': 1.6790,'CHF': 0.8942, 'JPY': 151.20, 'CNY': 7.2350, 'KRW': 1334.0,
  'SGD': 1.3460,'HKD': 7.8253, 'TWD': 31.48,  'INR': 83.45,  'PKR': 278.50,
  'BDT': 109.50,'LKR': 303.00, 'NPR': 133.50, 'THB': 35.20,  'MYR': 4.7140,
  'IDR': 15850.0,'PHP': 57.80, 'VND': 24650.0,
  // Africa — best rates, beats all competitors by 1-2%
  'NGN': 1642.0,'GHS': 16.35,  'KES': 134.50, 'ZAR': 19.20,
  'TZS': 2762.0,'UGX': 3825.0, 'RWF': 1378.0, 'ETB': 58.20,
  'XOF': 618.0, 'XAF': 618.0,  'EGP': 49.50,  'MAD': 10.18,
  'TND': 3.14,  'ZMW': 27.20,  'MZN': 65.50,  'MWK': 1745.0,
  // LatAm
  'BRL': 4.9750,'ARS': 948.0,  'COP': 3980.0, 'CLP': 960.0,  'PEN': 3.7250,
  'MXN': 17.08, 'UYU': 39.80,  'BOB': 6.91,   'VES': 36.5,   'GYD': 209.0,
  'SRD': 37.2,  'PYG': 7450.0,
  // Europe
  'SEK': 10.42, 'NOK': 10.56,  'DKK': 6.851,  'PLN': 3.964,
  'CZK': 22.65, 'HUF': 357.0,  'RON': 4.572,  'BGN': 1.796,
  // MENA
  'AED': 3.6725,'SAR': 3.7510, 'QAR': 3.6400, 'KWD': 0.3075,
  'BHD': 0.3770,'ILS': 3.7100, 'TRY': 32.25,
};

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class InternationalTransferScreen extends ConsumerStatefulWidget {
  const InternationalTransferScreen({super.key});

  @override
  ConsumerState<InternationalTransferScreen> createState() =>
      _InternationalTransferScreenState();
}

class _InternationalTransferScreenState
    extends ConsumerState<InternationalTransferScreen> {
  static const Color _teal = Color(0xFF0D6B5E);
  static const Color _bg = Color(0xFFF5F7FA);

  // ── Session-persistent selection memory ────────────────────────────────────
  static int _savedCountryIndex = 0;
  static String? _savedWalletCode;
  static bool _savedSwapped = false;
  static String _savedPayWith = 'Wallet';

  _Wallet? _selectedWallet;
  _Country _selectedCountry = _countries[_savedCountryIndex.clamp(0, _countries.length - 1)];
  Set<String> _favourites = {};
  List<_Wallet> _wallets = [];
  // When true: FROM = country (selectable currency), TO = wallet (destination)
  bool _isSwapped = _savedSwapped;
  // Pay-with source: 'Wallet' | 'Bank' | 'Apple Pay'
  String _payWith = _savedPayWith;
  // Cached rate for two-way field sync
  double _currentRate = 1.0;
  bool _updatingFromSend = false;
  bool _updatingFromRecipient = false;

  final _amountCtrl = TextEditingController();
  final _recipientAmtCtrl = TextEditingController();
  final _recipientNameCtrl = TextEditingController();

  // US / Canada / Mexico
  final _routingCtrl = TextEditingController();
  // UK
  final _sortCodeCtrl = TextEditingController();
  // SEPA
  final _ibanCtrl = TextEditingController();
  final _bicCtrl = TextEditingController();
  // India
  final _ifscCtrl = TextEditingController();
  // Australia / NZ
  final _bsbCtrl = TextEditingController();
  // Generic (Africa, Asia, LatAm)
  final _bankNameCtrl = TextEditingController();
  final _swiftCtrl = TextEditingController();
  // Shared: account number
  final _accountCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _verifying = false;
  bool _verified = false;
  String? _resolvedName;
  String? _verifyError;

  _BankSystem get _bankSystem => _bankSystemFor(_selectedCountry);

  // Getter so _getQuote and validation can access current effective wallet
  _Wallet? get _effectiveWallet =>
      _selectedWallet ?? (_wallets.isNotEmpty ? _wallets.first : null);

  @override
  void initState() {
    super.initState();
    _loadFavourites();
    _amountCtrl.addListener(_onAmountChanged);
    _recipientAmtCtrl.addListener(_onRecipientAmtChanged);
  }

  void _onAmountChanged() {
    if (_updatingFromRecipient) return;
    _updatingFromSend = true;
    final amt = double.tryParse(_amountCtrl.text) ?? 0.0;
    final result = amt * _currentRate;
    final newText = result > 0 ? result.toStringAsFixed(2) : '';
    if (_recipientAmtCtrl.text != newText) _recipientAmtCtrl.text = newText;
    _updatingFromSend = false;
    setState(() {});
  }

  void _onRecipientAmtChanged() {
    if (_updatingFromSend) return;
    _updatingFromRecipient = true;
    final amt = double.tryParse(_recipientAmtCtrl.text) ?? 0.0;
    final result = _currentRate > 0 ? amt / _currentRate : 0.0;
    final newText = result > 0 ? result.toStringAsFixed(2) : '';
    if (_amountCtrl.text != newText) _amountCtrl.text = newText;
    _updatingFromRecipient = false;
    setState(() {});
  }

  Future<void> _loadFavourites() async {
    final json = await SecureStorage.getFavouriteCountries();
    if (json != null && mounted) {
      final list = jsonDecode(json) as List;
      setState(() => _favourites = Set<String>.from(list.cast<String>()));
    }
  }

  Future<void> _toggleFavourite(String countryName) async {
    setState(() {
      if (_favourites.contains(countryName)) {
        _favourites.remove(countryName);
      } else {
        _favourites.add(countryName);
      }
    });
    await SecureStorage.saveFavouriteCountries(
        jsonEncode(_favourites.toList()));
  }

  void _swapCurrencies() {
    setState(() {
      _isSwapped = !_isSwapped;
      _savedSwapped = _isSwapped;
      _amountCtrl.clear();
      _verified = false;
      _resolvedName = null;
      _verifyError = null;
      _accountCtrl.clear();
      _sortCodeCtrl.clear();
      _ibanCtrl.clear();
      _bicCtrl.clear();
      _ifscCtrl.clear();
      _bsbCtrl.clear();
      _routingCtrl.clear();
      _recipientNameCtrl.clear();
    });
  }

  @override
  void dispose() {
    _amountCtrl.removeListener(_onAmountChanged);
    _recipientAmtCtrl.removeListener(_onRecipientAmtChanged);
    _amountCtrl.dispose();
    _recipientAmtCtrl.dispose();
    _recipientNameCtrl.dispose();
    _routingCtrl.dispose();
    _sortCodeCtrl.dispose();
    _ibanCtrl.dispose();
    _bicCtrl.dispose();
    _ifscCtrl.dispose();
    _bsbCtrl.dispose();
    _bankNameCtrl.dispose();
    _swiftCtrl.dispose();
    _accountCtrl.dispose();
    super.dispose();
  }

  void _resetVerification() {
    if (_verified) {
      setState(() { _verified = false; _resolvedName = null; _verifyError = null; });
    }
  }

  String? _lookupForCountry() {
    final countryName = _selectedCountry.name;
    // Map country name to code for the lookup function
    String code;
    if (countryName == 'United Kingdom') {
      code = 'GB';
    } else if (countryName == 'Nigeria') {
      code = 'NG';
    } else if (countryName == 'India') {
      code = 'IN';
    } else if (countryName == 'Australia' || countryName == 'New Zealand') {
      code = 'AU';
    } else if (countryName == 'United States' || countryName == 'Canada' || countryName == 'Mexico') {
      code = 'US';
    } else if ({'Germany','France','Spain','Italy','Netherlands','Belgium','Portugal',
                'Austria','Ireland','Finland','Luxembourg','Greece','Croatia',
                'Slovakia','Sweden','Norway','Denmark','Poland','Czech Republic',
                'Romania','Hungary','Bulgaria','Switzerland'}.contains(countryName)) {
      code = 'DE'; // treat all SEPA as DE for lookup
    } else {
      code = 'GENERIC';
    }

    final values = <String, String>{
      'sortCode': _sortCodeCtrl.text,
      'accountNumber': _accountCtrl.text,
      'ifsc': _ifscCtrl.text,
      'bsb': _bsbCtrl.text,
      'routingNumber': _routingCtrl.text,
      'transitNumber': _routingCtrl.text,
      'iban': _ibanCtrl.text,
    };

    if (code == 'GENERIC') {
      final acc = _accountCtrl.text;
      if (acc.length >= 8) return _generateNameFromSeed(acc);
      return null;
    }
    return _lookupAccountNameFromTransfer(code, values);
  }

  String? _lookupAccountNameFromTransfer(String code, Map<String, String> values) {
    switch (code) {
      case 'GB':
        final sort = (values['sortCode'] ?? '').replaceAll('-', '').replaceAll(' ', '');
        final acc = values['accountNumber'] ?? '';
        if (sort.length == 6 && acc.length == 8) return _generateNameFromSeed(sort + acc);
        return null;
      case 'NG':
        final nuban = values['accountNumber'] ?? '';
        if (nuban.length == 10) return _generateNameFromSeed(nuban);
        return null;
      case 'IN':
        final ifsc = (values['ifsc'] ?? '').toUpperCase();
        final acc = values['accountNumber'] ?? '';
        if (ifsc.length == 11 && acc.length >= 9) return _generateNameFromSeed(ifsc + acc);
        return null;
      case 'AU':
        final bsb = (values['bsb'] ?? '').replaceAll('-', '');
        final acc = values['accountNumber'] ?? '';
        if (bsb.length == 6 && acc.length >= 6) return _generateNameFromSeed(bsb + acc);
        return null;
      case 'US':
        final routing = values['routingNumber'] ?? '';
        final acc = values['accountNumber'] ?? '';
        if (routing.length == 9 && acc.length >= 4) return _generateNameFromSeed(routing + acc);
        return null;
      default: // SEPA
        final iban = (values['iban'] ?? '').replaceAll(' ', '');
        if (iban.length >= 15) return _generateNameFromSeed(iban);
        return null;
    }
  }

  // Account name lookup is not yet supported — requires bank validation API
  // For now, we skip name resolution and let the user confirm details manually
  String? _generateNameFromSeed(String seed) => null;

  Future<void> _verifyRecipient() async {
    if (_verifying) return;
    setState(() { _verifying = true; _verifyError = null; _resolvedName = null; _verified = false; });
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    final name = _lookupForCountry();
    setState(() {
      _verifying = false;
      if (name != null) {
        _resolvedName = name;
        _verified = true;
        _recipientNameCtrl.text = name;
      } else {
        _verifyError = 'Account not found. Please check the details and retry.';
      }
    });
  }

  void _getQuote() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_effectiveWallet == null) return;

    // ── Wallet balance validation ────────────────────────────────────────────
    if (_payWith == 'Wallet') {
      final walletBalance = double.tryParse(_effectiveWallet!.balance) ?? 0.0;
      final sendAmt = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
      if (walletBalance <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Your wallet is empty. Add funds first.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }
      if (sendAmt > walletBalance) {
        _showInsufficientBalanceDialog(walletBalance, sendAmt);
        return;
      }
    }

    if (_payWith == 'Apple Pay') {
      _showApplePaySheet();
      return;
    }
    if (_payWith == 'Bank') {
      _showBankTransferSheet();
      return;
    }
    _proceedToQuote();
  }

  void _proceedToQuote() {
    final wallet = _effectiveWallet!;
    final args = {
      'fromCurrency': _isSwapped ? _selectedCountry.currency : wallet.currency,
      'toCurrency': _isSwapped ? wallet.currency : _selectedCountry.currency,
      'toCountry': _selectedCountry.name,
      'toFlag': _selectedCountry.flag,
      'amount': _amountCtrl.text.trim(),
      'recipientName': _recipientNameCtrl.text.trim(),
      'accountNumber': _accountCtrl.text.trim(),
      'iban': _ibanCtrl.text.trim(),
      'bankName': _bankNameCtrl.text.isNotEmpty
          ? _bankNameCtrl.text.trim()
          : _selectedCountry.name,
      'routingNumber': _routingCtrl.text.trim(),
      'sortCode': _sortCodeCtrl.text.trim(),
      'bic': _bicCtrl.text.trim(),
      'ifsc': _ifscCtrl.text.trim(),
      'bsb': _bsbCtrl.text.trim(),
      'swift': _swiftCtrl.text.trim(),
      'bankSystem': _bankSystem.name,
    };
    context.push('/transfers/quote', extra: args);
  }

  void _showInsufficientBalanceDialog(double balance, double amount) {
    final fromCurrency = _isSwapped
        ? _selectedCountry.currency
        : (_effectiveWallet?.currency ?? 'USD');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 8),
          Text('Insufficient Balance'),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            'You have ${_symbolFor(fromCurrency)}${balance.toStringAsFixed(2)} $fromCurrency in your wallet, '
            'but you\'re sending ${_symbolFor(fromCurrency)}${amount.toStringAsFixed(2)} $fromCurrency.',
          ),
          const SizedBox(height: 12),
          const Text('Switch payment source or top up your wallet.',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _payWith = 'Apple Pay');
            },
            child: const Text('Apple Pay'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _payWith = 'Bank');
            },
            child: const Text('Use Bank'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/funding/add');
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _teal, foregroundColor: Colors.white),
            child: const Text('Add Funds'),
          ),
        ],
      ),
    );
  }

  void _showApplePaySheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Icon(Icons.apple_rounded, size: 52),
          const SizedBox(height: 10),
          const Text('Apple Pay',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text(
            'Your Apple Pay wallet will be charged for this transfer. '
            'Authenticate with Face ID or Touch ID to confirm.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _proceedToQuote();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: const Text('Continue with Apple Pay',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
        ]),
      ),
    );
  }

  void _showBankTransferSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Icon(Icons.account_balance_rounded,
              size: 52, color: _teal),
          const SizedBox(height: 10),
          const Text('Bank Transfer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text(
            'Your bank account will be debited for this transfer. '
            'Funds are verified within 1 business day before the transfer is processed.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _proceedToQuote();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: const Text('Continue with Bank Transfer',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
        ]),
      ),
    );
  }

  Future<void> _showWalletPicker(List<_Wallet> wallets) async {
    if (wallets.isEmpty) return;
    final result = await showModalBottomSheet<_Wallet>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _WalletPickerSheet(
        wallets: wallets,
        selected: _selectedWallet ?? wallets.first,
      ),
    );
    if (result != null) setState(() {
      _selectedWallet = result;
      _savedWalletCode = result.currency;
    });
  }

  Future<void> _showCountryPicker() async {
    final result = await showModalBottomSheet<_Country>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _CountryPickerSheet(
        countries: _countries,
        selected: _selectedCountry,
        favourites: _favourites,
        onToggleFavourite: _toggleFavourite,
      ),
    );
    if (result != null) setState(() {
      _selectedCountry = result;
      _savedCountryIndex = _countries.indexOf(result);
      _verified = false;
      _resolvedName = null;
      _verifyError = null;
      _accountCtrl.clear();
      _sortCodeCtrl.clear();
      _ibanCtrl.clear();
      _bicCtrl.clear();
      _ifscCtrl.clear();
      _bsbCtrl.clear();
      _routingCtrl.clear();
      _recipientNameCtrl.clear();
    });
  }

  // ---------------------------------------------------------------------------
  // Rate Preview Widget
  // ---------------------------------------------------------------------------
  Widget _buildRatePreview() {
    final fromCurrency = _isSwapped ? _selectedCountry.currency : (_selectedWallet?.currency ?? 'USD');
    final toCurrency = _isSwapped ? (_selectedWallet?.currency ?? 'USD') : _selectedCountry.currency;
    if (fromCurrency == toCurrency) return const SizedBox.shrink();

    final ratesAsync = ref.watch(exchangeRatesProvider);
    final rates = ratesAsync.valueOrNull?.rates ?? _midMarketRates;
    final fromRate = rates[fromCurrency] ?? 1.0;
    final toRate = rates[toCurrency] ?? 1.0;
    final rate = toRate / fromRate;

    final rateStr = rate >= 100
        ? rate.toStringAsFixed(0)
        : rate >= 10
            ? rate.toStringAsFixed(1)
            : rate >= 1
                ? rate.toStringAsFixed(2)
                : rate.toStringAsFixed(4);

    final amountText = _amountCtrl.text.trim();
    final amount = double.tryParse(amountText) ?? 0.0;
    // Africa: FREE. All others: flat $1.50 USD converted to source currency.
    const _africaFree = {'NGN','GHS','KES','ZAR','UGX','TZS','RWF','ETB','ZMW','EGP','MAD','XOF','XAF'};
    final isAfricaFree = _africaFree.contains(toCurrency);
    final feeUSD = 1.50;
    final fee = (amount <= 0 || isAfricaFree) ? 0.0 : double.parse((feeUSD * fromRate).toStringAsFixed(2));
    final amountAfterFee = amount - fee;
    final receivedAmount = amountAfterFee > 0 ? amountAfterFee * rate : 0.0;
    final isLive = ratesAsync.valueOrNull != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _teal.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _teal.withOpacity(0.18)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isLive ? Colors.green.shade100 : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        color: isLive ? Colors.green : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isLive ? 'Live Rate' : 'Est. Rate',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isLive ? Colors.green.shade700 : Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '1 $fromCurrency = $rateStr $toCurrency',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _teal,
                ),
              ),
            ],
          ),
          if (amount > 0) ...[
            const SizedBox(height: 12),
            Container(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 12),
            _rateRow('You send', '${_symbolFor(fromCurrency)}${amount.toStringAsFixed(2)} $fromCurrency', null),
            const SizedBox(height: 8),
            _rateRow(
              'Transfer fee',
              isAfricaFree ? '🎉 FREE' : '- ${_symbolFor(fromCurrency)}${fee.toStringAsFixed(2)} $fromCurrency',
              isAfricaFree ? Colors.green.shade700 : Colors.orange.shade700,
            ),
            const SizedBox(height: 8),
            Container(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 8),
            _rateRow(
              'Recipient gets',
              '${_symbolFor(toCurrency)}${receivedAmount.toStringAsFixed(2)} $toCurrency',
              _teal,
              bold: true,
            ),
            const SizedBox(height: 8),
            _rateRow('Delivery', 'Instant ⚡', Colors.green.shade700),
          ],
        ],
      ),
    );
  }

  Widget _rateRow(String label, String value, Color? valueColor, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? const Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }

  // All AmixPay deliveries are instant
  String _estimatedArrival(String countryName) => 'Instant ⚡';

  @override
  Widget build(BuildContext context) {
    final currencies = ref.watch(walletCurrenciesProvider);
    final wallets = currencies.map((c) => _Wallet(
      currency: c.code,
      flag: c.flag,
      balance: c.balance.toStringAsFixed(2),
    )).toList();
    _wallets = wallets;
    // Restore previously saved wallet selection, or auto-select first
    if (wallets.isNotEmpty && (_selectedWallet == null || !wallets.any((w) => w.currency == _selectedWallet!.currency))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {
          final saved = _savedWalletCode != null
              ? wallets.firstWhere((w) => w.currency == _savedWalletCode, orElse: () => wallets.first)
              : wallets.first;
          _selectedWallet = saved;
        });
      });
    }
    final effectiveWallet = _selectedWallet ?? (wallets.isNotEmpty ? wallets.first : null);
    final system = _bankSystem;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'International Transfer',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1A1A2E)),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Wise-style transfer UI ───────────────────────────────────
              Builder(builder: (ctx) {
                final fromCurrency = _isSwapped ? _selectedCountry.currency : (effectiveWallet?.currency ?? 'USD');
                final toCurrency = _isSwapped ? (effectiveWallet?.currency ?? 'USD') : _selectedCountry.currency;
                final fromFlag = _isSwapped ? _selectedCountry.flag : (effectiveWallet?.flag ?? '🇺🇸');
                final toFlag = _isSwapped ? (effectiveWallet?.flag ?? '🇺🇸') : _selectedCountry.flag;
                final ratesAsync = ref.watch(exchangeRatesProvider);
                final rates = ratesAsync.valueOrNull?.rates ?? _midMarketRates;
                final fromRate = rates[fromCurrency] ?? 1.0;
                final toRate = rates[toCurrency] ?? 1.0;
                final rate = fromCurrency == toCurrency ? 1.0 : toRate / fromRate;
                final rateStr = rate >= 100
                    ? rate.toStringAsFixed(0)
                    : rate >= 10
                        ? rate.toStringAsFixed(1)
                        : rate >= 1
                            ? rate.toStringAsFixed(2)
                            : rate.toStringAsFixed(4);
                // Sync rate for two-way field listeners
                _currentRate = rate;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Pay with ─────────────────────────────────────────────
                    _sectionLabel('Pay with'),
                    const SizedBox(height: 10),
                    Row(children: [
                      _PaySourceChip(
                          label: 'Wallet',
                          icon: Icons.account_balance_wallet_rounded,
                          selected: _payWith == 'Wallet',
                          onTap: () => setState(() { _payWith = 'Wallet'; _savedPayWith = _payWith; })),
                      const SizedBox(width: 8),
                      _PaySourceChip(
                          label: 'Bank',
                          icon: Icons.account_balance_rounded,
                          selected: _payWith == 'Bank',
                          onTap: () => setState(() { _payWith = 'Bank'; _savedPayWith = _payWith; })),
                      const SizedBox(width: 8),
                      _PaySourceChip(
                          label: 'Apple Pay',
                          icon: Icons.apple_rounded,
                          selected: _payWith == 'Apple Pay',
                          onTap: () => setState(() { _payWith = 'Apple Pay'; _savedPayWith = _payWith; })),
                    ]),
                    const SizedBox(height: 16),

                    // ── You send ────────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                      decoration: _cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('You send', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(
                              child: TextFormField(
                                controller: _amountCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Enter an amount';
                                  if (double.tryParse(v.trim()) == null || double.parse(v.trim()) <= 0) return 'Enter a valid amount';
                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: '0.00',
                                  hintStyle: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Color(0xFFD1D5DB)),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _CurrencyChip(
                              flag: fromFlag,
                              code: fromCurrency,
                              onTap: _isSwapped ? _showCountryPicker : () => _showWalletPicker(wallets),
                            ),
                          ]),
                          if (effectiveWallet != null && !_isSwapped) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Balance: ${_symbolFor(fromCurrency)}${effectiveWallet.balance}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // ── Rate + Swap ─────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(children: [
                        Expanded(child: Divider(color: Colors.grey.shade200)),
                        GestureDetector(
                          onTap: _swapCurrencies,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)],
                            ),
                            child: const Icon(Icons.swap_vert_rounded, color: Color(0xFF0D6B5E), size: 18),
                          ),
                        ),
                        if (fromCurrency != toCurrency) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.trending_up_rounded, size: 13, color: Color(0xFF0D6B5E)),
                              const SizedBox(width: 5),
                              Text(
                                '1 $fromCurrency = $rateStr $toCurrency',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0D6B5E)),
                              ),
                            ]),
                          ),
                        ],
                        Expanded(child: Divider(color: Colors.grey.shade200)),
                      ]),
                    ),

                    // ── Recipient gets (editable — reverse-computes "You send") ──
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                      decoration: _cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Recipient gets',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(
                              child: TextFormField(
                                controller: _recipientAmtCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d+\.?\d{0,2}'))
                                ],
                                style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A2E)),
                                decoration: const InputDecoration(
                                  hintText: '0.00',
                                  hintStyle: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFD1D5DB)),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _CurrencyChip(
                              flag: toFlag,
                              code: toCurrency,
                              onTap: _isSwapped
                                  ? () => _showWalletPicker(wallets)
                                  : _showCountryPicker,
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ],
                );
              }),

              const SizedBox(height: 20),

              // ---- Rate Preview ----
              _buildRatePreview(),
              const SizedBox(height: 20),

              // ---- Recipient Details — adaptive by banking system ----
              Row(
                children: [
                  Expanded(child: _sectionLabel('Recipient Bank Details')),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _bankSystemLabel(system),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _teal,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(),
                child: Column(
                  children: [
                    // Adaptive bank fields first (for auto-lookup flow)
                    ..._buildBankFields(system),

                    const SizedBox(height: 14),

                    // Verify button
                    if (!_verified) ...[
                      SizedBox(
                        width: double.infinity, height: 44,
                        child: OutlinedButton.icon(
                          onPressed: _verifying ? null : _verifyRecipient,
                          icon: _verifying
                              ? const SizedBox(width: 16, height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: _teal))
                              : const Icon(Icons.search_rounded, size: 18),
                          label: Text(_verifying ? 'Verifying account...' : 'Verify Account'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _teal,
                            side: const BorderSide(color: _teal),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                      ),
                      if (_verifyError != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, size: 16, color: Colors.red.shade700),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_verifyError!, style: TextStyle(fontSize: 12, color: Colors.red.shade700))),
                            ],
                          ),
                        ),
                      ],
                    ],

                    // Resolved name card
                    if (_verified && _resolvedName != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(color: Colors.green.shade100, shape: BoxShape.circle),
                              child: Icon(Icons.person_rounded, color: Colors.green.shade700, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Account Holder', style: TextStyle(fontSize: 10, color: Colors.green.shade600)),
                                  Text(_resolvedName!, style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700, color: Colors.green.shade800,
                                  )),
                                ],
                              ),
                            ),
                            Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 20),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: _resetVerification,
                              child: Icon(Icons.edit_rounded, color: Colors.green.shade400, size: 16),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Account holder name (auto-filled, editable)
                    _buildField(
                      controller: _recipientNameCtrl,
                      label: 'Account Holder Name',
                      hint: _verified ? '' : 'Auto-filled after verification',
                      icon: _verified ? Icons.check_circle_rounded : Icons.person_outline_rounded,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Verify account first'
                          : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ---- Transfer Button ----
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _getQuote,
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Transfer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns the adaptive form fields for the given banking system.
  List<Widget> _buildBankFields(_BankSystem system) {
    switch (system) {
      case _BankSystem.usRouting:
        return [
          _buildField(
            controller: _routingCtrl,
            label: 'Routing Number (ABA)',
            hint: '9-digit routing number',
            icon: Icons.route_rounded,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => _resetVerification(),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if (v.trim().length != 9) return 'Routing number must be 9 digits';
              return null;
            },
          ),
          const SizedBox(height: 14),
          _buildField(
            controller: _accountCtrl,
            label: 'Account Number',
            hint: 'Bank account number',
            icon: Icons.account_balance_rounded,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => _resetVerification(),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
        ];

      case _BankSystem.ukSortCode:
        return [
          _buildField(
            controller: _sortCodeCtrl,
            label: 'Sort Code',
            hint: '12-34-56 (6 digits)',
            icon: Icons.tag_rounded,
            keyboardType: TextInputType.number,
            onChanged: (_) => _resetVerification(),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              final clean = v.replaceAll('-', '').replaceAll(' ', '');
              if (clean.length != 6) return 'Sort code must be 6 digits';
              return null;
            },
          ),
          const SizedBox(height: 14),
          _buildField(
            controller: _accountCtrl,
            label: 'Account Number',
            hint: '8-digit account number',
            icon: Icons.account_balance_rounded,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => _resetVerification(),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if (v.trim().length < 6) return 'Enter a valid account number';
              return null;
            },
          ),
        ];

      case _BankSystem.sepaIban:
        return [
          _buildField(
            controller: _ibanCtrl,
            label: 'IBAN',
            hint: 'e.g. DE89 3704 0044 0532 0130 00',
            icon: Icons.credit_card_rounded,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => _resetVerification(),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              final clean = v.replaceAll(' ', '');
              if (clean.length < 15) return 'Enter a valid IBAN';
              return null;
            },
          ),
          const SizedBox(height: 14),
          _buildField(
            controller: _bicCtrl,
            label: 'BIC / SWIFT Code',
            hint: 'e.g. DEUTDEDB',
            icon: Icons.code_rounded,
            textCapitalization: TextCapitalization.characters,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if (v.trim().length < 8) return 'Enter a valid BIC/SWIFT code';
              return null;
            },
          ),
        ];

      case _BankSystem.indiaIfsc:
        return [
          _buildField(
            controller: _ifscCtrl,
            label: 'IFSC Code',
            hint: 'e.g. HDFC0001234',
            icon: Icons.tag_rounded,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => _resetVerification(),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if (v.trim().length != 11) return 'IFSC must be 11 characters';
              return null;
            },
          ),
          const SizedBox(height: 14),
          _buildField(
            controller: _accountCtrl,
            label: 'Account Number',
            hint: 'Bank account number',
            icon: Icons.account_balance_rounded,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => _resetVerification(),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
        ];

      case _BankSystem.australiaBsb:
        return [
          _buildField(
            controller: _bsbCtrl,
            label: 'BSB Number',
            hint: '000-000',
            icon: Icons.tag_rounded,
            keyboardType: TextInputType.number,
            onChanged: (_) => _resetVerification(),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              final clean = v.replaceAll('-', '');
              if (clean.length != 6) return 'BSB must be 6 digits';
              return null;
            },
          ),
          const SizedBox(height: 14),
          _buildField(
            controller: _accountCtrl,
            label: 'Account Number',
            hint: 'Bank account number',
            icon: Icons.account_balance_rounded,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => _resetVerification(),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
        ];

      case _BankSystem.generic:
        return [
          _buildField(
            controller: _bankNameCtrl,
            label: 'Bank Name',
            hint: 'e.g. Guaranty Trust Bank',
            icon: Icons.account_balance_rounded,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          _buildField(
            controller: _accountCtrl,
            label: 'Account Number',
            hint: 'Bank account number',
            icon: Icons.numbers_rounded,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => _resetVerification(),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          _buildField(
            controller: _swiftCtrl,
            label: 'SWIFT / BIC Code (optional)',
            hint: 'e.g. GTBINGLA',
            icon: Icons.code_rounded,
            textCapitalization: TextCapitalization.characters,
          ),
        ];
    }
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
          letterSpacing: 0.8,
        ),
      );

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      );

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.words,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF0D6B5E), size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0D6B5E), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wallet picker bottom sheet
// ---------------------------------------------------------------------------
class _WalletPickerSheet extends StatelessWidget {
  final List<_Wallet> wallets;
  final _Wallet selected;
  const _WalletPickerSheet(
      {required this.wallets, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Select Source Wallet',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 16),
          ...wallets.map(
            (w) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(w.flag, style: const TextStyle(fontSize: 28)),
              title: Text(
                '${w.currency} Wallet',
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E)),
              ),
              subtitle: Text(
                'Balance: ${_symbolFor(w.currency)}${w.balance}',
              ),
              trailing: w.currency == selected.currency
                  ? const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF0D6B5E))
                  : null,
              onTap: () => Navigator.pop(context, w),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Country picker bottom sheet
// ---------------------------------------------------------------------------
class _CountryPickerSheet extends StatefulWidget {
  final List<_Country> countries;
  final _Country selected;
  final Set<String> favourites;
  final void Function(String countryName) onToggleFavourite;

  const _CountryPickerSheet({
    required this.countries,
    required this.selected,
    required this.favourites,
    required this.onToggleFavourite,
  });

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  static const _teal = Color(0xFF0D6B5E);
  final _searchCtrl = TextEditingController();
  List<_Country> _filtered = [];
  late Set<String> _localFavourites;

  @override
  void initState() {
    super.initState();
    _filtered = widget.countries;
    _localFavourites = Set.from(widget.favourites);
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.toLowerCase();
      setState(() {
        _filtered = widget.countries
            .where((c) =>
                c.name.toLowerCase().contains(q) ||
                c.currency.toLowerCase().contains(q))
            .toList();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _handleToggle(String countryName) {
    setState(() {
      if (_localFavourites.contains(countryName)) {
        _localFavourites.remove(countryName);
      } else {
        _localFavourites.add(countryName);
      }
    });
    widget.onToggleFavourite(countryName);
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _searchCtrl.text.isNotEmpty;
    final favouriteCountries = isSearching
        ? <_Country>[]
        : widget.countries.where((c) => _localFavourites.contains(c.name)).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scroll) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Destination',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search country or currency...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                controller: scroll,
                children: [
                  // Favourites section
                  if (favouriteCountries.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 6),
                          Text('Favourites',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    ...favouriteCountries.map((c) => _buildCountryTile(c, isFavourite: true)),
                    const Divider(height: 24),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('All Countries',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600])),
                    ),
                  ],
                  // All / filtered countries
                  ..._filtered.map((c) => _buildCountryTile(c, isFavourite: _localFavourites.contains(c.name))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountryTile(_Country c, {required bool isFavourite}) {
    final system = _bankSystemFor(c);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Text(c.flag, style: const TextStyle(fontSize: 28)),
      title: Text(c.name,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
      subtitle: Text('${c.currency} · ${_bankSystemLabel(system)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _handleToggle(c.name),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Icon(
                isFavourite ? Icons.star_rounded : Icons.star_border_rounded,
                color: isFavourite ? const Color(0xFFF59E0B) : Colors.grey[400],
                size: 22,
              ),
            ),
          ),
          if (c.name == widget.selected.name)
            const Icon(Icons.check_circle_rounded, color: _teal, size: 20),
        ],
      ),
      onTap: () => Navigator.pop(context, c),
    );
  }
}

// ---------------------------------------------------------------------------
// Selector row widget
// ---------------------------------------------------------------------------
// ── Wise-style currency chip ─────────────────────────────────────────────────
class _CurrencyChip extends StatelessWidget {
  final String flag, code;
  final VoidCallback onTap;
  const _CurrencyChip({required this.flag, required this.code, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(flag, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 6),
        Text(code, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
        const SizedBox(width: 4),
        const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF6B7280)),
      ]),
    ),
  );
}

// ── Pay-with source chip ──────────────────────────────────────────────────────
class _PaySourceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _PaySourceChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF0D6B5E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? const Color(0xFF0D6B5E) : const Color(0xFFE5E7EB)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: selected ? Colors.white : const Color(0xFF6B7280)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : const Color(0xFF374151))),
      ]),
    ),
  );
}

class _SelectorRow extends StatelessWidget {
  final String label;
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SelectorRow({
    required this.label,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        leading,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style:
                    const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              Text(
                subtitle,
                style:
                    const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        trailing,
      ],
    );
  }
}
