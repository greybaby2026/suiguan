class NotificationModel {
  final int id;
  final String title;
  final String content;
  final String type;
  final bool isRead;
  final String? readAt;
  final String? sourceType;
  final int? sourceId;
  final String? createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.isRead,
    this.readAt,
    this.sourceType,
    this.sourceId,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? 'system',
      isRead: json['is_read'] == true || json['is_read'] == 1,
      readAt: json['read_at'],
      sourceType: json['source_type'],
      sourceId: json['source_id'],
      createdAt: json['created_at'],
    );
  }

  String get typeLabel {
    const map = {
      'system': '系统通知',
      'order': '订单通知',
      'production': '生产通知',
      'approval': '审批通知',
      'warehouse': '仓库通知',
      'quality': '质量通知',
    };
    return map[type] ?? '通知';
  }

  int get typeIcon {
    const map = {
      'system': 0xE88E,
      'order': 0xE8CC,
      'production': 0xE8F1,
      'approval': 0xE8D5,
      'warehouse': 0xE8D4,
      'quality': 0xE8D0,
    };
    return map[type] ?? 0xE88E;
  }
}
