import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../utils/number_utils.dart';

/// 计件审批页
class PieceApprovalPage extends StatefulWidget {
  const PieceApprovalPage({super.key});

  @override
  State<PieceApprovalPage> createState() => _PieceApprovalPageState();
}

class _PieceApprovalPageState extends State<PieceApprovalPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService.instance;

  // 三个Tab的数据
  List<Map<String, dynamic>> _pendingRecords = [];
  List<Map<String, dynamic>> _approvedRecords = [];
  List<Map<String, dynamic>> _rejectedRecords = [];

  bool _isLoading = true;
  bool _isBatchProcessing = false;
  Set<int> _selectedIds = {}; // 批量选择

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadAllRecords();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {}); // 切换Tab时刷新UI（更新批量操作按钮可见性）
  }

  /// 加载所有状态的记录
  Future<void> _loadAllRecords() async {
    setState(() {
      _isLoading = true;
      _selectedIds.clear();
    });

    try {
      dynamic pendingResult = <String, dynamic>{}, approvedResult = <String, dynamic>{}, rejectedResult = <String, dynamic>{};
      try { pendingResult = await _api.get(ApiConfig.workerPieceRecords, queryParameters: {'status': 'pending'}); } catch (_) {}
      try { approvedResult = await _api.get(ApiConfig.workerPieceRecords, queryParameters: {'status': 'approved'}); } catch (_) {}
      try { rejectedResult = await _api.get(ApiConfig.workerPieceRecords, queryParameters: {'status': 'rejected'}); } catch (_) {}

      _pendingRecords = _parseList(pendingResult);
      _approvedRecords = _parseList(approvedResult);
      _rejectedRecords = _parseList(rejectedResult);

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  /// 解析API返回的列表数据
  List<Map<String, dynamic>> _parseList(Map<String, dynamic> response) {
    final data = response['data'] ?? response;
    if (data is List) return data.cast<Map<String, dynamic>>();
    if (data is Map && data.containsKey('data')) {
      return (data['data'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('计件审批'),
        actions: [
          // 批量通过按钮（仅在待审批Tab显示）
          if (_tabController.index == 0 && _selectedIds.isNotEmpty)
            TextButton(
              onPressed: _isBatchProcessing ? null : _handleBatchApprove,
              child: _isBatchProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                    )
                  : Text(
                      '批量通过(${_selectedIds.length})',
                      style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                    ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPendingTab(),
                      _buildApprovedTab(),
                      _buildRejectedTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// Tab栏
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 14),
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        tabs: [
          Tab(text: '待审批${_pendingRecords.isNotEmpty ? '(${_pendingRecords.length})' : ''}'),
          Tab(text: '已通过'),
          Tab(text: '已驳回'),
        ],
      ),
    );
  }

  /// 待审批Tab
  Widget _buildPendingTab() {
    if (_pendingRecords.isEmpty) {
      return _buildEmptyView('暂无待审批记录');
    }

    return Column(
      children: [
        // 全选按钮
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: _toggleSelectAll,
                child: Row(
                  children: [
                    Checkbox(
                      value: _selectedIds.length == _pendingRecords.length && _pendingRecords.isNotEmpty,
                      onChanged: (_) => _toggleSelectAll(),
                      activeColor: AppTheme.primaryColor,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const Text('全选', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAllRecords,
            color: AppTheme.primaryColor,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: _pendingRecords.length,
              itemBuilder: (context, index) {
                return _buildPendingCard(_pendingRecords[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  /// 已通过Tab
  Widget _buildApprovedTab() {
    if (_approvedRecords.isEmpty) {
      return _buildEmptyView('暂无已通过记录');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _approvedRecords.length,
      itemBuilder: (context, index) {
        return _buildRecordCard(_approvedRecords[index], statusLabel: '已通过', statusColor: AppTheme.successColor);
      },
    );
  }

  /// 已驳回Tab
  Widget _buildRejectedTab() {
    if (_rejectedRecords.isEmpty) {
      return _buildEmptyView('暂无已驳回记录');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _rejectedRecords.length,
      itemBuilder: (context, index) {
        return _buildRecordCard(_rejectedRecords[index], statusLabel: '已驳回', statusColor: AppTheme.dangerColor);
      },
    );
  }

  /// 待审批卡片（带选择和操作按钮）
  Widget _buildPendingCard(Map<String, dynamic> record) {
    final id = record['id'] as int? ?? 0;
    final workerName = record['worker_name'] ?? record['worker']?['name'] ?? '未知';
    final processName = record['process_name'] ?? record['process']?['name'] ?? '工序';
    final quantity = safeToDouble(record['quantity']);
    final amount = safeToDouble(record['amount']);
    final workDate = record['work_date'] ?? '';
    final isSelected = _selectedIds.contains(id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryColor.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: AppTheme.primaryColor.withOpacity(0.3)) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleSelect(id),
                activeColor: AppTheme.primaryColor,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      workerName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '待审批',
                        style: TextStyle(fontSize: 11, color: AppTheme.warningColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildInfoItem(label: '工序', value: processName),
                    const SizedBox(width: 20),
                    _buildInfoItem(label: '数量', value: '${quantity.toStringAsFixed(0)}件'),
                    const SizedBox(width: 20),
                    _buildInfoItem(label: '金额', value: '¥${amount.toStringAsFixed(2)}', valueColor: AppTheme.primaryColor),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(workDate),
                  style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
                ),
                const SizedBox(height: 10),
                // 通过/驳回按钮
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _handleReject(id, workerName),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.dangerColor,
                          side: const BorderSide(color: AppTheme.dangerColor),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('驳回', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handleApprove(id, workerName),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('通过', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 通用记录卡片（已通过/已驳回）
  Widget _buildRecordCard(
    Map<String, dynamic> record, {
    required String statusLabel,
    required Color statusColor,
  }) {
    final workerName = record['worker_name'] ?? record['worker']?['name'] ?? '未知';
    final processName = record['process_name'] ?? record['process']?['name'] ?? '工序';
    final quantity = safeToDouble(record['quantity']);
    final amount = safeToDouble(record['amount']);
    final workDate = record['work_date'] ?? '';
    final rejectReason = record['reject_reason'];

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
              Text(
                workerName,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildInfoItem(label: '工序', value: processName),
              const SizedBox(width: 20),
              _buildInfoItem(label: '数量', value: '${quantity.toStringAsFixed(0)}件'),
              const SizedBox(width: 20),
              _buildInfoItem(label: '金额', value: '¥${amount.toStringAsFixed(2)}', valueColor: AppTheme.primaryColor),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(workDate),
                style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
              ),
              if (rejectReason != null)
                Text(
                  '驳回原因: $rejectReason',
                  style: const TextStyle(fontSize: 12, color: AppTheme.dangerColor),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 信息子项
  Widget _buildInfoItem({
    required String label,
    required String value,
    Color? valueColor,
  }) {
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

  /// 切换选择
  void _toggleSelect(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  /// 全选/取消全选
  void _toggleSelectAll() {
    setState(() {
      if (_selectedIds.length == _pendingRecords.length) {
        _selectedIds.clear();
      } else {
        _selectedIds = _pendingRecords
            .map((r) => r['id'] as int? ?? 0)
            .where((id) => id > 0)
            .toSet();
      }
    });
  }

  /// 单条通过
  Future<void> _handleApprove(int id, String workerName) async {
    try {
      await _api.post(
        ApiConfig.workerPieceRecordsApprove,
        data: {'ids': [id]},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已通过: $workerName'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        _loadAllRecords();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: $e'),
            backgroundColor: AppTheme.dangerColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 单条驳回
  void _handleReject(int id, String workerName) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('驳回原因'),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '请输入驳回原因',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _api.post(
                  ApiConfig.workerPieceRecordsReject,
                  data: {
                    'ids': [id],
                    'reject_reason': reasonController.text.isNotEmpty ? reasonController.text : '未填写原因',
                  },
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('已驳回: $workerName'),
                      backgroundColor: AppTheme.dangerColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                  _loadAllRecords();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('操作失败: $e'),
                      backgroundColor: AppTheme.dangerColor,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            child: const Text('确认驳回'),
          ),
        ],
      ),
    );
  }

  /// 批量通过
  Future<void> _handleBatchApprove() async {
    if (_selectedIds.isEmpty) return;

    setState(() => _isBatchProcessing = true);

    try {
      await _api.post(
        ApiConfig.workerPieceRecordsApprove,
        data: {'ids': _selectedIds.toList()},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已批量通过 ${_selectedIds.length} 条记录'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        _loadAllRecords();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('批量操作失败: $e'),
            backgroundColor: AppTheme.dangerColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBatchProcessing = false);
    }
  }

  /// 空状态
  Widget _buildEmptyView(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 48, color: AppTheme.textHint),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: AppTheme.textHint)),
        ],
      ),
    );
  }

  /// 格式化日期
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr.length > 10 ? dateStr.substring(0, 10) : dateStr;
    }
  }
}
