import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../widgets/error_state_widget.dart';
import '../../utils/number_utils.dart';

class SalaryReportPage extends StatefulWidget {
  const SalaryReportPage({super.key});

  @override
  State<SalaryReportPage> createState() => _SalaryReportPageState();
}

class _SalaryReportPageState extends State<SalaryReportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService.instance;

  Map<String, dynamic>? _summary;
  List<Map<String, dynamic>> _byProcess = [];
  List<Map<String, dynamic>> _byPeriod = [];
  bool _isLoading = true;
  dynamic _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      dynamic summaryResult = <String, dynamic>{}, processResult = <String, dynamic>{}, periodResult = <String, dynamic>{};
      try { summaryResult = await _api.get(ApiConfig.workerSalarySummary); } catch (_) {}
      try { processResult = await _api.get(ApiConfig.workerSalaryByProcess); } catch (_) {}
      try { periodResult = await _api.get(ApiConfig.workerSalaryByPeriod); } catch (_) {}

      if (summaryResult is Map && summaryResult.isNotEmpty) {
        final summaryData = summaryResult['data'] ?? summaryResult;
        if (summaryData is Map<String, dynamic>) {
          _summary = summaryData;
        } else if (summaryData is Map) {
          _summary = Map<String, dynamic>.from(summaryData);
        } else if (summaryData is List && summaryData.isNotEmpty) {
          double grossAmount = 0;
          double advanceDeduction = 0;
          for (final item in summaryData) {
            if (item is Map) {
              grossAmount += safeToDouble(item['piece_amount']);
              advanceDeduction += safeToDouble(item['advance_amount']);
            }
          }
          final rawMap = {
            'gross_amount': grossAmount,
            'advance_deduction': advanceDeduction,
            'worker_count': summaryData.length,
            'net_amount': grossAmount - advanceDeduction,
          };
          _summary = Map<String, dynamic>.from(rawMap);
        }
      }

      if (processResult is Map && processResult.isNotEmpty) {
        final processData = processResult['data'] ?? processResult;
        if (processData is List) {
          _byProcess = processData.cast<Map<String, dynamic>>();
        } else if (processData is Map && processData.containsKey('data')) {
          _byProcess = (processData['data'] as List).cast<Map<String, dynamic>>();
        }
      }

      if (periodResult is Map && periodResult.isNotEmpty) {
        final periodData = periodResult['data'] ?? periodResult;
        if (periodData is List) {
          _byPeriod = periodData.cast<Map<String, dynamic>>();
        } else if (periodData is Map && periodData.containsKey('data')) {
          _byPeriod = (periodData['data'] as List).cast<Map<String, dynamic>>();
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('薪资报表'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: '汇总'),
            Tab(text: '按工序'),
            Tab(text: '按周期'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _error != null
              ? ErrorStateWidget(error: _error, onRetry: _loadData)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSummaryTab(),
                    _buildByProcessTab(),
                    _buildByPeriodTab(),
                  ],
                ),
    );
  }

  Widget _buildSummaryTab() {
    final grossAmount = safeToDouble(_summary?['gross_amount']);
    final advanceDeduction = safeToDouble(_summary?['advance_deduction']);
    final netAmount = safeToDouble(_summary?['net_amount'] ?? grossAmount - advanceDeduction);
    final workerCount = (_summary?['worker_count'] ?? 0);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.gradientDecoration(
            colors: [AppTheme.primaryColor, AppTheme.primaryDark],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('本月实发总额', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              Text(
                '¥${netAmount.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildSummaryItem(label: '应发总额', value: '¥${grossAmount.toStringAsFixed(2)}')),
                  Container(width: 1, height: 36, color: Colors.white24),
                  Expanded(child: _buildSummaryItem(label: '预支扣减', value: '-¥${advanceDeduction.toStringAsFixed(2)}', valueColor: Colors.yellowAccent)),
                  Container(width: 1, height: 36, color: Colors.white24),
                  Expanded(child: _buildSummaryItem(label: '工人数', value: '$workerCount')),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem({required String label, required String value, Color? valueColor}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: valueColor ?? Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildByProcessTab() {
    if (_byProcess.isEmpty) {
      return _buildEmptyView('暂无工序薪资数据');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: _byProcess.length,
      itemBuilder: (context, index) {
        final item = _byProcess[index];
        final processName = item['process_name'] ?? '未知工序';
        final totalAmount = safeToDouble(item['total_amount']);
        final totalQty = safeToDouble(item['total_quantity']);
        final workerCount = item['worker_count'] ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(processName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  Text('¥${totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
                ],
              ),
              const SizedBox(height: 8),
              Text('数量: ${totalQty.toStringAsFixed(0)}件 | $workerCount人', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildByPeriodTab() {
    if (_byPeriod.isEmpty) {
      return _buildEmptyView('暂无周期薪资数据');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: _byPeriod.length,
      itemBuilder: (context, index) {
        final item = _byPeriod[index];
        final period = item['period'] ?? item['cycle'] ?? '';
        final totalAmount = safeToDouble(item['total_amount']);
        final workerCount = item['worker_count'] ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.cardDecoration,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(period, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text('$workerCount人', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                ],
              ),
              Text('¥${totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyView(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.assessment_outlined, size: 48, color: AppTheme.textHint),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: AppTheme.textHint)),
        ],
      ),
    );
  }

}
