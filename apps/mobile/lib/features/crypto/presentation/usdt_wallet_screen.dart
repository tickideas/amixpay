import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/providers/transaction_provider.dart';
import '../../wallet/presentation/wallet_screen.dart' show walletCurrenciesProvider, WalletCurrenciesNotifier, WalletCurrency;

// ── USDT wallet balance provider (separate from fiat wallets) ────────────────

class _UsdtNotifier extends StateNotifier<double> {
  _UsdtNotifier() : super(0.00);

  void add(double amount) => state = state + amount;
  void subtract(double amount) {
    if (amount > state) throw Exception('Insufficient USDT balance');
    state = state - amount;
  }

  void set(double amount) => state = amount;
}

final usdtBalanceProvider =
    StateNotifierProvider<_UsdtNotifier, double>((_) => _UsdtNotifier());

// Simulated deposit addresses
const _usdtAddressTrc20 = 'TAmxPay9vXkR3d8qLmZ1bUc7nWpQeS4FHj';
const _usdtAddressErc20 = '0xAmxPay5a2b3c4d5e6f7890abcdef1234567890AB';
const _btcAddress = 'bc1qAmxPay7yz8abc9def0ghi1jkl2mno3pqr4stu';

// ── Screen ───────────────────────────────────────────────────────────────────

class UsdtWalletScreen extends ConsumerStatefulWidget {
  const UsdtWalletScreen({super.key});
  @override
  ConsumerState<UsdtWalletScreen> createState() => _UsdtWalletScreenState();
}

