import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/feature_config.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/feature_guard.dart';

class SupplyCenterPage extends StatelessWidget {
  const SupplyCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final hasPurchase = auth.hasFeature(FeatureConfig.purchaseManagement);
    final hasOutsourcing = auth.hasFeature(FeatureConfig.outsourcingManagement);
    final hasWarehouse = auth.hasFeature(FeatureConfig.warehouseManagement);

    final hasAnyFeature = hasPurchase || hasOutsourcing || hasWarehouse;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('供应链中心')),
      body: !hasAnyFeature
          ? _buildNoFeatureState(context)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasPurchase) ...[
                    _buildSectionTitle('采购管理'),
                    _buildSectionCard([
                      _MenuItem(
                        icon: Icons.shopping_cart_outlined,
                        title: '采购订单',
                        color: AppTheme.primaryColor,
                        onTap: () => context.push('/supply/purchase-orders'),
                      ),
                      _MenuItem(
                        icon: Icons.local_shipping_outlined,
                        title: '供应商管理',
                        color: AppTheme.accentColor,
                        onTap: () => context.push('/supply/suppliers'),
                        showDivider: false,
                      ),
                    ]),
                    const SizedBox(height: 20),
                  ] else ...[
                    _buildLockedSection(context, '采购管理', FeatureConfig.purchaseManagement, [
                      '采购订单',
                      '供应商管理',
                    ]),
                    const SizedBox(height: 20),
                  ],

                  if (hasOutsourcing) ...[
                    _buildSectionTitle('外协管理'),
                    _buildSectionCard([
                      _MenuItem(
                        icon: Icons.business_outlined,
                        title: '接纳单位',
                        color: AppTheme.accentColor,
                        onTap: () => context.push('/supply/outsourcing-partners'),
                      ),
                      _MenuItem(
                        icon: Icons.handshake_outlined,
                        title: '外协订单',
                        color: AppTheme.infoColor,
                        onTap: () => context.push('/supply/outsourcing'),
                        showDivider: false,
                      ),
                    ]),
                    const SizedBox(height: 20),
                  ] else ...[
                    _buildLockedSection(context, '外协管理', FeatureConfig.outsourcingManagement, [
                      '接纳单位',
                      '外协订单',
                    ]),
                    const SizedBox(height: 20),
                  ],

                  if (hasWarehouse) ...[
                    _buildSectionTitle('仓储管理'),
                    _buildSectionCard([
                      _MenuItem(
                        icon: Icons.warehouse_outlined,
                        title: '仓库列表',
                        color: AppTheme.successColor,
                        onTap: () => context.push('/warehouse/manage'),
                      ),
                      _MenuItem(
                        icon: Icons.inventory_2_outlined,
                        title: '库存查询',
                        color: AppTheme.warningColor,
                        onTap: () => context.push('/supply/inventory-query'),
                      ),
                      _MenuItem(
                        icon: Icons.swap_horiz,
                        title: '出入库操作',
                        color: AppTheme.primaryColor,
                        onTap: () => context.push('/supply/stock-operation'),
                      ),
                      _MenuItem(
                        icon: Icons.history_outlined,
                        title: '出入库记录',
                        color: AppTheme.infoColor,
                        onTap: () => context.push('/warehouse/movements'),
                        showDivider: false,
                      ),
                    ]),
                    const SizedBox(height: 20),
                  ] else ...[
                    _buildLockedSection(context, '仓储管理', FeatureConfig.warehouseManagement, [
                      '仓库列表',
                      '库存查询',
                      '出入库操作',
                      '出入库记录',
                    ]),
                    const SizedBox(height: 20),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  Widget _buildNoFeatureState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 56, color: AppTheme.textHint),
          const SizedBox(height: 16),
          const Text(
            '供应链功能未开通',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            '升级至专业版即可使用采购、仓储等供应链功能',
            style: TextStyle(fontSize: 14, color: AppTheme.textHint),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.push('/management/subscription'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('升级套餐'),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedSection(
    BuildContext context,
    String title,
    String featureKey,
    List<String> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        InkWell(
          onTap: () => FeatureGuard.check(context, featureKey),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.lock_outline, size: 20, color: AppTheme.textHint),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        items.join('、'),
                        style: const TextStyle(fontSize: 14, color: AppTheme.textHint),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '升级解锁',
                        style: TextStyle(fontSize: 11, color: AppTheme.warningColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Column(children: children),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  final bool showDivider;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 20, color: AppTheme.textHint),
              ],
            ),
            if (showDivider)
              Padding(
                padding: const EdgeInsets.only(left: 52, top: 12),
                child: Divider(height: 1, color: AppTheme.border.withOpacity(0.5)),
              ),
          ],
        ),
      ),
    );
  }
}
