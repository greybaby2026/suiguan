import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/warehouse_provider.dart';
import '../../models/stock_movement.dart';

class StockMovementPage extends StatefulWidget {
  const StockMovementPage({super.key});

  @override
  State<StockMovementPage> createState() => _StockMovementPageState();
}

class _StockMovementPageState extends State<StockMovementPage> {
  String? _filterType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WarehouseProvider>().loadStockMovements();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WarehouseProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('出入库记录')),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : provider.movements.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.swap_horiz, size: 48, color: AppTheme.textHint),
                            SizedBox(height: 8),
                            Text('暂无记录', style: TextStyle(color: AppTheme.textHint)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => provider.loadStockMovements(type: _filterType),
                        color: AppTheme.primaryColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: provider.movements.length,
                          itemBuilder: (context, index) {
                            return _MovementCard(movement: provider.movements[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          _FilterTab(
            label: '全部',
            isActive: _filterType == null,
            onTap: () {
              setState(() => _filterType = null);
              context.read<WarehouseProvider>().loadStockMovements();
            },
          ),
          const SizedBox(width: 8),
          _FilterTab(
            label: '入库',
            isActive: _filterType == 'in',
            color: AppTheme.successColor,
            onTap: () {
              setState(() => _filterType = 'in');
              context.read<WarehouseProvider>().loadStockMovements(type: 'in');
            },
          ),
          const SizedBox(width: 8),
          _FilterTab(
            label: '出库',
            isActive: _filterType == 'out',
            color: AppTheme.dangerColor,
            onTap: () {
              setState(() => _filterType = 'out');
              context.read<WarehouseProvider>().loadStockMovements(type: 'out');
            },
          ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color? color;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.isActive,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppTheme.primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? activeColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _MovementCard extends StatelessWidget {
  final StockMovementModel movement;

  const _MovementCard({required this.movement});

  @override
  Widget build(BuildContext context) {
    final isIn = movement.isIn;
    final color = isIn ? AppTheme.successColor : AppTheme.dangerColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        movement.typeLabel,
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        movement.itemName ?? '未知物品',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '数量: ${movement.quantity.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      movement.warehouseName ?? '',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIn ? "+" : "-"}${movement.quantity.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              if (movement.createdAt != null)
                Text(
                  movement.createdAt!.substring(0, 10),
                  style: const TextStyle(fontSize: 11, color: AppTheme.textHint),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
