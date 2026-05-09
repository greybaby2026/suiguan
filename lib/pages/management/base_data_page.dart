import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';

/// 基础数据管理页
class BaseDataPage extends StatelessWidget {
  const BaseDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('基础数据')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
        children: [
          _buildDataCard(
            context: context,
            icon: Icons.inventory_2_outlined,
            title: '产品管理',
            subtitle: '管理产品信息',
            color: AppTheme.primaryColor,
            route: '/management/products',
          ),
          _buildDataCard(
            context: context,
            icon: Icons.science_outlined,
            title: '原料管理',
            subtitle: '管理原料信息',
            color: AppTheme.accentColor,
            route: '/management/materials',
          ),
          _buildDataCard(
            context: context,
            icon: Icons.widgets_outlined,
            title: '产品分类',
            subtitle: '管理产品分类',
            color: AppTheme.infoColor,
            route: '/management/product-categories',
          ),
          _buildDataCard(
            context: context,
            icon: Icons.account_tree_outlined,
            title: 'BOM管理',
            subtitle: '物料清单管理',
            color: AppTheme.warningColor,
            route: '/management/bom-items',
          ),
          _buildDataCard(
            context: context,
            icon: Icons.settings_outlined,
            title: '工序管理',
            subtitle: '管理生产工序',
            color: AppTheme.successColor,
            route: '/management/processes',
          ),
          _buildDataCard(
            context: context,
            icon: Icons.route_outlined,
            title: '工艺路线',
            subtitle: '管理工艺路线',
            color: const Color(0xFF8B5CF6),
            route: '/management/process-routes',
          ),
        ],
      ),
    );
  }

  /// 数据入口卡片
  Widget _buildDataCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String route,
  }) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
