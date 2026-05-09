import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../services/app_update_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/production_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/dashboard/stat_card.dart';
import '../../widgets/dashboard/progress_card.dart';
import '../notification/notification_list_page.dart';
import '../salary/salary_page.dart';
import '../work/piece_record_page.dart';
import '../supply/supply_center_page.dart';
import '../business/business_center_page.dart';
import '../management/management_center_page.dart';

class HomePage extends StatefulWidget {
  final Widget child;
  const HomePage({super.key, required this.child});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdate();
      context.read<AuthProvider>().refreshFeatures();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AuthProvider>().refreshFeatures();
    }
  }

  Future<void> _checkForUpdate() async {
    final updateInfo = await AppUpdateService().checkUpdate();
    if (updateInfo != null && mounted) {
      await AppUpdateService().showUpdateDialog(context, updateInfo: updateInfo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: authProvider.isWorker
          ? const _WorkerBottomNav()
          : const _AdminBottomNav(),
    );
  }
}

class _WorkerBottomNav extends StatelessWidget {
  const _WorkerBottomNav();
  @override
  Widget build(BuildContext context) {
    final np = context.watch<NotificationProvider>();
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -2))]),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: '工作', onTap: () => context.go('/dashboard'), isActive: _isActive(context, '/dashboard')),
            _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: '记录', onTap: () => context.go('/records'), isActive: _isActive(context, '/records')),
            _NavItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet_rounded, label: '薪资', onTap: () => context.go('/salary'), isActive: _isActive(context, '/salary')),
            _NavItem(icon: Icons.person_outlined, activeIcon: Icons.person_rounded, label: '我的', onTap: () => context.go('/profile'), isActive: _isActive(context, '/profile'), badge: np.unreadCount),
          ]),
        ),
      ),
    );
  }
  bool _isActive(BuildContext context, String path) => GoRouterState.of(context).matchedLocation.startsWith(path);
}

class _AdminBottomNav extends StatelessWidget {
  const _AdminBottomNav();
  @override
  Widget build(BuildContext context) {
    final np = context.watch<NotificationProvider>();
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -2))]),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: '工作台', onTap: () => context.go('/dashboard'), isActive: _isActive(context, '/dashboard'), badge: np.unreadCount),
            _NavItem(icon: Icons.precision_manufacturing_outlined, activeIcon: Icons.precision_manufacturing_rounded, label: '生产', onTap: () => context.go('/production'), isActive: _isActive(context, '/production')),
            _NavItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2_rounded, label: '供应链', onTap: () => context.go('/supply'), isActive: _isActive(context, '/supply')),
            _NavItem(icon: Icons.business_center_outlined, activeIcon: Icons.business_center_rounded, label: '业务', onTap: () => context.go('/business'), isActive: _isActive(context, '/business')),
            _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: '管理', onTap: () => context.go('/management'), isActive: _isActive(context, '/management')),
          ]),
        ),
      ),
    );
  }
  bool _isActive(BuildContext context, String path) => GoRouterState.of(context).matchedLocation.startsWith(path);
}

class _NavItem extends StatelessWidget {
  final IconData icon; final IconData activeIcon; final String label; final int badge; final VoidCallback onTap; final bool isActive;
  const _NavItem({required this.icon, required this.activeIcon, required this.label, this.badge = 0, required this.onTap, required this.isActive});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(width: 28, height: 28, child: Stack(clipBehavior: Clip.none, children: [
        Icon(isActive ? activeIcon : icon, size: 24, color: isActive ? AppTheme.primaryColor : AppTheme.textSecondary),
        if (badge > 0) Positioned(right: -6, top: -4, child: Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), decoration: BoxDecoration(color: AppTheme.dangerColor, borderRadius: BorderRadius.circular(10)), constraints: const BoxConstraints(minWidth: 16), child: Text(badge > 99 ? '99+' : '$badge', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center))),
      ])),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal, color: isActive ? AppTheme.primaryColor : AppTheme.textSecondary)),
    ])));
  }
}

// ============ 工人看板 ============
class WorkerDashboardContent extends StatefulWidget {
  const WorkerDashboardContent({super.key});
  @override
  State<WorkerDashboardContent> createState() => _WorkerDashboardContentState();
}

