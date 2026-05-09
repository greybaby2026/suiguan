import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../pages/splash/splash_page.dart';
import '../pages/login/login_page.dart';
import '../pages/home/home_page.dart';
import '../pages/production/production_list_page.dart';
import '../pages/production/production_detail_page.dart';
import '../pages/work/work_report_page.dart';
import '../pages/work/work_checkin_page.dart';
import '../pages/work/checkin_record_page.dart';
import '../pages/work/piece_record_page.dart';
import '../pages/warehouse/warehouse_scan_page.dart';
import '../pages/warehouse/warehouse_manage_page.dart';
import '../pages/warehouse/inventory_page.dart';
import '../pages/warehouse/stock_movement_page.dart';
import '../pages/notification/notification_list_page.dart';
import '../pages/salary/salary_page.dart';
import '../pages/salary/advance_apply_page.dart';
import '../pages/supply/supply_center_page.dart';
import '../pages/supply/purchase_order_page.dart';
import '../pages/supply/supplier_page.dart';
import '../pages/supply/outsourcing_page.dart';
import '../pages/supply/outsourcing_partner_page.dart';
import '../pages/supply/inventory_query_page.dart';
import '../pages/supply/stock_operation_page.dart';
import '../pages/business/business_center_page.dart';
import '../pages/business/order_list_page.dart';
import '../pages/business/order_create_page.dart';
import '../pages/business/customer_page.dart';
import '../pages/business/cost_overview_page.dart';
import '../pages/business/cost_record_page.dart';
import '../pages/financial/financial_overview_page.dart';
import '../pages/financial/financial_center_page.dart';
import '../pages/financial/financial_dashboard_page.dart';
import '../pages/financial/income_expense_page.dart';
import '../pages/financial/receivable_payable_page.dart';
import '../pages/financial/wage_summary_page.dart';
import '../pages/management/management_center_page.dart';
import '../pages/management/worker_manage_page.dart';
import '../pages/management/advance_manage_page.dart';
import '../pages/management/settlement_manage_page.dart';
import '../pages/management/salary_report_page.dart';
import '../pages/management/piece_approval_page.dart';
import '../pages/management/base_data_page.dart';
import '../pages/management/user_manage_page.dart';
import '../pages/management/role_manage_page.dart';
import '../pages/management/subscription_page.dart';
import '../pages/management/help_feedback_page.dart';
import '../pages/management/ticket_page.dart';
import '../pages/quality/quality_inspection_page.dart';
import '../pages/quality/quality_report_page.dart';
import '../pages/management/product_list_page.dart';
import '../pages/management/material_list_page.dart';
import '../pages/management/category_list_page.dart';
import '../pages/management/bom_list_page.dart';
import '../pages/management/process_list_page.dart';
import '../pages/management/process_route_list_page.dart';
import '../pages/approval/approval_center_page.dart';
import '../providers/auth_provider.dart' as app_auth;

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  debugLogDiagnostics: true,
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => HomePage(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) {
            final auth = context.read<app_auth.AuthProvider>();
            return NoTransitionPage(child: auth.isWorker ? const WorkerDashboardContent() : const AdminDashboardContent());
          },
        ),
        GoRoute(
          path: '/records',
          pageBuilder: (context, state) => const NoTransitionPage(child: WorkerRecordsContent()),
        ),
        GoRoute(
          path: '/salary',
          pageBuilder: (context, state) => const NoTransitionPage(child: WorkerSalaryContent()),
          routes: [
            GoRoute(path: 'apply-advance', parentNavigatorKey: _rootNavigatorKey, builder: (context, state) => const AdvanceApplyPage()),
          ],
        ),
        GoRoute(
          path: '/work',
          pageBuilder: (context, state) => const NoTransitionPage(child: WorkerWorkContent()),
          routes: [
            GoRoute(path: 'report', parentNavigatorKey: _rootNavigatorKey, builder: (context, state) => const WorkReportPage()),
            GoRoute(path: 'checkin', parentNavigatorKey: _rootNavigatorKey, builder: (context, state) => const WorkCheckinPage()),
            GoRoute(path: 'piece-records', parentNavigatorKey: _rootNavigatorKey, builder: (context, state) => const PieceRecordPage()),
          ],
        ),
        GoRoute(
          path: '/notifications',
          pageBuilder: (context, state) => const NoTransitionPage(child: NotificationListPage(isEmbedded: true)),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) {
            final auth = context.read<app_auth.AuthProvider>();
            return NoTransitionPage(child: auth.isWorker ? const WorkerProfileContent() : const AdminProfileContent());
          },
        ),
        GoRoute(
          path: '/production',
          pageBuilder: (context, state) => const NoTransitionPage(child: ProductionListPage()),
          routes: [
            GoRoute(path: ':id', parentNavigatorKey: _rootNavigatorKey, builder: (context, state) => ProductionDetailPage(orderId: int.parse(state.pathParameters['id']!))),
          ],
        ),
        GoRoute(
          path: '/supply',
          pageBuilder: (context, state) => const NoTransitionPage(child: SupplyCenterPage()),
        ),
        GoRoute(
          path: '/business',
          pageBuilder: (context, state) => const NoTransitionPage(child: BusinessCenterPage()),
        ),
        GoRoute(
          path: '/management',
          pageBuilder: (context, state) => const NoTransitionPage(child: ManagementCenterPage()),
        ),
      ],
    ),
    GoRoute(path: '/approval-center', builder: (context, state) => const ApprovalCenterPage()),
    GoRoute(path: '/warehouse', builder: (context, state) => const WarehouseScanPage(), routes: [
      GoRoute(path: 'inventory', builder: (context, state) => const InventoryPage()),
      GoRoute(path: 'movements', builder: (context, state) => const StockMovementPage()),
    ]),
    GoRoute(path: '/warehouse/manage', builder: (context, state) => const WarehouseManagePage()),
    GoRoute(path: '/supply/purchase-orders', builder: (context, state) => const PurchaseOrderPage()),
    GoRoute(path: '/supply/suppliers', builder: (context, state) => const SupplierPage()),
    GoRoute(path: '/supply/outsourcing', builder: (context, state) => const OutsourcingPage()),
    GoRoute(path: '/supply/outsourcing-partners', builder: (context, state) => const OutsourcingPartnerPage()),
    GoRoute(path: '/supply/inventory-query', builder: (context, state) => const InventoryQueryPage()),
    GoRoute(path: '/supply/stock-operation', builder: (context, state) => const StockOperationPage()),
    GoRoute(path: '/business/orders', builder: (context, state) => const OrderListPage()),
    GoRoute(path: '/business/orders/create', builder: (context, state) => const OrderCreatePage()),
    GoRoute(path: '/business/customers', builder: (context, state) => const CustomerPage()),
    GoRoute(path: '/business/cost-overview', builder: (context, state) => const CostOverviewPage()),
    GoRoute(path: '/business/cost-records', builder: (context, state) => const CostRecordPage()),
    GoRoute(path: '/financial/center', builder: (context, state) => const FinancialCenterPage()),
    GoRoute(path: '/financial/overview', builder: (context, state) => const FinancialOverviewPage()),
    GoRoute(path: '/financial/dashboard', builder: (context, state) => const FinancialDashboardPage()),
    GoRoute(path: '/financial/income-expense', builder: (context, state) => const IncomeExpensePage()),
    GoRoute(path: '/financial/receivable-payable', builder: (context, state) => const ReceivablePayablePage()),
    GoRoute(path: '/financial/wage-summary', builder: (context, state) => const WageSummaryPage()),
    GoRoute(path: '/management/workers', builder: (context, state) => const WorkerManagePage()),
    GoRoute(path: '/management/advances', builder: (context, state) => const AdvanceManagePage()),
    GoRoute(path: '/management/settlements', builder: (context, state) => const SettlementManagePage()),
    GoRoute(path: '/management/salary-report', builder: (context, state) => const SalaryReportPage()),
    GoRoute(path: '/management/piece-approval', builder: (context, state) => const PieceApprovalPage()),
    GoRoute(path: '/management/base-data', builder: (context, state) => const BaseDataPage()),
    GoRoute(path: '/management/products', builder: (context, state) => const ProductListPage()),
    GoRoute(path: '/management/materials', builder: (context, state) => const MaterialListPage()),
    GoRoute(path: '/management/product-categories', builder: (context, state) => const CategoryListPage()),
    GoRoute(path: '/management/bom-items', builder: (context, state) => const BomListPage()),
    GoRoute(path: '/management/processes', builder: (context, state) => const ProcessListPage()),
    GoRoute(path: '/management/process-routes', builder: (context, state) => const ProcessRouteListPage()),
    GoRoute(path: '/management/users', builder: (context, state) => const UserManagePage()),
    GoRoute(path: '/management/roles', builder: (context, state) => const RoleManagePage()),
    GoRoute(path: '/management/subscription', builder: (context, state) => const SubscriptionPage()),
    GoRoute(path: '/management/help-feedback', builder: (context, state) => const HelpFeedbackPage()),
    GoRoute(path: '/management/tickets', builder: (context, state) => const TicketPage()),
    GoRoute(path: '/management/checkin-records', builder: (context, state) => const CheckinRecordPage()),
    GoRoute(path: '/management/quality-inspections', builder: (context, state) => const QualityInspectionPage()),
    GoRoute(path: '/management/quality-report', builder: (context, state) => const QualityReportPage()),
  ],
  redirect: (context, state) {
    final auth = context.read<app_auth.AuthProvider>();
    final isLoggedIn = auth.isAuthenticated;
    final isSplash = state.matchedLocation == '/splash';
    final isLogin = state.matchedLocation == '/login';
    if (isSplash) return null;
    if (!isLoggedIn && !isLogin) return '/login';
    if (isLoggedIn && isLogin) return '/dashboard';
    return null;
  },
);
