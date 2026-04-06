import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/amix_button.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/amix_text_field.dart';

class CheckoutLinkScreen extends StatefulWidget {
  const CheckoutLinkScreen({super.key});
  @override
  State<CheckoutLinkScreen> createState() => _CheckoutLinkScreenState();
}

class _CheckoutLinkScreenState extends State<CheckoutLinkScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _currency = 'USD';
  bool _fixedAmount = false;
  bool _loading = false;
  String? _generatedLink;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Checkout Link')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AmixTextField(label: 'Title', hint: 'e.g. Coffee & Snacks', controller: _titleCtrl),
          const SizedBox(height: 16),
          AmixTextField(label: 'Description (optional)', hint: 'What are customers paying for?', controller: _descCtrl, maxLines: 2),
          const SizedBox(height: 16),

          Row(children: [
            Expanded(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _fixedAmount,
                onChanged: (v) => setState(() => _fixedAmount = v),
                title: const Text('Fixed Amount', style: AppTextStyles.bodyBold),
                subtitle: const Text('Customer cannot change the amount', style: AppTextStyles.caption),
                activeColor: AppColors.primary,
              ),
            ),
          ]),

          if (_fixedAmount) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: AmixTextField(
                label: 'Amount',
                hint: '0.00',
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              )),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Currency', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                DropdownButton<String>(
                  value: _currency,
                  underline: const SizedBox(),
                  items: ['USD', 'EUR', 'GBP', 'NGN'].map((c) => DropdownMenuItem(value: c, child: Row(mainAxisSize: MainAxisSize.min, children: [Text(currencyFlag(c), style: const TextStyle(fontSize: 16)), const SizedBox(width: 6), Text(c)]))).toList(),
                  onChanged: (v) => setState(() => _currency = v!),
                ),
              ]),
            ]),
          ],

          const SizedBox(height: 24),

          if (_generatedLink == null)
            AmixButton(label: 'Generate Link', isLoading: _loading, onPressed: _generate)
          else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.link, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  const Text('Checkout Link', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: _generatedLink!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard'), backgroundColor: AppColors.success),
                      );
                    },
                    child: const Icon(Icons.copy, color: AppColors.primary, size: 18),
                  ),
                ]),
                const SizedBox(height: 8),
                Text(_generatedLink!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ]),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () { setState(() => _generatedLink = null); },
                icon: const Icon(Icons.refresh),
                label: const Text('New Link'),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton.icon(
                onPressed: () => Share.share(_generatedLink!),
                icon: const Icon(Icons.share),
                label: const Text('Share'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              )),
            ]),
          ],
        ]),
      ),
    );
  }

  void _generate() {
    if (_titleCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }
    setState(() => _loading = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      final slug = 'a1b2c3d4e5f6';
      setState(() {
        _loading = false;
        _generatedLink = 'https://pay.amixpay.com/c/$slug';
      });
    });
  }
}
