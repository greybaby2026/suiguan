import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/feature_config.dart';
import '../providers/auth_provider.dart';

class FeatureGuard {
  static bool check(BuildContext context, String featureKey) {
    final auth = context.read<AuthProvider>();
    if (auth.hasFeature(featureKey)) return true;

    _showUpgradeDialog(context, featureKey);
    return false;
  }

  static void _showUpgradeDialog(BuildContext context, String featureKey) {
    final featureName = FeatureConfig.getFeatureName(featureKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lock_outline, color: AppTheme.warningColor, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('功能未开通'),
          ],
        ),
        content: Text('「$featureName」需要升级套餐后才能使用，是否前往升级？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('暂不升级'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/management/subscription');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('去升级'),
          ),
        ],
      ),
    );
  }
}
