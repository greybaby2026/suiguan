class ProductionTaskModel {
  final int id;
  final int? productionOrderId;
  final int? processId;
  final String? processName;
  final int? assigneeId;
  final double quantity;
  final double completedQty;
  final dynamic status;
  final String? remark;
  final String? orderNo;
  final String? productName;
  final double pendingQty;
  final double remainingQty;
  final double availableQty;

  ProductionTaskModel({
    required this.id,
    this.productionOrderId,
    this.processId,
    this.processName,
    this.assigneeId,
    required this.quantity,
    required this.completedQty,
    required this.status,
    this.remark,
    this.orderNo,
    this.productName,
    this.pendingQty = 0,
    this.remainingQty = 0,
    this.availableQty = 0,
  });

  factory ProductionTaskModel.fromJson(Map<String, dynamic> json) {
    return ProductionTaskModel(
      id: json['id'] ?? 0,
      productionOrderId: json['production_order_id'],
      processId: json['process_id'],
      processName: json['process']?['name'] ?? json['process_name'],
      assigneeId: json['assignee_id'],
      quantity: _parseDouble(json['quantity']),
      completedQty: _parseDouble(json['completed_quantity'] ?? json['completed_qty']),
      status: json['status'] ?? 'pending',
      remark: json['remark'],
      orderNo: json['order_no'] ?? json['production_order']?['order_no'],
      productName: json['product_name'] ?? json['production_order']?['product']?['name'],
      pendingQty: _parseDouble(json['pending_qty']),
      remainingQty: _parseDouble(json['remaining_qty']),
      availableQty: _parseDouble(json['available_qty']),
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
      '1': '待开工',
      '2': '进行中',
      '3': '已完成',
      '4': '已取消',
    };
    return map[statusStr] ?? '未知';
  }
}
