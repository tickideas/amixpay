import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'wallet_screen.dart';

const _teal = Color(0xFF0D6B5E);
const _bg = Color(0xFFF5F7FA);

class SupportedCurrency {
  final String flag;
  final String code;
  final String name;
  bool added;

  SupportedCurrency({
    required this.flag,
    required this.code,
    required this.name,
    this.added = false,
  });
}

final _allCurrencies = [
  // Popular / Default
  SupportedCurrency(flag: '🇺🇸', code: 'USD', name: 'US Dollar', added: true),
  SupportedCurrency(flag: '🇪🇺', code: 'EUR', name: 'Euro', added: true),
  SupportedCurrency(flag: '🇬🇧', code: 'GBP', name: 'British Pound', added: true),
  SupportedCurrency(flag: '🇨🇦', code: 'CAD', name: 'Canadian Dollar'),
  SupportedCurrency(flag: '🇦🇺', code: 'AUD', name: 'Australian Dollar'),
  SupportedCurrency(flag: '🇨🇭', code: 'CHF', name: 'Swiss Franc'),
  SupportedCurrency(flag: '🇳🇿', code: 'NZD', name: 'New Zealand Dollar'),
  // Africa
  SupportedCurrency(flag: '🇳🇬', code: 'NGN', name: 'Nigerian Naira'),
  SupportedCurrency(flag: '🇬🇭', code: 'GHS', name: 'Ghanaian Cedi'),
  SupportedCurrency(flag: '🇰🇪', code: 'KES', name: 'Kenyan Shilling'),
  SupportedCurrency(flag: '🇺🇬', code: 'UGX', name: 'Ugandan Shilling'),
  SupportedCurrency(flag: '🇹🇿', code: 'TZS', name: 'Tanzanian Shilling'),
  SupportedCurrency(flag: '🇿🇦', code: 'ZAR', name: 'South African Rand'),
  SupportedCurrency(flag: '🇨🇲', code: 'XAF', name: 'Central African CFA Franc'),
  SupportedCurrency(flag: '🇸🇳', code: 'XOF', name: 'West African CFA Franc'),
  SupportedCurrency(flag: '🇪🇹', code: 'ETB', name: 'Ethiopian Birr'),
  SupportedCurrency(flag: '🇷🇼', code: 'RWF', name: 'Rwandan Franc'),
  SupportedCurrency(flag: '🇿🇲', code: 'ZMW', name: 'Zambian Kwacha'),
  SupportedCurrency(flag: '🇲🇿', code: 'MZN', name: 'Mozambican Metical'),
  SupportedCurrency(flag: '🇨🇮', code: 'CIV', name: 'Ivorian CFA'),
  SupportedCurrency(flag: '🇲🇦', code: 'MAD', name: 'Moroccan Dirham'),
  SupportedCurrency(flag: '🇪🇬', code: 'EGP', name: 'Egyptian Pound'),
  // Asia
  SupportedCurrency(flag: '🇯🇵', code: 'JPY', name: 'Japanese Yen'),
  SupportedCurrency(flag: '🇨🇳', code: 'CNY', name: 'Chinese Yuan'),
  SupportedCurrency(flag: '🇮🇳', code: 'INR', name: 'Indian Rupee'),
  SupportedCurrency(flag: '🇰🇷', code: 'KRW', name: 'South Korean Won'),
  SupportedCurrency(flag: '🇸🇬', code: 'SGD', name: 'Singapore Dollar'),
  SupportedCurrency(flag: '🇭🇰', code: 'HKD', name: 'Hong Kong Dollar'),
  SupportedCurrency(flag: '🇹🇭', code: 'THB', name: 'Thai Baht'),
  SupportedCurrency(flag: '🇲🇾', code: 'MYR', name: 'Malaysian Ringgit'),
  SupportedCurrency(flag: '🇵🇭', code: 'PHP', name: 'Philippine Peso'),
  SupportedCurrency(flag: '🇮🇩', code: 'IDR', name: 'Indonesian Rupiah'),
  SupportedCurrency(flag: '🇻🇳', code: 'VND', name: 'Vietnamese Dong'),
  SupportedCurrency(flag: '🇵🇰', code: 'PKR', name: 'Pakistani Rupee'),
  SupportedCurrency(flag: '🇧🇩', code: 'BDT', name: 'Bangladeshi Taka'),
  SupportedCurrency(flag: '🇱🇰', code: 'LKR', name: 'Sri Lankan Rupee'),
  SupportedCurrency(flag: '🇳🇵', code: 'NPR', name: 'Nepalese Rupee'),
  SupportedCurrency(flag: '🇦🇪', code: 'AED', name: 'UAE Dirham'),
  SupportedCurrency(flag: '🇸🇦', code: 'SAR', name: 'Saudi Riyal'),
  SupportedCurrency(flag: '🇶🇦', code: 'QAR', name: 'Qatari Riyal'),
  SupportedCurrency(flag: '🇹🇷', code: 'TRY', name: 'Turkish Lira'),
  SupportedCurrency(flag: '🇮🇱', code: 'ILS', name: 'Israeli Shekel'),
  // South America
  SupportedCurrency(flag: '🇧🇷', code: 'BRL', name: 'Brazilian Real'),
  SupportedCurrency(flag: '🇦🇷', code: 'ARS', name: 'Argentine Peso'),
  SupportedCurrency(flag: '🇨🇱', code: 'CLP', name: 'Chilean Peso'),
  SupportedCurrency(flag: '🇨🇴', code: 'COP', name: 'Colombian Peso'),
  SupportedCurrency(flag: '🇵🇪', code: 'PEN', name: 'Peruvian Sol'),
  SupportedCurrency(flag: '🇲🇽', code: 'MXN', name: 'Mexican Peso'),
  SupportedCurrency(flag: '🇺🇾', code: 'UYU', name: 'Uruguayan Peso'),
  SupportedCurrency(flag: '🇧🇴', code: 'BOB', name: 'Bolivian Boliviano'),
  SupportedCurrency(flag: '🇵🇾', code: 'PYG', name: 'Paraguayan Guaraní'),
  SupportedCurrency(flag: '🇻🇪', code: 'VES', name: 'Venezuelan Bolívar'),
  // Europe
  SupportedCurrency(flag: '🇸🇪', code: 'SEK', name: 'Swedish Krona'),
  SupportedCurrency(flag: '🇳🇴', code: 'NOK', name: 'Norwegian Krone'),
  SupportedCurrency(flag: '🇩🇰', code: 'DKK', name: 'Danish Krone'),
  SupportedCurrency(flag: '🇵🇱', code: 'PLN', name: 'Polish Zloty'),
  SupportedCurrency(flag: '🇷🇴', code: 'RON', name: 'Romanian Leu'),
  SupportedCurrency(flag: '🇨🇿', code: 'CZK', name: 'Czech Koruna'),
  SupportedCurrency(flag: '🇭🇺', code: 'HUF', name: 'Hungarian Forint'),
  SupportedCurrency(flag: '🇷🇺', code: 'RUB', name: 'Russian Ruble'),
  SupportedCurrency(flag: '🇺🇦', code: 'UAH', name: 'Ukrainian Hryvnia'),
];