class _WorkerDashboardContentState extends State<WorkerDashboardContent> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) { context.read<ProductionProvider>().loadMyTasks(); context.read<NotificationProvider>().loadUnreadCount(); }); }
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final auth = context.watch<AuthProvider>();
    final prod = context.watch<ProductionProvider>();
    return Scaffold(backgroundColor: AppTheme.bgPrimary, body: RefreshIndicator(onRefresh: () => context.read<ProductionProvider>().loadMyTasks(), color: AppTheme.primaryColor, child: CustomScrollView(slivers: [
      SliverToBoxAdapter(child: _buildHeader(auth)),
      SliverToBoxAdapter(child: _buildQuickActions()),
      SliverToBoxAdapter(child: _buildTasks(prod)),
      const SliverToBoxAdapter(child: SizedBox(height: 100)),
    ])));
  }
  Widget _buildHeader(AuthProvider auth) {
    return Container(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primaryColor, AppTheme.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24))), child: SafeArea(bottom: false, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${auth.worker?.name ?? "工人"}，你好', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4), Text('工号: ${auth.worker?.code ?? "-"}', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
    ])));
  }
  Widget _buildQuickActions() {
    return Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(padding: EdgeInsets.only(left: 4, bottom: 12), child: Text('快捷操作', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary))),
      Row(children: [
        _QuickAction(icon: Icons.login_rounded, label: '打卡', color: AppTheme.successColor, onTap: () => context.push('/work/checkin')),
        _QuickAction(icon: Icons.edit_note_outlined, label: '报工', color: AppTheme.primaryColor, onTap: () => context.push('/work/report')),
        _QuickAction(icon: Icons.receipt_long_outlined, label: '计件记录', color: AppTheme.infoColor, onTap: () => context.push('/records')),
        _QuickAction(icon: Icons.account_balance_wallet_outlined, label: '薪资', color: AppTheme.warningColor, onTap: () => context.go('/salary')),
      ]),
    ]));
  }
  Widget _buildTasks(ProductionProvider provider) {
    final tasks = provider.myTasks;
    return Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(padding: EdgeInsets.only(left: 4, bottom: 12), child: Text('当前任务', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary))),
      if (tasks.isEmpty) Container(padding: const EdgeInsets.all(32), decoration: AppTheme.cardDecoration, child: const Center(child: Column(children: [Icon(Icons.inbox_outlined, size: 40, color: AppTheme.textHint), SizedBox(height: 8), Text('暂无待处理任务', style: TextStyle(color: AppTheme.textHint))])))
      else ...tasks.take(5).map((task) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Container(padding: const EdgeInsets.all(16), decoration: AppTheme.cardDecoration, child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.task_alt, color: AppTheme.primaryColor, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(task.processName ?? '工序', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)), const SizedBox(height: 2), Text('数量: ${task.quantity}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))])),
        Text('${task.completedQty}/${task.quantity}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
      ])))),
    ]));
  }
}

// ============ 管理看板 ============
class AdminDashboardContent extends StatefulWidget {
  const AdminDashboardContent({super.key});
  @override
  State<AdminDashboardContent> createState() => _AdminDashboardContentState();
}