class _UsdtWalletScreenState extends ConsumerState<UsdtWalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _selectedNetwork = 'TRC-20';
  final _sendAmtCtrl = TextEditingController();
  final _sendAddressCtrl = TextEditingController();
  bool _sending = false;

  static const _teal = Color(0xFF0D6B5E);
  static const _usdtGreen = Color(0xFF10B981);
  final _fmt = NumberFormat('#,##0.00####');

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _sendAmtCtrl.dispose();
    _sendAddressCtrl.dispose();
    super.dispose();
  }

  String get _depositAddress {
    switch (_selectedNetwork) {
      case 'TRC-20':
        return _usdtAddressTrc20;
      case 'ERC-20':
        return _usdtAddressErc20;
      default:
        return _btcAddress;
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = ref.watch(usdtBalanceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: _usdtGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('USDT Wallet',
            style: TextStyle(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Deposit'),
            Tab(text: 'Send'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildOverview(balance),
          _buildDeposit(),
          _buildSend(balance),
        ],
      ),
    );
  }

  // ── Overview ────────────────────────────────────────────────────────────────
  Widget _buildOverview(double balance) {
    final usdEquiv = balance; // USDT is 1:1 with USD
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // Balance card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF0D9488)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: _usdtGreen.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 6))
            ],
          ),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('USDT Balance',
                    style:
                        TextStyle(color: Colors.white70, fontSize: 13)),
                SizedBox(height: 4),
                Text('Tether USD (ERC-20 / TRC-20)',
                    style: TextStyle(color: Colors.white54, fontSize: 11)),
              ]),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('💲', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 4),
                  Text('USDT',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ]),
              ),
            ]),
            const SizedBox(height: 20),
            Text('\$${_fmt.format(balance)} USDT',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('≈ USD \$${_fmt.format(usdEquiv)}',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: _CardAction(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Deposit',
                  onTap: () => _tabs.animateTo(1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CardAction(
                  icon: Icons.send_rounded,
                  label: 'Send',
                  onTap: () => _tabs.animateTo(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CardAction(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Convert',
                  onTap: () => _showConvertSheet(balance),
                ),
              ),
            ]),
          ]),
        ),

        const SizedBox(height: 20),

        // Info cards
        Row(children: [
          Expanded(
            child: _StatCard(
              label: 'USD Value',
              value: '\$${_fmt.format(usdEquiv)}',
              icon: Icons.attach_money_rounded,
              color: _usdtGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label: 'USDT Rate',
              value: '1 USDT = \$1.00',
              icon: Icons.trending_flat_rounded,
              color: _teal,
            ),
          ),
        ]),

        const SizedBox(height: 20),

        // Network badges
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Supported Networks',
                  style:
                      TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 14),
              Row(children: [
                _NetworkBadge('TRC-20', 'TRON', Colors.red),
                const SizedBox(width: 10),
                _NetworkBadge('ERC-20', 'Ethereum', const Color(0xFF6366F1)),
                const SizedBox(width: 10),
                _NetworkBadge('BEP-20', 'BNB Chain', const Color(0xFFF59E0B)),
              ]),
              const SizedBox(height: 12),
              const Text(
                '⚡ TRC-20 recommended — lowest fees (~\$1) and fastest settlement (~3 min)',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Recent USDT transactions
        _UsdtTxHistory(),
      ]),
    );
  }

  // ── Deposit ─────────────────────────────────────────────────────────────────
  Widget _buildDeposit() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // Network selector
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Select Network',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 12),
            Row(children: [
              _NetChip('TRC-20', _selectedNetwork == 'TRC-20', Colors.red,
                  () => setState(() => _selectedNetwork = 'TRC-20')),
              const SizedBox(width: 8),
              _NetChip('ERC-20', _selectedNetwork == 'ERC-20',
                  const Color(0xFF6366F1),
                  () => setState(() => _selectedNetwork = 'ERC-20')),
              const SizedBox(width: 8),
              _NetChip('BTC', _selectedNetwork == 'BTC',
                  const Color(0xFFF59E0B),
                  () => setState(() => _selectedNetwork = 'BTC')),
            ]),
          ]),
        ),

        const SizedBox(height: 20),

        // QR Code
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _usdtGreen.withValues(alpha: 0.3), width: 2),
              ),
              child: QrImageView(
                data: _depositAddress,
                version: QrVersions.auto,
                size: 180,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF10B981),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${_selectedNetwork == 'BTC' ? 'BTC' : 'USDT'} Deposit Address ($_selectedNetwork)',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(children: [
                Expanded(
                  child: Text(
                    _depositAddress,
                    style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: Color(0xFF1A1A2E)),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: _depositAddress));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Address copied!'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 1)),
                    );
                  },
                  child: const Icon(Icons.copy_rounded,
                      color: _usdtGreen, size: 20),
                ),
              ]),
            ),
          ]),
        ),

        const SizedBox(height: 16),

        // Warning
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.amber.shade700, size: 16),
                const SizedBox(width: 8),
                Text('Important',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.amber.shade800,
                        fontSize: 13)),
              ]),
              const SizedBox(height: 8),
              Text(
                '• Only send ${_selectedNetwork == 'BTC' ? 'BTC' : 'USDT ($_selectedNetwork)'} to this address\n'
                '• Minimum deposit: ${_selectedNetwork == 'BTC' ? '0.0001 BTC' : '5 USDT'}\n'
                '• Wrong network will result in permanent loss of funds',
                style: TextStyle(fontSize: 11, color: Colors.amber.shade800),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Simulate deposit button (demo only)
        ElevatedButton.icon(
          onPressed: () => _simulateDeposit(),
          icon: const Icon(Icons.add_circle_outline_rounded),
          label: const Text('Simulate Deposit (Demo)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _usdtGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
        const SizedBox(height: 8),
        const Text('Demo only — simulates a 100 USDT deposit',
            style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 20),
      ]),
    );
  }

  void _simulateDeposit() {
    ref.read(usdtBalanceProvider.notifier).add(100.0);
    // Also credit USDT in wallet currencies list so it shows on wallet screen
    ref.read(walletCurrenciesProvider.notifier).addFunds('USDT', 100.0);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('100 USDT deposited successfully!'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Send ─────────────────────────────────────────────────────────────────────
  Widget _buildSend(double balance) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // Balance banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _usdtGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _usdtGreen.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            const Text('💲', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Available USDT',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('\$${_fmt.format(balance)} USDT',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF10B981))),
            ]),
          ]),
        ),

        const SizedBox(height: 20),

        // Network selector
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Network',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 10),
            Row(children: [
              _NetChip('TRC-20', _selectedNetwork == 'TRC-20', Colors.red,
                  () => setState(() => _selectedNetwork = 'TRC-20')),
              const SizedBox(width: 8),
              _NetChip('ERC-20', _selectedNetwork == 'ERC-20',
                  const Color(0xFF6366F1),
                  () => setState(() => _selectedNetwork = 'ERC-20')),
            ]),
          ]),
        ),

        const SizedBox(height: 16),

        // Address
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Recipient Address',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            TextField(
              controller: _sendAddressCtrl,
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: _selectedNetwork == 'TRC-20'
                    ? 'T... TRON address'
                    : '0x... Ethereum address',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner_rounded,
                      color: _usdtGreen),
                  onPressed: () => context.push(AppRoutes.qrScanner),
                ),
              ),
            ),
          ]),
        ),

        const SizedBox(height: 16),

        // Amount
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Amount (USDT)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _sendAmtCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.black12),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const Text('USDT',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _usdtGreen)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              for (final q in ['10', '50', '100', '500']) ...[
                GestureDetector(
                  onTap: () {
                    _sendAmtCtrl.text = q;
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: _usdtGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _usdtGreen.withValues(alpha: 0.2)),
                    ),
                    child: Text('+$q',
                        style: const TextStyle(
                            fontSize: 12,
                            color: _usdtGreen,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ]),
          ]),
        ),

        const SizedBox(height: 16),

        // Fee notice
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Network Fee',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              Text(
                _selectedNetwork == 'TRC-20' ? '~1 USDT (TRX)' : '~2–5 USDT (ETH gas)',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Send button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _sending ? null : () => _sendUsdt(balance),
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white)))
                : const Icon(Icons.send_rounded),
            label: Text(_sending
                ? 'Sending...'
                : 'Send USDT'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _usdtGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
              textStyle: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }

  void _sendUsdt(double balance) {
    final address = _sendAddressCtrl.text.trim();
    final amount = double.tryParse(_sendAmtCtrl.text.trim()) ?? 0.0;

    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enter recipient address'),
          behavior: SnackBarBehavior.floating));
      return;
    }
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enter a valid amount'),
          behavior: SnackBarBehavior.floating));
      return;
    }
    if (amount > balance) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Insufficient USDT balance. Available: ${_fmt.format(balance)} USDT'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating));
      return;
    }

    // Confirm dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Send'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _ConfirmRow('Amount', '${_fmt.format(amount)} USDT'),
          _ConfirmRow('Network', _selectedNetwork),
          _ConfirmRow('Fee', _selectedNetwork == 'TRC-20' ? '~1 USDT' : '~2–5 USDT'),
          _ConfirmRow('To', '${address.substring(0, 8)}...${address.substring(address.length - 6)}'),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _executeSend(amount);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _usdtGreen, foregroundColor: Colors.white),
            child: const Text('Confirm Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeSend(double amount) async {
    setState(() => _sending = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    try {
      ref.read(usdtBalanceProvider.notifier).subtract(amount);
      ref.read(walletCurrenciesProvider.notifier).addFunds('USDT', -amount);
    } catch (_) {}
    _sendAmtCtrl.clear();
    _sendAddressCtrl.clear();
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${_fmt.format(amount)} USDT sent successfully!'),
      backgroundColor: _usdtGreen,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Convert USDT → Fiat ──────────────────────────────────────────────────────
  void _showConvertSheet(double balance) {
    String toCurrency = 'USD';
    final amtCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        final amt = double.tryParse(amtCtrl.text) ?? 0.0;
        return Padding(
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Convert USDT',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: amtCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setSt(() {}),
              decoration: const InputDecoration(
                labelText: 'USDT Amount',
                border: OutlineInputBorder(),
                suffixText: 'USDT',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: toCurrency,
              decoration: const InputDecoration(
                  labelText: 'Convert to', border: OutlineInputBorder()),
              items: ['USD', 'GBP', 'EUR', 'NGN', 'GHS', 'KES']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setSt(() => toCurrency = v!),
            ),
            const SizedBox(height: 12),
            if (amt > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: _usdtGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('You receive'),
                      Text(
                          '${amt.toStringAsFixed(2)} $toCurrency',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _usdtGreen)),
                    ]),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: amt <= 0 || amt > balance
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        ref
                            .read(usdtBalanceProvider.notifier)
                            .subtract(amt);
                        ref
                            .read(walletCurrenciesProvider.notifier)
                            .addFunds(toCurrency, amt);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              'Converted ${amt.toStringAsFixed(2)} USDT → ${amt.toStringAsFixed(2)} $toCurrency'),
                          backgroundColor: _usdtGreen,
                          behavior: SnackBarBehavior.floating,
                        ));
                      },
                style: ElevatedButton.styleFrom(
                    backgroundColor: _usdtGreen,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                child: const Text('Convert Now',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        );
      }),
    );
  }
}

