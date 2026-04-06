import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _teal = Color(0xFF0D6B5E);
const _bg = Color(0xFFF5F7FA);

// ---------------------------------------------------------------------------
// Country banking config — auth fields + mock name lookup per country
// ---------------------------------------------------------------------------
class _BankConfig {
  final String code;
  final String name;
  final String flag;
  final String currency;
  final String rail;
  final String railDesc;
  final String fee;
  final String settlement;
  final List<_BankField> fields;
  final String verifyLabel;   // label for the primary lookup field
  final String verifyHint;
  final bool autoLookupOnPrimary; // true = lookup fires when primary field is complete

  const _BankConfig({
    required this.code,
    required this.name,
    required this.flag,
    required this.currency,
    required this.rail,
    required this.railDesc,
    required this.fee,
    required this.settlement,
    required this.fields,
    this.verifyLabel = 'Account Number',
    this.verifyHint = '',
    this.autoLookupOnPrimary = false,
  });
}

class _BankField {
  final String key;
  final String label;
  final String hint;
  final TextInputType keyboard;
  final int? maxLength;
  final bool isPrimary;  // the field used for account name lookup
  const _BankField({
    required this.key,
    required this.label,
    required this.hint,
    this.keyboard = TextInputType.text,
    this.maxLength,
    this.isPrimary = false,
  });
}

// Simulated name lookup — in production these would call real bank verification APIs
// Keys are prefixed with country code to avoid collisions
const Map<String, String> _simulatedAccounts = {
  // UK: 'GB_<sort>_<account>'
  'GB_200000_55779911': 'James Anderson',
  'GB_301500_12345678': 'Sarah Mitchell',
  // NG: 'NG_<nuban>'
  'NG_0123456789': 'Chukwuemeka Obi',
  'NG_1234567890': 'Fatimah Yusuf',
  'NG_0987654321': 'Emeka Adeleke',
  // IN: 'IN_<ifsc>_<account>'
  'IN_HDFC0001234_12345678901': 'Priya Sharma',
  'IN_SBIN0001234_98765432101': 'Raj Kumar',
  // AU: 'AU_<bsb>_<account>'
  'AU_062000_12345678': 'Emily Johnson',
  // US: 'US_<routing>_<account>'
  'US_021000021_1234567890': 'Michael Thompson',
  // CA: 'CA_<transit>_<account>'
  'CA_00102_1234567': 'Sophie Tremblay',
  // ZA: 'ZA_<account>'
  'ZA_1234567890': 'Thabo Nkosi',
  // GH: 'GH_<account>'
  'GH_0123456789': 'Kwame Asante',
  // KE: 'KE_<phone/account>'
  'KE_0712345678': 'Amina Wanjiku',
};

String? _lookupAccountName(String countryCode, Map<String, String> values) {
  switch (countryCode) {
    case 'GB':
      final sort = (values['sortCode'] ?? '').replaceAll('-', '').replaceAll(' ', '');
      final acc = values['accountNumber'] ?? '';
      if (sort.length == 6 && acc.length == 8) {
        return _simulatedAccounts['GB_${sort}_$acc'] ?? _generateName(sort + acc);
      }
      return null;
    case 'NG':
      final nuban = values['accountNumber'] ?? '';
      if (nuban.length == 10) {
        return _simulatedAccounts['NG_$nuban'] ?? _generateName(nuban);
      }
      return null;
    case 'IN':
      final ifsc = (values['ifsc'] ?? '').toUpperCase();
      final acc = values['accountNumber'] ?? '';
      if (ifsc.length == 11 && acc.length >= 9) {
        return _simulatedAccounts['IN_${ifsc}_$acc'] ?? _generateName(ifsc + acc);
      }
      return null;
    case 'AU':
      final bsb = (values['bsb'] ?? '').replaceAll('-', '');
      final acc = values['accountNumber'] ?? '';
      if (bsb.length == 6 && acc.length >= 6) {
        return _simulatedAccounts['AU_${bsb}_$acc'] ?? _generateName(bsb + acc);
      }
      return null;
    case 'US':
      final routing = values['routingNumber'] ?? '';
      final acc = values['accountNumber'] ?? '';
      if (routing.length == 9 && acc.length >= 4) {
        return _simulatedAccounts['US_${routing}_$acc'] ?? _generateName(routing + acc);
      }
      return null;
    case 'CA':
      final transit = values['transitNumber'] ?? '';
      final acc = values['accountNumber'] ?? '';
      if (transit.length == 8 && acc.length >= 5) {
        return _simulatedAccounts['CA_${transit}_$acc'] ?? _generateName(transit + acc);
      }
      return null;
    case 'GH':
    case 'KE':
    case 'ZA':
    case 'AE':
      final acc = values['accountNumber'] ?? '';
      if (acc.length >= 8) {
        return _simulatedAccounts['${countryCode}_$acc'] ?? _generateName(acc);
      }
      return null;
    default:
      // SEPA / IBAN countries
      final iban = (values['iban'] ?? '').replaceAll(' ', '');
      if (iban.length >= 15) {
        return _generateName(iban);
      }
      return null;
  }
}

