import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../widgets/error_state_widget.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final ApiService _api = ApiService.instance;
  List<Map<String, dynamic>> _items = [];
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
      final response = await _api.get(ApiConfig.products);
      final data = response['data'] ?? response;
      List<dynamic> list;
      if (data is List) { list = data; }
      else if (data is Map && data.containsKey('data')) { list = data['data'] as List; }
      else { list = []; }
      setState(() { _items = list.cast<Map<String, dynamic>>(); _isLoading = false; });
    } catch (e) {
      setState(() { _error = e; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('产品管理')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _error != null
              ? ErrorStateWidget(error: _error, onRetry: _loadData)
              : _items.isEmpty
                  ? _buildEmptyView()
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: AppTheme.primaryColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: _items.length,
                        itemBuilder: (context, index) => _buildCard(_items[index]),
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final name = item['name'] ?? '未知';
    final code = item['code'] ?? item['sku'] ?? '';
    final categoryName = item['category']?['name'] ?? item['category_name'] ?? '';
    final status = item['status'] ?? 1;
    final isActive = status == 1 || status == 'active';
    final unit = item['unit'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: AppTheme.primaryColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isActive ? AppTheme.successColor : AppTheme.textHint).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(isActive ? '启用' : '停用', style: TextStyle(fontSize: 11, color: isActive ? AppTheme.successColor : AppTheme.textHint, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (code.isNotEmpty) Text('编码: $code', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    if (categoryName.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Text('分类: $categoryName', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                    if (unit.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Text('单位: $unit', style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (action) => _handleAction(action, item),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryColor), SizedBox(width: 8), Text('编辑')])),
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerColor), SizedBox(width: 8), Text('删除', style: TextStyle(color: AppTheme.dangerColor))])),
            ],
          ),
        ],
      ),
    );
  }

  void _handleAction(String action, Map<String, dynamic> item) {
    switch (action) {
      case 'edit': _showFormDialog(item: item); break;
      case 'delete': _showDeleteConfirm(item); break;
    }
  }

  void _showFormDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    final nameCtrl = TextEditingController(text: item?['name'] ?? '');
    final codeCtrl = TextEditingController(text: item?['code'] ?? '');
    int? selectedCategoryId = item?['category_id'] as int?;
    final unitCtrl = TextEditingController(text: item?['unit'] ?? '');
    final specCtrl = TextEditingController(text: item?['specification'] ?? item?['spec'] ?? '');
    String status = item?['status']?.toString() ?? 'active';
    if (status == '1') status = 'active';
    if (status == '0') status = 'inactive';
    bool isSubmitting = false;
    List<Map<String, dynamic>> categories = [];
    bool categoriesLoaded = false;

    _loadCategories() async {
      try {
        final response = await _api.get(ApiConfig.productCategories);
        final data = response['data'] ?? response;
        if (data is List) {
          categories = data.cast<Map<String, dynamic>>();
        } else if (data is Map && data.containsKey('data')) {
          categories = (data['data'] as List).cast<Map<String, dynamic>>();
        }
        categoriesLoaded = true;
      } catch (_) {}
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) {
        if (!categoriesLoaded) {
          _loadCategories().then((_) => setDialogState(() {}));
        }
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEdit ? '编辑产品' : '新增产品'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '名称 *', prefixIcon: Icon(Icons.inventory_2_outlined))),
                  const SizedBox(height: 12),
                  TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: '编码', prefixIcon: Icon(Icons.badge_outlined))),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    value: selectedCategoryId,
                    decoration: const InputDecoration(labelText: '分类', prefixIcon: Icon(Icons.category_outlined)),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('未分类')),
                      ...categories.map((c) => DropdownMenuItem<int?>(
                        value: c['id'] as int,
                        child: Text(c['name']?.toString() ?? '未知'),
                      )),
                    ],
                    onChanged: (v) => setDialogState(() => selectedCategoryId = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: '单位', prefixIcon: Icon(Icons.straighten_outlined))),
                  const SizedBox(height: 12),
                  TextField(controller: specCtrl, decoration: const InputDecoration(labelText: '规格', prefixIcon: Icon(Icons.description_outlined))),
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
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('名称不能为空'), backgroundColor: AppTheme.dangerColor));
                  return;
                }
                setDialogState(() => isSubmitting = true);
                try {
                  final data = <String, dynamic>{
                    'name': nameCtrl.text.trim(),
                    'code': codeCtrl.text.trim().isEmpty ? null : codeCtrl.text.trim(),
                    'category_id': selectedCategoryId,
                    'unit': unitCtrl.text.trim().isEmpty ? null : unitCtrl.text.trim(),
                    'specification': specCtrl.text.trim().isEmpty ? null : specCtrl.text.trim(),
                    'status': status,
                  };
                  if (isEdit) {
                    await _api.put('${ApiConfig.products}/${item['id']}', data: data);
                  } else {
                    await _api.post(ApiConfig.products, data: data);
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
        );
      }),
    );
  }

  void _showDeleteConfirm(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('确认删除'),
        content: Text('确认删除产品 ${item['name'] ?? ''}？此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _api.delete('${ApiConfig.products}/${item['id']}');
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

  Widget _buildEmptyView() {
    return Center(child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.textHint),
        const SizedBox(height: 8),
        const Text('暂无产品数据', style: TextStyle(color: AppTheme.textHint)),
        const SizedBox(height: 8),
        Text('点击右下角按钮新增产品', style: TextStyle(color: AppTheme.textHint.withOpacity(0.7), fontSize: 13)),
      ],
    ));
  }

}
