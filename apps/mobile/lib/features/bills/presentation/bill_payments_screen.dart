import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class BillCategory {
  final String id, name, emoji;
  final Color color;
  final List<BillProvider> providers;
  const BillCategory({required this.id, required this.name, required this.emoji, required this.color, required this.providers});
}

class BillProvider {
  final String id, name, logo;
  const BillProvider({required this.id, required this.name, required this.logo});
}

final _billCategories = [
  BillCategory(
    id: 'airtime', name: 'Airtime', emoji: '📱', color: const Color(0xFF0D6B5E),
    providers: [
      BillProvider(id: 'mtn', name: 'MTN', logo: '🟡'),
      BillProvider(id: 'airtel', name: 'Airtel', logo: '🔴'),
      BillProvider(id: 'glo', name: 'Glo', logo: '🟢'),
      BillProvider(id: '9mobile', name: '9mobile', logo: '🟢'),
      BillProvider(id: 'att', name: 'AT&T', logo: '🔵'),
      BillProvider(id: 'tmobile', name: 'T-Mobile', logo: '🩷'),
      BillProvider(id: 'safaricom', name: 'Safaricom', logo: '🟢'),
      BillProvider(id: 'vodafone', name: 'Vodafone', logo: '🔴'),
    ],
  ),
  BillCategory(
    id: 'data', name: 'Data Bundle', emoji: '📶', color: const Color(0xFF7C3AED),
    providers: [
      BillProvider(id: 'mtn_data', name: 'MTN Data', logo: '🟡'),
      BillProvider(id: 'airtel_data', name: 'Airtel Data', logo: '🔴'),
      BillProvider(id: 'glo_data', name: 'Glo Data', logo: '🟢'),
    ],
  ),
  BillCategory(
    id: 'electricity', name: 'Electricity', emoji: '⚡', color: const Color(0xFFF59E0B),
    providers: [
      BillProvider(id: 'ekedc', name: 'EKEDC (Lagos)', logo: '💛'),
      BillProvider(id: 'ikedc', name: 'IKEDC (Ikeja)', logo: '🔵'),
      BillProvider(id: 'aedc', name: 'AEDC (Abuja)', logo: '🟢'),
      BillProvider(id: 'phed', name: 'PHED (PH)', logo: '🔴'),
      BillProvider(id: 'kedco', name: 'KEDCO (Kano)', logo: '🟣'),
    ],
  ),
  BillCategory(
    id: 'cable_tv', name: 'Cable TV', emoji: '📺', color: const Color(0xFFDB2777),
    providers: [
      BillProvider(id: 'dstv', name: 'DSTV', logo: '🔵'),
      BillProvider(id: 'gotv', name: 'GOtv', logo: '🟢'),
      BillProvider(id: 'startimes', name: 'StarTimes', logo: '⭐'),
    ],
  ),
  BillCategory(
    id: 'internet', name: 'Internet', emoji: '🌐', color: const Color(0xFF0891B2),
    providers: [
      BillProvider(id: 'spectranet', name: 'Spectranet', logo: '🔵'),
      BillProvider(id: 'swift', name: 'Swift Networks', logo: '🟡'),
      BillProvider(id: 'ipnx', name: 'ipNX', logo: '🟢'),
    ],
  ),
  BillCategory(
    id: 'water', name: 'Water Bill', emoji: '💧', color: const Color(0xFF06B6D4),
    providers: [
      BillProvider(id: 'lwsc', name: 'LWSC', logo: '💧'),
      BillProvider(id: 'fwsc', name: 'FWSC', logo: '💧'),
    ],
  ),
  BillCategory(
    id: 'insurance', name: 'Insurance', emoji: '🛡️', color: const Color(0xFF059669),
    providers: [
      BillProvider(id: 'aiico', name: 'AIICO', logo: '🛡️'),
      BillProvider(id: 'leadway', name: 'Leadway', logo: '🛡️'),
    ],
  ),
  BillCategory(
    id: 'education', name: 'School Fees', emoji: '🎓', color: const Color(0xFFEA580C),
    providers: [
      BillProvider(id: 'uni', name: 'University', logo: '🎓'),
      BillProvider(id: 'school', name: 'School', logo: '🏫'),
    ],
  ),
];

