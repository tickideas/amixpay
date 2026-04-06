import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class MerchantPaymentSummary {
  final String payer;
  final double amount;
  final DateTime date;
  final String status;

  const MerchantPaymentSummary({
    required this.payer,
    required this.amount,
    required this.date,
    required this.status,
  });
}

// ---------------------------------------------------------------------------
// Provider (stub data)
// ---------------------------------------------------------------------------

final merchantDashboardProvider = Provider<MerchantDashboardData>((ref) {
  return MerchantDashboardData(
    totalRevenue: 12450.0,
    totalPayments: 87,
    settlementBalance: 3200.0,
    weeklyRevenue: [820, 1450, 980, 2100, 1750, 2300, 3050],
    recentPayments: [
      MerchantPaymentSummary(
          payer: 'John Smith',
          amount: 450.00,
          date: DateTime.now().subtract(const Duration(hours: 1)),
          status: 'Completed'),
      MerchantPaymentSummary(
          payer: 'Emma Davis',
          amount: 120.50,
          date: DateTime.now().subtract(const Duration(hours: 3)),
          status: 'Completed'),
      MerchantPaymentSummary(
          payer: 'Mark Wilson',
          amount: 890.00,
          date: DateTime.now().subtract(const Duration(hours: 5)),
          status: 'Pending'),
      MerchantPaymentSummary(
          payer: 'Sara Lee',
          amount: 230.75,
          date: DateTime.now().subtract(const Duration(days: 1)),
          status: 'Completed'),
      MerchantPaymentSummary(
          payer: 'Tom Brown',
          amount: 65.00,
          date: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
          status: 'Refunded'),
    ],
  );
});

class MerchantDashboardData {
  final double totalRevenue;
  final int totalPayments;
  final double settlementBalance;
  final List<double> weeklyRevenue;
  final List<MerchantPaymentSummary> recentPayments;

  const MerchantDashboardData({
    required this.totalRevenue,
    required this.totalPayments,
    required this.settlementBalance,
    required this.weeklyRevenue,
    required this.recentPayments,
  });
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class MerchantDashboardScreen extends ConsumerWidget {
  const MerchantDashboardScreen({super.key});

  static const _teal = Color(0xFF0D6B5E);
  static const _bg = Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(merchantDashboardProvider);
    final currFmt = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Merchant Dashboard'),
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Stats cards ─────────────────────────────────────────────
              _StatsGrid(data: data, currFmt: currFmt),
              const SizedBox(height: 20),

              // ── Bar chart ───────────────────────────────────────────────
              _RevenueChart(weeklyRevenue: data.weeklyRevenue),
              const SizedBox(height: 20),

              // ── Recent payments ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Payments',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  TextButton(
                    onPressed: () =>
                        context.push('/merchants/payments'),
                    child: const Text('View all',
                        style: TextStyle(color: _teal)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...data.recentPayments.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _PaymentRow(payment: p, currFmt: currFmt),
                  )),
              const SizedBox(height: 20),

              // ── Create checkout link ─────────────────────────────────────
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      context.push('/merchants/checkout-link'),
                  icon: const Icon(Icons.add_link),
                  label: const Text(
                    'Create Checkout Link',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats grid
// ---------------------------------------------------------------------------

class _StatsGrid extends StatelessWidget {
  final MerchantDashboardData data;
  final NumberFormat currFmt;

  const _StatsGrid({required this.data, required this.currFmt});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total Revenue',
                value: currFmt.format(data.totalRevenue),
                icon: Icons.trending_up,
                iconBg: const Color(0xFFE0F2F1),
                iconColor: const Color(0xFF0D6B5E),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Total Payments',
                value: '${data.totalPayments}',
                icon: Icons.receipt_long_outlined,
                iconBg: const Color(0xFFE3F2FD),
                iconColor: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StatCard(
          label: 'Settlement Balance',
          value: currFmt.format(data.settlementBalance),
          icon: Icons.account_balance_wallet_outlined,
          iconBg: const Color(0xFFF3E5F5),
          iconColor: Colors.purple,
          wide: true,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final bool wide;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Revenue chart
// ---------------------------------------------------------------------------

class _RevenueChart extends StatelessWidget {
  final List<double> weeklyRevenue;

  const _RevenueChart({required this.weeklyRevenue});

  static const _teal = Color(0xFF0D6B5E);
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final maxY = weeklyRevenue.reduce((a, b) => a > b ? a : b) * 1.25;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Revenue',
              style:
                  TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => _teal,
                      getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                        '\$${rod.toY.toStringAsFixed(0)}',
                        const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12),
                      ),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) => Text(
                          _days[value.toInt()],
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black45),
                        ),
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (val) => FlLine(
                      color: Colors.grey.shade100,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(
                    weeklyRevenue.length,
                    (i) => BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: weeklyRevenue[i],
                          color: i == weeklyRevenue.length - 1
                              ? _teal
                              : _teal.withOpacity(0.4),
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Payment row
// ---------------------------------------------------------------------------

class _PaymentRow extends StatelessWidget {
  final MerchantPaymentSummary payment;
  final NumberFormat currFmt;

  const _PaymentRow({required this.payment, required this.currFmt});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, h:mm a');
    Color statusColor;
    switch (payment.status) {
      case 'Completed':
        statusColor = Colors.green;
        break;
      case 'Pending':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.red;
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE0F2F1),
          child: Text(
            payment.payer[0].toUpperCase(),
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D6B5E)),
          ),
        ),
        title: Text(payment.payer,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(fmt.format(payment.date),
            style: const TextStyle(fontSize: 12, color: Colors.black45)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currFmt.format(payment.amount),
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              payment.status,
              style: TextStyle(
                  fontSize: 11,
                  color: statusColor,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
