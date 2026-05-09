class WorkerModel {
  final int id;
  final String code;
  final String name;
  final String? phone;
  final String? skillType;
  final String status;
  final int? userId;

  WorkerModel({
    required this.id,
    required this.code,
    required this.name,
    this.phone,
    this.skillType,
    required this.status,
    this.userId,
  });

  factory WorkerModel.fromJson(Map<String, dynamic> json) {
    return WorkerModel(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      skillType: json['skill_type'],
      status: json['status'] ?? 'active',
      userId: json['user_id'],
    );
  }

  String get skillTypeLabel {
    const map = {
      '裁剪': '裁剪',
      '缝制': '缝制',
      '整烫': '整烫',
      '检验': '检验',
      '包装': '包装',
      '综合': '综合',
      'cutting': '裁剪',
      'sewing': '缝制',
      'ironing': '整烫',
      'inspecting': '检验',
      'packing': '包装',
      'general': '综合',
    };
    return map[skillType] ?? skillType ?? '未设置';
  }
}
