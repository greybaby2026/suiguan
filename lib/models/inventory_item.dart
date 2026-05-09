class InventoryItemModel {
  final int id;
  final int? warehouseId;
  final String? warehouseName;
  final String itemType;
  final int? itemId;
  final String? itemName;
  final String? itemCode;
  final String? itemSpec;
  final String? itemUnit;
  final double quantity;
  final double? safetyStock;

  InventoryItemModel({
    required this.id,
    this.warehouseId,
    this.warehouseName,
    required this.itemType,
    this.itemId,
    this.itemName,
    this.itemCode,
    this.itemSpec,
    this.itemUnit,
    required this.quantity,
    this.safetyStock,
  });

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryItemModel(
      id: json['id'] ?? 0,
      warehouseId: json['warehouse_id'],
      warehouseName: json['warehouse']?['name'],
      itemType: json['item_type'] ?? 'material',
      itemId: json['item_id'],
      itemName: json['item']?['name'],
      itemCode: json['item']?['code'],
      itemSpec: json['item']?['spec'],
      itemUnit: json['item']?['unit'],
      quantity: _parseDouble(json['quantity']),
      safetyStock: json['safety_stock'] != null ? _parseDouble(json['safety_stock']) : null,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  bool get isLowStock => safetyStock != null && quantity < safetyStock!;
}
