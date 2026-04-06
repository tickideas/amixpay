import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';

// ── Hardcoded live-ish rates (would be replaced by API call) ─────────────────
const Map<String, double> _usdRates = {
  'USD': 1.0,
  'EUR': 0.921,
  'GBP': 0.789,
  'NGN': 1610.0,
  'GHS': 15.8,
  'KES': 130.0,
  'ZAR': 18.5,
  'BRL': 5.07,
  'ARS': 1040.0,
  'COP': 3950.0,
  'MXN': 17.2,
  'INR': 84.5,
  'CNY': 7.28,
  'JPY': 149.5,
  'KRW': 1340.0,
  'SGD': 1.34,
  'AUD': 1.54,
  'CAD': 1.37,
  'CHF': 0.893,
  'AED': 3.67,
  'SAR': 3.75,
  'PKR': 278.0,
  'BDT': 110.0,
  'PHP': 57.5,
  'THB': 35.5,
  'IDR': 15750.0,
  'EGP': 49.0,
  'MAD': 10.05,
  'TZS': 2690.0,
  'UGX': 3830.0,
  'RWF': 1380.0,
  'XOF': 604.0, // West African CFA
  'XAF': 604.0, // Central African CFA
  'CLP': 945.0,
  'PEN': 3.72,
  'CRC': 522.0,
  'GTQ': 7.78,
  'HNL': 24.7,
  'DOP': 59.5,
  'TTD': 6.79,
  'JMD': 156.0,
  'UAH': 38.5,
  'PLN': 3.99,
  'CZK': 22.8,
  'HUF': 358.0,
  'RON': 4.56,
  'BGN': 1.80,
  'HRK': 6.93,
  'NOK': 10.6,
  'SEK': 10.5,
  'DKK': 6.88,
  'NZD': 1.65,
};

const Map<String, String> _currencyFlags = {
  'USD': '🇺🇸', 'EUR': '🇪🇺', 'GBP': '🇬🇧', 'NGN': '🇳🇬', 'GHS': '🇬🇭',
  'KES': '🇰🇪', 'ZAR': '🇿🇦', 'BRL': '🇧🇷', 'ARS': '🇦🇷', 'COP': '🇨🇴',
  'MXN': '🇲🇽', 'INR': '🇮🇳', 'CNY': '🇨🇳', 'JPY': '🇯🇵', 'KRW': '🇰🇷',
  'SGD': '🇸🇬', 'AUD': '🇦🇺', 'CAD': '🇨🇦', 'CHF': '🇨🇭', 'AED': '🇦🇪',
  'SAR': '🇸🇦', 'PKR': '🇵🇰', 'BDT': '🇧🇩', 'PHP': '🇵🇭', 'THB': '🇹🇭',
  'IDR': '🇮🇩', 'EGP': '🇪🇬', 'MAD': '🇲🇦', 'TZS': '🇹🇿', 'UGX': '🇺🇬',
  'RWF': '🇷🇼', 'XOF': '🌍', 'XAF': '🌍', 'CLP': '🇨🇱', 'PEN': '🇵🇪',
  'CRC': '🇨🇷', 'GTQ': '🇬🇹', 'HNL': '🇭🇳', 'DOP': '🇩🇴', 'TTD': '🇹🇹',
  'JMD': '🇯🇲', 'UAH': '🇺🇦', 'PLN': '🇵🇱', 'CZK': '🇨🇿', 'HUF': '🇭🇺',
  'RON': '🇷🇴', 'BGN': '🇧🇬', 'HRK': '🇭🇷', 'NOK': '🇳🇴', 'SEK': '🇸🇪',
  'DKK': '🇩🇰', 'NZD': '🇳🇿',
};

