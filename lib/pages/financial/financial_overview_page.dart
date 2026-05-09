import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../utils/number_utils.dart';

class FinancialOverviewPage extends StatefulWidget {
  const FinancialOverviewPage({super.key});

  @override
  State<FinancialOverviewPage> createState() => _FinancialOverviewPageState();
}

class _FinancialOverviewPageState extends State<FinancialOverviewPage> {
  final ApiService _api = ApiService.instance;
  Map<String, dynamic>? _overviewData;
  List<dynamic> _trendData = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final results = await Future.wait([
        _api.get(ApiConfig.financialProfitOverview),
        _api.get(ApiConfig.financialMonthlyTrend, queryParameters: {'months': 6}),
      ]);

      if (mounted) {
        final overviewResult = results[0];
        final overviewData = overviewResult['data'] is Map<String, dynamic>
            ? overviewResult['data'] as Map<String, dynamic>
            : <String, dynamic>{};

        final trendResult = results[1];
        List trendList;
        if (trendResult['data'] is List) {
          trendList = trendResult['data'] as List;
        } else if (trendResult['data'] is Map<String, dynamic>) {
          final d = trendResult['data'] as Map<String, dynamic>;
          trendList = d['list'] is List ? d['list'] as List : (d['items'] is List ? d['items'] as List : []);
        } else {
          trendList = [];
        }

        setState(() {
          _overviewData = overviewData;
          _trendData = trendList;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('利润概览')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryCards(),
                  const SizedBox(height: 16),
                  _buildCostBreakdown(),
                  const SizedBox(height: 16),
                  _buildTrendList(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    final revenue = safeToDouble(_overviewData?['total_revenue']);
    final cost = safeToDouble(_overviewData?['total_cost']);
    final profit = safeToDouble(_overviewData?['gross_profit']);
    final margin = safeToDouble(_overviewData?['gross_margin']);
    final orderCount = _overviewData?['order_count'] ?? 0;

    return Column(
      children: [
        Row(
          children: [
            _buildMetricCard('总收入', revenue, Colors.blue, '¥'),
            const SizedBox(width: 12),
            _buildMetricCard('总成本', cost, Colors.red, '¥'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildMetricCard('毛利润', profit, Colors.green, '¥'),
            const SizedBox(width: 12),
            _buildMetricCard('毛利率', margin, margin >= 20 ? Colors.green : Colors.orange, '%'),
          ],
        ),
        const SizedBox(height: 8),
        Text('共 $orderCount 笔订单', style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }

  Widget _buildMetricCard(String label, double value, Color color, String prefix) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 13)),
            const SizedBox(height: 8),
            Text(
              '$prefix${prefix == '%' ? value.toStringAsFixed(1) : value.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostBreakdown() {
    final costByType = _overviewData?['cost_by_type'] as Map<String, dynamic>? ?? {};
    final items = [
      {'label': '原料成本', 'value': safeToDouble(costByType['material']), 'color': Colors.blue},
      {'label': '人工成本', 'value': safeToDouble(costByType['labor']), 'color': Colors.orange},
      {'label': '外协成本', 'value': safeToDouble(costByType['outsourcing']), 'color': Colors.red},
      {'label': '制造费用', 'value': safeToDouble(costByType['overhead']), 'color': Colors.grey},
    ];

    final totalCost = items.fold(0.0, (sum, item) => sum + (item['value'] as double));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('成本构成', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...items.map((item) {
              final value = item['value'] as double;
              final percentage = totalCost > 0 ? (value / totalCost * 100) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item['label'] as String, style: const TextStyle(fontSize: 14)),
                        Text('¥${value.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(item['color'] as Color),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendList() {
    if (_trendData.isEmpty) {
      return const Card(
        child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('暂无趋势数据'))),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('月度趋势', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._trendData.map<Widget>((item) {
              final data = item as Map<String, dynamic>;
              final month = data['month'] ?? '-';
              final revenue = safeToDouble(data['revenue']);
              final cost = safeToDouble(data['cost']);
              final profit = safeToDouble(data['profit']);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(month, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildTrendItem('收入', revenue, Colors.blue),
                        const SizedBox(width: 16),
                        _buildTrendItem('成本', cost, Colors.red),
                        const SizedBox(width: 16),
                        _buildTrendItem('利润', profit, profit >= 0 ? Colors.green : Colors.red),
                      ],
                    ),
                    const Divider(height: 20),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendItem(String label, double value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          Text('¥${value.toStringAsFixed(0)}',
              style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
