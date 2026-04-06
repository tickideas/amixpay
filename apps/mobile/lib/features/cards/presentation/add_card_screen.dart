import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../wallet/presentation/wallet_screen.dart' show walletCurrenciesProvider;
import '../data/user_cards_provider.dart';

class AddCardScreen extends ConsumerStatefulWidget {
  const AddCardScreen({super.key});
  @override
  ConsumerState<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends ConsumerState<AddCardScreen> {
  String _cardType = 'virtual'; // 'virtual' | 'disposable' | 'physical'
  final _nameController = TextEditingController();
  final _limitController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  String _currency = 'USD';
  String _gradientKey = 'physical';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Pre-select primary wallet currency
      final currencies = ref.read(walletCurrenciesProvider);
      if (currencies.isNotEmpty) {
        final primary = currencies.first.code;
        const supported = ['USD', 'EUR', 'GBP', 'NGN', 'KES', 'GHS', 'ZAR', 'AUD', 'CAD', 'INR'];
        if (supported.contains(primary)) setState(() => _currency = primary);
      }
      // Auto-fill cardholder name from auth
      final user = ref.read(authProvider).value?.user;
      if (user != null) {
        final name = '${user.firstName} ${user.lastName}'.trim();
        if (name.isNotEmpty && _nameController.text.isEmpty) {
          setState(() => _nameController.text = name);
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  LinearGradient get _selectedGradient => cardGradientFor(_gradientKey);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: BackButton(color: AppColors.textPrimary),
        title: const Text('Get a Card', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card type toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  _TypeTab(label: 'Virtual Card', icon: Icons.credit_card_rounded, selected: _cardType == 'virtual', onTap: () => setState(() => _cardType = 'virtual')),
                  _TypeTab(label: 'Disposable', icon: Icons.timer_outlined, selected: _cardType == 'disposable', onTap: () => setState(() => _cardType = 'disposable')),
                  _TypeTab(label: 'Physical ATM', icon: Icons.credit_card_off_rounded, selected: _cardType == 'physical', onTap: () => setState(() => _cardType = 'physical')),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Card live preview
            Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: _selectedGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('VISA', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 2)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                        child: Text(_cardType == 'disposable' ? 'DISPOSABLE' : _cardType == 'physical' ? 'PHYSICAL' : 'VIRTUAL', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Text('•••• •••• •••• ••••', style: TextStyle(color: Colors.white70, fontSize: 18, letterSpacing: 4)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        _nameController.text.isEmpty ? 'YOUR NAME' : _nameController.text.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('EXPIRES', style: TextStyle(color: Colors.white54, fontSize: 9, letterSpacing: 1)),
                          Text('08/29', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Gradient / colour picker
            const Text('Card Color', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: kCardGradientOptions.map((opt) {
                  final selected = _gradientKey == opt.key;
                  return GestureDetector(
                    onTap: () => setState(() => _gradientKey = opt.key),
                    child: Container(
                      width: 48,
                      height: 48,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        gradient: opt.gradient,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? AppColors.primary : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: selected
                            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 8)]
                            : [],
                      ),
                      child: selected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Info badge
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (_cardType == 'physical' ? AppColors.warning : _cardType == 'disposable' ? AppColors.primary : AppColors.info).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: (_cardType == 'physical' ? AppColors.warning : _cardType == 'disposable' ? AppColors.primary : AppColors.info).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    _cardType == 'physical' ? Icons.local_shipping_rounded : _cardType == 'disposable' ? Icons.timer_outlined : Icons.flash_on_rounded,
                    color: _cardType == 'physical' ? AppColors.warning : _cardType == 'disposable' ? AppColors.primary : AppColors.info,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _cardType == 'physical'
                          ? 'Free delivery to your address. Works at ATMs and POS terminals in 150+ countries. Delivery in 5-7 business days.'
                          : _cardType == 'disposable'
                              ? 'Single-use card. Freezes automatically after first transaction. Perfect for one-off online purchases.'
                              : 'Instant. Use online, in apps, and for subscriptions. Works with Apple Pay & Google Pay.',
                      style: TextStyle(fontSize: 13, color: _cardType == 'physical' ? AppColors.warning : _cardType == 'disposable' ? AppColors.primary : AppColors.info),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Common fields
            _field('Cardholder Name', 'Your full name', _nameController, Icons.person_outline_rounded),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _field('Spending Limit (optional)', '1000', _limitController, Icons.shield_outlined, keyboardType: TextInputType.number),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Currency', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    DropdownButton<String>(
                      value: _currency,
                      underline: const SizedBox(),
                      items: ['USD', 'EUR', 'GBP', 'NGN', 'KES', 'GHS', 'ZAR', 'AUD', 'CAD', 'INR'].map((c) => DropdownMenuItem(value: c, child: Row(mainAxisSize: MainAxisSize.min, children: [Text(currencyFlag(c), style: const TextStyle(fontSize: 16)), const SizedBox(width: 6), Text(c)]))).toList(),
                      onChanged: (v) => setState(() => _currency = v!),
                    ),
                  ],
                ),
              ],
            ),

            // Physical card shipping address
            if (_cardType == 'physical') ...[
              const SizedBox(height: 20),
              const Text('Delivery Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 14),
              _field('Street Address', '123 Main Street', _addressController, Icons.location_on_outlined),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _field('City', 'Lagos', _cityController, Icons.location_city_outlined)),
                  const SizedBox(width: 12),
                  Expanded(child: _field('Country', 'Nigeria', _countryController, Icons.flag_outlined)),
                ],
              ),
            ],

            const SizedBox(height: 8),
            const Text('Spending limit resets monthly. Leave blank for no limit.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 20),

            // Fee notice for extra cards
            Builder(builder: (context) {
              final existingCards = ref.watch(userCardsProvider);
              final hasExtraCard = existingCards.length > 1;
              if (!hasExtraCard) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.card_giftcard_rounded, color: AppColors.success, size: 18),
                    SizedBox(width: 10),
                    Expanded(child: Text('Your first card is FREE forever.',
                        style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600))),
                  ]),
                );
              }
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Row(children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
                  SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('\$3.99/month fee', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
                    SizedBox(height: 2),
                    Text('Additional cards cost \$3.99/month each. Your first card is always free.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF92400E))),
                  ])),
                ]),
              );
            }),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _loading ? null : _issue,
              child: _loading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : Text(_cardType == 'physical' ? 'Request Physical Card' : _cardType == 'disposable' ? 'Issue Disposable Card' : 'Issue Virtual Card'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, String hint, TextEditingController ctrl, IconData icon, {TextInputType? keyboardType}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20)),
      ),
    ],
  );

  void _issue() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter cardholder name')));
      return;
    }
    if (_cardType == 'physical' && _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter delivery address')));
      return;
    }
    setState(() => _loading = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      ref.read(userCardsProvider.notifier).addCard(
        type: _cardType,
        holder: _nameController.text.trim(),
        currency: _currency,
        gradientKey: _gradientKey,
        isDisposable: _cardType == 'disposable',
      );
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_cardType == 'physical' ? 'Physical card requested! Arrives in 5-7 days.' : _cardType == 'disposable' ? 'Disposable card issued! Freezes after first use.' : 'Virtual card issued instantly!'),
        backgroundColor: AppColors.success,
      ));
      Navigator.pop(context);
    });
  }
}

