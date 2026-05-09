import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';

class FinancialCenterPage extends StatelessWidget {
  const FinancialCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('财务中心')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('核心数据'),
            _buildSectionCard([
              _MenuItem(
                icon: Icons.dashboard_outlined,
                title: '财务驾驶舱',
                color: AppTheme.primaryColor,
                onTap: () => context.push('/financial/dashboard'),
              ),
              _MenuItem(
                icon: Icons.receipt_long,
                title: '收支明细',
                color: Colors.green,
                onTap: () => context.push('/financial/income-expense'),
              ),
              _MenuItem(
                icon: Icons.trending_up,
                title: '利润概览',
                color: Colors.orange,
                onTap: () => context.push('/financial/overview'),
                showDivider: false,
              ),
            ]),
            const SizedBox(height: 20),
            _buildSectionTitle('应收应付'),
            _buildSectionCard([
              _MenuItem(
                icon: Icons.swap_horiz,
                title: '应收应付',
                color: AppTheme.warningColor,
                onTap: () => context.push('/financial/receivable-payable'),
                showDivider: false,
              ),
            ]),
            const SizedBox(height: 20),
            _buildSectionTitle('工资管理'),
            _buildSectionCard([
              _MenuItem(
                icon: Icons.account_balance_wallet_outlined,
                title: '工资管理',
                color: Colors.brown,
                onTap: () => context.push('/financial/wage-summary'),
                showDivider: false,
              ),
            ]),
            const SizedBox(height: 100),
          ],
        ),
      ),
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
