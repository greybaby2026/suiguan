class ProductionOrderModel {
  final int id;
  final String orderNo;
  final int? orderId;
  final int? orderItemId;
  final int? productId;
  final String? productName;
  final double quantity;
  final double completedQty;
  final dynamic status;
  final String? plannedStart;
  final String? plannedEnd;
  final String? actualStart;
  final String? actualEnd;
  final String? remark;
  final String? sourceOrderNo;
  final int? processRouteId;
  final String? processRouteName;
  final List<ProductionTaskDetailModel> tasks;

  ProductionOrderModel({
    required this.id,
    required this.orderNo,
    this.orderId,
    this.orderItemId,
    this.productId,
    this.productName,
    required this.quantity,
    required this.completedQty,
    required this.status,
    this.plannedStart,
    this.plannedEnd,
    this.actualStart,
    this.actualEnd,
    this.remark,
    this.sourceOrderNo,
    this.processRouteId,
    this.processRouteName,
    this.tasks = const [],
  });

  factory ProductionOrderModel.fromJson(Map<String, dynamic> json) {
    return ProductionOrderModel(
      id: json['id'] ?? 0,
      orderNo: json['order_no'] ?? '',
      orderId: json['order_id'],
      orderItemId: json['order_item_id'],
      productId: json['product_id'],
      productName: json['product']?['name'],
      quantity: _parseDouble(json['quantity']),
      completedQty: _parseDouble(json['completed_quantity'] ?? json['completed_qty']),
      status: json['status'] ?? 'pending',
      plannedStart: json['planned_start_date'] ?? json['planned_start'],
      plannedEnd: json['planned_end_date'] ?? json['planned_end'],
      actualStart: json['actual_start'],
      actualEnd: json['actual_end'],
      remark: json['remark'],
      sourceOrderNo: json['source_order_no'],
      processRouteId: json['process_route_id'],
      processRouteName: json['process_route']?['name'],
      tasks: _parseTasks(json['tasks']),
    );
  }

  static List<ProductionTaskDetailModel> _parseTasks(dynamic tasksJson) {
    if (tasksJson is List) {
      return tasksJson
          .map((e) => ProductionTaskDetailModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  double get progress => quantity > 0 ? completedQty / quantity : 0;

  String get statusStr {
    if (status is int) {
      const intMap = {1: 'pending', 2: 'scheduled', 3: 'in_production', 4: 'completed', 5: 'cancelled'};
      return intMap[status] ?? status.toString();
    }
    return status.toString();
  }

  String get statusLabel {
    const map = {
      'pending': '待排产',
      'scheduled': '已排产',
      'in_production': '生产中',
      'completed': '已完成',
      'cancelled': '已取消',
      '1': '待排产',
      '2': '已排产',
      '3': '生产中',
      '4': '已完成',
      '5': '已取消',
    };
    return map[statusStr] ?? '未知';
  }

  int get statusColor {
    const map = {
      'pending': 0xFFF59E0B,
      'scheduled': 0xFF6366F1,
      'in_production': 0xFF2563EB,
      'completed': 0xFF10B981,
      'cancelled': 0xFFEF4444,
      '1': 0xFFF59E0B,
      '2': 0xFF6366F1,
      '3': 0xFF2563EB,
      '4': 0xFF10B981,
      '5': 0xFFEF4444,
    };
    return map[statusStr] ?? 0xFF64748B;
  }
}

class ProductionTaskDetailModel {
  final int id;
  final int? productionOrderId;
  final int? processId;
  final String? processName;
  final int? stepOrder;
  final int? assigneeId;
  final String? assigneeName;
  final double quantity;
  final double completedQty;
  final dynamic status;
  final String? startedAt;
  final String? completedAt;
  final String? remark;

  ProductionTaskDetailModel({
    required this.id,
    this.productionOrderId,
    this.processId,
    this.processName,
    this.stepOrder,
    this.assigneeId,
    this.assigneeName,
    required this.quantity,
    required this.completedQty,
    required this.status,
    this.startedAt,
    this.completedAt,
    this.remark,
  });

  factory ProductionTaskDetailModel.fromJson(Map<String, dynamic> json) {
    return ProductionTaskDetailModel(
      id: json['id'] ?? 0,
      productionOrderId: json['production_order_id'],
      processId: json['process_id'],
      processName: json['process']?['name'] ?? json['process_name'],
      stepOrder: json['step_order'],
      assigneeId: json['assignee_id'],
      assigneeName: json['assignee']?['name'],
      quantity: _parseDouble(json['quantity']),
      completedQty: _parseDouble(json['completed_qty']),
      status: json['status'] ?? 'pending',
      startedAt: json['started_at'],
      completedAt: json['completed_at'],
      remark: json['remark'],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  double get progress => quantity > 0 ? completedQty / quantity : 0;

  String get statusStr {
    if (status is int) {
      const intMap = {1: 'pending', 2: 'in_progress', 3: 'completed', 4: 'cancelled'};
      return intMap[status] ?? status.toString();
    }
    return status.toString();
  }

  String get statusLabel {
    const map = {
      'pending': '待开工',
      'in_progress': '进行中',
      'completed': '已完成',
      'cancelled': '已取消',
    };
    return map[statusStr] ?? '未知';
  }

  int get statusColor {
    const map = {
      'pending': 0xFFF59E0B,
      'in_progress': 0xFF2563EB,
      'completed': 0xFF10B981,
      'cancelled': 0xFFEF4444,
    };
    return map[statusStr] ?? 0xFF64748B;
  }
}