// ── USDT Transaction History ─────────────────────────────────────────────────

class _UsdtTxHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final txns = [
      _UsdtTx('Deposit', '+100.00 USDT', 'Mar 19 · 10:00 AM', true, 'TRC-20'),
      _UsdtTx('Send to 0x4a2b...', '-50.00 USDT', 'Mar 18 · 3:15 PM', false, 'ERC-20'),
      _UsdtTx('Convert to NGN', '-200.00 USDT', 'Mar 17 · 9:30 AM', false, 'Internal'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Recent Activity',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          ),
          ...txns.map((t) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (t.isCredit
                              ? const Color(0xFF10B981)
                              : Colors.redAccent)
                          .withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      t.isCredit
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: t.isCredit
                          ? const Color(0xFF10B981)
                          : Colors.redAccent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(t.date,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                        ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(t.amount,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: t.isCredit
                                ? const Color(0xFF10B981)
                                : Colors.redAccent)),
                    Text(t.network,
                        style: const TextStyle(
                            fontSize: 10, color: Colors.grey)),
                  ]),
                ]),
              )),
        ],
      ),
    );
  }
}

class _UsdtTx {
  final String title, amount, date, network;
  final bool isCredit;
  const _UsdtTx(this.title, this.amount, this.date, this.isCredit, this.network);
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _CardAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _CardAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 14)),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
      );
}

class _NetworkBadge extends StatelessWidget {
  final String code, chain;
  final Color color;
  const _NetworkBadge(this.code, this.chain, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Text(code,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color)),
          Text(chain,
              style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.7))),
        ]),
      );
}

class _NetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _NetChip(this.label, this.selected, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.12) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? color : Colors.grey.shade300,
                width: selected ? 2 : 1),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? color : Colors.grey)),
        ),
      );
}

class _ConfirmRow extends StatelessWidget {
  final String label, value;
  const _ConfirmRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey)),
              Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
      );
}
