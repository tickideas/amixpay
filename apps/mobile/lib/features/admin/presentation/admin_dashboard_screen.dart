import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_outlined), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // System health banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.check_circle_outline, color: AppColors.success),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('All Systems Operational', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.success)),
                Text('API latency: 45ms · DB: healthy · Redis: healthy', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ])),
              const Text('Live', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w500)),
            ]),
          ),
          const SizedBox(height: 20),

          // Key metrics
          const Text('Key Metrics', style: AppTextStyles.bodyBold),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: const [
              _MetricCard(label: 'Total Users', value: '12,483', change: '+127 today', color: AppColors.primary),
              _MetricCard(label: 'Volume (24h)', value: '\$2.4M', change: '+8.2% vs yesterday', color: AppColors.success),
              _MetricCard(label: 'Active Alerts', value: '7', change: '3 high severity', color: AppColors.warning),
              _MetricCard(label: 'KYC Pending', value: '34', change: 'Needs review', color: Color(0xFF6366F1)),
            ],
          ),
          const SizedBox(height: 20),

          // Transaction volume chart (simple bar)
          const Text('Transaction Volume (7d)', style: AppTextStyles.bodyBold),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: const _SimpleBarChart(),
          ),
          const SizedBox(height: 20),

          // Recent fraud alerts
          Row(children: [
            const Text('Recent Fraud Alerts', style: AppTextStyles.bodyBold),
            const Spacer(),
            TextButton(
              onPressed: () => context.push(AppRoutes.fraudAlerts),
              child: const Text('View All', style: TextStyle(color: AppColors.primary)),
            ),
          ]),
          const SizedBox(height: 12),
          ..._mockAlerts.map((a) => _AlertTile(alert: a)),
          const SizedBox(height: 20),

          // Quick actions
          const Text('Quick Actions', style: AppTextStyles.bodyBold),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _ActionButton(
              icon: Icons.verified_user_outlined,
              label: 'Review KYC',
              onTap: () {},
            )),
            const SizedBox(width: 12),
            Expanded(child: _ActionButton(
              icon: Icons.block_outlined,
              label: 'Blocked Users',
              onTap: () {},
            )),
            const SizedBox(width: 12),
            Expanded(child: _ActionButton(
              icon: Icons.rule_outlined,
              label: 'Fraud Rules',
              onTap: () {},
            )),
          ]),
          const SizedBox(height: 20),

          // Recent registrations
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('New Registrations (Today)', style: AppTextStyles.bodyBold),
              const SizedBox(height: 12),
              ..._mockUsers.map((u) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  CircleAvatar(radius: 18, backgroundColor: AppColors.primarySurface, child: Text(u[0][0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(u[0], style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                    Text(u[1], style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(6)),
                    child: Text(u[2], style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                ]),
              )),
            ]),
          ),
        ]),
      ),
    );
  }
}

const _mockAlerts = [
  (id: '1', user: 'john.doe@email.com', type: 'VELOCITY_1HR', severity: 'HIGH', status: 'open'),
  (id: '2', user: 'mary.jane@email.com', type: 'LARGE_AMOUNT', severity: 'MEDIUM', status: 'reviewing'),
  (id: '3', user: 'bob.smith@email.com', type: 'NEW_RECIPIENT', severity: 'LOW', status: 'open'),
];

const _mockUsers = [
  ['Sarah Connor', 'sarah.c@email.com', 'KYC L0'],
  ['James Wilson', 'j.wilson@email.com', 'KYC L0'],
  ['Emma Davis', 'emma.d@email.com', 'KYC L1'],
];

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String change;
  final Color color;
  const _MetricCard({required this.label, required this.value, required this.change, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(change, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ]),
    );
  }
}

class _SimpleBarChart extends StatelessWidget {
  const _SimpleBarChart();

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const values = [0.6, 0.8, 0.5, 0.9, 0.7, 0.4, 0.85];
    const maxVal = '\$350K';

    return Column(children: [
      SizedBox(
        height: 120,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (i) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Container(
                  height: 100 * values[i],
                  decoration: BoxDecoration(
                    color: i == 6 ? AppColors.primary : AppColors.primary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ]),
            ),
          )),
        ),
      ),
      const SizedBox(height: 8),
      Row(children: days.map((d) => Expanded(child: Text(d, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)))).toList()),
    ]);
  }
}

class _AlertTile extends StatelessWidget {
  final ({String id, String user, String type, String severity, String status}) alert;
  const _AlertTile({required this.alert});

  Color get _severityColor {
    switch (alert.severity) {
      case 'HIGH': return AppColors.error;
      case 'MEDIUM': return AppColors.warning;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: _severityColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.warning_amber_rounded, color: _severityColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(alert.user, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          Text(alert.type, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _severityColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(alert.severity, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _severityColor)),
          ),
          const SizedBox(height: 4),
          Text(alert.status, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ]),
      ]),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
