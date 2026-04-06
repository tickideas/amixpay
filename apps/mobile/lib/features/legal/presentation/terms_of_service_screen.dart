import 'package:flutter/material.dart';

const _teal = Color(0xFF0D6B5E);

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        title: const Text('Terms of Service', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _Header(text: 'AmixPay Terms of Service'),
          _LastUpdated(date: 'Last updated: March 2026'),
          SizedBox(height: 8),
          _Body(
            'By creating an AmixPay account or using our services, you agree to these Terms of Service. '
            'Please read them carefully. If you do not agree, you must not use our services.',
          ),
          SizedBox(height: 20),

          _SectionTitle('1. About AmixPay'),
          _Body(
            'AmixPay is a digital wallet and international money transfer service operated by AmixPay Ltd, '
            'registered in England & Wales. Our services allow you to hold balances in multiple currencies, '
            'send and receive money, pay bills, and make international transfers.',
          ),

          _SectionTitle('2. Eligibility'),
          _Body(
            '• You must be at least 18 years old.\n'
            '• You must be a resident of a country in which AmixPay operates.\n'
            '• You must not be subject to any sanctions or restrictions that prohibit you from using financial services.\n'
            '• You may only hold one personal AmixPay account.',
          ),

          _SectionTitle('3. Account Registration & KYC'),
          _Body(
            'You must provide accurate, current, and complete information when registering. '
            'We are required by law to verify your identity (Know Your Customer). '
            'Failure to complete verification may limit your account to sending/receiving limits until KYC is approved. '
            'AmixPay reserves the right to refuse or close accounts at its sole discretion.',
          ),

          _SectionTitle('4. Acceptable Use'),
          _Body(
            'You agree NOT to use AmixPay to:\n'
            '• Fund or facilitate illegal activities, money laundering, or terrorist financing.\n'
            '• Send money on behalf of a third party without disclosure.\n'
            '• Use automated scripts, bots, or scrapers against our systems.\n'
            '• Abuse chargebacks or payment reversals fraudulently.\n'
            '• Circumvent account limits or verification requirements.\n\n'
            'Violation may result in immediate account suspension and reporting to relevant authorities.',
          ),

          _SectionTitle('5. Fees & Exchange Rates'),
          _Body(
            'Our current fee schedule is displayed in the app before you confirm any transaction. '
            'Fees may include a percentage of the transaction amount, fixed fees, and currency conversion markups. '
            'Exchange rates are sourced from mid-market rates and may include a margin. '
            'We reserve the right to update fees with 30 days\' notice.',
          ),

          _SectionTitle('6. Transaction Limits'),
          _Body(
            'Transaction limits vary by KYC level:\n'
            '• Level 0 (unverified): Receive only, up to £500/month.\n'
            '• Level 1 (email verified): Send up to £1,000/month.\n'
            '• Level 2 (ID verified): Send up to £10,000/month.\n'
            '• Level 3 (full KYC): Send up to £100,000/month.\n\n'
            'Higher limits may be available for business accounts.',
          ),

          _SectionTitle('7. Sending & Receiving Money'),
          _Body(
            'Transactions are processed in real time where possible. Some transactions may be delayed due to '
            'bank processing times, fraud checks, or regulatory holds. '
            'You are responsible for providing accurate recipient details. AmixPay is not liable for '
            'losses caused by incorrect recipient information.',
          ),

          _SectionTitle('8. Unauthorised Transactions'),
          _Body(
            'You must notify us immediately at security@amixpay.com if you suspect unauthorised access to your account. '
            'If you notify us within 13 months of an unauthorised transaction, we will investigate and '
            'may refund you subject to our investigation findings.',
          ),

          _SectionTitle('9. Intellectual Property'),
          _Body(
            'All content, trademarks, logos, and software in AmixPay are owned by or licensed to AmixPay Ltd. '
            'You may not copy, modify, distribute, or create derivative works without our written permission.',
          ),

          _SectionTitle('10. Limitation of Liability'),
          _Body(
            'To the maximum extent permitted by law, AmixPay\'s liability for any loss or damage arising '
            'from your use of the service is limited to the amount of fees paid by you in the 3 months '
            'preceding the event giving rise to the claim. We are not liable for indirect, consequential, '
            'or punitive damages.',
          ),

          _SectionTitle('11. Termination'),
          _Body(
            'You may close your account at any time from Settings → Account → Close Account. '
            'We may suspend or terminate your account if you breach these Terms, with notice where legally required. '
            'Upon closure, any remaining balance will be returned to your linked bank account after due diligence.',
          ),

          _SectionTitle('12. Governing Law'),
          _Body(
            'These Terms are governed by the laws of England & Wales. '
            'Any disputes will be subject to the exclusive jurisdiction of the courts of England & Wales.',
          ),

          _SectionTitle('13. Changes to These Terms'),
          _Body(
            'We may update these Terms. We will provide at least 30 days\' notice of material changes '
            'via push notification or email. Continued use after the effective date constitutes acceptance.',
          ),

          _SectionTitle('14. Contact'),
          _Body(
            'Questions about these Terms?\n'
            'Email: legal@amixpay.com\n'
            'Address: AmixPay Ltd, 1 Canada Square, Canary Wharf, London, E14 5AB',
          ),

          SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header({required this.text});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A2B3C)),
      );
}

class _LastUpdated extends StatelessWidget {
  final String date;
  const _LastUpdated({required this.date});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _teal),
        ),
      );
}

class _Body extends StatelessWidget {
  final String text;
  const _Body(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Text(
          text,
          style: const TextStyle(fontSize: 14, color: Color(0xFF4A5568), height: 1.65),
        ),
      );
}
