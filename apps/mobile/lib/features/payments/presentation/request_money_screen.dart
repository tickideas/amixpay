import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../wallet/presentation/wallet_screen.dart' show walletCurrenciesProvider;

class RequestMoneyScreen extends ConsumerStatefulWidget {
  const RequestMoneyScreen({super.key});
  @override
  ConsumerState<RequestMoneyScreen> createState() => _RequestMoneyScreenState();
}

class _RequestMoneyScreenState extends ConsumerState<RequestMoneyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _usernameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _currency; // null = use primary wallet currency
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _buildQrPayload(String username, String currency) {
    final amt = _amountController.text.trim();
    final note = Uri.encodeComponent(_noteController.text.trim());
    return 'amixpay://pay?to=@$username&amount=$amt&currency=$currency&note=$note';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value?.user;
    final username = user?.username ?? 'me';
    final wallets = ref.watch(walletCurrenciesProvider);
    final primaryCurrency = wallets.isNotEmpty ? wallets.first.code : 'USD';
    final effectiveCurrency = _currency ?? primaryCurrency;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: BackButton(color: AppColors.textPrimary),
        title: const Text('Request Money', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'By Username', icon: Icon(Icons.alternate_email_rounded, size: 18)),
            Tab(text: 'Share QR', icon: Icon(Icons.qr_code_rounded, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsernameTab(effectiveCurrency),
          _buildQrTab(username, effectiveCurrency),
        ],
      ),
    );
  }

  Widget _buildUsernameTab(String currency) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text('Request from someone by their @username or email', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        const SizedBox(height: 20),
        // Recipient
        _label('Request From'),
        const SizedBox(height: 6),
        TextField(
          controller: _usernameController,
          decoration: const InputDecoration(
            hintText: '@username or email',
            prefixIcon: Icon(Icons.alternate_email_rounded, color: AppColors.textSecondary, size: 20),
          ),
        ),
        const SizedBox(height: 16),
        // Amount row
        _label('Amount'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(hintText: '0.00'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currency,
                items: ['USD', 'EUR', 'GBP', 'NGN', 'KES', 'GHS', 'ZAR', 'XAF', 'BRL', 'AUD', 'CAD', 'INR'].map((c) => DropdownMenuItem(value: c, child: Row(mainAxisSize: MainAxisSize.min, children: [Text(currencyFlag(c), style: const TextStyle(fontSize: 16)), const SizedBox(width: 6), Text(c)]))).toList(),
                onChanged: (v) => setState(() => _currency = v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _label('Note (optional)'),
        const SizedBox(height: 6),
        TextField(
          controller: _noteController,
          maxLines: 2,
          decoration: const InputDecoration(hintText: 'What is this for?'),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _loading ? null : _sendRequest,
          icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white))) : const Icon(Icons.send_rounded, size: 18),
          label: Text(_loading ? 'Sending...' : 'Send Request'),
        ),
      ],
    ),
  );

  Widget _buildQrTab(String username, String currency) {
    final amt = _amountController.text.trim();
    final hasAmount = amt.isNotEmpty && double.tryParse(amt) != null && double.parse(amt) > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text('Share this QR code — the payer scans it and the amount is pre-filled.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 20),
          // Amount to embed in QR
          _label('Amount to Request'),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(hintText: '0.00'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: currency,
                  items: ['USD', 'EUR', 'GBP', 'NGN', 'KES', 'GHS', 'ZAR', 'AUD', 'CAD', 'INR'].map((c) => DropdownMenuItem(value: c, child: Row(mainAxisSize: MainAxisSize.min, children: [Text(currencyFlag(c), style: const TextStyle(fontSize: 16)), const SizedBox(width: 6), Text(c)]))).toList(),
                  onChanged: (v) => setState(() => _currency = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _label('Note (optional)'),
          const SizedBox(height: 6),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(hintText: 'What is this for?'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          // QR Code
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: _buildQrPayload(username, currency),
                    version: QrVersions.auto,
                    size: 220,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.primary),
                    dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Text('@$username', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 16)),
                        if (hasAmount) Text('Request: $currency $amt', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Share / Copy buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _buildQrPayload(username, currency)));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment link copied!'), backgroundColor: AppColors.primary));
                  },
                  icon: const Icon(Icons.link_rounded, size: 18),
                  label: const Text('Copy Link'),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary), foregroundColor: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sharing QR code...'), backgroundColor: AppColors.primary)),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Share QR'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary));

  void _sendRequest() {
    if (_usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a username or email')));
      return;
    }
    setState(() => _loading = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Request sent to ${_usernameController.text}!'),
        backgroundColor: AppColors.success,
      ));
      Navigator.pop(context);
    });
  }
}
