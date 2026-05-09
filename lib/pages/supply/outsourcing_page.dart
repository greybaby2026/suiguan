import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../widgets/error_state_widget.dart';

class OutsourcingPage extends StatefulWidget {
  const OutsourcingPage({super.key});

  @override
  State<OutsourcingPage> createState() => _OutsourcingPageState();
}

class _OutsourcingPageState extends State<OutsourcingPage> {
  String _filterStatus = 'all';
  bool _isLoading = false;
  dynamic _error;
  List<Map<String, dynamic>> _orders = [];

  static const List<Map<String, String>> _statusTabs = [
    {'label': '全部', 'value': 'all'},
    {'label': '待发料', 'value': 'pending_send'},
    {'label': '已发料', 'value': 'sent'},
    {'label': '部分回收', 'value': 'partial_received'},
    {'label': '已回收', 'value': 'received'},
    {'label': '已结算', 'value': 'settled'},
    {'label': '已取消', 'value': 'cancelled'},
  ];

  static const Map<String, Color> _statusColors = {
    'pending_send': AppTheme.warningColor,
    'sent': AppTheme.primaryColor,
    'partial_received': AppTheme.infoColor,
    'received': AppTheme.successColor,
    'settled': Color(0xFF8B5CF6),
    'cancelled': AppTheme.textHint,
  };

