import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class TransferConfirmScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> args;
  const TransferConfirmScreen({super.key, required this.args});

  @override
  ConsumerState<TransferConfirmScreen> createState() =>
      _TransferConfirmScreenState();
}

class _TransferConfirmScreenState
    extends ConsumerState<TransferConfirmScreen> {
  static const Color _teal = Color(0xFF0D6B5E);
  static const Color _bg = Color(0xFFF5F7FA);

  bool _loading = false;
  bool _agreed = false;

  Future<void> _submitTransfer() async {
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please agree to the terms before submitting'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _loading = false);
    // Generate a mock transfer ID
    final transferId =
        'TXN${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    context.go('/transfers/status/$transferId');
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.args;
    final fromCurrency = a['fromCurrency']?.toString() ?? 'USD';
    final toCurrency = a['toCurrency']?.toString() ?? 'GBP';
    final toFlag = a['toFlag']?.toString() ?? '🌍';
    final toCountry = a['toCountry']?.toString() ?? '';
    final amount = double.tryParse(a['amount']?.toString() ?? '0') ?? 0;
    final fee = (a['fee'] as num?)?.toDouble() ?? 0;
    final rate = (a['rate'] as num?)?.toDouble() ?? 1;
    final recipientAmount =
        (a['recipientAmount'] as num?)?.toDouble() ?? 0;
    final recipientName = a['recipientName']?.toString() ?? '';
    final accountNumber = a['accountNumber']?.toString() ?? '';
    final iban = a['iban']?.toString() ?? '';
    final bankName = a['bankName']?.toString() ?? '';
    final estimatedArrival =
        a['estimatedArrival']?.toString() ?? 'Instantly';
    final deliveryMethod = a['deliveryMethod']?.toString() ?? 'Bank Transfer';
    final tier = a['tier']?.toString() ?? 'Economy';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Review Transfer',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Transfer summary header ----
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D6B5E), Color(0xFF0A9E8A)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'You send',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${amount.toStringAsFixed(2)} $fromCurrency',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white70),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Text(toFlag,
                                  style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 4),
                              const Text(
                                'Recipient gets',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${recipientAmount.toStringAsFixed(2)} $toCurrency',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _HeaderStat(
                        label: 'Rate',
                        value: '1 $fromCurrency = ${rate.toStringAsFixed(4)} $toCurrency',
                      ),
                      _HeaderStat(label: 'Speed', value: tier),
                      _HeaderStat(label: 'Via', value: deliveryMethod),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ---- Recipient details ----
            _SectionCard(
              icon: Icons.person_rounded,
              iconColor: Colors.blue,
              iconBg: Colors.blue.withOpacity(0.1),
              title: 'Recipient Details',
              rows: [
                _DetailRow(label: 'Name', value: recipientName),
                _DetailRow(label: 'Country', value: '$toFlag  $toCountry'),
                _DetailRow(label: 'Account Number', value: accountNumber),
                _DetailRow(label: 'IBAN / Routing', value: iban),
                _DetailRow(label: 'Bank', value: bankName),
              ],
            ),

            const SizedBox(height: 16),

            // ---- Payment summary ----
            _SectionCard(
              icon: Icons.receipt_long_rounded,
              iconColor: Colors.orange,
              iconBg: Colors.orange.withOpacity(0.1),
              title: 'Payment Summary',
              rows: [
                _DetailRow(
                  label: 'Source Amount',
                  value: '${amount.toStringAsFixed(2)} $fromCurrency',
                ),
                _DetailRow(
                  label: 'Transfer Fee',
                  value: '${fee.toStringAsFixed(2)} $fromCurrency',
                  valueColor: Colors.orange,
                ),
                _DetailRow(
                  label: 'Exchange Rate',
                  value:
                      '1 $fromCurrency = ${rate.toStringAsFixed(4)} $toCurrency',
                ),
                _DetailRow(
                  label: 'Target Amount',
                  value:
                      '${recipientAmount.toStringAsFixed(2)} $toCurrency',
                  isTotal: true,
                  valueColor: _teal,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ---- Security notice ----
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FAF8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.teal.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D6B5E).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_rounded,
                        color: Color(0xFF0D6B5E), size: 16),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'This transfer is processed securely with real mid-market exchange rates.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF0D6B5E)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ---- Agreement checkbox ----
            GestureDetector(
              onTap: () => setState(() => _agreed = !_agreed),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _agreed,
                    onChanged: (v) =>
                        setState(() => _agreed = v ?? false),
                    activeColor: _teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'I confirm the recipient details are correct and agree to the AmixPay Transfer Terms and Conditions.',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ---- Submit button ----
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submitTransfer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _teal.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Submit Transfer'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------
class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  const _HeaderStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final List<_DetailRow> rows;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: r,
              )),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[500],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 15 : 13,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
            color: valueColor ?? const Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }
}
