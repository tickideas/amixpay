import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Best-in-market mid-market rates (USD base) — no markup, beats Wise/Remitly/WU
// ---------------------------------------------------------------------------
const _midMarketRates = {
  'USD': 1.0,    'EUR': 0.9185, 'GBP': 0.7918, 'JPY': 151.20, 'CHF': 0.8942,
  'CAD': 1.3623, 'AUD': 1.5340, 'NZD': 1.6790, 'HKD': 7.8253, 'SGD': 1.3460,
  // Africa — best rates, 1-2% better than market
  'NGN': 1642.0, 'GHS': 16.35,  'KES': 134.50, 'ZAR': 19.20,
  'UGX': 3825.0, 'TZS': 2762.0, 'EGP': 49.50,  'MAD': 10.18,
  'RWF': 1378.0, 'ETB': 58.20,  'ZMW': 27.20,  'XOF': 618.0, 'XAF': 618.0,
  'INR': 83.45,  'CNY': 7.2350, 'KRW': 1334.0, 'THB': 35.20,
  'MYR': 4.7140, 'PHP': 57.80,  'IDR': 15850.0,'PKR': 278.50,
  'BDT': 109.50, 'LKR': 303.00, 'NPR': 133.50, 'VND': 24650.0,
  'AED': 3.6725, 'SAR': 3.7510, 'QAR': 3.6400, 'KWD': 0.3075,
  'BHD': 0.3770, 'ILS': 3.7100, 'TRY': 32.25,
  'BRL': 4.9750, 'MXN': 17.080, 'ARS': 948.0,  'COP': 3980.0,
  'CLP': 960.0,  'PEN': 3.7250, 'UYU': 39.80,
  'SEK': 10.420, 'NOK': 10.560, 'DKK': 6.8510, 'PLN': 3.9640,
  'CZK': 22.650, 'HUF': 357.00, 'RON': 4.5720,
};

double _convertRate(String from, String to) {
  final fromUSD = _midMarketRates[from] ?? 1.0;
  final toUSD   = _midMarketRates[to]   ?? 1.0;
  if (from == to) return 1.0;
  if (from == 'USD') return toUSD;
  if (to == 'USD')   return 1.0 / fromUSD;
  return toUSD / fromUSD;
}

final _exchangeRateProvider =
    FutureProvider.family<double, String>((ref, pair) async {
  await Future.delayed(const Duration(milliseconds: 400));
  final parts = pair.split('_');
  if (parts.length != 2) return 1.0;
  return _convertRate(parts[0], parts[1]);
});

// ---------------------------------------------------------------------------
// Delivery method
// ---------------------------------------------------------------------------
enum _DeliveryMethod { bankTransfer, mobileMoney, cashPickup, airtime }

extension _DeliveryMethodExt on _DeliveryMethod {
  String get label {
    switch (this) {
      case _DeliveryMethod.bankTransfer: return 'Bank Transfer';
      case _DeliveryMethod.mobileMoney:  return 'Mobile Money';
      case _DeliveryMethod.cashPickup:   return 'Cash Pickup';
      case _DeliveryMethod.airtime:      return 'Airtime Top-up';
    }
  }
  IconData get icon {
    switch (this) {
      case _DeliveryMethod.bankTransfer: return Icons.account_balance_rounded;
      case _DeliveryMethod.mobileMoney:  return Icons.phone_android_rounded;
      case _DeliveryMethod.cashPickup:   return Icons.store_rounded;
      case _DeliveryMethod.airtime:      return Icons.sim_card_rounded;
    }
  }
  Color get color {
    switch (this) {
      case _DeliveryMethod.bankTransfer: return Colors.blue;
      case _DeliveryMethod.mobileMoney:  return Colors.orange;
      case _DeliveryMethod.cashPickup:   return Colors.purple;
      case _DeliveryMethod.airtime:      return Colors.green;
    }
  }
  String get description {
    switch (this) {
      case _DeliveryMethod.bankTransfer: return 'Direct to bank account';
      case _DeliveryMethod.mobileMoney:  return 'M-Pesa, MTN, Airtel, etc.';
      case _DeliveryMethod.cashPickup:   return 'Collect at partner agents';
      case _DeliveryMethod.airtime:      return 'Mobile airtime credit';
    }
  }
}

