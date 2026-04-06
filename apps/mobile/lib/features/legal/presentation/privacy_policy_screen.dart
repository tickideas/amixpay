import 'package:flutter/material.dart';

const _teal = Color(0xFF0D6B5E);

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _Header(text: 'AmixPay Privacy Policy'),
          _LastUpdated(date: 'Last updated: March 2026'),
          SizedBox(height: 8),
          _Body(
            'AmixPay ("we", "us", or "our") is committed to protecting your personal information. '
            'This Privacy Policy explains how we collect, use, share, and safeguard your data when you use our app.',
          ),
          SizedBox(height: 20),

          _SectionTitle('1. Information We Collect'),
          _Body(
            '• Identity data: full name, date of birth, national ID or passport number.\n'
            '• Contact data: email address, phone number, postal address.\n'
            '• Financial data: bank account numbers, card details (stored via Stripe), wallet balances, transaction history.\n'
            '• KYC documents: copies of government-issued ID, selfies for facial verification.\n'
            '• Device data: IP address, device model, OS version, unique device identifiers.\n'
            '• Usage data: pages viewed, features used, session duration, error logs.',
          ),

          _SectionTitle('2. How We Use Your Information'),
          _Body(
            '• To create and manage your AmixPay account.\n'
            '• To process payments, transfers, and wallet transactions.\n'
            '• To verify your identity and comply with KYC/AML regulations.\n'
            '• To detect and prevent fraud and unauthorized access.\n'
            '• To send transactional notifications (push, SMS, email).\n'
            '• To improve our services, fix bugs, and develop new features.\n'
            '• To comply with applicable laws and regulatory requirements.',
          ),

          _SectionTitle('3. How We Share Your Information'),
          _Body(
            '• Payment processors (Stripe, Wise) — to execute transactions.\n'
            '• Identity verification providers — for KYC checks.\n'
            '• Banking partners — for ACH transfers and wallet funding.\n'
            '• Regulators and law enforcement — when legally required.\n'
            '• Service providers (cloud hosting, analytics) under strict data processing agreements.\n\n'
            'We do NOT sell your personal information to third parties.',
          ),

          _SectionTitle('4. Data Retention'),
          _Body(
            'We retain your data for as long as your account is active and for up to 7 years afterward '
            'to comply with financial regulations. You may request deletion of non-mandatory data by contacting us.',
          ),

          _SectionTitle('5. Your Rights'),
          _Body(
            '• Access: request a copy of your personal data.\n'
            '• Correction: request corrections to inaccurate data.\n'
            '• Deletion: request removal of data we are not legally required to keep.\n'
            '• Portability: receive your data in a machine-readable format.\n'
            '• Objection: object to processing based on legitimate interests.\n\n'
            'To exercise these rights, contact privacy@amixpay.com.',
          ),

          _SectionTitle('6. Data Security'),
          _Body(
            'All data in transit is encrypted using TLS 1.3. Data at rest is encrypted using AES-256. '
            'Card and bank details are tokenised and never stored on our servers. '
            'We conduct regular security audits and penetration tests.',
          ),

          _SectionTitle('7. Cookies & Tracking'),
          _Body(
            'The AmixPay mobile app does not use browser cookies. We use anonymised analytics to '
            'understand feature usage. You can opt out of analytics in Settings → Privacy.',
          ),

          _SectionTitle('8. Children\'s Privacy'),
          _Body(
            'AmixPay is not intended for users under 18 years of age. We do not knowingly collect '
            'data from minors. If you believe a child has created an account, contact us immediately.',
          ),

          _SectionTitle('9. International Transfers'),
          _Body(
            'Your data may be processed in countries outside your own, including the UK, EU, and US. '
            'We ensure adequate protections are in place (e.g., Standard Contractual Clauses for EU data).',
          ),

          _SectionTitle('10. Changes to This Policy'),
          _Body(
            'We may update this policy. We will notify you of material changes via push notification '
            'or email at least 30 days before they take effect.',
          ),

          _SectionTitle('11. Contact Us'),
          _Body(
            'AmixPay Ltd\nRegistered in England & Wales\n'
            'Email: privacy@amixpay.com\nAddress: 1 Canada Square, Canary Wharf, London, E14 5AB',
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
