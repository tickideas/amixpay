import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/amix_button.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});
  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _push = true;
  bool _sms = true;
  bool _email = true;
  bool _paymentAlerts = true;
  bool _securityAlerts = true;
  bool _promotional = false;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _section('Channels', [
            _toggle('Push Notifications', 'Receive alerts on your device', Icons.notifications_active_outlined, _push, (v) => setState(() => _push = v)),
            _toggle('SMS Alerts', 'Receive alerts via text message', Icons.sms_outlined, _sms, (v) => setState(() => _sms = v)),
            _toggle('Email Notifications', 'Receive alerts via email', Icons.email_outlined, _email, (v) => setState(() => _email = v)),
          ]),
          const SizedBox(height: 24),
          _section('Alert Types', [
            _toggle('Payment Alerts', 'Notify on send/receive/request', Icons.payment, _paymentAlerts, (v) => setState(() => _paymentAlerts = v)),
            _toggle('Security Alerts', 'Login, 2FA, suspicious activity', Icons.security, _securityAlerts, (v) => setState(() => _securityAlerts = v)),
            _toggle('Promotional', 'News, offers and feature updates', Icons.campaign_outlined, _promotional, (v) => setState(() => _promotional = v)),
          ]),
          const SizedBox(height: 32),
          AmixButton(
            label: 'Save Preferences',
            isLoading: _loading,
            onPressed: () {
              setState(() => _loading = true);
              Future.delayed(const Duration(milliseconds: 800), () {
                if (!mounted) return;
                setState(() => _loading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Preferences saved'), backgroundColor: AppColors.success),
                );
              });
            },
          ),
        ]),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: AppTextStyles.heading3),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(children: children),
      ),
    ]);
  }

  Widget _toggle(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      title: Text(title, style: AppTextStyles.bodyBold),
      subtitle: Text(subtitle, style: AppTextStyles.caption),
      secondary: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
    );
  }
}
