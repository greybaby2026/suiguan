import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../widgets/error_state_widget.dart';

class WarehouseManagePage extends StatefulWidget {
  const WarehouseManagePage({super.key});

  @override
  State<WarehouseManagePage> createState() => _WarehouseManagePageState();
}

class _WarehouseManagePageState extends State<WarehouseManagePage> {
  final ApiService _api = ApiService.instance;
  List<Map<String, dynamic>> _warehouses = [];
  bool _isLoading = true;
  dynamic _error;

  @override
  void initState() {
    super.initState();
    _loadWarehouses();
  }

  Future<void> _loadWarehouses() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await _api.get(ApiConfig.warehouses);
      final data = response['data'] ?? response;
      List<dynamic> list;
      if (data is List) { list = data; }
      else if (data is Map && data.containsKey('data')) { list = data['data'] as List; }
      else { list = []; }
      setState(() { _warehouses = list.cast<Map<String, dynamic>>(); _isLoading = false; });
    } catch (e) {
      setState(() { _error = e; _isLoading = false; });
    }
  }

  void _showWarehouseFormDialog({Map<String, dynamic>? warehouse}) {
    final isEdit = warehouse != null;
    final nameCtrl = TextEditingController(text: warehouse?['name']?.toString() ?? '');
    final codeCtrl = TextEditingController(text: warehouse?['code']?.toString() ?? '');
    final locationCtrl = TextEditingController(text: warehouse?['location']?.toString() ?? '');
    String status = warehouse?['status']?.toString() ?? 'active';
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEdit ? '编辑仓库' : '新增仓库'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: '仓库名 *', prefixIcon: Icon(Icons.warehouse_outlined)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(labelText: '编码', prefixIcon: Icon(Icons.qr_code_outlined)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(labelText: '位置', prefixIcon: Icon(Icons.location_on_outlined)),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: '状态', prefixIcon: Icon(Icons.toggle_on_outlined)),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('启用')),
                    DropdownMenuItem(value: 'inactive', child: Text('停用')),
                  ],
                  onChanged: (v) => setDialogState(() => status = v ?? 'active'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: isSubmitting ? null : () async {
              if (nameCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('仓库名不能为空'), backgroundColor: AppTheme.dangerColor));
                return;
              }
              setDialogState(() => isSubmitting = true);
              try {
                final data = <String, dynamic>{
                  'name': nameCtrl.text.trim(),
                  'code': codeCtrl.text.trim().isEmpty ? null : codeCtrl.text.trim(),
                  'location': locationCtrl.text.trim().isEmpty ? null : locationCtrl.text.trim(),
                  'status': status,
                };
                if (isEdit) {
                  await _api.put('${ApiConfig.warehouses}/${warehouse!['id']}', data: data);
                } else {
                  await _api.post(ApiConfig.warehouses, data: data);
                }
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? '已更新' : '已创建'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating));
                  _loadWarehouses();
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

  void _showDeleteConfirm(Map<String, dynamic> warehouse) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('确认删除'),
        content: Text('确认删除仓库 ${warehouse['name'] ?? ''}？此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _api.delete('${ApiConfig.warehouses}/${warehouse['id']}');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已删除'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating));
                  _loadWarehouses();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('仓库管理')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _error != null
              ? ErrorStateWidget(error: _error, onRetry: _loadWarehouses)
              : _warehouses.isEmpty
                  ? _buildEmptyView()
                  : RefreshIndicator(
                      onRefresh: _loadWarehouses,
                      color: AppTheme.primaryColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: _warehouses.length,
                        itemBuilder: (context, index) => _buildCard(_warehouses[index]),
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showWarehouseFormDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final isActive = (item['status'] ?? 'active') == 'active';
    final statusColor = isActive ? AppTheme.successColor : AppTheme.textHint;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.warehouse_outlined, color: AppTheme.primaryColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(item['name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(isActive ? '启用' : '停用', style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (item['code'] != null && item['code'].toString().isNotEmpty) ...[
                      Text('编码: ${item['code']}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                      const SizedBox(width: 16),
                    ],
                    if (item['location'] != null && item['location'].toString().isNotEmpty)
                      Text('位置: ${item['location']}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (action) {
              if (action == 'edit') _showWarehouseFormDialog(warehouse: item);
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

  Widget _buildEmptyView() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.warehouse_outlined, size: 48, color: AppTheme.textHint),
      const SizedBox(height: 8),
      const Text('暂无仓库数据', style: TextStyle(color: AppTheme.textHint)),
      const SizedBox(height: 8),
      Text('点击右下角按钮新增仓库', style: TextStyle(color: AppTheme.textHint.withOpacity(0.7), fontSize: 13)),
    ]));
  }

}