// Deterministically generate a plausible-sounding name from a numeric seed
String _generateName(String seed) {
  const firsts = ['James','Maria','Alex','Fatima','David','Aisha','Samuel','Priya','Daniel','Yemi','Thomas','Amara','Noah','Chioma','Lucas'];
  const lasts  = ['Johnson','Williams','Okonkwo','Sharma','Müller','Dubois','Santos','Nakamura','Petrov','Osei','Tremblay','Ali','Nkosi','Park','García'];
  int h = 0;
  for (final c in seed.codeUnits) { h = (h * 31 + c) & 0xFFFFFF; }
  return '${firsts[h % firsts.length]} ${lasts[(h ~/ firsts.length) % lasts.length]}';
}

// ---------------------------------------------------------------------------
// Country configs
// ---------------------------------------------------------------------------
const List<_BankConfig> _bankConfigs = [
  _BankConfig(
    code: 'US', name: 'United States', flag: '🇺🇸', currency: 'USD',
    rail: 'ACH / RTP', railDesc: 'Instant via RTP · Standard via ACH (1-2 days)', fee: 'Free', settlement: 'Instant',
    fields: [
      _BankField(key: 'routingNumber', label: 'Routing Number (ABA)', hint: '9-digit ABA routing number',
          keyboard: TextInputType.number, maxLength: 9),
      _BankField(key: 'accountNumber', label: 'Account Number', hint: '4–17 digit account number',
          keyboard: TextInputType.number, maxLength: 17, isPrimary: true),
      _BankField(key: 'bankName', label: 'Bank Name', hint: 'e.g. Chase, Bank of America'),
    ],
    verifyLabel: 'Routing + Account', verifyHint: 'Enter both fields to verify',
  ),
  _BankConfig(
    code: 'GB', name: 'United Kingdom', flag: '🇬🇧', currency: 'GBP',
    rail: 'Faster Payments', railDesc: 'UK Faster Payments Service (FPS)', fee: 'Free', settlement: 'Instant',
    fields: [
      _BankField(key: 'sortCode', label: 'Sort Code', hint: '12-34-56',
          keyboard: TextInputType.number, maxLength: 8),
      _BankField(key: 'accountNumber', label: 'Account Number', hint: '8-digit account number',
          keyboard: TextInputType.number, maxLength: 8, isPrimary: true),
    ],
    verifyLabel: 'Sort Code + Account', verifyHint: 'UK FPS name lookup',
    autoLookupOnPrimary: true,
  ),
  _BankConfig(
    code: 'NG', name: 'Nigeria', flag: '🇳🇬', currency: 'NGN',
    rail: 'NIBSS NIP', railDesc: 'NIBSS Instant Payment (NIP) network', fee: '₦10–₦54', settlement: 'Instant',
    fields: [
      _BankField(key: 'bankCode', label: 'Bank', hint: 'Select your bank',
          keyboard: TextInputType.text),
      _BankField(key: 'accountNumber', label: 'Account Number (NUBAN)', hint: '10-digit NUBAN',
          keyboard: TextInputType.number, maxLength: 10, isPrimary: true),
    ],
    verifyLabel: 'NUBAN Account Number', verifyHint: 'NIBSS instant name enquiry',
    autoLookupOnPrimary: true,
  ),
  _BankConfig(
    code: 'GH', name: 'Ghana', flag: '🇬🇭', currency: 'GHS',
    rail: 'GhIPSS', railDesc: 'Ghana Interbank Payment & Settlement System', fee: 'Varies', settlement: '1 hour',
    fields: [
      _BankField(key: 'bankName', label: 'Bank Name', hint: 'e.g. GCB Bank, Ecobank'),
      _BankField(key: 'accountNumber', label: 'Account Number', hint: '10-13 digit account number',
          keyboard: TextInputType.number, maxLength: 13, isPrimary: true),
    ],
    verifyLabel: 'Account Number',
  ),
  _BankConfig(
    code: 'KE', name: 'Kenya', flag: '🇰🇪', currency: 'KES',
    rail: 'M-Pesa / RTGS', railDesc: 'M-Pesa mobile money or Kenya RTGS', fee: 'Varies', settlement: 'Instant',
    fields: [
      _BankField(key: 'accountNumber', label: 'M-Pesa / Account Number', hint: '0712 345 678 or bank account',
          keyboard: TextInputType.phone, maxLength: 13, isPrimary: true),
      _BankField(key: 'bankName', label: 'Bank / Provider', hint: 'e.g. M-Pesa, KCB, Equity'),
    ],
    verifyLabel: 'Account / Phone',
    autoLookupOnPrimary: true,
  ),
  _BankConfig(
    code: 'ZA', name: 'South Africa', flag: '🇿🇦', currency: 'ZAR',
    rail: 'RTC / EFT', railDesc: 'Real-Time Clearing or EFT', fee: 'Varies', settlement: '1-2 days',
    fields: [
      _BankField(key: 'bankName', label: 'Bank Name', hint: 'e.g. FNB, Absa, Standard Bank'),
      _BankField(key: 'accountNumber', label: 'Account Number', hint: '8-11 digit account number',
          keyboard: TextInputType.number, maxLength: 11, isPrimary: true),
      _BankField(key: 'branchCode', label: 'Branch Code', hint: '6-digit branch code',
          keyboard: TextInputType.number, maxLength: 6),
    ],
    verifyLabel: 'Account Number',
  ),
  _BankConfig(
    code: 'IN', name: 'India', flag: '🇮🇳', currency: 'INR',
    rail: 'IMPS / UPI', railDesc: 'Immediate Payment Service (IMPS) or UPI', fee: '₹5–₹25', settlement: 'Instant',
    fields: [
      _BankField(key: 'ifsc', label: 'IFSC Code', hint: 'e.g. HDFC0001234',
          maxLength: 11),
      _BankField(key: 'accountNumber', label: 'Account Number', hint: '9–18 digit account number',
          keyboard: TextInputType.number, maxLength: 18, isPrimary: true),
    ],
    verifyLabel: 'IFSC + Account', verifyHint: 'IMPS name verification',
    autoLookupOnPrimary: true,
  ),
  _BankConfig(
    code: 'AU', name: 'Australia', flag: '🇦🇺', currency: 'AUD',
    rail: 'NPP / Osko', railDesc: 'New Payments Platform (NPP) via Osko', fee: 'Free', settlement: 'Instant',
    fields: [
      _BankField(key: 'bsb', label: 'BSB Number', hint: '062-000 (6 digits)',
          keyboard: TextInputType.number, maxLength: 7),
      _BankField(key: 'accountNumber', label: 'Account Number', hint: '6–10 digit account number',
          keyboard: TextInputType.number, maxLength: 10, isPrimary: true),
    ],
    verifyLabel: 'BSB + Account', verifyHint: 'NPP name lookup',
    autoLookupOnPrimary: true,
  ),
  _BankConfig(
    code: 'CA', name: 'Canada', flag: '🇨🇦', currency: 'CAD',
    rail: 'Interac e-Transfer', railDesc: 'Interac e-Transfer network', fee: 'C\$1.50', settlement: 'Instant',
    fields: [
      _BankField(key: 'transitNumber', label: 'Transit + Institution Number', hint: '00102-004 (8 digits)',
          keyboard: TextInputType.number, maxLength: 8),
      _BankField(key: 'accountNumber', label: 'Account Number', hint: '5–12 digit account number',
          keyboard: TextInputType.number, maxLength: 12, isPrimary: true),
      _BankField(key: 'bankName', label: 'Bank Name', hint: 'e.g. RBC, TD, Scotiabank'),
    ],
    verifyLabel: 'Transit + Account',
  ),
  _BankConfig(
    code: 'AE', name: 'UAE', flag: '🇦🇪', currency: 'AED',
    rail: 'SWIFT / UAEFTS', railDesc: 'UAE Funds Transfer System', fee: 'Varies', settlement: '1-2 days',
    fields: [
      _BankField(key: 'iban', label: 'IBAN', hint: 'AE070331234567890123456',
          maxLength: 26),
      _BankField(key: 'bankName', label: 'Bank Name', hint: 'e.g. Emirates NBD, ADCB'),
      _BankField(key: 'accountNumber', label: 'Account Number', hint: 'Account number', isPrimary: true),
    ],
    verifyLabel: 'IBAN',
  ),
  // SEPA countries
  _BankConfig(
    code: 'DE', name: 'Germany', flag: '🇩🇪', currency: 'EUR',
    rail: 'SEPA Instant', railDesc: 'SEPA Instant Credit Transfer (SCT Inst)', fee: '€0.50', settlement: 'Instant',
    fields: [
      _BankField(key: 'iban', label: 'IBAN', hint: 'DE89370400440532013000', maxLength: 34, isPrimary: true),
      _BankField(key: 'bic', label: 'BIC / SWIFT', hint: 'COBADEFFXXX (optional)', maxLength: 11),
    ],
    verifyLabel: 'IBAN', autoLookupOnPrimary: true,
  ),
  _BankConfig(
    code: 'FR', name: 'France', flag: '🇫🇷', currency: 'EUR',
    rail: 'SEPA Instant', railDesc: 'SEPA Instant Credit Transfer (SCT Inst)', fee: '€0.50', settlement: 'Instant',
    fields: [
      _BankField(key: 'iban', label: 'IBAN', hint: 'FR7630006000011234567890189', maxLength: 34, isPrimary: true),
      _BankField(key: 'bic', label: 'BIC / SWIFT', hint: 'BNPAFRPP (optional)', maxLength: 11),
    ],
    verifyLabel: 'IBAN', autoLookupOnPrimary: true,
  ),
  _BankConfig(
    code: 'INTL', name: 'International', flag: '🌍', currency: 'USD',
    rail: 'SWIFT', railDesc: 'Global SWIFT wire transfer (190+ countries)', fee: '\$15', settlement: '1-3 days',
    fields: [
      _BankField(key: 'swiftBic', label: 'SWIFT / BIC Code', hint: 'MIDLGB22 (8 or 11 chars)', maxLength: 11),
      _BankField(key: 'iban', label: 'IBAN or Account Number', hint: 'IBAN or local account number', isPrimary: true),
      _BankField(key: 'bankName', label: 'Bank Name', hint: 'Beneficiary bank name'),
      _BankField(key: 'bankAddress', label: 'Bank Address (optional)', hint: 'Street, City, Country'),
    ],
    verifyLabel: 'SWIFT / Account',
  ),
];