// ── Gradient option model ──────────────────────────────────────────────────────

class _GradientOption {
  final String key;
  final LinearGradient gradient;
  final String label;
  const _GradientOption(this.key, this.gradient, this.label);
}

const kCardGradientOptions = [
  _GradientOption('physical', LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF16213E)], begin: Alignment.topLeft, end: Alignment.bottomRight), 'Dark'),
  _GradientOption('purple', LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)], begin: Alignment.topLeft, end: Alignment.bottomRight), 'Purple'),
  _GradientOption('gold', LinearGradient(colors: [Color(0xFFB8860B), Color(0xFFD4AF37)], begin: Alignment.topLeft, end: Alignment.bottomRight), 'Gold'),
  _GradientOption('rose', LinearGradient(colors: [Color(0xFFBE185D), Color(0xFF9D174D)], begin: Alignment.topLeft, end: Alignment.bottomRight), 'Rose'),
  _GradientOption('blue', LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF1E40AF)], begin: Alignment.topLeft, end: Alignment.bottomRight), 'Blue'),
  _GradientOption('primary', AppColors.cardGradient, 'Teal'),
];

LinearGradient cardGradientFor(String key) {
  return kCardGradientOptions.firstWhere((o) => o.key == key, orElse: () => kCardGradientOptions.first).gradient;
}

// ── Type tab ──────────────────────────────────────────────────────────────────

class _TypeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _TypeTab({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected ? [const BoxShadow(color: Color(0x0F000000), blurRadius: 8)] : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w400, color: selected ? AppColors.primary : AppColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );
}
