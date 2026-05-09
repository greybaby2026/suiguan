import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../widgets/error_state_widget.dart';
import '../../utils/number_utils.dart';

class AdvanceManagePage extends StatefulWidget {
  const AdvanceManagePage({super.key});

  @override
  State<AdvanceManagePage> createState() => _AdvanceManagePageState();
}

class _AdvanceManagePageState extends State<AdvanceManagePage> {
  final ApiService _api = ApiService.instance;
  List<Map<String, dynamic>> _advances = [];
  bool _isLoading = true;
  dynamic _error;
  String _statusFilter = 'all';
  final Map<String, dynamic> _statusMap = {
    'all': null,
    'pending': 1,
    'approved': 2,
    'rejected': 3,
  };

  @override
  void initState() {
    super.initState();
    _loadAdvances();
  }

  Future<void> _loadAdvances() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await _api.get(ApiConfig.workerAdvances, queryParameters: {
        if (_statusMap[_statusFilter] != null) 'status': _statusMap[_statusFilter],
      });
      final payload = response['data'] ?? response;
      final list = payload is Map && payload.containsKey('list')
          ? (payload['list'] as List<dynamic>)
          : payload is List
              ? payload
              : payload is Map && payload.containsKey('data')
                  ? (payload['data'] as List<dynamic>)
                  : <dynamic>[];
      setState(() { _advances = list.cast<Map<String, dynamic>>(); _isLoading = false; });
    } catch (e) {
      setState(() {
        _error = e;
        _isLoading = false;
        _advances = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('预支管理')),
      body: Column(
        children: [
          _buildStatusFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : _error != null
                    ? ErrorStateWidget(error: _error, onRetry: _loadAdvances)
                    : _advances.isEmpty
                        ? _buildEmptyView()
                        : RefreshIndicator(
                            onRefresh: _loadAdvances,
                            color: AppTheme.primaryColor,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                              itemCount: _advances.length,
                              itemBuilder: (context, index) => _buildAdvanceCard(_advances[index]),
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _buildFilterChip(label: '待审批', value: 'pending'),
          const SizedBox(width: 8),
          _buildFilterChip(label: '已通过', value: 'approved'),
          const SizedBox(width: 8),
          _buildFilterChip(label: '已驳回', value: 'rejected'),
          const SizedBox(width: 8),
          _buildFilterChip(label: '全部', value: 'all'),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required String value}) {
    final isActive = _statusFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _statusFilter = value);
        _loadAdvances();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildAdvanceCard(Map<String, dynamic> item) {
    final amount = safeToDouble(item['amount']);
    final workerName = item['worker']?['name'] ?? '未知工人';
    final date = item['advance_date'] ?? item['created_at'] ?? '';
    final status = item['status'] ?? 'pending';
    final remark = item['remark'] ?? '';

    const statusLabels = {1: '待审批', 2: '已通过', 3: '已驳回', 4: '已发放', 'pending': '待审批', 'approved': '已通过', 'rejected': '已驳回', 'paid': '已发放'};
    const statusColors = {
      1: AppTheme.warningColor, 2: AppTheme.successColor, 3: AppTheme.dangerColor, 4: AppTheme.infoColor,
      'pending': AppTheme.warningColor, 'approved': AppTheme.successColor, 'rejected': AppTheme.dangerColor, 'paid': AppTheme.infoColor,
    };
    final statusColor = statusColors[status] ?? AppTheme.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
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
                    Text(workerName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
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
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('¥${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
                    const SizedBox(width: 12),
                    Text(_formatDate(date), style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
                  ],
                ),
                if (remark.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(remark, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (action) => _handleAction(action, item),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerColor), SizedBox(width: 8), Text('删除', style: TextStyle(color: AppTheme.dangerColor))])),
            ],
          ),
        ],
      ),
    );
  }

  void _handleAction(String action, Map<String, dynamic> item) {
    switch (action) {
      case 'delete': _showDeleteConfirm(item); break;
    }
  }

  void _showFormDialog() {
    final amountCtrl = TextEditingController();
    final remarkCtrl = TextEditingController();
    String advanceDate = DateTime.now().toString().substring(0, 10);
    String type = 'salary_bonus';
    int? selectedWorkerId;
    String selectedWorkerName = '';
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('新增预支'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    try {
                      final result = await ApiService.instance.get(ApiConfig.workers);
                      final data = result['data'];
                      final workers = data is List ? data.cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];
                      if (!ctx.mounted) return;
                      final picked = await showModalBottomSheet<Map<String, dynamic>>(
                        context: context,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                        builder: (sheetCtx) {
                          String search = '';
                          return StatefulBuilder(builder: (sheetCtx, setSheetState) {
                            final filtered = search.isEmpty ? workers : workers.where((w) => (w['name'] ?? '').toString().toLowerCase().contains(search.toLowerCase())).toList();
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('选择工人', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)), IconButton(onPressed: () => Navigator.pop(sheetCtx), icon: const Icon(Icons.close))])),
                                Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: TextField(decoration: InputDecoration(hintText: '搜索工人姓名', prefixIcon: const Icon(Icons.search, size: 20), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), onChanged: (v) => setSheetState(() => search = v))),
                                const Divider(height: 1),
                                Flexible(child: ListView.separated(shrinkWrap: true, itemCount: filtered.length, separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16), itemBuilder: (_, i) => ListTile(title: Text(filtered[i]['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text(filtered[i]['phone'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textHint)), trailing: const Icon(Icons.chevron_right, color: AppTheme.textHint), onTap: () => Navigator.pop(sheetCtx, filtered[i])))),
                                SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
                              ],
                            );
                          });
                        },
                      );
                      if (picked != null) {
                        setDialogState(() { selectedWorkerId = picked['id']; selectedWorkerName = picked['name'] ?? ''; });
                      }
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('加载工人列表失败: $e'), backgroundColor: AppTheme.dangerColor));
                    }
                  },
                  child: AbsorbPointer(
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: '工人 *',
                        prefixIcon: const Icon(Icons.person_outline),
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                        errorText: selectedWorkerId == null ? '请选择工人' : null,
                      ),
                      child: Text(selectedWorkerName.isNotEmpty ? selectedWorkerName : '点击选择工人', style: TextStyle(fontSize: 16, color: selectedWorkerName.isNotEmpty ? AppTheme.textPrimary : AppTheme.textHint)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  decoration: const InputDecoration(labelText: '金额 *', prefixIcon: Icon(Icons.attach_money)),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.tryParse(advanceDate) ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setDialogState(() => advanceDate = picked.toString().substring(0, 10));
                    }
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      controller: TextEditingController(text: advanceDate),
                      decoration: const InputDecoration(labelText: '预支日期 *', prefixIcon: Icon(Icons.calendar_today_outlined)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: '类型', prefixIcon: Icon(Icons.category_outlined)),
                  items: const [
                    DropdownMenuItem(value: 'salary_bonus', child: Text('工资奖金')),
                    DropdownMenuItem(value: 'emergency', child: Text('紧急预支')),
                    DropdownMenuItem(value: 'other', child: Text('其他')),
                  ],
                  onChanged: (v) => setDialogState(() => type = v ?? 'salary_bonus'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: remarkCtrl,
                  decoration: const InputDecoration(labelText: '备注', prefixIcon: Icon(Icons.note_outlined)),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: isSubmitting ? null : () async {
              if (selectedWorkerId == null || amountCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择工人和填写金额'), backgroundColor: AppTheme.dangerColor));
                return;
              }
              setDialogState(() => isSubmitting = true);
              try {
                final data = {
                  'worker_id': selectedWorkerId,
                  'amount': double.tryParse(amountCtrl.text.trim()) ?? 0,
                  'advance_date': advanceDate,
                  'type': type,
                  'remark': remarkCtrl.text.trim().isEmpty ? null : remarkCtrl.text.trim(),
                };
                await _api.post(ApiConfig.workerAdvances, data: data);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已创建'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating));
                  _loadAdvances();
                }
              } catch (e) {
                setDialogState(() => isSubmitting = false);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败: $e'), backgroundColor: AppTheme.dangerColor, behavior: SnackBarBehavior.floating));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: isSubmitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('创建'),
          ),
        ],
      )),
    );
  }

  void _showDeleteConfirm(Map<String, dynamic> item) {
    final workerName = item['worker']?['name'] ?? '未知工人';
    final amount = safeToDouble(item['amount']);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('确认删除'),
        content: Text('确认删除 $workerName 的预支记录（¥${amount.toStringAsFixed(2)}）？此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _api.delete('${ApiConfig.workerAdvances}/${item['id']}');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已删除'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating));
                  _loadAdvances();
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败: $e'), backgroundColor: AppTheme.dangerColor, behavior: SnackBarBehavior.floating));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.account_balance_wallet_outlined, size: 48, color: AppTheme.textHint),
        const SizedBox(height: 8),
        const Text('暂无预支记录', style: TextStyle(color: AppTheme.textHint)),
        const SizedBox(height: 8),
        Text('点击右下角按钮新增预支', style: TextStyle(color: AppTheme.textHint.withOpacity(0.7), fontSize: 13)),
      ],
    ));
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