class _AdminDashboardContentState extends State<AdminDashboardContent> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) { _loadData(); }); }
  void _loadData() { context.read<ProductionProvider>().loadDashboard(); context.read<NotificationProvider>().loadUnreadCount(); }
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final auth = context.watch<AuthProvider>();
    final prod = context.watch<ProductionProvider>();
    return Scaffold(backgroundColor: AppTheme.bgPrimary, body: RefreshIndicator(onRefresh: () async => _loadData(), color: AppTheme.primaryColor, child: CustomScrollView(slivers: [
      SliverToBoxAdapter(child: _buildHeader(auth)),
      SliverToBoxAdapter(child: _buildStats(prod)),
      SliverToBoxAdapter(child: _buildQuickActions()),
      SliverToBoxAdapter(child: _buildProductionProgress(prod)),
      const SliverToBoxAdapter(child: SizedBox(height: 100)),
    ])));
  }
  Widget _buildHeader(AuthProvider auth) {
    return Container(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primaryColor, AppTheme.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24))), child: SafeArea(bottom: false, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('管理员，你好', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4), Text(auth.savedTenantCode.isNotEmpty ? '企业: ${auth.savedTenantCode}' : '智能工厂管理', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
    ])));
  }
  Widget _buildStats(ProductionProvider provider) {
    final stats = provider.stats;
    return Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(padding: EdgeInsets.only(left: 4, bottom: 12), child: Text('生产概览', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary))),
      Row(children: [Expanded(child: StatCard(title: '待处理', value: '${stats?.pendingOrders ?? 0}', icon: Icons.pending_actions_outlined, color: AppTheme.warningColor)), const SizedBox(width: 10), Expanded(child: StatCard(title: '生产中', value: '${stats?.inProgressOrders ?? 0}', icon: Icons.settings_outlined, color: AppTheme.primaryColor))]),
      const SizedBox(height: 10),
      Row(children: [Expanded(child: StatCard(title: '已完成', value: '${stats?.completedOrders ?? 0}', icon: Icons.check_circle_outline, color: AppTheme.successColor)), const SizedBox(width: 10), Expanded(child: StatCard(title: '完成率', value: '${(stats?.completionRate ?? 0).toStringAsFixed(1)}%', icon: Icons.trending_up_outlined, color: AppTheme.infoColor))]),
    ]));
  }
  Widget _buildQuickActions() {
    return Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(padding: EdgeInsets.only(left: 4, bottom: 12), child: Text('快捷操作', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary))),
      Row(children: [
        _QuickAction(icon: Icons.check_circle_outline, label: '审批中心', color: AppTheme.warningColor, onTap: () => context.push('/approval-center')),
        _QuickAction(icon: Icons.add_business_outlined, label: '新建订单', color: AppTheme.primaryColor, onTap: () => context.push('/business/orders/create')),
        _QuickAction(icon: Icons.inventory_2_outlined, label: '出入库', color: AppTheme.accentColor, onTap: () => context.push('/supply/stock-operation')),
        _QuickAction(icon: Icons.notifications_outlined, label: '通知', color: AppTheme.infoColor, onTap: () => context.push('/notifications')),
      ]),
    ]));
  }
  Widget _buildProductionProgress(ProductionProvider provider) {
    final progress = provider.progress;
    return Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 4, bottom: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('生产进度', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)), GestureDetector(onTap: () => context.push('/production'), child: const Text('查看全部', style: TextStyle(fontSize: 13, color: AppTheme.primaryColor)))])),
      if (progress.isEmpty) Container(padding: const EdgeInsets.all(32), decoration: AppTheme.cardDecoration, child: const Center(child: Column(children: [Icon(Icons.inbox_outlined, size: 40, color: AppTheme.textHint), SizedBox(height: 8), Text('暂无生产进度', style: TextStyle(color: AppTheme.textHint))])))
      else ...progress.take(5).map((item) => Padding(padding: const EdgeInsets.only(bottom: 10), child: ProgressCard(item: item))),
    ]));
  }
}

// ============ 工人记录页 ============
class WorkerRecordsContent extends StatelessWidget {
  const WorkerRecordsContent({super.key});
  @override
  Widget build(BuildContext context) {
    return const PieceRecordPage();
  }
}

// ============ 工人薪资页 ============
class WorkerSalaryContent extends StatelessWidget {
  const WorkerSalaryContent({super.key});
  @override
  Widget build(BuildContext context) {
    return const SalaryPage();
  }
}

// ============ 工人工作页 ============
class WorkerWorkContent extends StatelessWidget {
  const WorkerWorkContent({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppTheme.bgPrimary, appBar: AppBar(title: const Text('工作')), body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      _WorkMenuItem(icon: Icons.edit_note_outlined, title: '报工', subtitle: '提交生产报工记录', color: AppTheme.primaryColor, onTap: () => context.push('/work/report')),
      const SizedBox(height: 12),
      _WorkMenuItem(icon: Icons.access_time, title: '打卡', subtitle: '上下班打卡签到', color: AppTheme.successColor, onTap: () => context.push('/work/checkin')),
      const SizedBox(height: 12),
      _WorkMenuItem(icon: Icons.receipt_long_outlined, title: '计件记录', subtitle: '查看我的计件明细', color: AppTheme.infoColor, onTap: () => context.push('/work/piece-records')),
    ])));
  }
}

// ============ 工人个人中心 ============
class WorkerProfileContent extends StatefulWidget {
  const WorkerProfileContent({super.key});
  @override
  State<WorkerProfileContent> createState() => _WorkerProfileContentState();
}

