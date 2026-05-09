class WarehouseModel {
  final int id;
  final String code;
  final String name;
  final String? type;
  final String? location;
  final int? managerId;
  final int status;
  final String? remark;

  WarehouseModel({
    required this.id,
    required this.code,
    required this.name,
    this.type,
    this.location,
    this.managerId,
    required this.status,
    this.remark,
  });

  factory WarehouseModel.fromJson(Map<String, dynamic> json) {
    return WarehouseModel(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      type: json['type'],
      location: json['location'],
      managerId: json['manager_id'],
      status: json['status'] ?? 1,
      remark: json['remark'],
    );
  }

  String get typeLabel {
    const map = {
      'raw': '原材料仓',
      'finished': '成品仓',
      'semi': '半成品仓',
      'other': '其他',
    };
    return map[type] ?? '仓库';
  }
}