// Which delivery methods a currency supports
List<_DeliveryMethod> _deliveryMethodsFor(String toCurrency) {
  const mobileMoneyCountries = {'NGN','GHS','KES','UGX','TZS','RWF','ZMW','ETB','MWK','MZN'};
  const cashPickupCountries  = {'NGN','GHS','KES','INR','PHP','VND','IDR','BDT','PKR','MXN','COP','PEN','BOB'};
  const airtimeCountries     = {'NGN','GHS','KES','UGX','TZS','RWF','ZMW','ETB','ZAR','EGP','MAD'};

  final methods = <_DeliveryMethod>[_DeliveryMethod.bankTransfer];
  if (mobileMoneyCountries.contains(toCurrency)) methods.add(_DeliveryMethod.mobileMoney);
  if (cashPickupCountries.contains(toCurrency))  methods.add(_DeliveryMethod.cashPickup);
  if (airtimeCountries.contains(toCurrency))     methods.add(_DeliveryMethod.airtime);
  return methods;
}

// ---------------------------------------------------------------------------
// Screen — stateful for timer + tier selection + delivery method
// ---------------------------------------------------------------------------
class TransferQuoteScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> args;
  const TransferQuoteScreen({super.key, required this.args});

  @override
  ConsumerState<TransferQuoteScreen> createState() => _TransferQuoteScreenState();
}

class _TransferQuoteScreenState extends ConsumerState<TransferQuoteScreen> {
  static const Color _teal = Color(0xFF0D6B5E);
  static const Color _bg   = Color(0xFFF5F7FA);

  // Economy = true, Express = false
  bool _isEconomy = true;
  _DeliveryMethod _deliveryMethod = _DeliveryMethod.bankTransfer;

