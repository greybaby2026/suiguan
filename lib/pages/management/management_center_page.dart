import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../config/feature_config.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/feature_guard.dart';

class ManagementCenterPage extends StatefulWidget {
  const ManagementCenterPage({super.key});

  @override
  State<ManagementCenterPage> createState() => _ManagementCenterPageState();
}

class _ManagementCenterPageState extends State<ManagementCenterPage> {
  int _pendingPieceCount = 0;
  int _pendingTicketCount = 0;

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    try {
      final api = ApiService.instance;
      final pieceRes = await api.get(ApiConfig.workerPieceRecords, queryParameters: {'status': 'pending', 'limit': 1}).catchError((_) => <String, dynamic>{});
      final ticketRes = await api.get(ApiConfig.tickets, queryParameters: {'status': 'open', 'limit': 1}).catchError((_) => <String, dynamic>{});
      if (mounted) {
        setState(() {
          _pendingPieceCount = pieceRes['total'] ?? pieceRes['data']?['total'] ?? 0;
          _pendingTicketCount = ticketRes['total'] ?? ticketRes['data']?['total'] ?? 0;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final hasQuality = auth.hasFeature(FeatureConfig.qualityManagement);

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('管理中心')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMenuGroup(
              title: '人工管理',
              icon: Icons.groups_outlined,
              color: AppTheme.primaryColor,
              items: [
                _MenuItem(icon: Icons.badge_outlined, title: '工人管理', route: '/management/workers'),
                _MenuItem(icon: Icons.fact_check_outlined, title: '计件审批', route: '/management/piece-approval', badge: _pendingPieceCount),
                _MenuItem(icon: Icons.account_balance_wallet_outlined, title: '预支管理', route: '/management/advances'),
                _MenuItem(icon: Icons.receipt_long_outlined, title: '结算管理', route: '/management/settlements'),
                _MenuItem(icon: Icons.assessment_outlined, title: '薪资报表', route: '/management/salary-report'),
                _MenuItem(icon: Icons.event_available_outlined, title: '考勤记录', route: '/management/checkin-records'),
              ],
            ),
            const SizedBox(height: 20),

            if (hasQuality) ...[
              _buildMenuGroup(
                title: '质量管理',
                icon: Icons.verified_outlined,
                color: AppTheme.warningColor,
                items: [
                  _MenuItem(icon: Icons.fact_check_outlined, title: '质检列表', route: '/management/quality-inspections'),
                  _MenuItem(icon: Icons.bar_chart_outlined, title: '质量报表', route: '/management/quality-report'),
                ],
              ),
            ] else ...[
              _buildLockedGroup(context, '质量管理', FeatureConfig.qualityManagement, ['质检列表', '质量报表']),
            ],
            const SizedBox(height: 20),

            _buildMenuGroup(
              title: '基础数据',
              icon: Icons.storage_outlined,
              color: AppTheme.infoColor,
              items: [
                _MenuItem(icon: Icons.inventory_2_outlined, title: '产品管理', route: '/management/products'),
                _MenuItem(icon: Icons.category_outlined, title: '原料管理', route: '/management/materials'),
                _MenuItem(icon: Icons.widgets_outlined, title: '产品分类', route: '/management/product-categories'),
                _MenuItem(icon: Icons.account_tree_outlined, title: 'BOM管理', route: '/management/bom-items'),
                _MenuItem(icon: Icons.settings_outlined, title: '工序管理', route: '/management/processes'),
                _MenuItem(icon: Icons.route_outlined, title: '工艺路线', route: '/management/process-routes'),
              ],
            ),
            const SizedBox(height: 20),

            _buildMenuGroup(
              title: '系统设置',
              icon: Icons.settings_applications_outlined,
              color: AppTheme.successColor,
              items: [
                _MenuItem(icon: Icons.people_outlined, title: '用户管理', route: '/management/users'),
                _MenuItem(icon: Icons.admin_panel_settings_outlined, title: '角色权限', route: '/management/roles'),
                _MenuItem(icon: Icons.person_outline, title: '个人设置', route: '/profile'),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedGroup(BuildContext context, String title, String featureKey, List<String> itemNames) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: AppTheme.textHint.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.lock_outline, size: 16, color: AppTheme.textHint),
              ),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
            ],
          ),
        ),
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
                Expanded(
                  child: Text(
                    itemNames.join('、'),
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

  Widget _buildMenuGroup({
    required String title,
    required IconData icon,
    required Color color,
    required List<_MenuItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            ],
          ),
        ),
        Container(
          decoration: AppTheme.cardDecoration,
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;
              return _buildMenuItem(item, showDivider: !isLast);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(_MenuItem item, {bool showDivider = true}) {
    return Builder(
      builder: (context) => InkWell(
        onTap: () => context.push(item.route),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(item.icon, size: 22, color: AppTheme.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(child: Text(item.title, style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary))),
                  if (item.badge > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppTheme.dangerColor, borderRadius: BorderRadius.circular(10)),
                      constraints: const BoxConstraints(minWidth: 18),
                      child: Text('${item.badge}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                    ),
                  const Icon(Icons.chevron_right, size: 20, color: AppTheme.textHint),
                ],
              ),
              if (showDivider)
                Padding(padding: const EdgeInsets.only(left: 34, top: 12), child: Divider(height: 1, color: AppTheme.border.withOpacity(0.5))),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String route;
  final int badge;

  const _MenuItem({required this.icon, required this.title, required this.route, this.badge = 0});
}
