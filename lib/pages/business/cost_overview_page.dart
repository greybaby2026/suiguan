import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../utils/number_utils.dart';

/// 成本概览页
class CostOverviewPage extends StatefulWidget {
  const CostOverviewPage({super.key});

  @override
  State<CostOverviewPage> createState() => _CostOverviewPageState();
}

class _CostOverviewPageState extends State<CostOverviewPage> {
  bool _isLoading = false;
  dynamic _error;
  Map<String, dynamic>? _statistics;
  List<Map<String, dynamic>> _costByType = [];
  List<Map<String, dynamic>> _costTrend = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 加载成本数据
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      dynamic summaryResult, typeResult, periodResult;
      String? firstError;

      try {
        summaryResult = await ApiService.instance.get(ApiConfig.costStatisticsSummary);
      } catch (e) {
        firstError ??= e.toString();
        summaryResult = <String, dynamic>{};
      }
      try {
        typeResult = await ApiService.instance.get(ApiConfig.costStatisticsByType);
      } catch (e) {
        firstError ??= e.toString();
        typeResult = <String, dynamic>{};
      }
      try {
        periodResult = await ApiService.instance.get(ApiConfig.costStatisticsByPeriod);
      } catch (e) {
        firstError ??= e.toString();
        periodResult = <String, dynamic>{};
      }

      final summaryData = summaryResult['data'] ?? summaryResult;
      final typeData = typeResult['data'] ?? typeResult;
      final periodData = periodResult['data'] ?? periodResult;

      List<dynamic> typeList;
      if (typeData is List) { typeList = typeData; }
      else if (typeData is Map && typeData.containsKey('data')) { typeList = typeData['data'] as List; }
      else { typeList = []; }

      List<dynamic> periodList;
      if (periodData is List) { periodList = periodData; }
      else if (periodData is Map && periodData.containsKey('data')) { periodList = periodData['data'] as List; }
      else { periodList = []; }

      setState(() {
        _statistics = summaryData is Map<String, dynamic> ? summaryData : {};
        _costByType = typeList.cast<Map<String, dynamic>>();
        _costTrend = periodList.cast<Map<String, dynamic>>();
        _error = firstError;
      });
    } catch (e) {
      setState(() => _error = e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('成本概览')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.primaryColor,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber, color: AppTheme.warningColor, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '部分数据加载失败，下拉刷新重试',
                                style: const TextStyle(fontSize: 13, color: AppTheme.warningColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    _buildStatCards(),
                    const SizedBox(height: 20),
                    _buildCostByType(),
                    const SizedBox(height: 20),
                    _buildCostTrend(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  /// 顶部统计卡片
  Widget _buildStatCards() {
    final totalCost = safeToDouble(_statistics?['total_cost']);
    final materialCost = safeToDouble(_statistics?['material_cost']);
    final laborCost = safeToDouble(_statistics?['labor_cost']);
    final outsourcingCost = safeToDouble(_statistics?['outsourcing_cost']);
    final overheadCost = safeToDouble(_statistics?['overhead_cost']);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.gradientDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '总成本',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            '¥${_formatAmount(totalCost)}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCostInfoItem(label: '原材料', value: '¥${_formatAmount(materialCost)}'),
              ),
              Expanded(
                child: _buildCostInfoItem(label: '人工', value: '¥${_formatAmount(laborCost)}'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildCostInfoItem(label: '外协加工', value: '¥${_formatAmount(outsourcingCost)}'),
              ),
              Expanded(
                child: _buildCostInfoItem(label: '制造费用', value: '¥${_formatAmount(overheadCost)}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCostInfoItem({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ],
    );
  }

  /// 按类型分布列表
  Widget _buildCostByType() {
    if (_costByType.isEmpty) return const SizedBox.shrink();

    double maxAmount = 0;
    for (final item in _costByType) {
      final amt = safeToDouble(item['total_amount'] ?? item['amount']);
      if (amt > maxAmount) maxAmount = amt;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            '成本分布',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecoration,
          child: Column(
            children: _costByType.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final type = (item['label'] ?? item['type'] ?? '').toString();
              final amount = safeToDouble(item['total_amount'] ?? item['amount']);
              final percent = maxAmount > 0 ? amount / maxAmount : 0.0;
              final color = _getTypeColor(index);

              return Padding(
                padding: EdgeInsets.only(bottom: index < _costByType.length - 1 ? 14 : 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            type,
                            style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                          ),
                        ),
                        Text(
                          '¥${_formatAmount(amount)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percent,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// 按期间趋势
  Widget _buildCostTrend() {
    if (_costTrend.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            '成本趋势',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecoration,
          child: Column(
            children: _costTrend.map((item) {
              final period = (item['month'] ?? item['period'] ?? '').toString();
              final amount = safeToDouble(item['total_cost'] ?? item['amount']);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        period,
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '¥${_formatAmount(amount)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// 获取类型颜色
  Color _getTypeColor(int index) {
    const colors = [
      AppTheme.primaryColor,
      AppTheme.accentColor,
      AppTheme.warningColor,
      AppTheme.successColor,
      AppTheme.infoColor,
    ];
    return colors[index % colors.length];
  }

  /// 格式化金额
  String _formatAmount(double amount) {
    if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(2)}万';
    }
    return amount.toStringAsFixed(2);
  }
}
