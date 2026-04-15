import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/database_helper.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final DB = DatabaseHelper.instance;
  final _formatter = NumberFormat('#,##0.00');

  String _selectedMode = 'today';
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _dailyStats = [];
  List<Map<String, dynamic>> _topProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    final now = DateTime.now();
    String start, end;

    if (_selectedMode == 'today') {
      start = end = DateFormat('yyyy-MM-dd').format(now);
    } else if (_selectedMode == 'week') {
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      start = DateFormat('yyyy-MM-dd').format(weekStart);
      end = DateFormat('yyyy-MM-dd').format(now);
    } else if (_selectedMode == 'month') {
      start = DateFormat('yyyy-MM').format(now) + '-01';
      end = DateFormat('yyyy-MM-dd').format(now);
    } else {
      // custom
      final picked = await _showDateRangePicker();
      if (picked == null) {
        setState(() => _isLoading = false);
        return;
      }
      start = DateFormat('yyyy-MM-dd').format(picked.start);
      end = DateFormat('yyyy-MM-dd').format(picked.end);
    }

    final dailyStats = await DB.getCustomRangeStats(start, end);
    final topProducts = await DB.getTopProducts(start, end);

    double totalRevenue = 0, totalCost = 0, totalProfit = 0;
    for (var d in dailyStats) {
      totalRevenue += (d['totalRevenue'] as num).toDouble();
      totalCost += (d['totalCost'] as num).toDouble();
      totalProfit += (d['totalProfit'] as num).toDouble();
    }

    setState(() {
      _stats = {
        'totalRevenue': totalRevenue,
        'totalCost': totalCost,
        'totalProfit': totalProfit,
        'orderCount': dailyStats.fold<int>(0, (sum, d) => sum + (d['orderCount'] as int)),
      };
      _dailyStats = dailyStats;
      _topProducts = topProducts;
      _isLoading = false;
    });
  }

  Future<DateTimeRange?> _showDateRangePicker() async {
    return await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('统计报表'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 时间筛选
                  Wrap(
                    spacing: 8,
                    children: [
                      _FilterChip(label: '今日', selected: _selectedMode == 'today', onSelected: () { setState(() => _selectedMode = 'today'); _loadStats(); }),
                      _FilterChip(label: '本周', selected: _selectedMode == 'week', onSelected: () { setState(() => _selectedMode = 'week'); _loadStats(); }),
                      _FilterChip(label: '本月', selected: _selectedMode == 'month', onSelected: () { setState(() => _selectedMode = 'month'); _loadStats(); }),
                      _FilterChip(label: '自定义', selected: _selectedMode == 'custom', onSelected: () { setState(() => _selectedMode = 'custom'); _loadStats(); }),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 总体统计
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _StatBox(label: '总营收', value: '¥${_formatter.format(_stats['totalRevenue'] ?? 0)}', color: Colors.blue),
                              _StatBox(label: '总成本', value: '¥${_formatter.format(_stats['totalCost'] ?? 0)}', color: Colors.orange),
                              _StatBox(label: '净利润', value: '¥${_formatter.format(_stats['totalProfit'] ?? 0)}', color: Colors.green),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('订单数: ${_stats['orderCount'] ?? 0} 笔', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 每日营收图表
                  if (_dailyStats.isNotEmpty) ...[
                    const Text('每日营收趋势', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: _buildChart(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 热销商品排行
                  const Text('热销商品排行', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_topProducts.isEmpty)
                    Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('暂无销售数据', style: TextStyle(color: Colors.grey[600]))))
                  else
                    Card(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _topProducts.length > 10 ? 10 : _topProducts.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final p = _topProducts[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                            ),
                            title: Text(p['productName'] as String),
                            subtitle: Text('销量: ${(p['totalQuantity'] as num).toDouble().toStringAsFixed(1)} | 利润: ¥${_formatter.format((p['totalProfit'] as num).toDouble())}'),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildChart() {
    if (_dailyStats.isEmpty) return const SizedBox();

    final spots = <FlSpot>[];
    for (int i = 0; i < _dailyStats.length && i < 30; i++) {
      spots.add(FlSpot(i.toDouble(), (_dailyStats[i]['totalRevenue'] as num).toDouble()));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 50)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).primaryColor,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).primaryColor.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({required this.label, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }
}
