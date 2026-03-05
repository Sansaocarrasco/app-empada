import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/dashboard_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1E),
        title: Text('Relatórios',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
            onPressed: () => dash.load(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF6B35),
          labelColor: const Color(0xFFFF6B35),
          unselectedLabelColor: Colors.white38,
          labelStyle:
              GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Por Produto'),
            Tab(text: 'Por Dia'),
          ],
        ),
      ),
      body: dash.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
          : TabBarView(
              controller: _tabController,
              children: [
                _ByProductTab(data: dash.salesByProduct),
                _ByDayTab(data: dash.dailySales),
              ],
            ),
    );
  }
}

// ── Por Produto (Bar Chart) ──────────────────────────────────────────────────

class _ByProductTab extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _ByProductTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    if (data.isEmpty) {
      return _EmptyChart(label: 'Nenhuma venda registrada ainda.');
    }

    final bars = data.asMap().entries.map((e) {
      final total = (e.value['total'] as num?)?.toDouble() ?? 0;
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: total,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B35), Color(0xFFFF9A5C)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    }).toList();

    final maxY = data
        .map((e) => (e['total'] as num?)?.toDouble() ?? 0)
        .fold(0.0, (a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 8),
        Container(
          height: 260,
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: BarChart(
            BarChartData(
              maxY: maxY * 1.2,
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: Colors.white10, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
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
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= data.length) {
                        return const SizedBox.shrink();
                      }
                      final name =
                          (data[idx]['product_name'] as String?)?.split(' ').first ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(name,
                            style: GoogleFonts.outfit(
                                color: Colors.white54, fontSize: 10)),
                      );
                    },
                    reservedSize: 28,
                  ),
                ),
              ),
              barGroups: bars,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Detalhe por Produto',
            style: GoogleFonts.outfit(
                color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 10),
        ...data.map((item) {
          final name = item['product_name'] as String? ?? '';
          final total = (item['total'] as num?)?.toDouble() ?? 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.fastfood_rounded,
                      color: Color(0xFFFF6B35), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(name,
                      style: GoogleFonts.outfit(color: Colors.white70)),
                ),
                Text(fmt.format(total),
                    style: GoogleFonts.outfit(
                        color: const Color(0xFF43D29B),
                        fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ── Por Dia (Line Chart) ─────────────────────────────────────────────────────

class _ByDayTab extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _ByDayTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    if (data.isEmpty) {
      return _EmptyChart(label: 'Nenhuma venda nos últimos 30 dias.');
    }

    final spots = data.asMap().entries.map((e) {
      final total = (e.value['total'] as num?)?.toDouble() ?? 0;
      return FlSpot(e.key.toDouble(), total);
    }).toList();

    final maxY = data
        .map((e) => (e['total'] as num?)?.toDouble() ?? 0)
        .fold(0.0, (a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 8),
        Container(
          height: 260,
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY * 1.2,
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: Colors.white10, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
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
                    interval: (data.length / 5).ceilToDouble(),
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= data.length) {
                        return const SizedBox.shrink();
                      }
                      final day = data[idx]['day'] as String? ?? '';
                      final label = day.length >= 10 ? day.substring(5) : day;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(label,
                            style: GoogleFonts.outfit(
                                color: Colors.white54, fontSize: 10)),
                      );
                    },
                    reservedSize: 28,
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: const Color(0xFF6C63FF),
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, __, ___, ____) =>
                        FlDotCirclePainter(
                      radius: 3,
                      color: const Color(0xFF6C63FF),
                      strokeWidth: 1.5,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFF6C63FF).withOpacity(0.12),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Histórico diário',
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 10),
        ...data.reversed.take(10).map((item) {
          final day = item['day'] as String? ?? '';
          final total = (item['total'] as num?)?.toDouble() ?? 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    color: Color(0xFF6C63FF), size: 18),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(day,
                        style: GoogleFonts.outfit(color: Colors.white70))),
                Text(fmt.format(total),
                    style: GoogleFonts.outfit(
                        color: const Color(0xFF43D29B),
                        fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String label;
  const _EmptyChart({required this.label});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded,
                size: 72, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 12),
            Text(label,
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 14)),
          ],
        ),
      );
}