final currencyListProvider = StateProvider<List<SupportedCurrency>>((ref) => _allCurrencies);

String _symbolFor(String code) {
  const map = {
    'USD': '\$', 'EUR': '€', 'GBP': '£', 'JPY': '¥', 'CNY': '¥',
    'INR': '₹', 'KRW': '₩', 'BRL': 'R\$', 'ZAR': 'R', 'NGN': '₦',
    'GHS': 'GH₵', 'KES': 'KSh', 'UGX': 'USh', 'TZS': 'TSh',
    'EGP': 'E£', 'MAD': 'MAD', 'XAF': 'FCFA', 'XOF': 'CFA',
    'ARS': 'ARS', 'CLP': 'CLP', 'COP': 'COP', 'PEN': 'S/',
    'MXN': 'MX\$', 'VES': 'Bs.S', 'AED': 'AED', 'SAR': 'SAR',
    'CAD': 'CA\$', 'AUD': 'A\$', 'CHF': 'Fr', 'SGD': 'S\$',
    'HKD': 'HK\$', 'SEK': 'kr', 'NOK': 'kr', 'DKK': 'kr',
  };
  return map[code] ?? code;
}

class AddCurrencyScreen extends ConsumerStatefulWidget {
  const AddCurrencyScreen({super.key});

  @override
  ConsumerState<AddCurrencyScreen> createState() => _AddCurrencyScreenState();
}

class _AddCurrencyScreenState extends ConsumerState<AddCurrencyScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Sync "added" markers with actual wallet state on every open
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncAddedState());
  }

  void _syncAddedState() {
    final walletCodes =
        ref.read(walletCurrenciesProvider).map((w) => w.code).toSet();
    final current = ref.read(currencyListProvider);
    final updated = current
        .map((c) => SupportedCurrency(
              flag: c.flag,
              code: c.code,
              name: c.name,
              added: walletCodes.contains(c.code),
            ))
        .toList();
    ref.read(currencyListProvider.notifier).state = updated;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addCurrency(SupportedCurrency currency) {
    if (currency.added) return;
    final list = ref.read(currencyListProvider.notifier);
    final current = ref.read(currencyListProvider);
    final updated = current.map((c) {
      if (c.code == currency.code) {
        return SupportedCurrency(flag: c.flag, code: c.code, name: c.name, added: true);
      }
      return c;
    }).toList();
    list.state = updated;

    // Also add to the wallet provider
    ref.read(walletCurrenciesProvider.notifier).add(WalletCurrency(
      flag: currency.flag,
      code: currency.code,
      name: currency.name,
      balance: 0.0,
      available: 0.0,
      symbol: _symbolFor(currency.code),
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('${currency.flag} ${currency.name} added to your wallet!'),
          ],
        ),
        backgroundColor: _teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allCurrencies = ref.watch(currencyListProvider);
    final filtered = _query.isEmpty
        ? allCurrencies
        : allCurrencies
            .where((c) =>
                c.name.toLowerCase().contains(_query.toLowerCase()) ||
                c.code.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    final notAdded = filtered.where((c) => !c.added).toList();
    final added = filtered.where((c) => c.added).toList();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        title: const Text('Add Currency', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search currencies...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: _bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (notAdded.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('Available Currencies',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                  ...notAdded.map((c) => _CurrencyTile(currency: c, onAdd: _addCurrency)),
                  const SizedBox(height: 16),
                ],
                if (added.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('Already in Wallet',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                  ...added.map((c) => _CurrencyTile(currency: c, onAdd: _addCurrency)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyTile extends StatelessWidget {
  final SupportedCurrency currency;
  final void Function(SupportedCurrency) onAdd;

  const _CurrencyTile({required this.currency, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: Text(currency.flag, style: const TextStyle(fontSize: 24)),
        ),
        title: Text(currency.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(currency.code, style: const TextStyle(color: Colors.grey)),
        trailing: currency.added
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Added',
                    style: TextStyle(color: _teal, fontSize: 12, fontWeight: FontWeight.w600)),
              )
            : ElevatedButton(
                onPressed: () => onAdd(currency),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Add', style: TextStyle(fontSize: 13)),
              ),
      ),
    );
  }
}
