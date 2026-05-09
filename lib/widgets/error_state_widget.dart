import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';

class ErrorStateWidget extends StatelessWidget {
  final dynamic error;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final apiError = ApiException.fromDynamic(error);

    if (apiError.isFeatureError) {
      return _buildFeatureLocked(context);
    }

    IconData icon;
    Color iconColor;
    String title;
    String subtitle;

    if (apiError.isSubscriptionError) {
      icon = Icons.card_membership_outlined;
      iconColor = AppTheme.warningColor;
      title = '订阅已过期';
      subtitle = apiError.friendlyMessage;
    } else if (apiError.isPermissionError) {
      icon = Icons.no_accounts_outlined;
      iconColor = AppTheme.textHint;
      title = '暂无权限';
      subtitle = apiError.friendlyMessage;
    } else if (apiError.isAuthError) {
      icon = Icons.login_outlined;
      iconColor = AppTheme.dangerColor;
      title = '登录已过期';
      subtitle = '请重新登录后继续操作';
    } else if (error is DioException &&
        (error as DioException).type == DioExceptionType.connectionError) {
      icon = Icons.wifi_off_outlined;
      iconColor = AppTheme.textHint;
      title = '网络连接失败';
      subtitle = '请检查网络后重试';
    } else {
      icon = Icons.error_outline;
      iconColor = AppTheme.dangerColor;
      title = '加载失败';
      subtitle = apiError.friendlyMessage;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: iconColor),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('重试'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureLocked(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.warningColor.withOpacity(0.2), AppTheme.primaryColor.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.upgrade_outlined, size: 40, color: AppTheme.warningColor),
            ),
            const SizedBox(height: 16),
            const Text(
              '功能未开通',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '当前套餐未包含此功能\n请联系管理员升级套餐以解锁',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => context.push('/management/subscription'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('查看套餐'),
                ),
                const SizedBox(width: 12),
                if (onRetry != null)
                  ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('重试'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