class _WorkerProfileContentState extends State<WorkerProfileContent> {
  void _showChangePasswordDialog() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool isSubmitting = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('修改密码'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: oldCtrl, obscureText: true, decoration: const InputDecoration(labelText: '当前密码', prefixIcon: Icon(Icons.lock_outline))),
              const SizedBox(height: 12),
              TextField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(labelText: '新密码', prefixIcon: Icon(Icons.vpn_key_outlined))),
              const SizedBox(height: 12),
              TextField(controller: confirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: '确认新密码', prefixIcon: Icon(Icons.check_circle_outline))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: isSubmitting ? null : () async {
              if (newCtrl.text.trim().isEmpty || newCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('两次密码输入不一致'), backgroundColor: AppTheme.dangerColor, behavior: SnackBarBehavior.floating));
                return;
              }
              if (newCtrl.text.trim().length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('密码至少6位'), backgroundColor: AppTheme.dangerColor, behavior: SnackBarBehavior.floating));
                return;
              }
              setDialogState(() => isSubmitting = true);
              try {
                await ApiService.instance.put('${ApiConfig.me}/password', data: {
                  'current_password': oldCtrl.text.trim(),
                  'new_password': newCtrl.text.trim(),
                  'new_password_confirmation': confirmCtrl.text.trim(),
                });
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('密码修改成功'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating));
                }
              } catch (e) {
                setDialogState(() => isSubmitting = false);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('修改失败: $e'), backgroundColor: AppTheme.dangerColor, behavior: SnackBarBehavior.floating));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: isSubmitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('确认'),
          ),
        ],
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(backgroundColor: AppTheme.bgPrimary, appBar: AppBar(title: const Text('我的')), body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      Container(padding: const EdgeInsets.all(20), decoration: AppTheme.cardDecoration, child: Row(children: [
        Container(width: 56, height: 56, decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primaryColor, AppTheme.primaryDark]), borderRadius: BorderRadius.circular(16)), child: Center(child: Text((auth.worker?.name ?? '用').substring(0, 1), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)))),
        const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(auth.worker?.name ?? '工人', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)), const SizedBox(height: 4), Text('工号: ${auth.worker?.code ?? "-"}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))])),
      ])),
      const SizedBox(height: 16),
      Container(decoration: AppTheme.cardDecoration, child: Column(children: [
        _ProfileMenuItem(icon: Icons.receipt_long_outlined, title: '我的计件', onTap: () => context.push('/records')),
        _ProfileMenuItem(icon: Icons.account_balance_wallet_outlined, title: '我的薪资', onTap: () => context.go('/salary')),
        _ProfileMenuItem(icon: Icons.notifications_outlined, title: '消息通知', onTap: () => context.push('/notifications')),
        _ProfileMenuItem(icon: Icons.system_update_outlined, title: '检查更新', onTap: () => AppUpdateService().showUpdateDialog(context)),
        _ProfileMenuItem(icon: Icons.lock_outline, title: '修改密码', onTap: _showChangePasswordDialog),
        _ProfileMenuItem(icon: Icons.help_outline, title: '帮助与反馈', showDivider: false, onTap: () => context.push('/management/help-feedback')),
      ])),
      const SizedBox(height: 24),
      SizedBox(width: double.infinity, height: 48, child: OutlinedButton(onPressed: () async { await auth.logout(); if (context.mounted) context.go('/login'); }, style: OutlinedButton.styleFrom(foregroundColor: AppTheme.dangerColor, side: const BorderSide(color: AppTheme.dangerColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('退出登录', style: TextStyle(fontSize: 16)))),
    ])));
  }
}

// ============ 管理员个人中心 ============
class AdminProfileContent extends StatefulWidget {
  const AdminProfileContent({super.key});
  @override
  State<AdminProfileContent> createState() => _AdminProfileContentState();
}