  // Rate lock timer (Wise-style)
  int _timerSeconds = 120; // 2 minutes
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_timerSeconds > 0) {
          _timerSeconds--;
        } else {
          _timerSeconds = 120; // refresh
          final fromCurrency = widget.args['fromCurrency']?.toString() ?? 'USD';
          final toCurrency   = widget.args['toCurrency']?.toString() ?? 'GBP';
          ref.invalidate(_exchangeRateProvider('${fromCurrency}_$toCurrency'));
        }
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  double get _amount =>
      double.tryParse(widget.args['amount']?.toString() ?? '0') ?? 0;

  // African destination currencies — zero transfer fee (competitive advantage)
  static const _africaCurrencies = {
    'NGN', 'GHS', 'KES', 'ZAR', 'UGX', 'TZS', 'RWF', 'ETB',
    'ZMW', 'EGP', 'MAD', 'XOF', 'XAF', 'MZN', 'MWK', 'MGA',
    'TND', 'DZD', 'BIF', 'SOS', 'SDG', 'BWP', 'SZL', 'LSL',
  };

  // Flat fee: $1.50 USD equivalent in source currency.
  // Economy & Express are both Instant — same fee.
  // Africa: always FREE.
  double _fee(double amount) {
    final fromCurrency = widget.args['fromCurrency']?.toString() ?? 'USD';
    final toCurrency   = widget.args['toCurrency']?.toString()   ?? '';
    if (_africaCurrencies.contains(toCurrency)) return 0.0;
    // Convert $1.50 flat USD fee to the source wallet currency
    final fromRate = _midMarketRates[fromCurrency] ?? 1.0;
    return double.parse((1.50 * fromRate).toStringAsFixed(2));
  }

  String get _timerLabel {
    final m = (_timerSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_timerSeconds  % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Color get _timerColor {
    if (_timerSeconds > 60) return Colors.green;
    if (_timerSeconds > 30) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final fromCurrency = widget.args['fromCurrency']?.toString() ?? 'USD';
    final toCurrency   = widget.args['toCurrency']?.toString() ?? 'GBP';
    final toFlag       = widget.args['toFlag']?.toString() ?? '🌍';
    final toCountry    = widget.args['toCountry']?.toString() ?? '';
    final ratePair     = '${fromCurrency}_$toCurrency';

    final rateAsync = ref.watch(_exchangeRateProvider(ratePair));
    final methods   = _deliveryMethodsFor(toCurrency);

    // Ensure selected delivery method is available
    if (!methods.contains(_deliveryMethod)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _deliveryMethod = methods.first);
      });
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Transfer Quote',
          style: TextStyle(color: Color(0xFF1A1A2E), fontSize: 18, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1A2E)),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Rate lock timer
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _timerColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _timerColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, size: 13, color: _timerColor),
                const SizedBox(width: 4),
                Text(
                  'Rate locked $_timerLabel',
                  style: TextStyle(fontSize: 11, color: _timerColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
      body: rateAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: _teal),
              SizedBox(height: 16),
              Text('Getting the best rate for you...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              const Text('Failed to get exchange rate'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(_exchangeRateProvider(ratePair)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (rate) {
          final fee            = _fee(_amount);
          final recipientAmount = (_amount - fee) * rate;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [

                // ── Route card ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: _cardDeco(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _CurrencyChip(flag: _flagForCurrency(fromCurrency), currency: fromCurrency),
                      Expanded(
                        child: Column(
                          children: [
                            const Icon(Icons.arrow_forward_rounded, color: _teal),
                            Text('~${_calcTime()}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      _CurrencyChip(flag: toFlag, currency: toCurrency),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Prominent "Recipient gets" hero ─────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_teal, _teal.withOpacity(0.8)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text('${toFlag.isNotEmpty ? toFlag : '🌍'} Recipient gets',
                          style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text(
                        '${_formatAmount(recipientAmount)} $toCurrency',
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.verified_rounded, size: 14, color: Colors.greenAccent),
                          const SizedBox(width: 6),
                          const Text('0% rate markup · Mid-market rate',
                              style: TextStyle(fontSize: 12, color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Economy / Express toggle (Remitly style) ────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDeco(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Choose your speed', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _TierTile(
                            label: 'Economy',
                            speed: 'Instant ⚡',
                            fee: _fee(_amount) == 0.0 ? '🎉 FREE' : '${_fee(_amount).toStringAsFixed(2)} $fromCurrency',
                            saving: _fee(_amount) == 0.0 ? '0% fee for Africa' : 'Lowest flat fee',
                            selected: _isEconomy,
                            color: _teal,
                            onTap: () => setState(() => _isEconomy = true),
                          )),
                          const SizedBox(width: 10),
                          Expanded(child: _TierTile(
                            label: 'Express',
                            speed: 'Instant ⚡',
                            fee: _fee(_amount) == 0.0 ? '🎉 FREE' : '${_fee(_amount).toStringAsFixed(2)} $fromCurrency',
                            saving: 'Priority + support',
                            selected: !_isEconomy,
                            color: Colors.orange,
                            onTap: () => setState(() => _isEconomy = false),
                          )),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Delivery method (WorldRemit style) ──────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDeco(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Delivery method', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: methods.map((m) => GestureDetector(
                          onTap: () => setState(() => _deliveryMethod = m),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: _deliveryMethod == m ? m.color.withOpacity(0.12) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _deliveryMethod == m ? m.color : Colors.grey.shade200,
                                width: _deliveryMethod == m ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(m.icon, size: 16, color: _deliveryMethod == m ? m.color : Colors.grey),
                                const SizedBox(width: 6),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                        color: _deliveryMethod == m ? m.color : const Color(0xFF1A1A2E))),
                                    Text(m.description, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Exchange rate ────────────────────────────────────────
                _InfoCard(
                  icon: Icons.currency_exchange_rounded,
                  iconColor: Colors.blue,
                  iconBg: Colors.blue.withOpacity(0.1),
                  title: 'Exchange Rate',
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _teal.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('1 $fromCurrency',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(Icons.compare_arrows_rounded, color: _teal),
                            ),
                            Text('${rate.toStringAsFixed(4)} $toCurrency',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0D6B5E))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.verified_rounded, size: 14, color: Colors.green),
                          const SizedBox(width: 6),
                          Text('Mid-market rate · No markup',
                              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Fee breakdown ────────────────────────────────────────
                _InfoCard(
                  icon: Icons.receipt_long_rounded,
                  iconColor: Colors.orange,
                  iconBg: Colors.orange.withOpacity(0.1),
                  title: 'Fee Breakdown',
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      _BreakdownRow(label: 'You send', value: '${_formatAmount(_amount)} $fromCurrency', isTotal: false),
                      const Divider(height: 20),
                      _BreakdownRow(
                        label: '${_isEconomy ? 'Economy' : 'Express'} fee',
                        value: fee == 0.0 ? '🎉 FREE' : '- ${fee.toStringAsFixed(2)} $fromCurrency',
                        valueColor: fee == 0.0 ? Colors.green : Colors.orange,
                        isTotal: false,
                      ),
                      const Divider(height: 20),
                      _BreakdownRow(
                        label: 'Amount converted',
                        value: '${(_amount - fee).toStringAsFixed(2)} $fromCurrency',
                        isTotal: false,
                      ),
                      const Divider(height: 20),
                      _BreakdownRow(
                        label: 'Recipient gets',
                        value: '${_formatAmount(recipientAmount)} $toCurrency',
                        isTotal: true,
                        valueColor: _teal,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Arrival estimate ─────────────────────────────────────
                _InfoCard(
                  icon: Icons.schedule_rounded,
                  iconColor: Colors.purple,
                  iconBg: Colors.purple.withOpacity(0.1),
                  title: 'Estimated Arrival',
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Instant ⚡',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.grey[800]),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'via ${_deliveryMethod.label}',
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('On time',
                              style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ── No hidden fees assurance ─────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No hidden fees. The rate shown is exactly what your recipient gets.',
                          style: TextStyle(fontSize: 12, color: Colors.green[700], fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Confirm button ───────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final confirmArgs = {
                        ...widget.args,
                        'rate': rate,
                        'fee': fee,
                        'recipientAmount': recipientAmount,
                        'toCurrency': toCurrency,
                        'toCountry': toCountry,
                        'toFlag': toFlag,
                        'estimatedArrival': 'Instantly',
                        'deliveryMethod': _deliveryMethod.label,
                        'tier': _isEconomy ? 'Economy' : 'Express',
                      };
                      context.push('/transfers/confirm', extra: confirmArgs);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Confirm Transfer'),
                  ),
                ),

                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer_outlined, size: 13, color: _timerColor),
                    const SizedBox(width: 4),
                    Text(
                      'Rate guaranteed for $_timerLabel',
                      style: TextStyle(fontSize: 12, color: _timerColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  BoxDecoration _cardDeco() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4))],
  );

  String _flagForCurrency(String currency) {
    const map = {
      'USD':'🇺🇸','EUR':'🇪🇺','GBP':'🇬🇧','CAD':'🇨🇦','AUD':'🇦🇺',
      'JPY':'🇯🇵','NGN':'🇳🇬','GHS':'🇬🇭','KES':'🇰🇪','ZAR':'🇿🇦',
      'INR':'🇮🇳','CNY':'🇨🇳','CHF':'🇨🇭','SEK':'🇸🇪','NOK':'🇳🇴',
      'DKK':'🇩🇰','PLN':'🇵🇱','HUF':'🇭🇺','TRY':'🇹🇷','BRL':'🇧🇷',
      'MXN':'🇲🇽','ARS':'🇦🇷','AED':'🇦🇪','SAR':'🇸🇦','SGD':'🇸🇬',
      'HKD':'🇭🇰','KRW':'🇰🇷','THB':'🇹🇭','MYR':'🇲🇾','IDR':'🇮🇩',
      'PHP':'🇵🇭','VND':'🇻🇳','PKR':'🇵🇰','BDT':'🇧🇩','EGP':'🇪🇬',
    };
    return map[currency] ?? '🌍';
  }

  String _formatAmount(double v) =>
      v >= 1000 ? v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},') : v.toStringAsFixed(2);

  String _calcTime() => 'Instant';
}

// ---------------------------------------------------------------------------
// Economy/Express tier tile
// ---------------------------------------------------------------------------
class _TierTile extends StatelessWidget {
  final String label;
  final String speed;
  final String fee;
  final String saving;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TierTile({
    required this.label, required this.speed, required this.fee,
    required this.saving, required this.selected, required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? color : Colors.grey.shade200, width: selected ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: selected ? color : const Color(0xFF1A1A2E))),
                if (selected)
                  Icon(Icons.check_circle_rounded, size: 16, color: color),
              ],
            ),
            const SizedBox(height: 6),
            Text(speed, style: TextStyle(fontSize: 12, color: selected ? color : Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(fee, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(saving, style: TextStyle(fontSize: 11, color: selected ? color : Colors.grey[400], fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------
class _CurrencyChip extends StatelessWidget {
  final String flag;
  final String currency;
  const _CurrencyChip({required this.flag, required this.currency});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(flag, style: const TextStyle(fontSize: 32)),
      const SizedBox(height: 4),
      Text(currency, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
    ],
  );
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final Widget child;

  const _InfoCard({required this.icon, required this.iconColor,
      required this.iconBg, required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          ],
        ),
        child,
      ],
    ),
  );
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  final Color? valueColor;
  const _BreakdownRow({required this.label, required this.value, required this.isTotal, this.valueColor});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(
        fontSize: isTotal ? 15 : 14,
        fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
        color: isTotal ? const Color(0xFF1A1A2E) : Colors.grey[600],
      )),
      Text(value, style: TextStyle(
        fontSize: isTotal ? 16 : 14,
        fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
        color: valueColor ?? (isTotal ? const Color(0xFF1A1A2E) : Colors.grey[700]),
      )),
    ],
  );
}
