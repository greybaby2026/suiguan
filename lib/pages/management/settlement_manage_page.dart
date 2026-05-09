import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../widgets/error_state_widget.dart';

class SettlementManagePage extends StatefulWidget {
  const SettlementManagePage({super.key});

  @override
  State<SettlementManagePage> createState() => _SettlementManagePageState();
}

class _SettlementManagePageState extends State<SettlementManagePage> {
  final ApiService _api = ApiService.instance;
  List<Map<String, dynamic>> _settlements = [];
  List<Map<String, dynamic>> _workers = [];
  bool _isLoading = true;
  dynamic _error;

  @override
  void initState() {
    super.initState();
    _loadSettlements();
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    try {
      final response = await _api.get(ApiConfig.workers);
      final data = response['data'] ?? response;
      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map && data.containsKey('data')) {
        list = data['data'] as List;
      } else {
        list = [];
      }
      setState(() => _workers = list.cast<Map<String, dynamic>>());
    } catch (_) {}
  }

  Future<void> _loadSettlements() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _api.get(ApiConfig.workerSettlements);
      final data = response['data'] ?? response;
      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map && data.containsKey('data')) {
        list = data['data'] as List;
      } else {
        list = [];
      }

      setState(() {
        _settlements = list.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  String _formatPeriod(Map<String, dynamic> item) {
    final start = item['period_start'] ?? '';
    final end = item['period_end'] ?? '';
    if (start.isNotEmpty && end.isNotEmpty) {
      return '$start ~ $end';
    }
    return item['period'] ?? item['settlement_period'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('结算管理')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _error != null
              ? ErrorStateWidget(error: _error, onRetry: _loadSettlements)
              : _settlements.isEmpty
                  ? _buildEmptyView()
                  : RefreshIndicator(
                      onRefresh: _loadSettlements,
                      color: AppTheme.primaryColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: _settlements.length,
                        itemBuilder: (context, index) => _buildSettlementCard(_settlements[index]),
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGenerateDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSettlementCard(Map<String, dynamic> item) {
    final period = _formatPeriod(item);
    final pieceAmount = _toDouble(item['piece_amount']);
    final advanceAmount = _toDouble(item['advance_amount']);
    final deductionAmount = _toDouble(item['deduction_amount']);
    final netAmount = _toDouble(item['net_amount']);
    final totalAmount = pieceAmount > 0 ? pieceAmount : _toDouble(item['total_amount']);
    final deduction = deductionAmount > 0 ? deductionAmount : (advanceAmount > 0 ? advanceAmount : _toDouble(item['deduction']));
    final status = (item['status'] ?? 'pending').toString();
    final workerName = item['worker']?['name'] ?? '未知工人';

    const statusLabels = {'pending': '待确认', 'confirmed': '已确认', 'paid': '已支付'};
    const statusColors = {
      'pending': AppTheme.warningColor,
      'confirmed': AppTheme.primaryColor,
      'paid': AppTheme.successColor,
    };
    final statusColor = statusColors[status] ?? AppTheme.textSecondary;

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
              Expanded(
                child: Text(
                  '$workerName - $period',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabels[status] ?? '未知',
                  style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoItem(label: '计件总额', value: '¥${totalAmount.toStringAsFixed(2)}'),
              const SizedBox(width: 16),
              _buildInfoItem(label: '预支扣减', value: '-¥${deduction.toStringAsFixed(2)}', valueColor: AppTheme.dangerColor),
              const SizedBox(width: 16),
              _buildInfoItem(label: '实发', value: '¥${netAmount.toStringAsFixed(2)}', valueColor: AppTheme.primaryColor),
            ],
          ),
          if (status == 'pending' || status == 'confirmed') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: status == 'pending'
                    ? () => _confirmSettlement(item)
                    : () => _markAsPaid(item),
                style: ElevatedButton.styleFrom(
                  backgroundColor: status == 'pending' ? AppTheme.primaryColor : AppTheme.successColor,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(status == 'pending' ? '确认结算' : '标记已付', style: const TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  void _showGenerateDialog() {
    int? selectedWorkerId;
    String selectedPeriodType = 'monthly';
    final startDateCtrl = TextEditingController();
    final endDateCtrl = TextEditingController();
    final deductionCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('生成结算单'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedWorkerId,
                  decoration: const InputDecoration(
                    labelText: '工人 *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: _workers.map((w) => DropdownMenuItem<int>(
                    value: w['id'] as int,
                    child: Text(w['name']?.toString() ?? '未知'),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedWorkerId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedPeriodType,
                  decoration: const InputDecoration(
                    labelText: '周期类型 *',
                    prefixIcon: Icon(Icons.repeat),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('日结')),
                    DropdownMenuItem(value: 'weekly', child: Text('周结')),
                    DropdownMenuItem(value: 'monthly', child: Text('月结')),
                    DropdownMenuItem(value: 'yearly', child: Text('年结')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedPeriodType = v ?? 'monthly'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: startDateCtrl,
                  decoration: const InputDecoration(
                    labelText: '开始日期 *',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    hintText: '如: 2026-05-01',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: endDateCtrl,
                  decoration: const InputDecoration(
                    labelText: '结束日期 *',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    hintText: '如: 2026-05-31',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: deductionCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '扣款金额',
                    prefixIcon: Icon(Icons.money_off_outlined),
                    hintText: '0',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: isSubmitting ? null : () async {
              if (selectedWorkerId == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择工人'), backgroundColor: AppTheme.dangerColor));
                return;
              }
              if (startDateCtrl.text.trim().isEmpty || endDateCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写开始和结束日期'), backgroundColor: AppTheme.dangerColor));
                return;
              }
              setDialogState(() => isSubmitting = true);
              try {
                final data = {
                  'worker_id': selectedWorkerId,
                  'period_type': selectedPeriodType,
                  'period_start': startDateCtrl.text.trim(),
                  'period_end': endDateCtrl.text.trim(),
                };
                if (deductionCtrl.text.trim().isNotEmpty) {
                  data['deduction_amount'] = deductionCtrl.text.trim();
                }
                await _api.post(ApiConfig.workerSettlementsGenerate, data: data);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已生成结算单'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating));
                  _loadSettlements();
                }
              } catch (e) {
                setDialogState(() => isSubmitting = false);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败: $e'), backgroundColor: AppTheme.dangerColor, behavior: SnackBarBehavior.floating));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: isSubmitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('生成'),
          ),
        ],
      )),
    );
  }

  Future<void> _confirmSettlement(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('确认结算'),
        content: Text('确认结算 ${item['worker']?['name'] ?? '未知工人'} 的 ${_formatPeriod(item)} 结算单？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('确认'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _api.post(ApiConfig.replaceId(ApiConfig.workerSettlementsConfirm, item['id']));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已确认结算'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating));
          _loadSettlements();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败: $e'), backgroundColor: AppTheme.dangerColor, behavior: SnackBarBehavior.floating));
      }
    }
  }

  Future<void> _markAsPaid(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('标记已付'),
        content: Text('确认将 ${item['worker']?['name'] ?? '未知工人'} 的 ${_formatPeriod(item)} 结算单标记为已付？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
            child: const Text('确认'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _api.post(ApiConfig.replaceId(ApiConfig.workerSettlementsPay, item['id']));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已标记为已付'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating));
          _loadSettlements();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败: $e'), backgroundColor: AppTheme.dangerColor, behavior: SnackBarBehavior.floating));
      }
    }
  }

  Widget _buildInfoItem({required String label, required String value, Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.textHint),
          const SizedBox(height: 8),
          const Text('暂无结算记录', style: TextStyle(color: AppTheme.textHint)),
          const SizedBox(height: 4),
          const Text('点击右下角按钮生成结算单', style: TextStyle(fontSize: 12, color: AppTheme.textHint)),
        ],
      ),
    );
  }
}
