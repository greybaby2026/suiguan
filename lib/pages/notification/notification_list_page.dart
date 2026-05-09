import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification.dart';

class NotificationListPage extends StatefulWidget {
  final bool isEmbedded;

  const NotificationListPage({super.key, this.isEmbedded = false});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    Widget body;
    if (provider.isLoading && provider.notifications.isEmpty) {
      body = const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    } else if (provider.notifications.isEmpty) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_none_outlined, size: 56, color: AppTheme.textHint),
            const SizedBox(height: 12),
            const Text('暂无通知', style: TextStyle(color: AppTheme.textHint)),
          ],
        ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: () => provider.loadNotifications(),
        color: AppTheme.primaryColor,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: provider.notifications.length,
          itemBuilder: (context, index) {
            return _NotificationCard(
              notification: provider.notifications[index],
              onTap: () => _handleNotificationTap(provider.notifications[index]),
            );
          },
        ),
      );
    }

    if (widget.isEmbedded) {
      return Scaffold(
        backgroundColor: AppTheme.bgPrimary,
        appBar: AppBar(
          title: const Text('消息'),
          actions: [
            if (provider.unreadCount > 0)
              TextButton(
                onPressed: () => provider.markAllRead(),
                child: const Text('全部已读', style: TextStyle(fontSize: 13)),
              ),
          ],
        ),
        body: body,
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('消息通知'),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: () => provider.markAllRead(),
              child: const Text('全部已读', style: TextStyle(fontSize: 13)),
            ),
        ],
      ),
      body: body,
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'system': return Icons.info_outline;
      case 'order': return Icons.receipt_long_outlined;
      case 'production': return Icons.precision_manufacturing_outlined;
      case 'approval': return Icons.task_alt_outlined;
      case 'warehouse': return Icons.warehouse_outlined;
      case 'quality': return Icons.verified_outlined;
      default: return Icons.notifications_outlined;
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    context.read<NotificationProvider>().markAsRead(notification.id);

    final icon = _getIconForType(notification.type);
    final actionRoute = _getRouteForNotification(notification);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 22),
            const SizedBox(width: 8),
            Expanded(child: Text(notification.title, style: const TextStyle(fontSize: 16))),
          ],
        ),
        content: Text(notification.content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('知道了'),
          ),
          if (actionRoute != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.push(actionRoute);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('查看详情'),
            ),
        ],
      ),
    );
  }

  String? _getRouteForNotification(NotificationModel notification) {
    switch (notification.type) {
      case 'order':
        return '/management/base-data';
      case 'production':
        return '/management/base-data';
      case 'approval':
        return '/approval-center';
      case 'warehouse':
        return '/warehouse/manage';
      case 'quality':
        return '/management/base-data';
      default:
        return null;
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : AppTheme.primaryColor.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: notification.isRead
              ? null
              : Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _typeIcon,
                color: _typeColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.dangerColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.content,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        notification.typeLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: _typeColor,
                        ),
                      ),
                      Text(
                        notification.createdAt ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textHint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color get _typeColor {
    switch (notification.type) {
      case 'system':
        return AppTheme.infoColor;
      case 'order':
        return AppTheme.primaryColor;
      case 'production':
        return AppTheme.accentColor;
      case 'approval':
        return AppTheme.warningColor;
      case 'warehouse':
        return AppTheme.successColor;
      case 'quality':
        return AppTheme.dangerColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData get _typeIcon {
    switch (notification.type) {
      case 'system':
        return Icons.info_outline;
      case 'order':
        return Icons.receipt_long_outlined;
      case 'production':
        return Icons.precision_manufacturing_outlined;
      case 'approval':
        return Icons.task_alt_outlined;
      case 'warehouse':
        return Icons.warehouse_outlined;
      case 'quality':
        return Icons.verified_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}
