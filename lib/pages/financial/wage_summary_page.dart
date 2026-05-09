import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../utils/number_utils.dart';

class WageSummaryPage extends StatefulWidget {
  const WageSummaryPage({super.key});

  @override
  State<WageSummaryPage> createState() => _WageSummaryPageState();
}

class _WageSummaryPageState extends State<WageSummaryPage> {
  final ApiService _api = ApiService.instance;
  Map<String, dynamic>? _data;
  List<dynamic> _advanceList = [];
  List<dynamic> _settlementList = [];
  bool _loading = true;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final results = await Future.wait([
        _api.get(ApiConfig.financialWageSummary),
        _api.get(ApiConfig.workerAdvances, queryParameters: {'status': 'pending'}),
        _api.get(ApiConfig.workerSettlements, queryParameters: {'page_size': 50}),
      ]);

      if (mounted) {
        final summaryData = results[0];
        final data = summaryData['data'] is Map<String, dynamic>
            ? summaryData['data'] as Map<String, dynamic>
            : <String, dynamic>{};

        final advanceData = results[1];
        final advances = advanceData['data'] is List
            ? advanceData['data'] as List
            : (advanceData['data'] is Map<String, dynamic> && advanceData['data']['list'] is List
                ? advanceData['data']['list'] as List
                : []);

        final settlementData = results[2];
        List settlements;
        if (settlementData['data'] is List) {
          settlements = settlementData['data'] as List;
        } else if (settlementData['data'] is Map<String, dynamic>) {
          final d = settlementData['data'] as Map<String, dynamic>;
          settlements = d['list'] is List ? d['list'] as List : (d['items'] is List ? d['items'] as List : []);
        } else {
          settlements = [];
        }

        final pendingSettlements = data['pending_settlements'] is List ? data['pending_settlements'] as List : <dynamic>[];
        final pendingAdvances = data['pending_advances'] is List ? data['pending_advances'] as List : <dynamic>[];

        setState(() {
          _data = data;
          _advanceList = pendingAdvances.isNotEmpty ? pendingAdvances : advances;
          _settlementList = pendingSettlements.isNotEmpty ? pendingSettlements : settlements;
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
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('工资管理')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : RefreshIndicator(
              onRefresh: _fetchData,
              color: AppTheme.primaryColor,
              child: Column(
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 16),
                  _buildTabBar(),
                  Expanded(child: _tabIndex == 0 ? _buildAdvanceList() : _buildSettlementList()),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final pendingWagesTotal = safeToDouble(_data?['pending_wages_total']);
    final paidWagesTotal = safeToDouble(_data?['paid_wages_total']);
    final pendingCount = _data?['pending_count'] ?? 0;
    final confirmedCount = _data?['confirmed_count'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.brown, Colors.brown.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('待发工资总额', style: TextStyle(color: Colors.white70, fontSize: 13)),
                Text('¥${pendingWagesTotal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.white.withOpacity(0.2), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('已发放总额', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('¥${paidWagesTotal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('待确认', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('$pendingCount 笔', style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('待发放', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('$confirmedCount 笔', style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _tabIndex == 0 ? Colors.brown : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '待审批预支',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _tabIndex == 0 ? Colors.white : AppTheme.textSecondary,
                    fontWeight: _tabIndex == 0 ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _tabIndex == 1 ? Colors.brown : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '工资结算',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _tabIndex == 1 ? Colors.white : AppTheme.textSecondary,
                    fontWeight: _tabIndex == 1 ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvanceList() {
    if (_advanceList.isEmpty) {
      return const Center(child: Text('暂无待审批预支', style: TextStyle(color: AppTheme.textHint)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _advanceList.length,
      itemBuilder: (context, index) {
        final item = _advanceList[index] as Map<String, dynamic>;
        final workerName = item['worker_name'] ?? '';
        final amount = safeToDouble(item['amount']);
        final date = item['apply_date'] ?? item['advance_date'] ?? '';
        final id = item['id'];

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: AppTheme.cardDecoration,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(workerName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    const SizedBox(height: 4),
                    Text(date, style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
                  ],
                ),
              ),
              Text('¥${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.brown)),
              const SizedBox(width: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () => _handleAdvanceAction(id, approve: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('审批', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton(
                    onPressed: () => _handleAdvanceAction(id, approve: false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.dangerColor,
                      side: const BorderSide(color: AppTheme.dangerColor),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('驳回', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettlementList() {
    if (_settlementList.isEmpty) {
      return const Center(child: Text('暂无工资结算数据', style: TextStyle(color: AppTheme.textHint)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _settlementList.length,
      itemBuilder: (context, index) {
        final item = _settlementList[index] as Map<String, dynamic>;
        final workerName = item['worker_name'] ?? '';
        final period = item['period'] ?? '';
        final pieceAmount = safeToDouble(item['piece_amount']);
        final advanceAmount = safeToDouble(item['advance_amount']);
        final netAmount = safeToDouble(item['net_amount']);
        final status = item['status'] ?? '';
        final statusLabel = item['status_label'] ?? '';

        Color statusColor;
        String statusText;
        switch (status) {
          case 'paid':
            statusColor = AppTheme.successColor;
            statusText = statusLabel.isNotEmpty ? statusLabel : '已发放';
            break;
          case 'confirmed':
            statusColor = AppTheme.primaryColor;
            statusText = statusLabel.isNotEmpty ? statusLabel : '待发放';
            break;
          case 'pending':
            statusColor = AppTheme.warningColor;
            statusText = statusLabel.isNotEmpty ? statusLabel : '待确认';
            break;
          case 'draft':
            statusColor = AppTheme.textHint;
            statusText = statusLabel.isNotEmpty ? statusLabel : '草稿';
            break;
          case 'cancelled':
            statusColor = AppTheme.textHint;
            statusText = statusLabel.isNotEmpty ? statusLabel : '已取消';
            break;
          default:
            statusColor = AppTheme.textHint;
            statusText = statusLabel.isNotEmpty ? statusLabel : status;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: AppTheme.cardDecoration,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(workerName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(statusText, style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(period, style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('计件金额', style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
                        Text('¥${pieceAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('预支扣减', style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
                        Text('-¥${advanceAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, color: AppTheme.dangerColor, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('应发金额', style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
                        Text('¥${netAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, color: Colors.brown, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleAdvanceAction(dynamic id, {required bool approve}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approve ? '确认审批' : '确认驳回'),
        content: Text(approve ? '确定审批通过该预支申请？' : '确定驳回该预支申请？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(approve ? '审批' : '驳回', style: TextStyle(color: approve ? AppTheme.successColor : AppTheme.dangerColor)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (approve) {
        await _api.post(ApiConfig.workerAdvanceApprove.toString().replaceAll('{id}', id.toString()));
      } else {
        await _api.post(ApiConfig.workerAdvanceReject.toString().replaceAll('{id}', id.toString()));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? '审批通过' : '已驳回'),
            backgroundColor: approve ? AppTheme.successColor : AppTheme.warningColor,
          ),
        );
        _fetchData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('操作失败，请重试'), backgroundColor: AppTheme.dangerColor),
        );
      }
    }
  }
}
