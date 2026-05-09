import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/pagination_widget.dart';
import '../../utils/number_utils.dart';

class SalaryPage extends StatefulWidget {
  const SalaryPage({super.key});

  @override
  State<SalaryPage> createState() => _SalaryPageState();
}

class _SalaryPageState extends State<SalaryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService.instance;

  Map<String, dynamic>? _salaryData;
  bool _isLoading = true;
  dynamic _error;

  final GlobalKey<StatsPaginationState> _pieceKey = GlobalKey();
  final GlobalKey<StatsPaginationState> _advanceKey = GlobalKey();
  final GlobalKey<StatsPaginationState> _settlementKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSalaryData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSalaryData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final result = await _api.get(ApiConfig.workerMySalary);
      _salaryData = result['data'] ?? result;
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() { _error = e; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('我的薪资')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _error != null
              ? ErrorStateWidget(error: _error, onRetry: _loadSalaryData)
              : RefreshIndicator(
                  onRefresh: _loadSalaryData,
                  color: AppTheme.primaryColor,
                  child: Column(
                    children: [
                      _buildSalaryHeader(),
                      _buildTabBar(),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildPieceTab(),
                            _buildAdvanceTab(),
                            _buildSettlementTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSalaryHeader() {
    final summary = _salaryData?['summary'] as Map<String, dynamic>? ?? {};
    final lastSettlement = _salaryData?['last_settlement'] as Map<String, dynamic>?;
    final settledSummary = _salaryData?['settled_summary'] as Map<String, dynamic>? ?? {};
    final grossAmount = safeToDouble(summary['approved_piece_amount']);
    final advanceDeduction = safeToDouble(summary['advance_amount']);
    final netAmount = safeToDouble(summary['net_amount'] ?? grossAmount - advanceDeduction);
    final settledPieceAmount = safeToDouble(settledSummary['piece_amount']);
    final settledAdvanceAmount = safeToDouble(settledSummary['advance_amount']);
    final settledNetAmount = safeToDouble(settledSummary['net_amount']);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.gradientDecoration(
        colors: [AppTheme.primaryColor, AppTheme.primaryDark],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('待结算工资', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text('¥${netAmount.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildSalaryInfoItem(label: '应发计件', value: '¥${grossAmount.toStringAsFixed(2)}')),
              Container(width: 1, height: 36, color: Colors.white24),
              Expanded(child: _buildSalaryInfoItem(label: '预支扣减', value: '-¥${advanceDeduction.toStringAsFixed(2)}', valueColor: Colors.yellowAccent)),
            ],
          ),
          if (settledNetAmount > 0) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildSalaryInfoItem(label: '已结算计件', value: '¥${settledPieceAmount.toStringAsFixed(2)}')),
                Container(width: 1, height: 36, color: Colors.white24),
                Expanded(child: _buildSalaryInfoItem(label: '已结算预支', value: '-¥${settledAdvanceAmount.toStringAsFixed(2)}', valueColor: Colors.yellowAccent)),
                Container(width: 1, height: 36, color: Colors.white24),
                Expanded(child: _buildSalaryInfoItem(label: '已结算实发', value: '¥${settledNetAmount.toStringAsFixed(2)}', valueColor: Colors.greenAccent)),
              ],
            ),
          ],
          if (lastSettlement != null) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white54, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '上次结算: ${lastSettlement['paid_at'] ?? ''}  已发 ¥${safeToDouble(lastSettlement['net_amount']).toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSalaryInfoItem({required String label, required String value, Color? valueColor}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(8)),
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 14),
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        tabs: const [Tab(text: '计件明细'), Tab(text: '预支记录'), Tab(text: '结算记录')],
      ),
    );
  }

  Widget _buildPieceTab() {
    return StatsPagination(
      key: _pieceKey,
      fetchUrl: ApiConfig.workerMyPieceRecords,
      defaultParams: {'status': 'approved'},
      builder: (items) {
        final grouped = <String, List<Map<String, dynamic>>>{};
        for (final item in items) {
          final processName = item['process_name'] ?? item['process']?['name'] ?? '未知工序';
          grouped.putIfAbsent(processName, () => []).add(item);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          itemCount: grouped.length,
          itemBuilder: (context, index) {
            final processName = grouped.keys.elementAt(index);
            final groupItems = grouped[processName]!;
            double totalAmount = 0, totalQty = 0;
            for (final item in groupItems) {
              totalAmount += safeToDouble(item['amount']);
              totalQty += safeToDouble(item['quantity']);
            }

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
                      Expanded(child: Text(processName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary))),
                      Text('¥${totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('数量: ${totalQty.toStringAsFixed(0)}件 | ${groupItems.length}条记录', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  ...groupItems.map((item) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item['work_date'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
                        Text('${safeToDouble(item['quantity']).toStringAsFixed(0)}件 x ¥${safeToDouble(item['unit_price']).toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  )),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAdvanceTab() {
    return Column(
      children: [
        Expanded(
          child: StatsPagination(
            key: _advanceKey,
            fetchUrl: ApiConfig.workerMyAdvances,
            builder: (items) {
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                itemCount: items.length,
                itemBuilder: (context, index) => _buildAdvanceCard(items[index]),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _showAdvanceApplyDialog(),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('申请预支', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvanceCard(Map<String, dynamic> record) {
    final amount = safeToDouble(record['amount']);
    final date = record['advance_date'] ?? record['created_at'] ?? '';
    final type = record['type'] ?? 'cash';
    final statusRaw = record['status'] ?? 1;
    final status = statusRaw is int
        ? const {1: 'pending', 2: 'approved', 3: 'rejected', 4: 'paid'}[statusRaw] ?? 'pending'
        : statusRaw.toString();

    const typeLabels = {'cash': '现金', 'transfer': '转账'};
    const statusLabels = {'pending': '待审批', 'approved': '已通过', 'rejected': '已驳回', 'paid': '已发放'};
    const statusColors = {'pending': AppTheme.warningColor, 'approved': AppTheme.successColor, 'rejected': AppTheme.dangerColor, 'paid': AppTheme.infoColor};
    final statusColor = statusColors[status] ?? AppTheme.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppTheme.warningColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.warningColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('¥${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(statusLabels[status] ?? '未知', style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(typeLabels[type] ?? type, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(width: 12),
                    Text(_formatDate(date), style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementTab() {
    return StatsPagination(
      key: _settlementKey,
      fetchUrl: ApiConfig.workerMySettlements,
      builder: (items) {
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          itemCount: items.length,
          itemBuilder: (context, index) => _buildSettlementCard(items[index]),
        );
      },
    );
  }

  Widget _buildSettlementCard(Map<String, dynamic> record) {
    final period = record['period'] ?? '${record['period_start'] ?? ''} ~ ${record['period_end'] ?? ''}';
    final pieceAmount = safeToDouble(record['piece_amount'] ?? record['total_amount']);
    final advanceAmount = safeToDouble(record['advance_amount'] ?? record['advance_deduction']);
    final deductionAmount = safeToDouble(record['deduction_amount'] ?? 0);
    final netAmount = safeToDouble(record['net_amount'] ?? pieceAmount - advanceAmount - deductionAmount);
    final status = record['status'] ?? 'pending';
    final remark = record['remark'] ?? '';

    const statusLabels = {'pending': '待确认', 'confirmed': '已确认', 'paid': '已支付'};
    const statusColors = {'pending': AppTheme.warningColor, 'confirmed': AppTheme.primaryColor, 'paid': AppTheme.successColor};
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
              Expanded(child: Text(period, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(statusLabels[status] ?? '未知', style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSettlementInfoItem(label: '计件金额', value: '¥${pieceAmount.toStringAsFixed(2)}'),
              const SizedBox(width: 16),
              _buildSettlementInfoItem(label: '预支扣减', value: '-¥${advanceAmount.toStringAsFixed(2)}', valueColor: AppTheme.dangerColor),
              if (deductionAmount > 0) ...[
                const SizedBox(width: 16),
                _buildSettlementInfoItem(label: '其他扣减', value: '-¥${deductionAmount.toStringAsFixed(2)}', valueColor: AppTheme.dangerColor),
              ],
              const SizedBox(width: 16),
              _buildSettlementInfoItem(label: '实发', value: '¥${netAmount.toStringAsFixed(2)}', valueColor: AppTheme.primaryColor),
            ],
          ),
          if (remark.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('备注: $remark', style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
          ],
        ],
      ),
    );
  }

  Widget _buildSettlementInfoItem({required String label, required String value, Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? AppTheme.textPrimary)),
      ],
    );
  }

  void _showAdvanceApplyDialog() {
    final amountController = TextEditingController();
    final remarkController = TextEditingController();
    String selectedType = 'cash';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('申请预支'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('金额（必填）', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              TextField(controller: amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(hintText: '请输入预支金额')),
              const SizedBox(height: 16),
              const Text('类型', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildTypeChip(label: '现金', isSelected: selectedType == 'cash', onTap: () => setDialogState(() => selectedType = 'cash')),
                  const SizedBox(width: 10),
                  _buildTypeChip(label: '转账', isSelected: selectedType == 'transfer', onTap: () => setDialogState(() => selectedType = 'transfer')),
                ],
              ),
              const SizedBox(height: 16),
              const Text('备注', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              TextField(controller: remarkController, maxLines: 2, decoration: const InputDecoration(hintText: '请输入备注信息（选填）')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入有效金额'), backgroundColor: AppTheme.dangerColor));
                  return;
                }
                Navigator.pop(context);
                await _submitAdvanceApply(amount: amount, type: selectedType, remark: remarkController.text);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              child: const Text('提交'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(color: isSelected ? AppTheme.primaryColor : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : AppTheme.textSecondary)),
      ),
    );
  }

  Future<void> _submitAdvanceApply({required double amount, required String type, String? remark}) async {
    try {
      await _api.post(ApiConfig.workerApplyAdvance, data: {
        'amount': amount,
        'type': type,
        if (remark != null && remark.isNotEmpty) 'remark': remark,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('预支申请已提交'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating));
        _advanceKey.currentState?.refresh();
        _loadSalaryData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('提交失败: $e'), backgroundColor: AppTheme.dangerColor, behavior: SnackBarBehavior.floating));
      }
    }
  }

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

class StatsPagination extends StatefulWidget {
  final String fetchUrl;
  final Map<String, dynamic> defaultParams;
  final Widget Function(List<Map<String, dynamic>> items) builder;

  const StatsPagination({
    super.key,
    required this.fetchUrl,
    this.defaultParams = const {},
    required this.builder,
  });

  @override
  State<StatsPagination> createState() => StatsPaginationState();
}

class StatsPaginationState extends State<StatsPagination> {
  final ApiService _api = ApiService.instance;
  List<Map<String, dynamic>> _items = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _total = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;

  bool get _hasMore => _currentPage < _totalPages;

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
  }

  Future<void> refresh() async {
    await _loadFirstPage();
  }

  Future<void> _loadFirstPage() async {
    setState(() { _isLoading = true; _currentPage = 1; });
    try {
      final response = await _api.get(widget.fetchUrl, queryParameters: {...widget.defaultParams, 'page': 1, 'per_page': 15});
      _parseResponse(response);
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final response = await _api.get(widget.fetchUrl, queryParameters: {...widget.defaultParams, 'page': nextPage, 'per_page': 15});
      final newItems = _extractItems(response);
      final pagination = _extractPagination(response);
      _currentPage = nextPage;
      _items = [..._items, ...newItems];
      if (pagination != null) {
        _total = pagination['total'] ?? _items.length;
        _totalPages = pagination['last_page'] ?? 1;
      }
      if (mounted) setState(() => _isLoadingMore = false);
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _goToPage(int page) async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get(widget.fetchUrl, queryParameters: {...widget.defaultParams, 'page': page, 'per_page': 15});
      _parseResponse(response);
      _currentPage = page;
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _parseResponse(Map<String, dynamic> response) {
    _items = _extractItems(response);
    final pagination = _extractPagination(response);
    if (pagination != null) {
      _total = pagination['total'] ?? _items.length;
      _totalPages = pagination['last_page'] ?? 1;
    } else {
      _total = _items.length;
      _totalPages = _items.length >= 15 ? _currentPage + 1 : _currentPage;
    }
  }

  List<Map<String, dynamic>> _extractItems(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map && data.containsKey('list')) {
      final list = data['list'];
      if (list is List) return list.cast<Map<String, dynamic>>();
    }
    if (data is List) return data.cast<Map<String, dynamic>>();
    if (data is Map && data.containsKey('data')) {
      final inner = data['data'];
      if (inner is List) return inner.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Map<String, dynamic>? _extractPagination(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map && data.containsKey('pagination')) return data['pagination'] as Map<String, dynamic>?;
    if (response.containsKey('pagination')) return response['pagination'] as Map<String, dynamic>?;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 48, color: AppTheme.textHint),
            const SizedBox(height: 8),
            const Text('暂无数据', style: TextStyle(color: AppTheme.textHint)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(child: widget.builder(_items)),
        if (_hasMore && !_isLoadingMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TextButton.icon(
              onPressed: _loadMore,
              icon: const Icon(Icons.expand_more, size: 18),
              label: const Text('加载更多'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
            ),
          ),
        if (_isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor))),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppTheme.border.withOpacity(0.5)))),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('共 $_total 条', style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
                      icon: const Icon(Icons.chevron_left, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text('$_currentPage/$_totalPages', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
                    ),
                    IconButton(
                      onPressed: _hasMore ? () => _goToPage(_currentPage + 1) : null,
                      icon: const Icon(Icons.chevron_right, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
