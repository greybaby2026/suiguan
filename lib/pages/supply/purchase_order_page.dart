import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../utils/number_utils.dart';
import '../../widgets/error_state_widget.dart';

class PurchaseOrderPage extends StatefulWidget {
  const PurchaseOrderPage({super.key});

  @override
  State<PurchaseOrderPage> createState() => _PurchaseOrderPageState();
}

class _PurchaseOrderPageState extends State<PurchaseOrderPage> {
  final _searchController = TextEditingController();
  String _filterStatus = 'all';
  bool _isLoading = false;
  dynamic _error;
  List<Map<String, dynamic>> _orders = [];

  static const List<Map<String, String>> _statusTabs = [
    {'label': '全部', 'value': 'all'},
    {'label': '待审批', 'value': 'pending'},
    {'label': '已审批', 'value': 'approved'},
    {'label': '部分入库', 'value': 'partial_received'},
    {'label': '已入库', 'value': 'received'},
    {'label': '已完成', 'value': 'completed'},
    {'label': '已取消', 'value': 'cancelled'},
  ];

  static const Map<String, Color> _statusColors = {
    'pending': AppTheme.warningColor,
    'approved': AppTheme.primaryColor,
    'partial_received': AppTheme.infoColor,
    'received': AppTheme.successColor,
    'completed': Color(0xFF8B5CF6),
    'cancelled': AppTheme.textHint,
  };

