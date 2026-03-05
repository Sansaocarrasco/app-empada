import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/dashboard_provider.dart';
import '../providers/product_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    final prodProv = context.watch<ProductProvider>();
    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final maxEstimate = prodProv.maxDayEstimate;
    final todayRevenue = dash.todayRevenue;
    final percent = maxEstimate > 0 ? (todayRevenue / maxEstimate * 100).clamp(0, 100) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => dash.load(),
          color: const Color(0xFFFF6B35),
          child: dash.isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dashboard',
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold)),
                            Text(DateFormat('EEEE, d MMM', 'pt_BR').format(DateTime.now()),
                                style: GoogleFonts.outfit(
                                    color: Colors.white54, fontSize: 13)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B35).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.storefront_rounded,
                              color: Color(0xFFFF6B35)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Stat Cards Row
                    Row(
                      children: [
                        Expanded(
                            child: _StatCard(
                          label: 'Vendas Hoje',
                          value: dash.todaySaleCount.toString(),
                          icon: Icons.receipt_long_rounded,
                          iconColor: const Color(0xFF6C63FF),
                        )),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _StatCard(
                          label: 'Receita Hoje',
                          value: currencyFmt.format(todayRevenue),
                          icon: Icons.attach_money_rounded,
                          iconColor: const Color(0xFF43D29B),
                        )),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Estimativa do dia
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Estimativa do Dia',
                              style: GoogleFonts.outfit(
                                  color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(currencyFmt.format(todayRevenue),
                                      style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold)),
                                  Text('de ${currencyFmt.format(maxEstimate)}',
                                      style: GoogleFonts.outfit(
                                          color: Colors.white54, fontSize: 12)),
                                ],
                              ),
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFFF6B35).withOpacity(0.15),
                                  border: Border.all(
                                      color: const Color(0xFFFF6B35), width: 2),
                                ),
                                child: Center(
                                  child: Text('${percent.toStringAsFixed(0)}%',
                                      style: GoogleFonts.outfit(
                                          color: const Color(0xFFFF6B35),
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: percent / 100,
                              backgroundColor: Colors.white10,
                              valueColor: const AlwaysStoppedAnimation(Color(0xFFFF6B35)),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Mini line chart últimos dias
                    if (dash.dailySales.isNotEmpty) ...[
                      Text('Vendas por Dia (30 dias)',
                          style: GoogleFonts.outfit(
                              color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 10),
                      _DailyLineChart(data: dash.dailySales),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style:
                  GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}

class _DailyLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _DailyLineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final spots = data.asMap().entries.map((e) {
      final total = (e.value['total'] as num?)?.toDouble() ?? 0;
      return FlSpot(e.key.toDouble(), total);
    }).toList();

    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: Colors.white10, strokeWidth: 1),
          ),
          titlesData: const FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFFFF6B35),
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFFFF6B35).withOpacity(0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
