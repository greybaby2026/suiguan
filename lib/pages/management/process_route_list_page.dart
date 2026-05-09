import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../widgets/error_state_widget.dart';

class ProcessRouteListPage extends StatefulWidget {
  const ProcessRouteListPage({super.key});

  @override
  State<ProcessRouteListPage> createState() => _ProcessRouteListPageState();
}

class _ProcessRouteListPageState extends State<ProcessRouteListPage> {
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
      final response = await _api.get(ApiConfig.processRoutes);
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
      appBar: AppBar(title: const Text('工艺路线')),
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
    final productName = item['product']?['name'] ?? item['product_name'] ?? '';
    final steps = item['steps'] ?? item['process_route_steps'] ?? [];
    final stepList = steps is List ? steps : [];
    final stepCount = stepList.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.cardDecoration,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetailDialog(item),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.route_outlined, color: Color(0xFF8B5CF6), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (productName.isNotEmpty) ...[
                              Text('产品: $productName', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              const SizedBox(width: 12),
                            ],
                            Text('$stepCount个工序步骤', style: const TextStyle(fontSize: 12, color: AppTheme.infoColor, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (action) => _handleAction(action, item),
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'detail', child: Row(children: [Icon(Icons.visibility_outlined, size: 18, color: AppTheme.primaryColor), SizedBox(width: 8), Text('查看步骤')])),
                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryColor), SizedBox(width: 8), Text('编辑')])),
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerColor), SizedBox(width: 8), Text('删除', style: TextStyle(color: AppTheme.dangerColor))])),
                    ],
                  ),
                ],
              ),
              if (stepList.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppTheme.border),
                const SizedBox(height: 10),
                _buildStepPreview(stepList),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepPreview(List stepList) {
    final displaySteps = stepList.take(3).toList();
    final hasMore = stepList.length > 3;

    return Column(
      children: [
        for (int i = 0; i < displaySteps.length; i++)
          _buildStepRow(displaySteps[i], i, isLast: i == displaySteps.length - 1 && !hasMore),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.only(left: 21),
            child: Text(
              '... 还有 ${stepList.length - 3} 个步骤',
              style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
            ),
          ),
      ],
    );
  }

  Widget _buildStepRow(dynamic stepData, int index, {bool isLast = false}) {
    final step = stepData is Map<String, dynamic> ? stepData : <String, dynamic>{};
    final processName = step['process']?['name'] ?? step['process_name'] ?? '工序${index + 1}';
    final processCode = step['process']?['code'] ?? step['process_code'] ?? '';
    final stepOrder = step['step_order'] ?? (index + 1);
    final estimatedTime = step['estimated_time'];
    final isKey = step['process']?['is_key'] ?? false;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: isKey ? AppTheme.warningColor.withOpacity(0.2) : AppTheme.primaryColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('$stepOrder', style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: isKey ? AppTheme.warningColor : AppTheme.primaryColor,
                    )),
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: AppTheme.primaryColor.withOpacity(0.2))),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      processCode.isNotEmpty ? '$processCode - $processName' : processName,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                    ),
                  ),
                  if (isKey)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('关键', style: TextStyle(fontSize: 10, color: AppTheme.warningColor, fontWeight: FontWeight.w600)),
                    ),
                  if (estimatedTime != null) ...[
                    const SizedBox(width: 6),
                    Text('${estimatedTime}min', style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(Map<String, dynamic> item) {
    final name = item['name'] ?? '未知';
    final productName = item['product']?['name'] ?? item['product_name'] ?? '';
    final steps = item['steps'] ?? item['process_route_steps'] ?? [];
    final stepList = steps is List ? steps : [];

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7, maxWidth: MediaQuery.of(context).size.width * 0.9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                          if (productName.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('产品: $productName', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                          ],
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (stepList.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, size: 40, color: AppTheme.textHint),
                      SizedBox(height: 8),
                      Text('暂无工序步骤', style: TextStyle(color: AppTheme.textHint)),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: stepList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) => _buildStepRow(stepList[index], index, isLast: index == stepList.length - 1),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showFormDialog(item: item);
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('编辑'),
                        style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primaryColor, side: const BorderSide(color: AppTheme.primaryColor)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAction(String action, Map<String, dynamic> item) {
    switch (action) {
      case 'detail': _showDetailDialog(item); break;
      case 'edit': _showFormDialog(item: item); break;
      case 'delete': _showDeleteConfirm(item); break;
    }
  }

  void _showFormDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    final nameCtrl = TextEditingController(text: item?['name']?.toString() ?? '');
    final descCtrl = TextEditingController(text: item?['description']?.toString() ?? '');
    int? selectedProductId = item?['product_id'];
    String selectedProductName = item?['product']?['name'] ?? '';
    List<Map<String, dynamic>> steps = [];
    bool isSubmitting = false;

    if (isEdit) {
      final existingSteps = item?['steps'] ?? item?['process_route_steps'] ?? [];
      if (existingSteps is List) {
        for (final s in existingSteps) {
          if (s is Map<String, dynamic>) {
            steps.add(Map<String, dynamic>.from(s));
          }
        }
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEdit ? '编辑工艺路线' : '新增工艺路线'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: '路线名称 *', prefixIcon: Icon(Icons.route_outlined)),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final result = await _showProductPicker();
                    if (result != null) {
                      setDialogState(() {
                        selectedProductId = result['id'] as int?;
                        selectedProductName = result['name']?.toString() ?? '';
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: '产品 *',
                      prefixIcon: const Icon(Icons.inventory_2_outlined),
                      suffixIcon: const Icon(Icons.arrow_forward_ios, size: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      selectedProductName.isNotEmpty ? selectedProductName : '请选择产品',
                      style: TextStyle(
                        fontSize: 16,
                        color: selectedProductName.isNotEmpty ? AppTheme.textPrimary : AppTheme.textHint,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: '描述', prefixIcon: Icon(Icons.description_outlined)),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('工序步骤 (${steps.length})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    IconButton(
                      onPressed: () async {
                        final step = await _showStepAddDialog(steps.length + 1);
                        if (step != null) {
                          setDialogState(() => steps.add(step));
                        }
                      },
                      icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
                      tooltip: '添加步骤',
                    ),
                  ],
                ),
                if (steps.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppTheme.bgPrimary, borderRadius: BorderRadius.circular(8)),
                    child: const Text('请添加至少一个工序步骤', style: TextStyle(color: AppTheme.textHint, fontSize: 13)),
                  )
                else
                  ...steps.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final s = entry.value;
                    final pName = s['process']?['name'] ?? s['process_name'] ?? '工序';
                    final pCode = s['process']?['code'] ?? s['process_code'] ?? '';
                    return Dismissible(
                      key: ValueKey('step_$idx'),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => setDialogState(() => steps.removeAt(idx)),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        color: AppTheme.dangerColor,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                          child: Text('${s['step_order'] ?? idx + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
                        ),
                        title: Text(pCode.isNotEmpty ? '$pCode - $pName' : pName, style: const TextStyle(fontSize: 13)),
                        subtitle: s['estimated_time'] != null ? Text('预计 ${s['estimated_time']} 分钟', style: const TextStyle(fontSize: 11, color: AppTheme.textHint)) : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () async {
                            final updated = await _showStepAddDialog(idx + 1, existing: s);
                            if (updated != null) {
                              setDialogState(() => steps[idx] = updated);
                            }
                          },
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: isSubmitting ? null : () async {
              if (nameCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('路线名称不能为空'), backgroundColor: AppTheme.dangerColor));
                return;
              }
              if (selectedProductId == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择产品'), backgroundColor: AppTheme.dangerColor));
                return;
              }
              if (steps.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请至少添加一个工序步骤'), backgroundColor: AppTheme.dangerColor));
                return;
              }
              setDialogState(() => isSubmitting = true);
              try {
                final data = <String, dynamic>{
                  'name': nameCtrl.text.trim(),
                  'product_id': selectedProductId,
                  'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                  'steps': steps.map((s) => {
                    'process_id': s['process_id'] ?? s['process']?['id'],
                    'step_order': s['step_order'] ?? steps.indexOf(s) + 1,
                    'estimated_time': s['estimated_time'],
                    'remark': s['remark'],
                  }).toList(),
                };
                if (isEdit) {
                  await _api.put('${ApiConfig.processRoutes}/${item?['id']}', data: data);
                } else {
                  await _api.post(ApiConfig.processRoutes, data: data);
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

  Future<Map<String, dynamic>?> _showProductPicker() async {
    try {
      final response = await _api.get(ApiConfig.products);
      final data = response['data'] ?? response;
      List<dynamic> list;
      if (data is List) { list = data; }
      else if (data is Map && data.containsKey('data')) { list = data['data'] as List; }
      else { list = []; }

      if (!mounted) return null;

      return showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('选择产品', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: list.isEmpty
                  ? const Padding(padding: EdgeInsets.all(32), child: Text('暂无产品数据', style: TextStyle(color: AppTheme.textHint)))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: list.length,
                      itemBuilder: (ctx, index) {
                        final p = list[index] as Map<String, dynamic>;
                        return ListTile(
                          leading: const Icon(Icons.inventory_2_outlined, color: AppTheme.primaryColor),
                          title: Text(p['name']?.toString() ?? ''),
                          subtitle: p['code'] != null ? Text(p['code'].toString(), style: const TextStyle(fontSize: 12, color: AppTheme.textHint)) : null,
                          onTap: () => Navigator.pop(ctx, p),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('加载产品失败: $e'), backgroundColor: AppTheme.dangerColor));
      return null;
    }
  }

  Future<Map<String, dynamic>?> _showStepAddDialog(int stepOrder, {Map<String, dynamic>? existing}) async {
    int? selectedProcessId = existing?['process_id'] ?? existing?['process']?['id'];
    String selectedProcessName = existing?['process']?['name'] ?? existing?['process_name'] ?? '';
    final estTimeCtrl = TextEditingController(text: existing?['estimated_time']?.toString() ?? '');
    final remarkCtrl = TextEditingController(text: existing?['remark']?.toString() ?? '');

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('步骤 $stepOrder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () async {
                final result = await _showProcessPicker();
                if (result != null) {
                  setDialogState(() {
                    selectedProcessId = result['id'] as int?;
                    selectedProcessName = result['name']?.toString() ?? '';
                  });
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: '工序 *',
                  prefixIcon: const Icon(Icons.precision_manufacturing_outlined),
                  suffixIcon: const Icon(Icons.arrow_forward_ios, size: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  selectedProcessName.isNotEmpty ? selectedProcessName : '请选择工序',
                  style: TextStyle(fontSize: 16, color: selectedProcessName.isNotEmpty ? AppTheme.textPrimary : AppTheme.textHint),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: estTimeCtrl,
              decoration: const InputDecoration(labelText: '预计用时(分钟)', prefixIcon: Icon(Icons.timer_outlined)),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: remarkCtrl,
              decoration: const InputDecoration(labelText: '备注', prefixIcon: Icon(Icons.note_outlined)),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              if (selectedProcessId == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择工序'), backgroundColor: AppTheme.dangerColor));
                return;
              }
              Navigator.pop(ctx, <String, dynamic>{
                'process_id': selectedProcessId,
                'step_order': stepOrder,
                'estimated_time': estTimeCtrl.text.trim().isNotEmpty ? int.tryParse(estTimeCtrl.text.trim()) : null,
                'remark': remarkCtrl.text.trim().isEmpty ? null : remarkCtrl.text.trim(),
                'process': <String, dynamic>{
                  'id': selectedProcessId,
                  'name': selectedProcessName,
                },
                'process_name': selectedProcessName,
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('确定'),
          ),
        ],
      )),
    );
  }

  Future<Map<String, dynamic>?> _showProcessPicker() async {
    try {
      final response = await _api.get(ApiConfig.processes);
      final data = response['data'] ?? response;
      List<dynamic> list;
      if (data is List) { list = data; }
      else if (data is Map && data.containsKey('data')) { list = data['data'] as List; }
      else { list = []; }

      if (!mounted) return null;

      return showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('选择工序', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: list.isEmpty
                  ? const Padding(padding: EdgeInsets.all(32), child: Text('暂无工序数据', style: TextStyle(color: AppTheme.textHint)))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: list.length,
                      itemBuilder: (ctx, index) {
                        final p = list[index] as Map<String, dynamic>;
                        final isKey = p['is_key'] == true;
                        return ListTile(
                          leading: Icon(
                            isKey ? Icons.star_outlined : Icons.precision_manufacturing_outlined,
                            color: isKey ? AppTheme.warningColor : AppTheme.primaryColor,
                          ),
                          title: Text(p['name']?.toString() ?? ''),
                          subtitle: p['code'] != null ? Text(p['code'].toString(), style: const TextStyle(fontSize: 12, color: AppTheme.textHint)) : null,
                          trailing: isKey ? const Text('关键工序', style: TextStyle(fontSize: 11, color: AppTheme.warningColor)) : null,
                          onTap: () => Navigator.pop(ctx, p),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('加载工序失败: $e'), backgroundColor: AppTheme.dangerColor));
      return null;
    }
  }

  void _showDeleteConfirm(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('确认删除'),
        content: Text('确认删除工艺路线 ${item['name'] ?? ''}？此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _api.delete('${ApiConfig.processRoutes}/${item['id']}');
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
        const Icon(Icons.route_outlined, size: 48, color: AppTheme.textHint),
        const SizedBox(height: 8),
        const Text('暂无工艺路线数据', style: TextStyle(color: AppTheme.textHint)),
        const SizedBox(height: 8),
        Text('点击右下角按钮新增工艺路线', style: TextStyle(color: AppTheme.textHint.withOpacity(0.7), fontSize: 13)),
      ],
    ));
  }
}