const Map<String, String> _currencyNames = {
  'USD': 'US Dollar', 'EUR': 'Euro', 'GBP': 'British Pound', 'NGN': 'Nigerian Naira',
  'GHS': 'Ghanaian Cedi', 'KES': 'Kenyan Shilling', 'ZAR': 'South African Rand',
  'BRL': 'Brazilian Real', 'ARS': 'Argentine Peso', 'COP': 'Colombian Peso',
  'MXN': 'Mexican Peso', 'INR': 'Indian Rupee', 'CNY': 'Chinese Yuan',
  'JPY': 'Japanese Yen', 'KRW': 'South Korean Won', 'SGD': 'Singapore Dollar',
  'AUD': 'Australian Dollar', 'CAD': 'Canadian Dollar', 'CHF': 'Swiss Franc',
  'AED': 'UAE Dirham', 'SAR': 'Saudi Riyal', 'PKR': 'Pakistani Rupee',
  'BDT': 'Bangladeshi Taka', 'PHP': 'Philippine Peso', 'THB': 'Thai Baht',
  'IDR': 'Indonesian Rupiah', 'EGP': 'Egyptian Pound', 'MAD': 'Moroccan Dirham',
  'TZS': 'Tanzanian Shilling', 'UGX': 'Ugandan Shilling', 'RWF': 'Rwandan Franc',
  'XOF': 'West African CFA Franc', 'XAF': 'Central African CFA Franc',
  'CLP': 'Chilean Peso', 'PEN': 'Peruvian Sol', 'CRC': 'Costa Rican Colón',
  'GTQ': 'Guatemalan Quetzal', 'HNL': 'Honduran Lempira', 'DOP': 'Dominican Peso',
  'TTD': 'Trinidad & Tobago Dollar', 'JMD': 'Jamaican Dollar',
  'UAH': 'Ukrainian Hryvnia', 'PLN': 'Polish Złoty', 'CZK': 'Czech Koruna',
  'HUF': 'Hungarian Forint', 'RON': 'Romanian Leu', 'BGN': 'Bulgarian Lev',
  'HRK': 'Croatian Kuna', 'NOK': 'Norwegian Krone', 'SEK': 'Swedish Krona',
  'DKK': 'Danish Krone', 'NZD': 'New Zealand Dollar',
};

double _convert(double amount, String from, String to) {
  final fromRate = _usdRates[from] ?? 1.0;
  final toRate = _usdRates[to] ?? 1.0;
  return amount / fromRate * toRate;
}

class CurrencyConverterScreen extends ConsumerStatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  ConsumerState<CurrencyConverterScreen> createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends ConsumerState<CurrencyConverterScreen> {
  final _amountController = TextEditingController(text: '100');
  String _fromCurrency = 'USD';
  String _toCurrency = 'NGN';
  String _search = '';

  double get _convertedAmount {
    final input = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    return _convert(input, _fromCurrency, _toCurrency);
  }

  double get _rate => _convert(1, _fromCurrency, _toCurrency);
  double get _reverseRate => _convert(1, _toCurrency, _fromCurrency);

