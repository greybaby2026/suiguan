import '../config/api_config.dart';
import '../models/notification.dart';
import 'api_service.dart';

class NotificationService {
  final ApiService _api = ApiService.instance;

  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _api.get(
      ApiConfig.notifications,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
      },
    );

    final data = response['data'] ?? response;
    if (data is List) {
      return data.map((e) => NotificationModel.fromJson(e)).toList();
    }
    if (data is Map && data.containsKey('data')) {
      final list = data['data'] as List;
      return list.map((e) => NotificationModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<int> getUnreadCount() async {
    final response = await _api.get(ApiConfig.notificationsUnreadCount);
    final data = response['data'] ?? response;
    return data['count'] ?? data['unread_count'] ?? 0;
  }

  Future<void> markAllRead() async {
    await _api.post(ApiConfig.notificationsMarkAllRead);
  }

  Future<void> markAsRead(int id) async {
    await _api.get('${ApiConfig.notifications}/$id');
  }

  Future<void> deleteNotification(int id) async {
    await _api.delete('${ApiConfig.notifications}/$id');
  }
}
