class ApiConfig {
  static const String baseUrl = 'http://118.196.72.190/api';

  static const String appVersionCheck = '/app/v2/version/check';

  // Auth
  static const String authLogin = '/auth/login';
  static const String authTenants = '/auth/tenants';
  static const String me = '/me';

  // Worker App
  static const String workerAppLogin = '/worker-app/login';
  static const String workerMyTasks = '/worker-app/my-tasks';
  static const String workerMyTaskDetail = '/worker-app/my-tasks';
  static const String workerSubmitPiece = '/worker-app/submit-piece';
  static const String workerMyPieceRecords = '/worker-app/my-piece-records';
  static const String workerMySalary = '/worker-app/my-salary';
  static const String workerMyAdvances = '/worker-app/my-advances';
  static const String workerApplyAdvance = '/worker-app/apply-advance';
  static const String workerMySettlements = '/worker-app/my-settlements';
  static const String workerMyNotifications = '/worker-app/my-notifications';
  static const String workerWorkStats = '/worker-app/work-stats';
  static const String workerCheckin = '/worker-app/checkin';
  static const String workerCheckinToday = '/worker-app/checkin/today';

  // Dashboard
  static const String dashboardStatistics = '/tenant/dashboard/statistics';
  static const String dashboardOrderStatus = '/tenant/dashboard/order-status-distribution';
  static const String dashboardProductionProgress = '/tenant/dashboard/production-progress';
  static const String dashboardCostTrend = '/tenant/dashboard/cost-trend';
  static const String dashboardQualityRate = '/tenant/dashboard/quality-rate';

  // Production
  static const String productionOrders = '/tenant/production-orders';
  static const String productionOrderSchedule = '/tenant/production-orders/{id}/schedule';
  static const String productionOrderStart = '/tenant/production-orders/{id}/start';
  static const String productionOrderPreCompleteCheck = '/tenant/production-orders/{id}/pre-complete-check';
  static const String productionOrderComplete = '/tenant/production-orders/{id}/complete';
  static const String productionOrderCancel = '/tenant/production-orders/{id}/cancel';
  static const String productionTasks = '/tenant/production-tasks';
  static const String productionTaskAssign = '/tenant/production-tasks/{id}/assign';
  static const String productionTaskStatus = '/tenant/production-tasks/{id}/status';
  static const String workReports = '/tenant/work-reports';
  static const String qualityInspections = '/tenant/quality-inspections';

  // Orders & Business
  static const String orders = '/tenant/orders';
  static const String orderApprove = '/tenant/orders/{id}/approve';
  static const String orderReject = '/tenant/orders/{id}/reject';
  static const String customers = '/tenant/customers';
  static const String costRecords = '/tenant/cost-records';
  static const String costStatisticsSummary = '/tenant/cost-statistics/summary';
  static const String costStatisticsByPeriod = '/tenant/cost-statistics/by-period';
  static const String costStatisticsByType = '/tenant/cost-statistics/by-type';

  // Supply Chain
  static const String purchaseOrders = '/tenant/purchase-orders';
  static const String purchaseOrderApprove = '/tenant/purchase-orders/{id}/approve';
  static const String purchaseOrderReject = '/tenant/purchase-orders/{id}/reject';
  static const String suppliers = '/tenant/suppliers';
  static const String outsourcingPartners = '/tenant/outsourcing-partners';
  static const String outsourcingOrders = '/tenant/outsourcing-orders';
  static const String warehouses = '/tenant/warehouses';
  static const String inventories = '/tenant/inventories';
  static const String stockMovements = '/tenant/stock-movements';

  // Workers & HR
  static const String workers = '/tenant/workers';
  static const String workerResetPin = '/tenant/workers/{id}/reset-pin';
  static const String workerPieceRecords = '/tenant/worker-piece-records';
  static const String workerPieceRecordsApprove = '/tenant/worker-piece-records/approve';
  static const String workerPieceRecordsReject = '/tenant/worker-piece-records/reject';
  static const String workerAdvances = '/tenant/worker-advances';
  static const String workerAdvanceApprove = '/tenant/worker-advances/{id}/approve';
  static const String workerAdvanceReject = '/tenant/worker-advances/{id}/reject';
  static const String workerAdvanceMarkPaid = '/tenant/worker-advances/{id}/mark-paid';

  // Financial Reports
  static const String financialProfitOverview = '/tenant/financial-reports/profit-overview';
  static const String financialOrderProfit = '/tenant/financial-reports/order-profit';
  static const String financialProductCost = '/tenant/financial-reports/product-cost';
  static const String financialCostStructure = '/tenant/financial-reports/cost-structure';
  static const String financialMonthlyTrend = '/tenant/financial-reports/monthly-trend';
  static const String financialBudgetManagement = '/tenant/financial-reports/budget-management';
  static const String financialCashFlow = '/tenant/financial-reports/cash-flow';
  static const String financialReceivablePayable = '/tenant/financial-reports/receivable-payable';
  static const String financialDashboard = '/tenant/financial-dashboard';
  static const String financialIncomeExpense = '/tenant/financial-dashboard/income-expense';
  static const String financialReceivablePayableNew = '/tenant/financial-dashboard/receivable-payable';
  static const String financialWageSummary = '/tenant/financial-dashboard/wage-summary';
  static const String paymentRecords = '/tenant/payment-records';
  static const String workerSettlements = '/tenant/worker-settlements';
  static const String workerSettlementsGenerate = '/tenant/worker-settlements/generate';
  static const String workerSettlementsConfirm = '/tenant/worker-settlements/{id}/confirm';
  static const String workerSettlementsPay = '/tenant/worker-settlements/{id}/pay';
  static const String workerCheckins = '/tenant/worker-checkins';
  static const String workerCheckinsDailySummary = '/tenant/worker-checkins/daily-summary';
  static const String workerCheckinsMonthlyStats = '/tenant/worker-checkins/monthly-stats';
  static const String workerSalary = '/tenant/worker-salary';
  static const String workerSalarySummary = '/tenant/worker-salary/summary';
  static const String workerSalaryByProcess = '/tenant/worker-salary/by-process';
  static const String workerSalaryByPeriod = '/tenant/worker-salary/by-period';

  // Base Data
  static const String products = '/tenant/products';
  static const String materials = '/tenant/materials';
  static const String productCategories = '/tenant/product-categories';
  static const String bomItems = '/tenant/bom-items';
  static const String processes = '/tenant/processes';
  static const String processRoutes = '/tenant/process-routes';

  // System
  static const String users = '/tenant/users';
  static const String roles = '/tenant/roles';
  static const String subscriptionCurrent = '/tenant/my-subscription/current';
  static const String subscriptionHistory = '/tenant/my-subscription/history';
  static const String subscriptionPlans = '/tenant/subscription-plans';
  static const String paymentCreate = '/tenant/payment/create';
  static const String paymentQuery = '/tenant/payment/query';
  static const String tickets = '/tenant/tickets';
  static const String notifications = '/tenant/notifications';
  static const String notificationsUnreadCount = '/tenant/notifications/unread-count';
  static const String notificationsMarkAllRead = '/tenant/notifications/mark-all-read';

  static String replaceId(String path, int id) {
    return path.replaceAll('{id}', id.toString());
  }
}
