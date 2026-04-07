import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/transaction_provider.dart';

class SpendingCategory {
  final String name;
  final String emoji;
  final double amount;
  final Color color;
  const SpendingCategory(
      {required this.name,
      required this.emoji,
      required this.amount,
      required this.color});
}

class SpendingAnalyticsScreen extends ConsumerStatefulWidget {
  const SpendingAnalyticsScreen({super.key});

  @override
  ConsumerState<SpendingAnalyticsScreen> createState() =>
      _SpendingAnalyticsScreenState();
}

class _SpendingAnalyticsScreenState
    extends ConsumerState<SpendingAnalyticsScreen> {
  int _selectedPeriod = 0; // 0=month, 1=quarter, 2=year
  int _touchedIndex = -1;

  // ── Derive categories from real transactions ──────────────────────────────

  List<SpendingCategory> _buildCategories(List<AppTransaction> txs) {
    double transfers = 0, received = 0, funded = 0, other = 0;
    for (final tx in txs) {
      switch (tx.type) {
        case AppTxType.sent:
        case AppTxType.transfer:
          transfers += tx.amount.abs();
        case AppTxType.received:
          received += tx.amount.abs();
        case AppTxType.funded:
          funded += tx.amount.abs();
      }
    }
    if (transfers == 0 && received == 0 && funded == 0) {
      return []; // No data yet
    }
    final cats = <SpendingCategory>[];
    if (transfers > 0) cats.add(SpendingCategory(name: 'Transfers Sent', emoji: '💸', amount: transfers, color: const Color(0xFF0D6B5E)));
    if (received > 0) cats.add(SpendingCategory(name: 'Money Received', emoji: '📥', amount: received, color: const Color(0xFF059669)));
    if (funded > 0) cats.add(SpendingCategory(name: 'Wallet Top-Ups', emoji: '💳', amount: funded, color: const Color(0xFF7C3AED)));
    if (other > 0) cats.add(SpendingCategory(name: 'Other', emoji: '📦', amount: other, color: const Color(0xFF92400E)));
    return cats;
  }

  // ── Monthly trend ─────────────────────────────────────────────────────────

  List<FlSpot> _buildTrend(List<AppTransaction> txs) {
    final now = DateTime.now();
    final spots = <FlSpot>[];
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final total = txs
          .where((t) =>
              t.type == AppTxType.sent || t.type == AppTxType.transfer)
          .where((t) => t.date.year == month.year && t.date.month == month.month)
          .fold<double>(0, (s, t) => s + t.amount.abs());
      spots.add(FlSpot((5 - i).toDouble(), total > 0 ? total : 0));
    }

    return spots;
  }

  List<String> _buildMonthLabels() {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final m = DateTime(now.year, now.month - (5 - i));
      return DateFormat('MMM').format(m);
    });
  }



  @override
  Widget build(BuildContext context) {
    final allTxs = ref.watch(transactionProvider);

    // Filter by period
    final now = DateTime.now();
    final cutoff = _selectedPeriod == 0
        ? DateTime(now.year, now.month, 1)
        : _selectedPeriod == 1
            ? now.subtract(const Duration(days: 90))
            : now.subtract(const Duration(days: 365));
    final filtered = allTxs.where((t) => t.date.isAfter(cutoff)).toList();

    final categories = _buildCategories(filtered);
    final monthlySpots = _buildTrend(allTxs);
    final months = _buildMonthLabels();
    final totalSpend = categories.fold<double>(0, (s, c) => s + c.amount);
    final fmt = NumberFormat('#,##0.00');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: BackButton(color: AppColors.textPrimary),
        title: const Text('Spending Analytics',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Period selector ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  _PeriodTab(label: 'Month', selected: _selectedPeriod == 0, onTap: () => setState(() => _selectedPeriod = 0)),
                  _PeriodTab(label: 'Quarter', selected: _selectedPeriod == 1, onTap: () => setState(() => _selectedPeriod = 1)),
                  _PeriodTab(label: 'Year', selected: _selectedPeriod == 2, onTap: () => setState(() => _selectedPeriod = 2)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Summary row ─────────────────────────────────────────────
            Row(
              children: [
                Expanded(child: _StatCard(
                  label: 'Total Sent',
                  value: '\$${fmt.format(totalSpend)}',
                  icon: Icons.trending_up_rounded,
                  color: AppColors.primary,
                )),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(
                  label: 'Transactions',
                  value: '${filtered.length}',
                  icon: Icons.receipt_long_rounded,
                  color: const Color(0xFF7C3AED),
                )),
              ],
            ),

            const SizedBox(height: 24),

            // ── Monthly trend chart ─────────────────────────────────────
            const Text('6-Month Trend',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 14),

            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: AppColors.border, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= months.length) return const SizedBox.shrink();
                          return Text(months[i],
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11));
                        },
                        interval: 1,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: monthlySpots,
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.2),
                            AppColors.primary.withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, _, __, i) => FlDotCirclePainter(
                          radius: i == monthlySpots.length - 1 ? 6 : 3,
                          color: AppColors.primary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Donut chart ─────────────────────────────────────────────
            const Text('By Category',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (event, resp) {
                            setState(() {
                              _touchedIndex = resp?.touchedSection?.touchedSectionIndex ?? -1;
                            });
                          },
                        ),
                        sectionsSpace: 2,
                        centerSpaceRadius: 36,
                        sections: categories.asMap().entries.map((e) {
                          final isTouched = e.key == _touchedIndex;
                          return PieChartSectionData(
                            color: e.value.color,
                            value: e.value.amount,
                            title: '',
                            radius: isTouched ? 38 : 30,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: categories.take(5).map((cat) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(width: 10, height: 10,
                                decoration: BoxDecoration(color: cat.color, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(cat.name,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                overflow: TextOverflow.ellipsis)),
                            Text('\$${cat.amount.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Category breakdown ──────────────────────────────────────
            const Text('Category Breakdown',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 14),

            ...categories.map((cat) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                        color: cat.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text(cat.emoji, style: const TextStyle(fontSize: 20))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: totalSpend > 0 ? cat.amount / totalSpend : 0,
                            backgroundColor: cat.color.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('\$${fmt.format(cat.amount)}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                      Text(totalSpend > 0 ? '${(cat.amount / totalSpend * 100).toStringAsFixed(1)}%' : '—',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            )),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PeriodTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    ),
  );
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    ),
  );
}
