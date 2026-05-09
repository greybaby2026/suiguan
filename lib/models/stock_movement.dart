import '../utils/number_utils.dart';

class StockMovementModel {
  final int id;
  final int? warehouseId;
  final String? warehouseName;
  final String itemType;
  final int? itemId;
  final String? itemName;
  final String type;
  final double quantity;
  final double beforeQty;
  final double afterQty;
  final String? sourceType;
  final int? sourceId;
  final int? operatorId;
  final String? operatorName;
  final String? remark;
  final String? createdAt;

  StockMovementModel({
    required this.id,
    this.warehouseId,
    this.warehouseName,
    required this.itemType,
    this.itemId,
    this.itemName,
    required this.type,
    required this.quantity,
    required this.beforeQty,
    required this.afterQty,
    this.sourceType,
    this.sourceId,
    this.operatorId,
    this.operatorName,
    this.remark,
    this.createdAt,
  });

  factory StockMovementModel.fromJson(Map<String, dynamic> json) {
    return StockMovementModel(
      id: json['id'] ?? 0,
      warehouseId: json['warehouse_id'],
      warehouseName: json['warehouse']?['name'],
      itemType: json['item_type'] ?? 'material',
      itemId: json['item_id'],
      itemName: json['item']?['name'],
      type: json['type'] ?? 'in',
      quantity: safeToDouble(json['quantity']),
      beforeQty: safeToDouble(json['before_qty']),
      afterQty: safeToDouble(json['after_qty']),
      sourceType: json['source_type'],
      sourceId: json['source_id'],
      operatorId: json['operator_id'],
      operatorName: json['operator']?['name'],
      remark: json['remark'],
      createdAt: json['created_at'],
    );
  }

  bool get isIn => type == 'in';
  String get typeLabel => isIn ? '入库' : '出库';
}
