import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';

/// 出入库操作页
class StockOperationPage extends StatefulWidget {
  const StockOperationPage({super.key});

  @override
  State<StockOperationPage> createState() => _StockOperationPageState();
}

class _StockOperationPageState extends State<StockOperationPage> {
  // 操作类型：in=入库, out=出库, transfer=调拨
  String _operationType = 'in';
  int? _selectedWarehouseId;
  int? _selectedMaterialId;
  final _quantityController = TextEditingController();
  final _remarkController = TextEditingController();
  bool _isSubmitting = false;

  // 仓库列表
  List<Map<String, dynamic>> _warehouses = [];
  // 物料列表
  List<Map<String, dynamic>> _materials = [];

  // 操作类型选项
  static const List<Map<String, String>> _operationTypes = [
    {'label': '入库', 'value': 'in', 'icon': 'arrow_downward'},
    {'label': '出库', 'value': 'out', 'icon': 'arrow_upward'},
    {'label': '调拨', 'value': 'transfer', 'icon': 'swap_horiz'},
  ];

  @override
  void initState() {
    super.initState();
    _loadWarehouses();
    _loadMaterials();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  /// 加载仓库列表
  Future<void> _loadWarehouses() async {
    try {
      final result = await ApiService.instance.get(ApiConfig.warehouses);
      final data = result['data'];
      final list = data is List ? data : (data?['list'] ?? data?['data'] ?? []);
      setState(() {
        _warehouses = list.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      // 加载失败时保持空列表
    }
  }

  Future<void> _loadMaterials() async {
    try {
      final result = await ApiService.instance.get(ApiConfig.materials);
      final data = result['data'];
      final list = data is List ? data : (data?['list'] ?? data?['data'] ?? []);
      setState(() {
        _materials = list.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      // 加载失败时保持空列表
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('出入库操作')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOperationTypeSelector(),
            const SizedBox(height: 20),
            _buildForm(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  /// 操作类型选择器
  Widget _buildOperationTypeSelector() {
    return Row(
      children: _operationTypes.map((type) {
        final isActive = _operationType == type['value'];
        final color = _getTypeColor(type['value']!);
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _operationType = type['value']!),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isActive ? color.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? color : AppTheme.border,
                  width: isActive ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    type['value'] == 'in'
                        ? Icons.arrow_downward
                        : type['value'] == 'out'
                            ? Icons.arrow_upward
                            : Icons.swap_horiz,
                    color: isActive ? color : AppTheme.textHint,
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    type['label']!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isActive ? color : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 获取操作类型颜色
  Color _getTypeColor(String type) {
    switch (type) {
      case 'in':
        return AppTheme.successColor;
      case 'out':
        return AppTheme.warningColor;
      case 'transfer':
        return AppTheme.infoColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  /// 表单区域
  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 选择仓库
          _buildFormLabel('选择仓库'),
          const SizedBox(height: 8),
          _buildWarehouseDropdown(),
          const SizedBox(height: 16),

          // 选择物料
          _buildFormLabel('选择物料'),
          const SizedBox(height: 8),
          _buildMaterialDropdown(),
          const SizedBox(height: 16),

          // 数量
          _buildFormLabel('数量'),
          const SizedBox(height: 8),
          TextField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: '请输入数量',
              prefixIcon: Icon(Icons.numbers_outlined, size: 22),
            ),
          ),
          const SizedBox(height: 16),

          // 备注
          _buildFormLabel('备注'),
          const SizedBox(height: 8),
          TextField(
            controller: _remarkController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: '请输入备注信息（选填）',
            ),
          ),
        ],
      ),
    );
  }

  /// 表单标签
  Widget _buildFormLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }

  /// 仓库下拉选择
  Widget _buildWarehouseDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _selectedWarehouseId,
          hint: const Text('请选择仓库', style: TextStyle(color: AppTheme.textHint)),
          isExpanded: true,
          icon: const Icon(Icons.expand_more, color: AppTheme.textHint),
          items: _warehouses.map((warehouse) {
            return DropdownMenuItem<int?>(
              value: warehouse['id'] as int,
              child: Text(warehouse['name'] ?? ''),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedWarehouseId = value);
          },
        ),
      ),
    );
  }

  /// 物料下拉选择
  Widget _buildMaterialDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _selectedMaterialId,
          hint: const Text('请选择物料', style: TextStyle(color: AppTheme.textHint)),
          isExpanded: true,
          icon: const Icon(Icons.expand_more, color: AppTheme.textHint),
          items: _materials.map((material) {
            return DropdownMenuItem<int?>(
              value: material['id'] as int,
              child: Text('${material['name'] ?? ''} (${material['unit'] ?? ''})'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedMaterialId = value);
          },
        ),
      ),
    );
  }

  /// 提交按钮
  Widget _buildSubmitButton() {
    final color = _getTypeColor(_operationType);
    final label = _operationTypes.firstWhere((t) => t['value'] == _operationType)['label'];

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(
                '确认$label',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
      ),
    );
  }

  /// 提交操作
  Future<void> _handleSubmit() async {
    // 表单验证
    if (_selectedWarehouseId == null) {
      _showToast('请选择仓库', AppTheme.warningColor);
      return;
    }
    if (_selectedMaterialId == null) {
      _showToast('请选择物料', AppTheme.warningColor);
      return;
    }
    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity <= 0) {
      _showToast('请输入有效数量', AppTheme.warningColor);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ApiService.instance.post(
        ApiConfig.stockMovements,
        data: {
          'type': _operationType == 'transfer' ? 'out' : _operationType,
          'warehouse_id': _selectedWarehouseId,
          'item_type': 'material',
          'item_id': _selectedMaterialId,
          'quantity': quantity,
          if (_remarkController.text.trim().isNotEmpty) 'remark': _remarkController.text.trim(),
        },
      );
      if (mounted) {
        _showToast('操作成功', AppTheme.successColor);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showToast('操作失败: $e', AppTheme.dangerColor);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// 显示提示
  void _showToast(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
