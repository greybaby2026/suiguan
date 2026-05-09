class UserModel {
  final int id;
  final int? tenantId;
  final String name;
  final String? email;
  final String? phone;
  final String? avatar;
  final int status;
  final String? lastLoginAt;

  UserModel({
    required this.id,
    this.tenantId,
    required this.name,
    this.email,
    this.phone,
    this.avatar,
    required this.status,
    this.lastLoginAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      tenantId: json['tenant_id'],
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      avatar: json['avatar'],
      status: json['status'] ?? 1,
      lastLoginAt: json['last_login_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'status': status,
      'last_login_at': lastLoginAt,
    };
  }
}