final _quickAmounts = [100.0, 200.0, 500.0, 1000.0, 2000.0, 5000.0];

class BillPaymentsScreen extends StatefulWidget {
  const BillPaymentsScreen({super.key});

  @override
  State<BillPaymentsScreen> createState() => _BillPaymentsScreenState();
}

class _BillPaymentsScreenState extends State<BillPaymentsScreen> {
  BillCategory? _selectedCategory;
  BillProvider? _selectedProvider;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: _selectedCategory != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                onPressed: () => setState(() { _selectedCategory = null; _selectedProvider = null; }),
              )
            : BackButton(color: AppColors.textPrimary),
        title: Text(
          _selectedCategory?.name ?? 'Bill Payments',
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
      ),
      body: _selectedCategory == null ? _CategoryGrid() : _selectedProvider == null
          ? _ProviderList(category: _selectedCategory!, onSelect: (p) => setState(() => _selectedProvider = p))
          : _PaymentForm(category: _selectedCategory!, provider: _selectedProvider!),
    );
  }

  Widget _CategoryGrid() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What would you like to pay?',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.85,
            ),
            itemCount: _billCategories.length,
            itemBuilder: (_, i) {
              final cat = _billCategories[i];
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: Column(
                  children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: cat.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(child: Text(cat.emoji, style: const TextStyle(fontSize: 28))),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cat.name,
                      style: const TextStyle(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0.1), AppColors.primary.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Text('📢', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Instant payments', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      Text('Bills are processed immediately 24/7', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderList extends StatelessWidget {
  final BillCategory category;
  final void Function(BillProvider) onSelect;
  const _ProviderList({required this.category, required this.onSelect});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text('Select ${category.name} Provider', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      const SizedBox(height: 16),
      ...category.providers.map((p) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: ListTile(
          leading: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: category.color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(p.logo, style: const TextStyle(fontSize: 22))),
          ),
          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          onTap: () => onSelect(p),
        ),
      )).toList(),
    ],
  );
}

class _PaymentForm extends StatefulWidget {
  final BillCategory category;
  final BillProvider provider;
  const _PaymentForm({required this.category, required this.provider});

  @override
  State<_PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<_PaymentForm> {
  final _accountCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Provider card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: widget.category.color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                child: Center(child: Text(widget.provider.logo, style: const TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.provider.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
                  Text(widget.category.name, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Account number
        Text(
          widget.category.id == 'airtime' || widget.category.id == 'data' ? 'Phone Number' : 'Account / Customer ID',
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _accountCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: widget.category.id == 'airtime' ? '+234 800 000 0000' : 'Enter account number',
            prefixIcon: Icon(
              widget.category.id == 'airtime' || widget.category.id == 'data'
                  ? Icons.phone_rounded
                  : Icons.badge_outlined,
              color: AppColors.textSecondary, size: 20,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Amount
        const Text('Amount', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: _amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: '0.00',
            prefixText: '₦ ',
            prefixIcon: Icon(Icons.attach_money_rounded, color: AppColors.textSecondary, size: 20),
          ),
        ),

        const SizedBox(height: 14),

        // Quick amount chips
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _quickAmounts.map((amt) => GestureDetector(
            onTap: () => setState(() => _amountCtrl.text = amt.toInt().toString()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _amountCtrl.text == amt.toInt().toString()
                    ? AppColors.primary
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                '₦${amt.toInt()}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _amountCtrl.text == amt.toInt().toString() ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          )).toList(),
        ),

        const SizedBox(height: 28),

        ElevatedButton(
          onPressed: _isLoading ? null : () async {
            if (_accountCtrl.text.isEmpty || _amountCtrl.text.isEmpty) return;
            setState(() => _isLoading = true);
            await Future.delayed(const Duration(seconds: 2));
            if (!mounted) return;
            setState(() => _isLoading = false);
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 70, height: 70,
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded, color: AppColors.primary, size: 36),
                    ),
                    const SizedBox(height: 16),
                    const Text('Payment Successful!', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Text(
                      '₦${_amountCtrl.text} sent to ${_accountCtrl.text}\nvia ${widget.provider.name}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () { Navigator.pop(context); Navigator.pop(context); },
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
            );
          },
          child: _isLoading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
              : const Text('Pay Now'),
        ),
      ],
    ),
  );
}
