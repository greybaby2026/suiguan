import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../providers/production_provider.dart';
import '../../models/production_order.dart';

class ProductionListPage extends StatefulWidget {
  const ProductionListPage({super.key});

  @override
  State<ProductionListPage> createState() => _ProductionListPageState();
}

class _ProductionListPageState extends State<ProductionListPage> {
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductionProvider>().loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductionProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('生产管理')),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : provider.orders.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.precision_manufacturing_outlined, size: 48, color: AppTheme.textHint),
                            SizedBox(height: 8),
                            Text('暂无生产工单', style: TextStyle(color: AppTheme.textHint)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => provider.loadOrders(status: _filterStatus),
                        color: AppTheme.primaryColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                          itemCount: provider.orders.length,
                          itemBuilder: (context, index) {
                            return _OrderCard(
                              order: provider.orders[index],
                              onTap: () => context.push('/production/${provider.orders[index].id}'),
                            );
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _StatusChip(label: '全部', value: null, currentValue: _filterStatus),
            const SizedBox(width: 8),
            _StatusChip(label: '待排产', value: 'pending', currentValue: _filterStatus),
            const SizedBox(width: 8),
            _StatusChip(label: '已排产', value: 'scheduled', currentValue: _filterStatus),
            const SizedBox(width: 8),
            _StatusChip(label: '生产中', value: 'in_production', currentValue: _filterStatus),
            const SizedBox(width: 8),
            _StatusChip(label: '已完成', value: 'completed', currentValue: _filterStatus),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final String? value;
  final String? currentValue;

  const _StatusChip({
    required this.label,
    required this.value,
    required this.currentValue,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = value == currentValue;
    return GestureDetector(
      onTap: () {
        context.read<ProductionProvider>().loadOrders(status: value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : const Color(0xFFF1F5F9),
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

class _OrderCard extends StatelessWidget {
  final ProductionOrderModel order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = Color(order.statusColor);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.orderNo,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    order.statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (order.productName != null) ...[
              const SizedBox(height: 6),
              Text(
                order.productName!,
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: order.progress,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(order.progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '完成: ${order.completedQty.toStringAsFixed(0)} / ${order.quantity.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
                ),
                if (order.plannedEnd != null)
                  Text(
                    '计划完成: ${order.plannedEnd!.substring(0, 10)}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
