class DashboardStats {
  final int totalOrders;
  final int pendingOrders;
  final int inProgressOrders;
  final int completedOrders;
  final int totalProductionOrders;
  final int pendingProductionOrders;
  final int completedProductionOrders;
  final int inventoryWarning;
  final double completionRate;

  DashboardStats({
    this.totalOrders = 0,
    this.pendingOrders = 0,
    this.inProgressOrders = 0,
    this.completedOrders = 0,
    this.totalProductionOrders = 0,
    this.pendingProductionOrders = 0,
    this.completedProductionOrders = 0,
    this.inventoryWarning = 0,
    this.completionRate = 0,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalOrders: json['total_orders'] ?? 0,
      pendingOrders: json['pending_orders'] ?? 0,
      inProgressOrders: json['in_production_orders'] ?? json['in_progress_orders'] ?? 0,
      completedOrders: json['completed_orders'] ?? 0,
      totalProductionOrders: json['total_production_orders'] ?? 0,
      pendingProductionOrders: json['pending_production_orders'] ?? 0,
      completedProductionOrders: json['completed_production_orders'] ?? 0,
      inventoryWarning: json['inventory_warning'] ?? json['low_stock_items'] ?? 0,
      completionRate: _parseDouble(json['completion_rate']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

class OrderStatusItem {
  final String status;
  final int count;

  OrderStatusItem({required this.status, required this.count});

  factory OrderStatusItem.fromJson(Map<String, dynamic> json) {
    return OrderStatusItem(
      status: json['status'] ?? '',
      count: json['count'] ?? 0,
    );
  }

  String get statusLabel {
    const map = {
      'pending': '待审核',
      'approved': '已审核',
      'in_production': '生产中',
      'completed': '已完成',
      'cancelled': '已取消',
    };
    return map[status] ?? status;
  }
}

class ProductionProgressItem {
  final String orderNo;
  final String? productName;
  final double quantity;
  final double completedQty;
  final String status;

  ProductionProgressItem({
    required this.orderNo,
    this.productName,
    required this.quantity,
    required this.completedQty,
    required this.status,
  });

  factory ProductionProgressItem.fromJson(Map<String, dynamic> json) {
    return ProductionProgressItem(
      orderNo: json['order_no'] ?? '',
      productName: json['product_name'],
      quantity: DashboardStats._parseDouble(json['quantity']),
      completedQty: DashboardStats._parseDouble(json['completed_qty']),
      status: json['status'] ?? '',
    );
  }

  double get progress => quantity > 0 ? completedQty / quantity : 0;
}
