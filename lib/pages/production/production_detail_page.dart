import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../models/production_order.dart';
import '../../services/api_service.dart';
import '../../services/production_service.dart';
import '../../utils/number_utils.dart';

class ProductionDetailPage extends StatefulWidget {
  final int orderId;

  const ProductionDetailPage({super.key, required this.orderId});

  @override
  State<ProductionDetailPage> createState() => _ProductionDetailPageState();
}

class _ProductionDetailPageState extends State<ProductionDetailPage> {
  final ProductionService _service = ProductionService();
  bool _isLoading = true;
  String? _error;
  ProductionOrderModel? _order;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final order = await _service.getProductionOrderDetail(widget.orderId);
      if (mounted) {
        setState(() {
          _order = order;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleStart() async {
    if (_order == null) return;
    setState(() => _isActionLoading = true);
    try {
      await _service.startProduction(_order!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('开工成功'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadDetail();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: $e'),
            backgroundColor: AppTheme.dangerColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _handleComplete() async {
    if (_order == null) return;

    try {
      final checkResult = await ApiService.instance.get(
        ApiConfig.replaceId(ApiConfig.productionOrderPreCompleteCheck, _order!.id),
      );

      final data = checkResult['data'] ?? checkResult;
      final canComplete = data['can_complete'] == true;
      final warnings = data['warnings'] as List? ?? [];
      final hasWarnings = data['has_warnings'] == true;

      if (!canComplete) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? '当前状态不允许完工'),
              backgroundColor: AppTheme.dangerColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      if (hasWarnings) {
        final confirmed = await _showCompleteConfirmDialog(warnings);
        if (confirmed != true) return;
      } else {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('确认完工'),
            content: Text('确认将工单 ${_order!.orderNo} 标记为完工？'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
                child: const Text('确认完工'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
      }

      setState(() => _isActionLoading = true);
      await _service.completeProduction(_order!.id, force: hasWarnings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('完工成功'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating),
        );
        _loadDetail();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e'), backgroundColor: AppTheme.dangerColor, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<bool?> _showCompleteConfirmDialog(List warnings) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppTheme.warningColor, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('完工确认'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('以下事项尚未完成，确认完工后将无法继续生产：', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            ...warnings.map((w) {
              final warning = w as Map<String, dynamic>;
              final type = warning['type'] ?? '';
              final message = warning['message'] ?? '';
              final detail = warning['detail'];

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: type == 'incomplete_tasks'
                      ? AppTheme.warningColor.withOpacity(0.06)
                      : AppTheme.primaryColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: type == 'incomplete_tasks'
                      ? AppTheme.warningColor.withOpacity(0.2)
                      : AppTheme.primaryColor.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          type == 'incomplete_tasks' ? Icons.assignment_late_outlined : Icons.info_outline,
                          size: 16,
                          color: type == 'incomplete_tasks' ? AppTheme.warningColor : AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(message, style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: type == 'incomplete_tasks' ? AppTheme.warningColor : AppTheme.primaryColor,
                          )),
                        ),
                      ],
                    ),
                    if (type == 'incomplete_tasks' && detail is List) ...[
                      const SizedBox(height: 8),
                      ...detail.map((d) {
                        final item = d as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.only(left: 22, bottom: 4),
                          child: Row(
                            children: [
                              Text(item['process_name'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.warningColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(item['status_label'] ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.warningColor)),
                              ),
                              const SizedBox(width: 6),
                              Text('${item['progress']}%', style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
                            ],
                          ),
                        );
                      }),
                    ],
                    if (type == 'quantity_mismatch' && detail is Map) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 22),
                        child: Text(
                          '计划: ${detail['planned_qty']} | 完成: ${detail['completed_qty']}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.dangerColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: AppTheme.dangerColor),
                  SizedBox(width: 6),
                  Expanded(child: Text('适用于供应商暂停加工等特殊情况，确认后工单将标记为完工', style: TextStyle(fontSize: 12, color: AppTheme.dangerColor))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('继续生产')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningColor),
            child: const Text('确认完工'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCancel() async {
    if (_order == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('确认取消'),
        content: Text('确认取消生产工单 ${_order!.orderNo}？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('返回'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            child: const Text('确认取消'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isActionLoading = true);
    try {
      await _service.cancelProduction(_order!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已取消'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadDetail();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: $e'),
            backgroundColor: AppTheme.dangerColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  String _formatDateStr(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    if (dateStr.length >= 10) return dateStr.substring(0, 10);
    return dateStr;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: Text('工单详情 #${widget.orderId}')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppTheme.dangerColor),
          const SizedBox(height: 12),
          Text('加载失败', style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Text(_error ?? '', style: const TextStyle(fontSize: 13, color: AppTheme.textHint)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadDetail,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final order = _order!;
    final statusColor = Color(order.statusColor);

    return RefreshIndicator(
      onRefresh: _loadDetail,
      color: AppTheme.primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(order, statusColor),
            const SizedBox(height: 16),
            _buildInfoSection(order),
            const SizedBox(height: 16),
            _buildProgressSection(order, statusColor),
            if (order.tasks.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildTasksSection(order),
            ],
            if (order.remark != null && order.remark!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildRemarkSection(order),
            ],
            const SizedBox(height: 16),
            _buildActionButtons(order),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(ProductionOrderModel order, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor, Color.lerp(statusColor, Colors.black, 0.2)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.statusLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(
                _statusIcon(order.statusStr),
                color: Colors.white,
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            order.orderNo,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            order.productName ?? '未关联产品',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (order.sourceOrderNo != null) ...[
            const SizedBox(height: 4),
            Text(
              '来源订单: ${order.sourceOrderNo}',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule_outlined;
      case 'scheduled':
        return Icons.event_outlined;
      case 'in_production':
        return Icons.settings_outlined;
      case 'completed':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildInfoSection(ProductionOrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '工单信息',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _buildInfoRow('订单数量', '${safeToDouble(order.quantity).toStringAsFixed(0)}'),
          _buildInfoRow('已完成', '${safeToDouble(order.completedQty).toStringAsFixed(0)}'),
          _buildInfoRow('计划开始', _formatDateStr(order.plannedStart)),
          _buildInfoRow('计划完成', _formatDateStr(order.plannedEnd)),
          _buildInfoRow('实际开始', _formatDateStr(order.actualStart)),
          _buildInfoRow('实际完成', _formatDateStr(order.actualEnd)),
          if (order.processRouteName != null)
            _buildInfoRow('工艺路线', order.processRouteName!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(ProductionOrderModel order, Color statusColor) {
    final progress = order.progress;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '生产进度',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
              Text(
                '${safeToDouble(order.completedQty).toStringAsFixed(0)} / ${safeToDouble(order.quantity).toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 13, color: AppTheme.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTasksSection(ProductionOrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '工序任务',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...order.tasks.map((task) => _buildTaskItem(task)),
        ],
      ),
    );
  }

  Widget _buildTaskItem(ProductionTaskDetailModel task) {
    final taskColor = Color(task.statusColor);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: taskColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: taskColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  task.processName ?? '工序 #${task.id}',
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
                  color: taskColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  task.statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: taskColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: task.progress,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(taskColor),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${safeToDouble(task.completedQty).toStringAsFixed(0)}/${safeToDouble(task.quantity).toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
              ),
            ],
          ),
          if (task.assigneeName != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: AppTheme.textHint),
                const SizedBox(width: 4),
                Text(
                  task.assigneeName!,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRemarkSection(ProductionOrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '备注',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            order.remark!,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ProductionOrderModel order) {
    final statusStr = order.statusStr;

    return Column(
      children: [
        if (statusStr == 'pending')
          _buildActionRow(
            primaryLabel: '排产',
            primaryIcon: Icons.event_outlined,
            primaryOnTap: () => _handleSchedule(context),
            secondaryLabel: '取消工单',
            secondaryIcon: Icons.cancel_outlined,
            secondaryOnTap: _handleCancel,
            isDanger: true,
          ),
        if (statusStr == 'scheduled')
          _buildActionRow(
            primaryLabel: '开始生产',
            primaryIcon: Icons.play_arrow_rounded,
            primaryOnTap: _handleStart,
            secondaryLabel: '取消工单',
            secondaryIcon: Icons.cancel_outlined,
            secondaryOnTap: _handleCancel,
            isDanger: true,
          ),
        if (statusStr == 'in_production')
          _buildActionRow(
            primaryLabel: '完工',
            primaryIcon: Icons.check_circle_outline,
            primaryOnTap: _handleComplete,
            secondaryLabel: '报工',
            secondaryIcon: Icons.edit_note_outlined,
            secondaryOnTap: () => context.push('/work/report'),
          ),
      ],
    );
  }

  Widget _buildActionRow({
    required String primaryLabel,
    required IconData primaryIcon,
    required VoidCallback primaryOnTap,
    required String secondaryLabel,
    required IconData secondaryIcon,
    required VoidCallback secondaryOnTap,
    bool isDanger = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isActionLoading ? null : primaryOnTap,
            icon: Icon(primaryIcon, size: 20),
            label: Text(primaryLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDanger ? AppTheme.dangerColor : AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isActionLoading ? null : secondaryOnTap,
            icon: Icon(secondaryIcon, size: 20),
            label: Text(secondaryLabel),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDanger ? AppTheme.textSecondary : AppTheme.primaryColor,
              side: BorderSide(color: isDanger ? AppTheme.border : AppTheme.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSchedule(BuildContext context) async {
    if (_order == null) return;

    final processRoutes = await _loadProcessRoutes();
    if (!mounted) return;

    if (processRoutes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('暂无可用工艺路线，请先在基础数据中创建工艺路线'),
          backgroundColor: AppTheme.warningColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    int? selectedRouteId;
    DateTime plannedStart = DateTime.now().add(const Duration(days: 1));
    DateTime? plannedEnd;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('排产'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedRouteId,
                  decoration: const InputDecoration(
                    labelText: '工艺路线',
                    prefixIcon: Icon(Icons.alt_route_outlined),
                  ),
                  items: processRoutes
                      .map((r) => DropdownMenuItem<int>(
                            value: r['id'] as int,
                            child: Text(r['name'] ?? '未命名路线'),
                          ))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedRouteId = v),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: plannedStart,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setDialogState(() => plannedStart = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '计划开始日期',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      '${plannedStart.year}-${plannedStart.month.toString().padLeft(2, '0')}-${plannedStart.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final initial = plannedEnd ?? plannedStart.add(const Duration(days: 14));
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: initial,
                      firstDate: plannedStart,
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setDialogState(() => plannedEnd = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '计划完成日期（可选）',
                      prefixIcon: Icon(Icons.event_outlined),
                    ),
                    child: Text(
                      plannedEnd != null
                          ? '${plannedEnd!.year}-${plannedEnd!.month.toString().padLeft(2, '0')}-${plannedEnd!.day.toString().padLeft(2, '0')}'
                          : '请选择',
                      style: TextStyle(
                        fontSize: 15,
                        color: plannedEnd != null ? AppTheme.textPrimary : AppTheme.textHint,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (selectedRouteId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('请选择工艺路线'),
                            backgroundColor: AppTheme.dangerColor,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      setDialogState(() => isSubmitting = true);
                      try {
                        final startStr = '${plannedStart.year}-${plannedStart.month.toString().padLeft(2, '0')}-${plannedStart.day.toString().padLeft(2, '0')}';
                        final endStr = plannedEnd != null
                            ? '${plannedEnd!.year}-${plannedEnd!.month.toString().padLeft(2, '0')}-${plannedEnd!.day.toString().padLeft(2, '0')}'
                            : null;
                        await _service.scheduleProduction(
                          _order!.id,
                          processRouteId: selectedRouteId!,
                          plannedStart: startStr,
                          plannedEnd: endStr,
                        );
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('排产成功'),
                              backgroundColor: AppTheme.successColor,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          _loadDetail();
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('排产失败: $e'),
                              backgroundColor: AppTheme.dangerColor,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('确认排产'),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadProcessRoutes() async {
    try {
      final response = await ApiService.instance.get(ApiConfig.processRoutes);
      final data = response['data'] ?? response;
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      } else if (data is Map && data.containsKey('list')) {
        return (data['list'] as List).cast<Map<String, dynamic>>();
      } else if (data is Map && data.containsKey('data')) {
        final inner = data['data'];
        if (inner is List) return inner.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
