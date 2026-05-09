import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/feature_config.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/feature_guard.dart';

class BusinessCenterPage extends StatelessWidget {
  const BusinessCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final hasCost = auth.hasFeature(FeatureConfig.costManagement);

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('业务中心')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('销售管理'),
            _buildSectionCard([
              _MenuItem(
                icon: Icons.receipt_long_outlined,
                title: '订单列表',
                color: AppTheme.primaryColor,
                onTap: () => context.push('/business/orders'),
              ),
              _MenuItem(
                icon: Icons.add_circle_outline,
                title: '新建订单',
                color: AppTheme.successColor,
                onTap: () => context.push('/business/orders/create'),
                showDivider: false,
              ),
            ]),
            const SizedBox(height: 20),

            _buildSectionTitle('客户管理'),
            _buildSectionCard([
              _MenuItem(
                icon: Icons.group_outlined,
                title: '客户列表',
                color: AppTheme.accentColor,
                onTap: () => context.push('/business/customers'),
                showDivider: false,
              ),
            ]),
            const SizedBox(height: 20),

            if (hasCost) ...[
              _buildSectionTitle('成本管理'),
              _buildSectionCard([
                _MenuItem(
                  icon: Icons.analytics_outlined,
                  title: '成本概览',
                  color: AppTheme.infoColor,
                  onTap: () => context.push('/business/cost-overview'),
                ),
                _MenuItem(
                  icon: Icons.history_outlined,
                  title: '成本记录',
                  color: AppTheme.warningColor,
                  onTap: () => context.push('/business/cost-records'),
                  showDivider: false,
                ),
              ]),
            ] else ...[
              _buildLockedSection(context, '成本管理', FeatureConfig.costManagement, ['成本概览', '成本记录']),
            ],
            _buildSectionTitle('财务中心'),
            _buildSectionCard([
              _MenuItem(
                icon: Icons.account_balance_outlined,
                title: '财务中心',
                color: Colors.green,
                onTap: () => context.push('/financial/center'),
                showDivider: false,
              ),
            ]),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedSection(BuildContext context, String title, String featureKey, List<String> items) {
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
            child: Row(
              children: [
                const Icon(Icons.lock_outline, size: 20, color: AppTheme.textHint),
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
