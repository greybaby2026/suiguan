import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../widgets/error_state_widget.dart';
import '../../utils/number_utils.dart';

class CostRecordPage extends StatefulWidget {
  const CostRecordPage({super.key});

  @override
  State<CostRecordPage> createState() => _CostRecordPageState();
}

class _CostRecordPageState extends State<CostRecordPage> {
  final ApiService _api = ApiService.instance;
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;
  dynamic _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await _api.get(ApiConfig.costRecords);
      final data = response['data'] ?? response;
      List<dynamic> list;
      if (data is List) { list = data; }
      else if (data is Map && data.containsKey('data')) { list = data['data'] as List; }
      else { list = []; }
      setState(() { _records = list.cast<Map<String, dynamic>>(); _isLoading = false; });
    } catch (e) {
      setState(() { _error = e; _isLoading = false; });
    }
  }

  void _showCostFormDialog({Map<String, dynamic>? record}) {
    final isEdit = record != null;
    String costType = record?['cost_type'] ?? record?['type'] ?? 'material';
    final amountCtrl = TextEditingController(text: record?['amount']?.toString() ?? '');
    final costDateCtrl = TextEditingController(text: _formatDateForInput(record?['cost_date'] ?? record?['date']));
    final remarkCtrl = TextEditingController(text: record?['remark']?.toString() ?? '');
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEdit ? '编辑成本记录' : '新增成本记录'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: costType,
                  decoration: const InputDecoration(labelText: '类型 *', prefixIcon: Icon(Icons.category_outlined)),
                  items: const [
                    DropdownMenuItem(value: 'material', child: Text('材料')),
                    DropdownMenuItem(value: 'labor', child: Text('人工')),
                    DropdownMenuItem(value: 'outsourcing', child: Text('外协')),
                    DropdownMenuItem(value: 'overhead', child: Text('制造费用')),
                  ],
                  onChanged: (v) => setDialogState(() => costType = v ?? 'material'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '金额 *', prefixIcon: Icon(Icons.attach_money)),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final initialDate = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: initialDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      costDateCtrl.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                    }
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      controller: costDateCtrl,
                      decoration: const InputDecoration(labelText: '日期 *', prefixIcon: Icon(Icons.calendar_today_outlined)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: remarkCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: '备注', prefixIcon: Icon(Icons.note_outlined)),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: isSubmitting ? null : () async {
              if (amountCtrl.text.trim().isEmpty || costDateCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('金额和日期不能为空'), backgroundColor: AppTheme.dangerColor));
                return;
              }
              setDialogState(() => isSubmitting = true);
              try {
                final data = <String, dynamic>{
                  'type': costType,
                  'amount': double.tryParse(amountCtrl.text.trim()) ?? 0,
                  'recorded_date': costDateCtrl.text.trim(),
                };
                if (remarkCtrl.text.trim().isNotEmpty) {
                  data['remark'] = remarkCtrl.text.trim();
                }
                if (isEdit) {
                  await _api.put('${ApiConfig.costRecords}/${record!['id']}', data: data);
                } else {
                  await _api.post(ApiConfig.costRecords, data: data);
                }
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? '已更新' : '已创建'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating));
                  _loadData();
                }
              } catch (e) {
                setDialogState(() => isSubmitting = false);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败: $e'), backgroundColor: AppTheme.dangerColor, behavior: SnackBarBehavior.floating));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: isSubmitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(isEdit ? '保存' : '创建'),
          ),
        ],
      )),
    );
  }

  void _showDeleteConfirm(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('确认删除'),
        content: Text('确认删除此成本记录（¥${record['amount'] ?? 0}）？此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _api.delete('${ApiConfig.costRecords}/${record['id']}');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已删除'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating));
                  _loadData();
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

  String _formatDateForInput(dynamic dateStr) {
    if (dateStr == null) return '';
    final s = dateStr.toString();
    if (s.isEmpty) return '';
    try {
      final dt = DateTime.parse(s);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) { return s.length > 10 ? s.substring(0, 10) : s; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('成本记录')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _error != null
              ? ErrorStateWidget(error: _error, onRetry: _loadData)
              : _records.isEmpty
                  ? _buildEmptyView()
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: AppTheme.primaryColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: _records.length,
                        itemBuilder: (context, index) => _buildCard(_records[index]),
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCostFormDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final type = item['cost_type'] ?? item['type'] ?? 'other';
    final amount = safeToDouble(item['amount']);
    final date = item['cost_date'] ?? item['recorded_date'] ?? item['date'] ?? item['created_at'] ?? '';
    final remark = item['remark'] ?? '';

    const typeLabels = {'material': '材料', 'labor': '人工', 'outsourcing': '外协', 'overhead': '制造费用'};
    const typeIcons = {'material': Icons.science_outlined, 'labor': Icons.groups_outlined, 'outsourcing': Icons.handshake_outlined, 'overhead': Icons.factory_outlined};
    const typeColors = {'material': AppTheme.accentColor, 'labor': AppTheme.primaryColor, 'outsourcing': AppTheme.infoColor, 'overhead': AppTheme.warningColor};

    final typeColor = typeColors[type] ?? AppTheme.textSecondary;
    final typeIcon = typeIcons[type] ?? Icons.receipt_outlined;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(typeIcon, color: typeColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(typeLabels[type] ?? type, style: TextStyle(fontSize: 10, color: typeColor, fontWeight: FontWeight.w600)),
                    ),
                    Text('¥${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(_formatDate(date), style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
                    if (remark.isNotEmpty) ...[const SizedBox(width: 12), Expanded(child: Text(remark, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis))],
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (action) {
              if (action == 'edit') _showCostFormDialog(record: item);
              if (action == 'delete') _showDeleteConfirm(item);
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryColor), const SizedBox(width: 8), const Text('编辑')])),
              PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerColor), const SizedBox(width: 8), const Text('删除', style: TextStyle(color: AppTheme.dangerColor))])),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) { return dateStr.length > 10 ? dateStr.substring(0, 10) : dateStr; }
  }

  Widget _buildEmptyView() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.textHint),
      const SizedBox(height: 8),
      const Text('暂无成本记录', style: TextStyle(color: AppTheme.textHint)),
      const SizedBox(height: 8),
      Text('点击右下角按钮新增记录', style: TextStyle(color: AppTheme.textHint.withOpacity(0.7), fontSize: 13)),
    ]));
  }

}
