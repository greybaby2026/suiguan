import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/warehouse_provider.dart';
import '../../models/inventory_item.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final _searchController = TextEditingController();
  int? _selectedWarehouseId;
  String? _selectedItemType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WarehouseProvider>().loadInventories();
      context.read<WarehouseProvider>().loadWarehouses();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    context.read<WarehouseProvider>().loadInventories(
      warehouseId: _selectedWarehouseId,
      itemType: _selectedItemType,
      keyword: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WarehouseProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('库存查询')),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildWarehouseFilter(provider),
          _buildItemTypeFilter(),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : provider.inventories.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.textHint),
                            SizedBox(height: 8),
                            Text('暂无库存数据', style: TextStyle(color: AppTheme.textHint)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: provider.inventories.length,
                        itemBuilder: (context, index) {
                          return _InventoryCard(item: provider.inventories[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索物料编码或名称',
          prefixIcon: const Icon(Icons.search, size: 22),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear, size: 20),
            onPressed: () {
              _searchController.clear();
              _applyFilters();
            },
          ),
        ),
        onSubmitted: (_) => _applyFilters(),
      ),
    );
  }

  Widget _buildWarehouseFilter(WarehouseProvider provider) {
    if (provider.warehouses.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: '全部仓库',
              isSelected: _selectedWarehouseId == null,
              onTap: () {
                setState(() => _selectedWarehouseId = null);
                _applyFilters();
              },
            ),
            ...provider.warehouses.map((warehouse) {
              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: _FilterChip(
                  label: warehouse.name,
                  isSelected: _selectedWarehouseId == warehouse.id,
                  onTap: () {
                    setState(() => _selectedWarehouseId = warehouse.id);
                    _applyFilters();
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTypeFilter() {
    const types = [
      (value: null, label: '全部类型'),
      (value: 'material', label: '原料'),
      (value: 'product', label: '成品'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: types.map((t) {
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _FilterChip(
                label: t.label,
                isSelected: _selectedItemType == t.value,
                onTap: () {
                  setState(() => _selectedItemType = t.value);
                  _applyFilters();
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
        ),
        constraints: const BoxConstraints(minHeight: 24),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final InventoryItemModel item;

  const _InventoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final typeLabel = item.itemType == 'product' ? '成品' : '原料';
    final typeColor = item.itemType == 'product' ? AppTheme.primaryColor : const Color(0xFF8B5CF6);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (item.isLowStock ? AppTheme.dangerColor : typeColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.isLowStock ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
                  color: item.isLowStock ? AppTheme.dangerColor : typeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.itemName ?? '未知物品',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(typeLabel, style: TextStyle(fontSize: 10, color: typeColor, fontWeight: FontWeight.w600, height: 1.4)),
                        ),
                        if (item.isLowStock) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.dangerColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('低库存', style: TextStyle(fontSize: 10, color: AppTheme.dangerColor, fontWeight: FontWeight.w600, height: 1.4)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [item.itemCode, item.itemSpec].where((e) => e != null && e.isNotEmpty).join(' · '),
                      style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity.toStringAsFixed(2)}${item.itemUnit != null ? ' ${item.itemUnit}' : ''}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: item.isLowStock ? AppTheme.dangerColor : AppTheme.textPrimary,
                    ),
                  ),
                  if (item.safetyStock != null)
                    Text(
                      '安全库存: ${item.safetyStock! % 1 == 0 ? item.safetyStock!.toInt() : item.safetyStock!.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 10, color: AppTheme.textHint),
                    ),
                ],
              ),
            ],
          ),
          if (item.warehouseName != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.warehouse_outlined, size: 12, color: AppTheme.textHint),
                const SizedBox(width: 4),
                Text(item.warehouseName!, style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