  static const Map<String, String> _statusLabels = {
    'pending': '待审批',
    'approved': '已审批',
    'partial_received': '部分入库',
    'received': '已入库',
    'completed': '已完成',
    'cancelled': '已取消',
  };

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final params = <String, dynamic>{};
      if (_filterStatus != 'all') params['status'] = _filterStatus;
      if (_searchController.text.trim().isNotEmpty) {
        params['keyword'] = _searchController.text.trim();
      }
      final result = await ApiService.instance.get(
        ApiConfig.purchaseOrders,
        queryParameters: params.isNotEmpty ? params : null,
      );
      final data = result['data'];
      List<dynamic> list;
      if (data is List) { list = data; }
      else if (data is Map && data.containsKey('data')) { list = data['data'] as List; }
      else if (data is Map && data.containsKey('list')) { list = data['list'] as List; }
      else { list = []; }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('采购订单')),
      body: Column(
        children: [
          _buildStatusTabs(),
          _buildSearchBar(),
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
                            return _OrderCard(
                              order: _orders[index],
                              onApprove: () => _handleApprove(_orders[index]),
                              onEdit: () => _showPurchaseOrderFormDialog(order: _orders[index]),
                              onDelete: () => _showDeleteConfirm(_orders[index]),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPurchaseOrderFormDialog(),
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索订单号或供应商',
          prefixIcon: const Icon(Icons.search, size: 22),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear, size: 20),
            onPressed: () {
              _searchController.clear();
              _loadOrders();
            },
          ),
        ),
        onSubmitted: (_) => _loadOrders(),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 48, color: AppTheme.textHint),
          const SizedBox(height: 8),
          const Text('暂无采购订单', style: TextStyle(color: AppTheme.textHint)),
        ],
      ),
    );
  }

  void _showPurchaseOrderFormDialog({Map<String, dynamic>? order}) {
    final isEdit = order != null;

    if (isEdit) {
      _showEditForm(order);
    } else {
      _showCreateForm();
    }
  }

  void _showEditForm(Map<String, dynamic> order) {
    final remarkCtrl = TextEditingController(text: order['remark'] ?? '');
    DateTime orderDate = order['order_date'] != null
        ? DateTime.tryParse(order['order_date']) ?? DateTime.now()
        : DateTime.now();
    DateTime? expectedDate = order['expected_date'] != null
        ? DateTime.tryParse(order['expected_date'])
        : null;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('编辑采购单'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: orderDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setDialogState(() => orderDate = picked);
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      controller: TextEditingController(
                        text: _fmtDate(orderDate),
                      ),
                      decoration: const InputDecoration(
                        labelText: '采购日期 *',
                        prefixIcon: Icon(Icons.event_outlined),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: expectedDate ?? orderDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setDialogState(() => expectedDate = picked);
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      controller: TextEditingController(
                        text: expectedDate != null ? _fmtDate(expectedDate!) : '',
                      ),
                      decoration: const InputDecoration(
                        labelText: '预计到货日期',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: remarkCtrl,
                  decoration: const InputDecoration(labelText: '备注', prefixIcon: Icon(Icons.note_outlined)),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: isSubmitting ? null : () async {
              setDialogState(() => isSubmitting = true);
              try {
                final data = <String, dynamic>{
                  'order_date': _fmtDate(orderDate),
                };
                if (expectedDate != null) data['expected_date'] = _fmtDate(expectedDate!);
                if (remarkCtrl.text.trim().isNotEmpty) data['remark'] = remarkCtrl.text.trim();
                await ApiService.instance.put('${ApiConfig.purchaseOrders}/${order['id']}', data: data);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('已更新'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating,
                  ));
                  _loadOrders();
                }
              } catch (e) {
                setDialogState(() => isSubmitting = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('操作失败: $e'), backgroundColor: AppTheme.dangerColor, behavior: SnackBarBehavior.floating,
                  ));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: isSubmitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('保存'),
          ),
        ],
      )),
    );
  }

  void _showCreateForm() {
    final remarkCtrl = TextEditingController();
    DateTime orderDate = DateTime.now();
    DateTime? expectedDate;
    int? selectedSupplierId;
    String selectedSupplierName = '';
    bool isSubmitting = false;
    List<Map<String, dynamic>> suppliers = [];
    bool suppliersLoading = true;
    List<Map<String, dynamic>> allMaterials = [];
    bool materialsLoading = true;
    final List<Map<String, dynamic>> items = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        if (suppliersLoading) {
          _fetchList(ApiConfig.suppliers).then((list) {
            suppliers = list;
            suppliersLoading = false;
            (ctx as StatefulElement).markNeedsBuild();
          });
        }
        if (materialsLoading) {
          _fetchList(ApiConfig.materials).then((list) {
            allMaterials = list;
            materialsLoading = false;
            (ctx as StatefulElement).markNeedsBuild();
          });
        }

        return StatefulBuilder(builder: (ctx, setDialogState) {
          final qtyTotal = items.fold<double>(0, (sum, item) {
            final q = double.tryParse((item['quantityCtrl'] as TextEditingController).text) ?? 0;
            final p = double.tryParse((item['unitPriceCtrl'] as TextEditingController).text) ?? 0;
            return sum + q * p;
          });

          return DraggableScrollableSheet(
            initialChildSize: 0.88,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (ctx, scrollCtrl) => Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('新增采购单', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    children: [
                      GestureDetector(
                        onTap: suppliersLoading ? null : () async {
                           final picked = await _openPicker(ctx, '选择供应商', suppliers);
                           if (picked != null) {
                             setDialogState(() {
                               selectedSupplierId = picked['id'];
                               selectedSupplierName = picked['name'] ?? '';
                             });
                           }
                         },
                        child: AbsorbPointer(
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: '供应商 *',
                              prefixIcon: const Icon(Icons.business_outlined),
                              suffixIcon: suppliersLoading
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.arrow_drop_down),
                              errorText: selectedSupplierId == null && !suppliersLoading ? '请选择供应商' : null,
                            ),
                            child: Text(
                              selectedSupplierName.isNotEmpty ? selectedSupplierName : (suppliersLoading ? '加载中...' : '点击选择供应商'),
                              style: TextStyle(fontSize: 16, color: selectedSupplierName.isNotEmpty ? AppTheme.textPrimary : AppTheme.textHint),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: orderDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setDialogState(() => orderDate = picked);
                        },
                        child: AbsorbPointer(
                          child: TextField(
                            controller: TextEditingController(text: _fmtDate(orderDate)),
                            decoration: const InputDecoration(labelText: '采购日期 *', prefixIcon: Icon(Icons.event_outlined)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: expectedDate ?? orderDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setDialogState(() => expectedDate = picked);
                        },
                        child: AbsorbPointer(
                          child: TextField(
                            controller: TextEditingController(text: expectedDate != null ? _fmtDate(expectedDate!) : ''),
                            decoration: const InputDecoration(labelText: '预计到货日期', prefixIcon: Icon(Icons.calendar_today_outlined)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: remarkCtrl,
                        decoration: const InputDecoration(labelText: '备注', prefixIcon: Icon(Icons.note_outlined)),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.list_alt_outlined, size: 18, color: AppTheme.textSecondary),
                          const SizedBox(width: 6),
                          const Text('采购明细', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          if (qtyTotal > 0) ...[
                            Text('合计: ¥${qtyTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
                            const SizedBox(width: 8),
                          ],
                          TextButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                items.add({
                                  'material_id': null,
                                  'material_name': '',
                                  'quantityCtrl': TextEditingController(text: '1'),
                                  'unitPriceCtrl': TextEditingController(),
                                });
                              });
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('添加原料'),
                          ),
                        ],
                      ),
                      if (items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: Text('暂无采购明细，请点击"添加原料"', style: TextStyle(color: AppTheme.textHint, fontSize: 13))),
                        )
                      else
                        ...items.asMap().entries.map((entry) {
                          final i = entry.key;
                          final item = entry.value;
                          final qCtrl = item['quantityCtrl'] as TextEditingController;
                          final pCtrl = item['unitPriceCtrl'] as TextEditingController;
                          final qty = double.tryParse(qCtrl.text) ?? 0;
                          final price = double.tryParse(pCtrl.text) ?? 0;
                          final subtotal = qty * price;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: item['material_id'] == null ? AppTheme.dangerColor.withOpacity(0.3) : AppTheme.border),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: GestureDetector(
                                        onTap: materialsLoading ? null : () async {
                                           final picked = await _openPicker(ctx, '选择原料', allMaterials);
                                           if (picked != null) {
                                             setDialogState(() {
                                               item['material_id'] = picked['id'];
                                               item['material_name'] = '${picked['name'] ?? ''} ${picked['spec'] ?? ''}'.trim();
                                             });
                                           }
                                         },
                                        child: AbsorbPointer(
                                          child: InputDecorator(
                                            decoration: InputDecoration(
                                              isDense: true,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              suffixIcon: const Icon(Icons.arrow_drop_down, size: 20),
                                              errorText: item['material_id'] == null ? '请选择原料' : null,
                                            ),
                                            child: Text(
                                              (item['material_name'] as String).isNotEmpty
                                                  ? item['material_name'] as String
                                                  : '选择原料',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: (item['material_name'] as String).isNotEmpty
                                                    ? AppTheme.textPrimary
                                                    : AppTheme.textHint,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    SizedBox(
                                      width: 36,
                                      child: TextField(
                                        controller: qCtrl,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(hintText: '数量', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8)),
                                        style: const TextStyle(fontSize: 13),
                                        onChanged: (_) => setDialogState(() {}),
                                      ),
                                    ),
                                    const Text(' × ', style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
                                    SizedBox(
                                      width: 56,
                                      child: TextField(
                                        controller: pCtrl,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(hintText: '单价', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8)),
                                        style: const TextStyle(fontSize: 13),
                                        onChanged: (_) => setDialogState(() {}),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    SizedBox(
                                      width: 65,
                                      child: Text(
                                        '¥${subtotal.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryColor),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 18, color: AppTheme.dangerColor),
                                      onPressed: () {
                                        setDialogState(() {
                                          qCtrl.dispose();
                                          pCtrl.dispose();
                                          items.removeAt(i);
                                        });
                                      },
                                      visualDensity: VisualDensity.compact,
                                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isSubmitting ? null : () async {
                            if (selectedSupplierId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择供应商'), backgroundColor: AppTheme.dangerColor));
                              return;
                            }
                            final validItems = <Map<String, dynamic>>[];
                            bool hasError = false;
                            for (final item in items) {
                              if (item['material_id'] == null) { hasError = true; break; }
                              final q = double.tryParse((item['quantityCtrl'] as TextEditingController).text);
                              final p = double.tryParse((item['unitPriceCtrl'] as TextEditingController).text);
                              if (q == null || q <= 0 || p == null || p < 0) { hasError = true; break; }
                              validItems.add({
                                'material_id': item['material_id'],
                                'quantity': q,
                                'unit_price': p,
                              });
                            }
                            if (hasError) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请完善采购明细（原料/数量/单价）'), backgroundColor: AppTheme.dangerColor));
                              return;
                            }
                            setDialogState(() => isSubmitting = true);
                            try {
                              final data = <String, dynamic>{
                                'supplier_id': selectedSupplierId,
                                'order_date': _fmtDate(orderDate),
                                'items': validItems,
                              };
                              if (expectedDate != null) data['expected_date'] = _fmtDate(expectedDate!);
                              if (remarkCtrl.text.trim().isNotEmpty) data['remark'] = remarkCtrl.text.trim();
                              await ApiService.instance.post(ApiConfig.purchaseOrders, data: data);
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  content: Text('已创建'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating,
                                ));
                                _loadOrders();
                              }
                            } catch (e) {
                              setDialogState(() => isSubmitting = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('操作失败: $e'), backgroundColor: AppTheme.dangerColor, behavior: SnackBarBehavior.floating,
                                ));
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: isSubmitting
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('创建采购单', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
      },
    ).then((_) {
      for (final item in items) {
        (item['quantityCtrl'] as TextEditingController).dispose();
        (item['unitPriceCtrl'] as TextEditingController).dispose();
      }
    });
  }

  String _fmtDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<List<Map<String, dynamic>>> _fetchList(String path) async {
    try {
      final result = await ApiService.instance.get(path);
      final data = result['data'];
      final list = data is List ? data : (data?['list'] ?? data?['data'] ?? []);
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> _openPicker(
    BuildContext context,
    String title,
    List<Map<String, dynamic>> options,
  ) async {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        String search = '';
        return StatefulBuilder(builder: (ctx, setSheetState) {
          final filtered = search.isEmpty ? options : options.where((o) {
            final kw = search.toLowerCase();
            final name = (o['name'] ?? '').toString().toLowerCase();
            final code = (o['code'] ?? '').toString().toLowerCase();
            return name.contains(kw) || code.contains(kw);
          }).toList();

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
                    hintText: '搜索...',
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
                    ? const Padding(padding: EdgeInsets.all(32), child: Text('无匹配项', style: TextStyle(color: AppTheme.textHint)))
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                        itemBuilder: (_, i) {
                          final o = filtered[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                              radius: 18,
                              child: Text((o['name'] ?? '?')[0], style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 13)),
                            ),
                            title: Text(o['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: o['code'] != null ? Text(o['code'], style: const TextStyle(fontSize: 12, color: AppTheme.textHint)) : null,
                            trailing: const Icon(Icons.chevron_right, color: AppTheme.textHint),
                            onTap: () => Navigator.pop(ctx, o),
                          );
                        },
                      ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          );
        });
      },
    );
  }

  void _showDeleteConfirm(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('确认删除'),
        content: Text('确认删除采购订单 ${order['order_no']}？此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService.instance.delete('${ApiConfig.purchaseOrders}/${order['id']}');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已删除'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating),
                  );
                  _loadOrders();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('删除失败: $e'), backgroundColor: AppTheme.dangerColor, behavior: SnackBarBehavior.floating),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleApprove(Map<String, dynamic> order) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('审批确认'),
        content: Text('确认通过采购订单 ${order['order_no']}？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
            child: const Text('确认通过'),
          ),
        ],
      ),
    );
    if (approved == true) {
      try {
        final id = order['id'];
        await ApiService.instance.post(ApiConfig.replaceId(ApiConfig.purchaseOrderApprove, id));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已通过: ${order['order_no']}'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
        _loadOrders();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('操作失败: $e'),
              backgroundColor: AppTheme.dangerColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      }
    }
  }
}

class _SupplierPicker extends StatefulWidget {
  final List<Map<String, dynamic>> suppliers;

  const _SupplierPicker({required this.suppliers});

  @override
  State<_SupplierPicker> createState() => _SupplierPickerState();
}

class _SupplierPickerState extends State<_SupplierPicker> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.suppliers;
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final keyword = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = keyword.isEmpty
          ? widget.suppliers
          : widget.suppliers.where((s) {
              final name = (s['name'] ?? '').toString().toLowerCase();
              final contact = (s['contact_person'] ?? '').toString().toLowerCase();
              final phone = (s['phone'] ?? '').toString().toLowerCase();
              return name.contains(keyword) || contact.contains(keyword) || phone.contains(keyword);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('选择供应商', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: '搜索供应商名称/联系人/电话',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const Divider(height: 1),
        Flexible(
          child: _filtered.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.business_outlined, size: 40, color: AppTheme.textHint),
                      SizedBox(height: 8),
                      Text('未找到供应商', style: TextStyle(color: AppTheme.textHint)),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final s = _filtered[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        child: Text(
                          (s['name'] ?? '?')[0],
                          style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                        ),
                      ),
                      title: Text(s['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      subtitle: Row(
                        children: [
                          if (s['contact_person'] != null) ...[
                            const Icon(Icons.person_outline, size: 14, color: AppTheme.textHint),
                            const SizedBox(width: 2),
                            Text(s['contact_person'], style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
                            const SizedBox(width: 8),
                          ],
                          if (s['phone'] != null) ...[
                            const Icon(Icons.phone_outlined, size: 14, color: AppTheme.textHint),
                            const SizedBox(width: 2),
                            Text(s['phone'], style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
                          ],
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right, color: AppTheme.textHint),
                      onTap: () => Navigator.pop(context, s),
                    );
                  },
                ),
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onApprove;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _OrderCard({required this.order, required this.onApprove, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final status = order['status'] ?? 'pending';
    final statusColor = _PurchaseOrderPageState._statusColors[status] ?? AppTheme.textHint;
    final statusLabel = _PurchaseOrderPageState._statusLabels[status] ?? '未知';
    final isPending = status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(order['order_no'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(statusLabel, style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600)),
              ),
              if (isPending && (onEdit != null || onDelete != null)) ...[
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  onSelected: (action) {
                    if (action == 'edit' && onEdit != null) onEdit!();
                    if (action == 'delete' && onDelete != null) onDelete!();
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryColor), SizedBox(width: 8), Text('编辑')])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerColor), SizedBox(width: 8), Text('删除', style: TextStyle(color: AppTheme.dangerColor))])),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined, size: 16, color: AppTheme.textHint),
              const SizedBox(width: 4),
              Text(order['supplier']?['name'] ?? '', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.payments_outlined, size: 16, color: AppTheme.textHint),
              const SizedBox(width: 4),
              Text(
                '¥${safeToDouble(order['total_amount'] ?? order['amount']).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
              const Spacer(),
              const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textHint),
              const SizedBox(width: 4),
              Text(order['created_at'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleReject(context),
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
                    onPressed: onApprove,
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
        ],
      ),
    );
  }

  void _handleReject(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('驳回原因'),
        content: const TextField(maxLines: 3, decoration: InputDecoration(hintText: '请输入驳回原因', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('已驳回: ${order['order_no']}'),
                  backgroundColor: AppTheme.dangerColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            child: const Text('确认驳回'),
          ),
        ],
      ),
    );
  }
}