  void _swap() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
  }

  void _pickCurrency(bool isFrom) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _CurrencyPickerSheet(
        selected: isFrom ? _fromCurrency : _toCurrency,
        exclude: isFrom ? _toCurrency : _fromCurrency,
      ),
    );
    if (selected != null) {
      setState(() {
        if (isFrom) _fromCurrency = selected;
        else _toCurrency = selected;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _format(double v) {
    if (v >= 1000) return NumberFormat('#,##0.00').format(v);
    if (v >= 1) return NumberFormat('0.0000').format(v);
    return NumberFormat('0.00000000').format(v);
  }

  @override
  Widget build(BuildContext context) {
    final currencies = _usdRates.keys.toList()..sort();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: BackButton(color: AppColors.textPrimary),
        title: const Text(
          'Currency Converter',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Live Rates', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Main converter card ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(
                children: [
                  // From
                  _CurrencyInputRow(
                    currency: _fromCurrency,
                    label: 'You send',
                    controller: _amountController,
                    onCurrencyTap: () => _pickCurrency(true),
                    editable: true,
                    onChanged: () => setState(() {}),
                  ),

                  const SizedBox(height: 16),

                  // Swap button
                  GestureDetector(
                    onTap: _swap,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.swap_vert_rounded, color: Colors.white, size: 22),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // To
                  _CurrencyDisplayRow(
                    currency: _toCurrency,
                    label: 'Recipient gets',
                    amount: _convertedAmount,
                    onCurrencyTap: () => _pickCurrency(false),
                    format: _format,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Rate info card ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _RateRow(
                    label: 'Exchange rate',
                    value: '1 $_fromCurrency = ${_format(_rate)} $_toCurrency',
                  ),
                  const Divider(height: 20, color: AppColors.border),
                  _RateRow(
                    label: 'Reverse rate',
                    value: '1 $_toCurrency = ${_format(_reverseRate)} $_fromCurrency',
                  ),
                  const Divider(height: 20, color: AppColors.border),
                  _RateRow(
                    label: 'AmixPay fee',
                    value: 'From 0.5%',
                    valueColor: AppColors.primary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Popular pairs ─────────────────────────────────────────────
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Popular Pairs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ['USD', 'NGN'], ['USD', 'GHS'], ['USD', 'KES'], ['EUR', 'GBP'],
                ['GBP', 'EUR'], ['USD', 'INR'], ['USD', 'BRL'], ['USD', 'ZAR'],
              ].map((pair) {
                final isActive = _fromCurrency == pair[0] && _toCurrency == pair[1];
                return GestureDetector(
                  onTap: () => setState(() { _fromCurrency = pair[0]; _toCurrency = pair[1]; }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isActive ? AppColors.primary : AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_currencyFlags[pair[0]] ?? ''} ${pair[0]}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isActive ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        Icon(Icons.arrow_forward_rounded, size: 14,
                            color: isActive ? Colors.white : AppColors.textSecondary),
                        Text(
                          '${_currencyFlags[pair[1]] ?? ''} ${pair[1]}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isActive ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // ── Send money CTA ────────────────────────────────────────────
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: Text('Send ${_fromCurrency} now'),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _CurrencyInputRow extends StatelessWidget {
  final String currency;
  final String label;
  final TextEditingController controller;
  final VoidCallback onCurrencyTap;
  final bool editable;
  final VoidCallback onChanged;

  const _CurrencyInputRow({
    required this.currency, required this.label, required this.controller,
    required this.onCurrencyTap, required this.editable, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: '0',
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 28),
                ),
                onChanged: (_) => onChanged(),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onCurrencyTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(_currencyFlags[currency] ?? '🌐', style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Text(currency, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CurrencyDisplayRow extends StatelessWidget {
  final String currency;
  final String label;
  final double amount;
  final VoidCallback onCurrencyTap;
  final String Function(double) format;

  const _CurrencyDisplayRow({
    required this.currency, required this.label, required this.amount,
    required this.onCurrencyTap, required this.format,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
              const SizedBox(height: 6),
              Text(
                format(amount),
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onCurrencyTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(_currencyFlags[currency] ?? '🌐', style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Text(currency, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RateRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _RateRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: valueColor ?? AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}

class _CurrencyPickerSheet extends StatefulWidget {
  final String selected;
  final String exclude;
  const _CurrencyPickerSheet({required this.selected, required this.exclude});

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final currencies = _usdRates.keys.where((c) => c != widget.exclude).toList()..sort();
    final filtered = currencies.where((c) {
      final q = _search.toLowerCase();
      return c.toLowerCase().contains(q) || (_currencyNames[c] ?? '').toLowerCase().contains(q);
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Search currency...',
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              controller: ctrl,
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final c = filtered[i];
                final isSelected = c == widget.selected;
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text(_currencyFlags[c] ?? '🌐', style: const TextStyle(fontSize: 20))),
                  ),
                  title: Text(c, style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  subtitle: Text(_currencyNames[c] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                  onTap: () => Navigator.pop(context, c),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
