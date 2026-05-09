class FeatureConfig {
  static const String productManagement = 'product_management';
  static const String orderManagement = 'order_management';
  static const String productionManagement = 'production_management';
  static const String workerManagement = 'worker_management';
  static const String basicReport = 'basic_report';
  static const String purchaseManagement = 'purchase_management';
  static const String warehouseManagement = 'warehouse_management';
  static const String qualityManagement = 'quality_management';
  static const String costManagement = 'cost_management';
  static const String outsourcingManagement = 'outsourcing_management';
  static const String advancedReport = 'advanced_report';
  static const String dataExport = 'data_export';
  static const String dedicatedSupport = 'dedicated_support';
  static const String apiAccess = 'api_access';

  static const Map<String, String> featureNames = {
    productManagement: '产品管理',
    orderManagement: '订单管理',
    productionManagement: '生产管理',
    workerManagement: '工人管理',
    basicReport: '基础报表',
    purchaseManagement: '采购管理',
    warehouseManagement: '仓库管理',
    qualityManagement: '质量管理',
    costManagement: '成本管理',
    outsourcingManagement: '外发管理',
    advancedReport: '高级报表',
    dataExport: '数据导出',
    dedicatedSupport: '专属客服',
    apiAccess: 'API接入',
  };

  static String getFeatureName(String key) =>
      featureNames[key] ?? key;

  static const Map<String, String> menuFeatureMap = {
    'supply': purchaseManagement,
    'warehouse': warehouseManagement,
    'quality': qualityManagement,
    'cost': costManagement,
    'outsourcing': outsourcingManagement,
  };

  static String? getRequiredFeature(String menuKey) =>
      menuFeatureMap[menuKey];
}
