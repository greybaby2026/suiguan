import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../utils/number_utils.dart';

class OrderCreatePage extends StatefulWidget {
  const OrderCreatePage({super.key});

  @override
  State<OrderCreatePage> createState() => _OrderCreatePageState();
}

class _OrderCreatePageState extends State<OrderCreatePage> {
  final ApiService _api = ApiService.instance;
  final _formKey = GlobalKey<FormState>();
  final _remarkController = TextEditingController();
  bool _isSubmitting = false;
  bool _isLoading = true;

  int? _selectedCustomerId;
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _products = [];

  DateTime _orderDate = DateTime.now();
  DateTime? _deliveryDate;

  final List<_OrderItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.get(ApiConfig.customers).catchError((_) => <String, dynamic>{}),
        _api.get(ApiConfig.products).catchError((_) => <String, dynamic>{}),
      ]);

      final customerData = results[0]['data'] ?? results[0];
      if (customerData is List) {
        _customers = customerData.cast<Map<String, dynamic>>();
      } else if (customerData is Map && customerData.containsKey('list')) {
        _customers = (customerData['list'] as List).cast<Map<String, dynamic>>();
      }

      final productData = results[1]['data'] ?? results[1];
      if (productData is List) {
        _products = productData.cast<Map<String, dynamic>>();
      } else if (productData is Map && productData.containsKey('list')) {
        _products = (productData['list'] as List).cast<Map<String, dynamic>>();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载数据失败: $e'),
            backgroundColor: AppTheme.dangerColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickOrderDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _orderDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _orderDate = picked);
  }

  Future<void> _pickDeliveryDate() async {
    final initial = _deliveryDate ?? _orderDate.add(const Duration(days: 7));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _orderDate,
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _deliveryDate = picked);
  }

  void _addItem() {
    setState(() {
      _items.add(_OrderItem());
    });
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  double get _totalAmount {
    double total = 0;
    for (final item in _items) {
      total += item.quantity * item.unitPrice;
    }
    return total;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请选择客户'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请至少添加一个产品明细'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].productId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('第${i + 1}行请选择产品'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (_items[i].quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('第${i + 1}行数量必须大于0'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);
    try {
      final itemsData = _items.map((item) => {
        'product_id': item.productId,
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
      }).toList();

      await _api.post(ApiConfig.orders, data: {
        'customer_id': _selectedCustomerId,
        'order_date': _orderDate.toIso8601String().substring(0, 10),
        'delivery_date': _deliveryDate?.toIso8601String().substring(0, 10),
        'remark': _remarkController.text.trim(),
        'items': itemsData,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('订单创建成功'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('创建失败: $e'),
            backgroundColor: AppTheme.dangerColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('创建订单')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionCard(children: [
                            DropdownButtonFormField<int?>(
                              value: _selectedCustomerId,
                              decoration: const InputDecoration(
                                labelText: '客户名称',
                                hintText: '请选择客户',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              items: _customers
                                  .map((c) => DropdownMenuItem<int?>(
                                        value: c['id'] as int?,
                                        child: Text(c['name'] ?? c['contact_name'] ?? '未知'),
                                      ))
                                  .toList(),
                              onChanged: (v) => setState(() => _selectedCustomerId = v),
                              validator: (v) => v == null ? '请选择客户' : null,
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: _pickOrderDate,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: '订单日期',
                                  prefixIcon: Icon(Icons.calendar_today_outlined),
                                ),
                                child: Text(
                                  _formatDate(_orderDate),
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: _pickDeliveryDate,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: '交货日期（可选）',
                                  prefixIcon: Icon(Icons.event_outlined),
                                ),
                                child: Text(
                                  _deliveryDate != null
                                      ? _formatDate(_deliveryDate!)
                                      : '请选择交货日期',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: _deliveryDate != null
                                        ? AppTheme.textPrimary
                                        : AppTheme.textHint,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _remarkController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: '备注',
                                hintText: '请输入备注信息（可选）',
                                prefixIcon: Icon(Icons.note_outlined),
                              ),
                            ),
                          ]),

                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '订单明细',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              InkWell(
                                onTap: _addItem,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add, size: 16, color: AppTheme.primaryColor),
                                      SizedBox(width: 4),
                                      Text(
                                        '添加产品',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          if (_items.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: AppTheme.cardDecoration,
                              child: const Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.inventory_2_outlined, size: 36, color: AppTheme.textHint),
                                    SizedBox(height: 8),
                                    Text('暂无产品明细，请点击添加', style: TextStyle(color: AppTheme.textHint)),
                                  ],
                                ),
                              ),
                            )
                          else
                            ..._items.asMap().entries.map(
                                  (entry) => _buildItemCard(entry.key, entry.value),
                                ),

                          if (_items.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('合计金额', style: TextStyle(fontSize: 15, color: AppTheme.textSecondary)),
                                  Text(
                                    '¥${_totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom: MediaQuery.of(context).padding.bottom + 12,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 8,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              '提交订单',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(children: children),
    );
  }

  Widget _buildItemCard(int index, _OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '产品 #${index + 1}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              InkWell(
                onTap: () => _removeItem(index),
                child: const Icon(Icons.close, size: 18, color: AppTheme.dangerColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int?>(
            value: item.productId,
            decoration: const InputDecoration(labelText: '选择产品', isDense: true),
            items: _products
                .map((p) => DropdownMenuItem<int?>(
                      value: p['id'] as int?,
                      child: Text(
                        p['name'] ?? p['product_name'] ?? '未知',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ))
                .toList(),
            onChanged: (v) => setState(() {
              item.productId = v;
              if (v != null) {
                final product = _products.firstWhere(
                  (p) => p['id'] == v,
                  orElse: () => <String, dynamic>{},
                );
                item.unitPrice = safeToDouble(product['price'] ?? product['unit_price'] ?? 0);
              }
            }),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: item.quantity > 0 ? item.quantity.toString() : '',
                  decoration: const InputDecoration(labelText: '数量', isDense: true),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) => setState(() => item.quantity = double.tryParse(v) ?? 0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  initialValue: item.unitPrice > 0 ? item.unitPrice.toStringAsFixed(2) : '',
                  decoration: const InputDecoration(labelText: '单价', isDense: true),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) => setState(() => item.unitPrice = double.tryParse(v) ?? 0),
                ),
              ),
            ],
          ),
          if (item.quantity > 0 && item.unitPrice > 0) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '小计: ¥${(item.quantity * item.unitPrice).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderItem {
  int? productId;
  double quantity = 0;
  double unitPrice = 0;
}
