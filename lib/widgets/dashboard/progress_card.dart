import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/dashboard.dart';

class ProgressCard extends StatelessWidget {
  final ProductionProgressItem item;

  const ProgressCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
              Expanded(
                child: Text(
                  item.orderNo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: _statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (item.productName != null) ...[
            const SizedBox(height: 6),
            Text(
              item.productName!,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: item.progress,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(item.progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${item.completedQty.toStringAsFixed(0)} / ${item.quantity.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Color get _statusColor {
    const colorMap = {
      'pending': AppTheme.warningColor,
      'scheduled': AppTheme.primaryColor,
      'in_production': AppTheme.primaryColor,
      'completed': AppTheme.successColor,
      'cancelled': AppTheme.textHint,
    };
    if (item.status != null) {
      return colorMap[item.status] ?? AppTheme.textSecondary;
    }
    if (item.progress >= 1) return AppTheme.successColor;
    if (item.progress > 0) return AppTheme.primaryColor;
    return AppTheme.warningColor;
  }

  String get _statusLabel {
    const labelMap = {
      'pending': '待排产',
      'scheduled': '已排产',
      'in_production': '生产中',
      'completed': '已完成',
      'cancelled': '已取消',
    };
    if (item.status != null) {
      return labelMap[item.status] ?? item.status!;
    }
    if (item.progress >= 1) return '已完成';
    if (item.progress > 0) return '进行中';
    return '待生产';
  }
}