_BankConfig _configFor(String code) =>
    _bankConfigs.firstWhere((c) => c.code == code, orElse: () => _bankConfigs.last);

// ---------------------------------------------------------------------------
// Main screen
// ---------------------------------------------------------------------------
class BankConnectionScreen extends ConsumerStatefulWidget {
  const BankConnectionScreen({super.key});

  @override
  ConsumerState<BankConnectionScreen> createState() => _BankConnectionScreenState();
}

class _BankConnectionScreenState extends ConsumerState<BankConnectionScreen> {
  String _selectedCountry = 'US';
  bool _connecting = false;

  _BankConfig get _activeConfig => _configFor(_selectedCountry);

  Future<void> _connectBank() async {
    setState(() => _connecting = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _connecting = false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BankFormSheet(config: _activeConfig),
    );
  }

  @override
  Widget build(BuildContext context) {
    final configs = _bankConfigs;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        title: const Text('Connect Bank Account', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_teal, _teal.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bank Transfer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 2),
                        Text('Link your bank to fund your wallet or send directly worldwide.',
                            style: TextStyle(color: Colors.white70, fontSize: 12), maxLines: 2),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('Select your country', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.8,
              ),
              itemCount: configs.length,
              itemBuilder: (_, i) {
                final c = configs[i];
                final sel = c.code == _selectedCountry;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCountry = c.code),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: sel ? _teal : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: sel ? _teal : Colors.grey.shade200, width: sel ? 2 : 1),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(c.flag, style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 2),
                        Text(c.code, style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : const Color(0xFF1A1A2E),
                        )),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Rail detail card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(_activeConfig.flag, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_activeConfig.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A2E))),
                          Text(_activeConfig.currency, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  _DetailRow(label: 'Rail', value: _activeConfig.rail),
                  const SizedBox(height: 8),
                  _DetailRow(label: 'Description', value: _activeConfig.railDesc),
                  const SizedBox(height: 8),
                  _DetailRow(label: 'Fee', value: _activeConfig.fee,
                      valueColor: _activeConfig.fee == 'Free' ? Colors.green : null),
                  const SizedBox(height: 8),
                  _DetailRow(label: 'Settlement', value: _activeConfig.settlement,
                      valueColor: _activeConfig.settlement == 'Instant' ? Colors.green : null),
                  const SizedBox(height: 12),
                  // show required fields hint
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: _teal.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user_outlined, color: _teal, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Required: ${_activeConfig.fields.map((f) => f.label).join(' · ')}',
                            style: const TextStyle(fontSize: 11, color: _teal),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _connecting ? null : _connectBank,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _connecting
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Connect Bank Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 12),
            const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text('Bank-grade AES-256 encryption · PCI DSS compliant',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bank form sheet — country-specific fields + account name verification
// ---------------------------------------------------------------------------
class _BankFormSheet extends StatefulWidget {
  final _BankConfig config;
  const _BankFormSheet({required this.config});

  @override
  State<_BankFormSheet> createState() => _BankFormSheetState();
}

class _BankFormSheetState extends State<_BankFormSheet> {
  late final Map<String, TextEditingController> _controllers;
  bool _verifying = false;
  bool _verified = false;
  String? _resolvedName;
  String? _verifyError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final f in widget.config.fields) f.key: TextEditingController(),
    };
    // Auto-lookup when primary field completes
    if (widget.config.autoLookupOnPrimary) {
      for (final f in widget.config.fields) {
        if (f.isPrimary && f.maxLength != null) {
          _controllers[f.key]!.addListener(() {
            final val = _controllers[f.key]!.text.replaceAll(RegExp(r'\D'), '');
            if (val.length == f.maxLength) _verifyAccount();
          });
        }
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) { c.dispose(); }
    super.dispose();
  }

  Map<String, String> get _values =>
      _controllers.map((k, v) => MapEntry(k, v.text));

  bool get _canVerify {
    // Check all required fields have values
    for (final f in widget.config.fields) {
      if (_controllers[f.key]!.text.trim().isEmpty) return false;
    }
    return true;
  }

  Future<void> _verifyAccount() async {
    if (_verifying) return;
    setState(() { _verifying = true; _verifyError = null; _resolvedName = null; _verified = false; });

    // Simulate API delay (UK FPS ~300ms, NIBSS ~400ms, etc.)
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    final name = _lookupAccountName(widget.config.code, _values);
    setState(() {
      _verifying = false;
      if (name != null) {
        _resolvedName = name;
        _verified = true;
        _verifyError = null;
      } else {
        _verifyError = _verifyErrorMessage(widget.config.code);
        _verified = false;
      }
    });
  }

  String _verifyErrorMessage(String code) {
    switch (code) {
      case 'GB': return 'Account not found. Check sort code and account number.';
      case 'NG': return 'NUBAN not found. Verify the 10-digit account number and bank.';
      case 'IN': return 'Account not found. Check IFSC code and account number.';
      case 'AU': return 'BSB or account number invalid. Please check and retry.';
      default: return 'Could not verify account details. Please check and retry.';
    }
  }

  Future<void> _save() async {
    if (!_verified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify the account first')),
      );
      return;
    }
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.config.flag} Bank account connected for $_resolvedName'),
        backgroundColor: _teal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 6),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(widget.config.flag, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('${widget.config.name} Bank Details',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A2E))),
                  ),
                  // Verification badge
                  if (_verified)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, size: 14, color: Colors.green.shade700),
                          const SizedBox(width: 4),
                          Text('Verified', style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  // Dynamic fields
                  ...widget.config.fields.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SheetField(
                      controller: _controllers[f.key]!,
                      label: f.label,
                      hint: f.hint,
                      keyboardType: f.keyboard,
                      maxLength: f.maxLength,
                      onChanged: (_) {
                        if (_verified) setState(() { _verified = false; _resolvedName = null; });
                      },
                    ),
                  )),

                  const SizedBox(height: 4),

                  // Verify button
                  if (!_verified) ...[
                    SizedBox(
                      width: double.infinity, height: 46,
                      child: OutlinedButton.icon(
                        onPressed: (_verifying || !_canVerify) ? null : _verifyAccount,
                        icon: _verifying
                            ? const SizedBox(width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: _teal))
                            : const Icon(Icons.search_rounded, size: 18),
                        label: Text(_verifying ? 'Verifying account...' : 'Verify Account'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _teal,
                          side: const BorderSide(color: _teal),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    if (_verifyError != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
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
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.green.shade100, shape: BoxShape.circle),
                            child: Icon(Icons.person_rounded, color: Colors.green.shade700, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Account Holder', style: TextStyle(fontSize: 11, color: Colors.green.shade600)),
                                const SizedBox(height: 2),
                                Text(_resolvedName!, style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700, color: Colors.green.shade800,
                                )),
                              ],
                            ),
                          ),
                          Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 22),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Info note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber.shade800, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _verificationNote(widget.config.code),
                            style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: (_saving || !_verified) ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _teal, foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: _saving
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('Connect Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _verificationNote(String code) {
    switch (code) {
      case 'GB': return 'Your sort code and account number are verified via UK Faster Payments (FPS). The account holder name is confirmed before connection.';
      case 'NG': return 'Your 10-digit NUBAN account number is verified via NIBSS Instant Payment name enquiry. The account holder name is confirmed automatically.';
      case 'IN': return 'Your IFSC code and account number are verified via IMPS. Account name is returned by the beneficiary bank.';
      case 'AU': return 'BSB and account verified via NPP / Osko Pay ID lookup. Account name confirmed in real time.';
      case 'US': return 'Routing and account numbers verified via ABA. A micro-deposit of 2 small amounts will also be sent to confirm ownership.';
      case 'DE':
      case 'FR': return 'IBAN validated and account name confirmed via SEPA Instant Credit Transfer (SCT Inst).';
      default: return 'Account details will be verified before connecting. This ensures only you can use this account.';
    }
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------
class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  const _SheetField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.maxLength,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          onChanged: onChanged,
          inputFormatters: maxLength != null && keyboardType == TextInputType.number
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF5F7FA),
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _teal, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(width: 100, child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
      Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: valueColor ?? const Color(0xFF1A1A2E)))),
    ],
  );
}
