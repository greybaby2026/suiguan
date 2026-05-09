import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../widgets/error_state_widget.dart';
import '../../utils/number_utils.dart';

class BomListPage extends StatefulWidget {
  const BomListPage({super.key});

  @override
  State<BomListPage> createState() => _BomListPageState();
}

class _BomListPageState extends State<BomListPage> {
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
      final response = await _api.get(ApiConfig.bomItems);
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
      appBar: AppBar(title: const Text('BOM管理')),
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
    final productName = item['product']?['name'] ?? item['product_name'] ?? '未知产品';
    final materialName = item['material']?['name'] ?? item['material_name'] ?? '未知原料';
    final quantity = safeToDouble(item['quantity']);
    final unit = item['unit'] ?? item['material']?['unit'] ?? '';

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
            child: const Icon(Icons.account_tree_outlined, color: AppTheme.warningColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(productName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('原料: $materialName', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(width: 12),
                    Text('用量: ${quantity.toStringAsFixed(0)}${unit.isNotEmpty ? unit : ''}', style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
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

  Future<List<Map<String, dynamic>>> _loadOptions(String endpoint) async {
    try {
      final result = await _api.get(endpoint);
      final data = result['data'];
      if (data is List) return data.cast<Map<String, dynamic>>();
      return [];
    } catch (_) { return []; }
  }

  Future<Map<String, dynamic>?> _showPicker({
    required String title,
    required Future<List<Map<String, dynamic>>> Function() loader,
    String searchHint = '搜索',
    String Function(Map<String, dynamic>)? subtitleBuilder,
  }) async {
    final items = await loader();
    if (!mounted) return null;

    String search = '';
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheetState) {
        final filtered = search.isEmpty
            ? items
            : items.where((i) => (i['name'] ?? '').toString().toLowerCase().contains(search.toLowerCase())).toList();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: searchHint,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: (v) => setSheetState(() => search = v),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: filtered.isEmpty
                  ? const Padding(padding: EdgeInsets.all(32), child: Text('未找到数据', style: TextStyle(color: AppTheme.textHint)))
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return ListTile(
                          title: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: subtitleBuilder != null ? Text(subtitleBuilder(item), style: const TextStyle(fontSize: 12, color: AppTheme.textHint)) : null,
                          trailing: const Icon(Icons.chevron_right, color: AppTheme.textHint),
                          onTap: () => Navigator.pop(ctx, item),
                        );
                      },
                    ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        );
      }),
    );
  }

  void _showFormDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    final quantityCtrl = TextEditingController(text: item?['quantity']?.toString() ?? '');
    final unitCtrl = TextEditingController(text: item?['unit']?.toString() ?? '');
    int? selectedProductId = item?['product_id'];
    String selectedProductName = item?['product']?['name'] ?? item?['product_name'] ?? '';
    int? selectedMaterialId = item?['material_id'];
    String selectedMaterialName = item?['material']?['name'] ?? item?['material_name'] ?? '';
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEdit ? '编辑BOM' : '新增BOM'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picked = await _showPicker(
                      title: '选择产品',
                      loader: () => _loadOptions(ApiConfig.products),
                      searchHint: '搜索产品名称',
                    );
                    if (picked != null) {
                      setDialogState(() {
                        selectedProductId = picked['id'];
                        selectedProductName = picked['name'] ?? '';
                      });
                    }
                  },
                  child: AbsorbPointer(
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: '产品 *',
                        prefixIcon: const Icon(Icons.inventory_2_outlined),
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                        errorText: selectedProductId == null ? '请选择产品' : null,
                      ),
                      child: Text(
                        selectedProductName.isNotEmpty ? selectedProductName : '点击选择产品',
                        style: TextStyle(fontSize: 16, color: selectedProductName.isNotEmpty ? AppTheme.textPrimary : AppTheme.textHint),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await _showPicker(
                      title: '选择原料',
                      loader: () => _loadOptions(ApiConfig.materials),
                      searchHint: '搜索原料名称',
                    );
                    if (picked != null) {
                      setDialogState(() {
                        selectedMaterialId = picked['id'];
                        selectedMaterialName = picked['name'] ?? '';
                        if (picked['unit'] != null && unitCtrl.text.isEmpty) {
                          unitCtrl.text = picked['unit'].toString();
                        }
                      });
                    }
                  },
                  child: AbsorbPointer(
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: '原料 *',
                        prefixIcon: const Icon(Icons.category_outlined),
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                        errorText: selectedMaterialId == null ? '请选择原料' : null,
                      ),
                      child: Text(
                        selectedMaterialName.isNotEmpty ? selectedMaterialName : '点击选择原料',
                        style: TextStyle(fontSize: 16, color: selectedMaterialName.isNotEmpty ? AppTheme.textPrimary : AppTheme.textHint),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: quantityCtrl,
                  decoration: const InputDecoration(labelText: '用量 *', prefixIcon: Icon(Icons.format_list_numbered)),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: unitCtrl,
                  decoration: const InputDecoration(labelText: '单位', prefixIcon: Icon(Icons.straighten)),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: isSubmitting ? null : () async {
              if (selectedProductId == null || selectedMaterialId == null || quantityCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择产品和原料，填写用量'), backgroundColor: AppTheme.dangerColor));
                return;
              }
              setDialogState(() => isSubmitting = true);
              try {
                final data = {
                  'product_id': selectedProductId,
                  'material_id': selectedMaterialId,
                  'quantity': double.tryParse(quantityCtrl.text.trim()) ?? 0,
                  'unit': unitCtrl.text.trim().isEmpty ? null : unitCtrl.text.trim(),
                };
                if (isEdit) {
                  await _api.put('${ApiConfig.bomItems}/${item!['id']}', data: data);
                } else {
                  await _api.post(ApiConfig.bomItems, data: data);
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

  void _showDeleteConfirm(Map<String, dynamic> item) {
    final productName = item['product']?['name'] ?? item['product_name'] ?? '未知产品';
    final materialName = item['material']?['name'] ?? item['material_name'] ?? '未知原料';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('确认删除'),
        content: Text('确认删除BOM记录（$productName - $materialName）？此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _api.delete('${ApiConfig.bomItems}/${item['id']}');
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
        const Icon(Icons.account_tree_outlined, size: 48, color: AppTheme.textHint),
        const SizedBox(height: 8),
        const Text('暂无BOM数据', style: TextStyle(color: AppTheme.textHint)),
        const SizedBox(height: 8),
        Text('点击右下角按钮新增BOM', style: TextStyle(color: AppTheme.textHint.withOpacity(0.7), fontSize: 13)),
      ],
    ));
  }
}
