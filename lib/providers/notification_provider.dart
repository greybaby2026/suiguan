import '../services/api_service.dart';
import 'package:flutter/foundation.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notifications = await _service.getNotifications();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = ApiException.fromDynamic(e).friendlyMessage;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      _unreadCount = await _service.getUnreadCount();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await _service.markAllRead();
      _unreadCount = 0;
      for (var n in _notifications) {
        _notifications[_notifications.indexOf(n)] = NotificationModel(
          id: n.id,
          title: n.title,
          content: n.content,
          type: n.type,
          isRead: true,
          readAt: DateTime.now().toIso8601String(),
          sourceType: n.sourceType,
          sourceId: n.sourceId,
          createdAt: n.createdAt,
        );
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markAsRead(int id) async {
    try {
      await _service.markAsRead(id);
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1 && !_notifications[index].isRead) {
        _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          title: _notifications[index].title,
          content: _notifications[index].content,
          type: _notifications[index].type,
          isRead: true,
          readAt: DateTime.now().toIso8601String(),
          sourceType: _notifications[index].sourceType,
          sourceId: _notifications[index].sourceId,
          createdAt: _notifications[index].createdAt,
        );
        notifyListeners();
      }
    } catch (_) {}
  }
}
