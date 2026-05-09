import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../widgets/error_state_widget.dart';

/// 库存查询页
class InventoryQueryPage extends StatefulWidget {
  const InventoryQueryPage({super.key});

  @override
  State<InventoryQueryPage> createState() => _InventoryQueryPageState();
}

class _InventoryQueryPageState extends State<InventoryQueryPage> {
  final _searchController = TextEditingController();
  int? _selectedWarehouseId;
  String _selectedMaterialType = 'all';
  bool _isLoading = false;
  dynamic _error;
  List<Map<String, dynamic>> _inventories = [];
  List<Map<String, dynamic>> _warehouses = [];

  // 物料类型选项
  static const List<Map<String, String>> _materialTypes = [
    {'label': '全部', 'value': 'all'},
    {'label': '原材料', 'value': 'raw_material'},
    {'label': '半成品', 'value': 'semi_finished'},
    {'label': '成品', 'value': 'finished_product'},
    {'label': '辅料', 'value': 'auxiliary_material'},
  ];

  @override
  void initState() {
    super.initState();
    _loadWarehouses();
    _loadInventories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 加载仓库列表
  Future<void> _loadWarehouses() async {
    try {
      final result = await ApiService.instance.get(ApiConfig.warehouses);
      final data = result['data'];
      final list = data is List ? data : [];
      setState(() {
        _warehouses = list.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      // 加载失败时保持空列表
    }
  }

  /// 加载库存数据
  Future<void> _loadInventories() async {
    setState(() => _isLoading = true);
    try {
      final params = <String, dynamic>{};
      if (_selectedWarehouseId != null) params['warehouse_id'] = _selectedWarehouseId;
      if (_selectedMaterialType != 'all') params['material_type'] = _selectedMaterialType;
      if (_searchController.text.trim().isNotEmpty) {
        params['keyword'] = _searchController.text.trim();
      }
      final result = await ApiService.instance.get(
        ApiConfig.inventories,
        queryParameters: params.isNotEmpty ? params : null,
      );
      final data = result['data'];
      final list = data is List ? data : [];
      setState(() {
        _inventories = list.cast<Map<String, dynamic>>();
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
      appBar: AppBar(title: const Text('库存查询')),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildWarehouseFilter(),
          _buildMaterialTypeFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : _error != null
                    ? ErrorStateWidget(error: _error, onRetry: _loadInventories)
                    : _inventories.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _loadInventories,
                        color: AppTheme.primaryColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: _inventories.length,
                          itemBuilder: (context, index) {
                            return _InventoryCard(item: _inventories[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  /// 搜索栏
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索物料名称或编码',
          prefixIcon: const Icon(Icons.search, size: 22),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear, size: 20),
            onPressed: () {
              _searchController.clear();
              _loadInventories();
            },
          ),
        ),
        onSubmitted: (_) => _loadInventories(),
      ),
    );
  }

  /// 仓库筛选
  Widget _buildWarehouseFilter() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: '全部仓库',
            isSelected: _selectedWarehouseId == null,
            onTap: () {
              setState(() => _selectedWarehouseId = null);
              _loadInventories();
            },
          ),
          ..._warehouses.map((warehouse) {
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _FilterChip(
                label: warehouse['name'] ?? '',
                isSelected: _selectedWarehouseId == warehouse['id'],
                onTap: () {
                  setState(() => _selectedWarehouseId = warehouse['id'] as int);
                  _loadInventories();
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 物料类型筛选
  Widget _buildMaterialTypeFilter() {
    return Container(
      height: 40,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _materialTypes.map((type) {
          final isActive = _selectedMaterialType == type['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedMaterialType = type['value']!);
                _loadInventories();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.infoColor : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  type['label']!,
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
    );
  }

  /// 空状态
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.textHint),
          const SizedBox(height: 8),
          const Text('暂无库存数据', style: TextStyle(color: AppTheme.textHint)),
        ],
      ),
    );
  }

}

/// 筛选标签组件
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// 库存卡片
class _InventoryCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _InventoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isWarning = item['is_warning'] == true;
    final itemColor = isWarning ? AppTheme.dangerColor : AppTheme.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration.copyWith(
        // 预警项加红色边框
        border: isWarning
            ? Border.all(color: AppTheme.dangerColor.withOpacity(0.3), width: 1)
            : null,
      ),
      child: Row(
        children: [
          // 图标
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: itemColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isWarning ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
              color: itemColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // 物料信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 物料名 + 预警标识
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['item_name'] ?? '',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isWarning ? AppTheme.dangerColor : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (isWarning)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.dangerColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '低库存',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.dangerColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                // 仓库
                Row(
                  children: [
                    const Icon(Icons.warehouse_outlined, size: 14, color: AppTheme.textHint),
                    const SizedBox(width: 4),
                    Text(
                      item['warehouse_name'] ?? '',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 数量
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item['quantity'] ?? 0}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isWarning ? AppTheme.dangerColor : AppTheme.textPrimary,
                ),
              ),
              Text(
                item['unit'] ?? '',
                style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