  static const Map<String, String> _statusLabels = {
    'pending_send': '待发料',
    'sent': '已发料',
    'partial_received': '部分回收',
    'received': '已回收',
    'settled': '已结算',
    'cancelled': '已取消',
  };

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final params = <String, dynamic>{};
      if (_filterStatus != 'all') params['status'] = _filterStatus;
      final result = await ApiService.instance.get(
        ApiConfig.outsourcingOrders,
        queryParameters: params.isNotEmpty ? params : null,
      );
      final data = result['data'];
      final list = data is List ? data : (data?['list'] ?? data?['data'] ?? []);
      setState(() {
        _orders = list.cast<Map<String, dynamic>>();
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showOrderFormDialog({Map<String, dynamic>? order}) {
    final isEdit = order != null;
    int? selectedProcessId = order?['process_id'];
    String selectedProcessName = order?['process']?['name'] ?? '';
    final quantityCtrl = TextEditingController(text: order?['quantity']?.toString() ?? '');
    final unitPriceCtrl = TextEditingController(text: order?['unit_price']?.toString() ?? '');
    final expectedDateCtrl = TextEditingController(text: order?['expected_date']?.toString() ?? '');
    final remarkCtrl = TextEditingController(text: order?['remark']?.toString() ?? '');
    int? selectedPartnerId = order?['partner_id'];
    String selectedPartnerName = order?['partner']?['name'] ?? '';
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEdit ? '编辑外协订单' : '新增外协订单'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    try {
                      final result = await ApiService.instance.get(ApiConfig.outsourcingPartners);
                      final data = result['data'];
                      final partners = (data is List ? data : (data?['list'] ?? data?['data'] ?? []))
                          .cast<Map<String, dynamic>>();
                      if (!ctx.mounted) return;
                      final picked = await showModalBottomSheet<Map<String, dynamic>>(
                        context: context,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                        builder: (sheetCtx) {
                          String search = '';
                          return StatefulBuilder(builder: (sheetCtx, setSheetState) {
                            final filtered = search.isEmpty ? partners : partners.where((p) => (p['name'] ?? '').toString().toLowerCase().contains(search.toLowerCase())).toList();
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('选择接纳单位', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)), IconButton(onPressed: () => Navigator.pop(sheetCtx), icon: const Icon(Icons.close))])),
                                Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: TextField(decoration: InputDecoration(hintText: '搜索单位名称', prefixIcon: const Icon(Icons.search, size: 20), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), onChanged: (v) => setSheetState(() => search = v))),
                                const Divider(height: 1),
                                Flexible(child: ListView.separated(shrinkWrap: true, itemCount: filtered.length, separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16), itemBuilder: (_, i) => ListTile(title: Text(filtered[i]['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text(filtered[i]['contact_person'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textHint)), trailing: const Icon(Icons.chevron_right, color: AppTheme.textHint), onTap: () => Navigator.pop(sheetCtx, filtered[i])))),
                                SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
                              ],
                            );
                          });
                        },
                      );
                      if (picked != null) {
                        setDialogState(() { selectedPartnerId = picked['id']; selectedPartnerName = picked['name'] ?? ''; });
                      }
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('加载接纳单位列表失败: $e'), backgroundColor: AppTheme.dangerColor));
                    }
                  },
                  child: AbsorbPointer(
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: '接纳单位 *',
                        prefixIcon: const Icon(Icons.business_outlined),
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                        errorText: selectedPartnerId == null ? '请选择接纳单位' : null,
                      ),
                      child: Text(selectedPartnerName.isNotEmpty ? selectedPartnerName : '点击选择接纳单位', style: TextStyle(fontSize: 16, color: selectedPartnerName.isNotEmpty ? AppTheme.textPrimary : AppTheme.textHint)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    try {
                      final result = await ApiService.instance.get(ApiConfig.processes);
                      final data = result['data'];
                      final processes = (data is List ? data : (data?['list'] ?? data?['data'] ?? []))
                          .cast<Map<String, dynamic>>();
                      if (!ctx.mounted) return;
                      final picked = await showModalBottomSheet<Map<String, dynamic>>(
                        context: context,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                        builder: (sheetCtx) {
                          String search = '';
                          return StatefulBuilder(builder: (sheetCtx, setSheetState) {
                            final filtered = search.isEmpty ? processes : processes.where((p) => (p['name'] ?? '').toString().toLowerCase().contains(search.toLowerCase())).toList();
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('选择工序', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)), IconButton(onPressed: () => Navigator.pop(sheetCtx), icon: const Icon(Icons.close))])),
                                Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: TextField(decoration: InputDecoration(hintText: '搜索工序名称', prefixIcon: const Icon(Icons.search, size: 20), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), onChanged: (v) => setSheetState(() => search = v))),
                                const Divider(height: 1),
                                Flexible(child: ListView.separated(shrinkWrap: true, itemCount: filtered.length, separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16), itemBuilder: (_, i) => ListTile(title: Text(filtered[i]['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text(filtered[i]['code'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textHint)), trailing: const Icon(Icons.chevron_right, color: AppTheme.textHint), onTap: () => Navigator.pop(sheetCtx, filtered[i])))),
                                SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
                              ],
                            );
                          });
                        },
                      );
                      if (picked != null) {
                        setDialogState(() { selectedProcessId = picked['id']; selectedProcessName = picked['name'] ?? ''; });
                      }
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('加载工序列表失败: $e'), backgroundColor: AppTheme.dangerColor));
                    }
                  },
                  child: AbsorbPointer(
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: '工序 *',
                        prefixIcon: const Icon(Icons.precision_manufacturing_outlined),
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                        errorText: selectedProcessId == null ? '请选择工序' : null,
                      ),
                      child: Text(selectedProcessName.isNotEmpty ? selectedProcessName : '点击选择工序', style: TextStyle(fontSize: 16, color: selectedProcessName.isNotEmpty ? AppTheme.textPrimary : AppTheme.textHint)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: quantityCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '数量 *', prefixIcon: Icon(Icons.format_list_numbered)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: unitPriceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '单价', prefixIcon: Icon(Icons.attach_money)),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      expectedDateCtrl.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                    }
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      controller: expectedDateCtrl,
                      decoration: const InputDecoration(labelText: '预计完成日期', prefixIcon: Icon(Icons.calendar_today_outlined)),
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
              if (selectedPartnerId == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择接纳单位'), backgroundColor: AppTheme.dangerColor));
                return;
              }
              if (selectedProcessId == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择工序'), backgroundColor: AppTheme.dangerColor));
                return;
              }
              if (quantityCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('数量不能为空'), backgroundColor: AppTheme.dangerColor));
                return;
              }
              final quantity = double.tryParse(quantityCtrl.text.trim()) ?? 0;
              if (quantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('数量必须大于 0'), backgroundColor: AppTheme.dangerColor));
                return;
              }
              setDialogState(() => isSubmitting = true);
              try {
                final data = <String, dynamic>{
                  'partner_id': selectedPartnerId,
                  'process_id': selectedProcessId,
                  'quantity': quantity,
                };
                if (unitPriceCtrl.text.trim().isNotEmpty) {
                  data['unit_price'] = double.tryParse(unitPriceCtrl.text.trim()) ?? 0;
                }
                if (expectedDateCtrl.text.trim().isNotEmpty) {
                  data['expected_date'] = expectedDateCtrl.text.trim();
                }
                if (remarkCtrl.text.trim().isNotEmpty) {
                  data['remark'] = remarkCtrl.text.trim();
                }
                if (isEdit) {
                  await ApiService.instance.put('${ApiConfig.outsourcingOrders}/${order!['id']}', data: data);
                } else {
                  await ApiService.instance.post(ApiConfig.outsourcingOrders, data: data);
                }
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? '已更新' : '已创建'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating));
                  _loadOrders();
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

  void _showDeleteConfirm(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('确认删除'),
        content: Text('确认删除外协订单 ${order['order_no'] ?? ''}？此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService.instance.delete('${ApiConfig.outsourcingOrders}/${order['id']}');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已删除'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating));
                  _loadOrders();
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
      appBar: AppBar(title: const Text('外协订单')),
      body: Column(
        children: [
          _buildStatusTabs(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : _error != null
                    ? ErrorStateWidget(error: _error, onRetry: _loadOrders)
                    : _orders.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        color: AppTheme.primaryColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: _orders.length,
                          itemBuilder: (context, index) {
                            return _OutsourcingOrderCard(
                              order: _orders[index],
                              onEdit: _orders[index]['status'] == 'pending'
                                  ? () => _showOrderFormDialog(order: _orders[index])
                                  : null,
                              onDelete: _orders[index]['status'] == 'pending'
                                  ? () => _showDeleteConfirm(_orders[index])
                                  : null,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showOrderFormDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatusTabs() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statusTabs.map((tab) {
            final isActive = _filterStatus == tab['value'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() => _filterStatus = tab['value']!);
                  _loadOrders();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.primaryColor : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tab['label']!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isActive ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.handshake_outlined, size: 48, color: AppTheme.textHint),
          const SizedBox(height: 8),
          const Text('暂无外协订单', style: TextStyle(color: AppTheme.textHint)),
        ],
      ),
    );
  }

}

class _OutsourcingOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _OutsourcingOrderCard({
    required this.order,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final status = order['status'] ?? 'pending';
    final statusColor = _OutsourcingPageState._statusColors[status] ?? AppTheme.textHint;
    final statusLabel = _OutsourcingPageState._statusLabels[status] ?? '未知';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                order['order_no'] ?? '',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onEdit != null || onDelete != null) ...[
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  onSelected: (action) {
                    if (action == 'edit' && onEdit != null) onEdit!();
                    if (action == 'delete' && onDelete != null) onDelete!();
                  },
                  itemBuilder: (ctx) => [
                    if (onEdit != null)
                      PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryColor), const SizedBox(width: 8), const Text('编辑')])),
                    if (onDelete != null)
                      PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerColor), const SizedBox(width: 8), const Text('删除', style: TextStyle(color: AppTheme.dangerColor))])),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.factory_outlined, size: 16, color: AppTheme.textHint),
              const SizedBox(width: 4),
              Text(
                order['factory_name'] ?? order['partner']?['name'] ?? '',
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 16, color: AppTheme.textHint),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  order['product_name'] ?? order['process_name'] ?? '',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ),
              Text(
                'x${order['quantity'] ?? 0}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