class _AdminProfileContentState extends State<AdminProfileContent> {
  void _showChangePasswordDialog() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool isSubmitting = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('修改密码'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: oldCtrl, obscureText: true, decoration: const InputDecoration(labelText: '当前密码', prefixIcon: Icon(Icons.lock_outline))),
              const SizedBox(height: 12),
              TextField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(labelText: '新密码', prefixIcon: Icon(Icons.vpn_key_outlined))),
              const SizedBox(height: 12),
              TextField(controller: confirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: '确认新密码', prefixIcon: Icon(Icons.check_circle_outline))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: isSubmitting ? null : () async {
              if (newCtrl.text.trim().isEmpty || newCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('两次密码输入不一致'), backgroundColor: AppTheme.dangerColor, behavior: SnackBarBehavior.floating));
                return;
              }
              if (newCtrl.text.trim().length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('密码至少6位'), backgroundColor: AppTheme.dangerColor, behavior: SnackBarBehavior.floating));
                return;
              }
              setDialogState(() => isSubmitting = true);
              try {
                await ApiService.instance.put('${ApiConfig.me}/password', data: {
                  'current_password': oldCtrl.text.trim(),
                  'new_password': newCtrl.text.trim(),
                  'new_password_confirmation': confirmCtrl.text.trim(),
                });
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('密码修改成功'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating));
                }
              } catch (e) {
                setDialogState(() => isSubmitting = false);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('修改失败: $e'), backgroundColor: AppTheme.dangerColor, behavior: SnackBarBehavior.floating));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: isSubmitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('确认'),
          ),
        ],
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(backgroundColor: AppTheme.bgPrimary, appBar: AppBar(title: const Text('我的')), body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      Container(padding: const EdgeInsets.all(20), decoration: AppTheme.cardDecoration, child: Row(children: [
        Container(width: 56, height: 56, decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primaryColor, AppTheme.primaryDark]), borderRadius: BorderRadius.circular(16)), child: const Center(child: Text('管', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)))),
        const SizedBox(width: 16), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('管理员', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)), SizedBox(height: 4), Text('智能工厂管理系统', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary))])),
      ])),
      const SizedBox(height: 16),
      Container(decoration: AppTheme.cardDecoration, child: Column(children: [
        _ProfileMenuItem(icon: Icons.diamond_outlined, title: '订阅管理', onTap: () => context.push('/management/subscription')),
        _ProfileMenuItem(icon: Icons.support_agent_outlined, title: '工单支持', onTap: () => context.push('/management/tickets')),
        _ProfileMenuItem(icon: Icons.system_update_outlined, title: '检查更新', onTap: () => AppUpdateService().showUpdateDialog(context)),
        _ProfileMenuItem(icon: Icons.lock_outline, title: '修改密码', onTap: _showChangePasswordDialog),
        _ProfileMenuItem(icon: Icons.help_outline, title: '帮助与反馈', showDivider: false, onTap: () => context.push('/management/help-feedback')),
      ])),
      const SizedBox(height: 24),
      SizedBox(width: double.infinity, height: 48, child: OutlinedButton(onPressed: () async { await auth.logout(); if (context.mounted) context.go('/login'); }, style: OutlinedButton.styleFrom(foregroundColor: AppTheme.dangerColor, side: const BorderSide(color: AppTheme.dangerColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('退出登录', style: TextStyle(fontSize: 16)))),
    ])));
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Expanded(child: GestureDetector(onTap: onTap, child: Column(children: [
      Container(width: 52, height: 52, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 26)),
      const SizedBox(height: 8), Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
    ])));
  }
}

class _WorkMenuItem extends StatelessWidget {
  final IconData icon; final String title; final String subtitle; final Color color; final VoidCallback onTap;
  const _WorkMenuItem({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(16), decoration: AppTheme.cardDecoration, child: Row(children: [
      Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 24)),
      const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)), const SizedBox(height: 2), Text(subtitle, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))])),
      const Icon(Icons.chevron_right, color: AppTheme.textHint),
    ]))));
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon; final String title; final VoidCallback onTap; final bool showDivider;
  const _ProfileMenuItem({required this.icon, required this.title, required this.onTap, this.showDivider = true});
  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), child: Column(children: [
      Row(children: [Icon(icon, size: 22, color: AppTheme.textSecondary), const SizedBox(width: 12), Expanded(child: Text(title, style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary))), const Icon(Icons.chevron_right, size: 20, color: AppTheme.textHint)]),
      if (showDivider) Padding(padding: const EdgeInsets.only(left: 34, top: 12), child: Divider(height: 1, color: AppTheme.border.withOpacity(0.5))),
    ])));
  }
}
