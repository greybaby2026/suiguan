import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../widgets/error_state_widget.dart';
import '../../utils/number_utils.dart';

/// 销售订单列表页
class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  final _searchController = TextEditingController();
  String _filterStatus = 'all';
  bool _isLoading = false;
  dynamic _error;
  List<Map<String, dynamic>> _orders = [];

  // 状态筛选选项
  static const List<Map<String, String>> _statusTabs = [
    {'label': '全部', 'value': 'all'},
    {'label': '待审批', 'value': 'pending'},
    {'label': '已审批', 'value': 'approved'},
    {'label': '生产中', 'value': 'in_production'},
    {'label': '已完成', 'value': 'completed'},
    {'label': '已取消', 'value': 'cancelled'},
  ];

  // 状态颜色映射
  static const Map<String, Color> _statusColors = {
    'pending': AppTheme.warningColor,
    'approved': AppTheme.primaryColor,
    'in_production': AppTheme.infoColor,
    'completed': AppTheme.successColor,
    'cancelled': AppTheme.textHint,
  };

  // 状态中文映射
  static const Map<String, String> _statusLabels = {
    'pending': '待审批',
    'approved': '已审批',
    'in_production': '生产中',
    'completed': '已完成',
    'cancelled': '已取消',
  };

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 加载销售订单列表
  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final params = <String, dynamic>{};
      if (_filterStatus != 'all') params['status'] = _filterStatus;
      if (_searchController.text.trim().isNotEmpty) {
        params['keyword'] = _searchController.text.trim();
      }
      final result = await ApiService.instance.get(
        ApiConfig.orders,
        queryParameters: params.isNotEmpty ? params : null,
      );
      final data = result['data'];
      final list = data is List ? data : [];
      setState(() {
        _orders = list.cast<Map<String, dynamic>>();
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('销售订单')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/business/orders/create'),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          _buildStatusTabs(),
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : _error != null
                    ? ErrorStateWidget(error: _error, onRetry: _loadOrders)
                    : _orders.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        color: AppTheme.primaryColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: _orders.length,
                          itemBuilder: (context, index) {
                            return _OrderCard(
                              order: _orders[index],
                              onApprove: () => _handleApprove(_orders[index]),
                              onEdit: () => _showEditOrderDialog(_orders[index]),
                              onDelete: () => _showDeleteConfirm(_orders[index]),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  /// 状态筛选Tab
  Widget _buildStatusTabs() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statusTabs.map((tab) {
            final isActive = _filterStatus == tab['value'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() => _filterStatus = tab['value']!);
                  _loadOrders();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.primaryColor : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tab['label']!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isActive ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 搜索栏
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索订单号或客户名',
          prefixIcon: const Icon(Icons.search, size: 22),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear, size: 20),
            onPressed: () {
              _searchController.clear();
              _loadOrders();
            },
          ),
        ),
        onSubmitted: (_) => _loadOrders(),
      ),
    );
  }

  /// 空状态
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 48, color: AppTheme.textHint),
          const SizedBox(height: 8),
          const Text('暂无销售订单', style: TextStyle(color: AppTheme.textHint)),
        ],
      ),
    );
  }

  void _showEditOrderDialog(Map<String, dynamic> order) {
    final nameCtrl = TextEditingController(text: order['customer_name'] ?? order['customer']?['name'] ?? '');
    final remarkCtrl = TextEditingController(text: order['remark'] ?? '');
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('编辑订单'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: '客户名称 *', prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: remarkCtrl,
                  decoration: const InputDecoration(labelText: '备注', prefixIcon: Icon(Icons.note_outlined)),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: isSubmitting ? null : () async {
              if (nameCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('客户名称不能为空'), backgroundColor: AppTheme.dangerColor));
                return;
              }
              setDialogState(() => isSubmitting = true);
              try {
                final data = {
                  'customer_name': nameCtrl.text.trim(),
                  'remark': remarkCtrl.text.trim().isEmpty ? null : remarkCtrl.text.trim(),
                };
                await ApiService.instance.put('${ApiConfig.orders}/${order['id']}', data: data);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已更新'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating));
                  _loadOrders();
                }
              } catch (e) {
                setDialogState(() => isSubmitting = false);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败: $e'), backgroundColor: AppTheme.dangerColor, behavior: SnackBarBehavior.floating));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: isSubmitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('保存'),
          ),
        ],
      )),
    );
  }

  void _showDeleteConfirm(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('确认删除'),
        content: Text('确认删除销售订单 ${order['order_no']}？此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService.instance.delete('${ApiConfig.orders}/${order['id']}');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已删除'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating));
                  _loadOrders();
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败: $e'), backgroundColor: AppTheme.dangerColor, behavior: SnackBarBehavior.floating));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 审批操作
  Future<void> _handleApprove(Map<String, dynamic> order) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('审批确认'),
        content: Text('确认通过销售订单 ${order['order_no']}？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
            child: const Text('确认通过'),
          ),
        ],
      ),
    );
    if (approved == true) {
      try {
        final id = order['id'];
        await ApiService.instance.post(
          ApiConfig.replaceId(ApiConfig.orderApprove, id),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已通过: ${order['order_no']}'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
        _loadOrders();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('操作失败: $e'),
              backgroundColor: AppTheme.dangerColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      }
    }
  }
}

/// 销售订单卡片
class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onApprove;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _OrderCard({required this.order, required this.onApprove, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final status = order['status'] ?? 'pending';
    final statusColor = _OrderListPageState._statusColors[status] ?? AppTheme.textHint;
    final statusLabel = _OrderListPageState._statusLabels[status] ?? '未知';
    final isPending = status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部：订单号 + 状态
          Row(
            children: [
              Text(
                order['order_no'] ?? '',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isPending && (onEdit != null || onDelete != null)) ...[
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  onSelected: (action) {
                    if (action == 'edit' && onEdit != null) onEdit!();
                    if (action == 'delete' && onDelete != null) onDelete!();
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryColor), SizedBox(width: 8), Text('编辑')])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerColor), SizedBox(width: 8), Text('删除', style: TextStyle(color: AppTheme.dangerColor))])),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // 客户名
          Row(
            children: [
              const Icon(Icons.person_outline, size: 16, color: AppTheme.textHint),
              const SizedBox(width: 4),
              Text(
                order['customer_name'] ?? order['customer']?['name'] ?? '',
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 金额 + 日期
          Row(
            children: [
              const Icon(Icons.payments_outlined, size: 16, color: AppTheme.textHint),
              const SizedBox(width: 4),
              Text(
                '¥${safeToDouble(order['total_amount'] ?? order['amount']).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
              const Spacer(),
              const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textHint),
              const SizedBox(width: 4),
              Text(
                order['created_at'] ?? '',
                style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
              ),
            ],
          ),
          // 待审批时显示审批按钮
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleReject(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.dangerColor,
                      side: const BorderSide(color: AppTheme.dangerColor),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('驳回', style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('通过', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 驳回操作
  void _handleReject(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('驳回原因'),
        content: const TextField(
          maxLines: 3,
          decoration: InputDecoration(
            hintText: '请输入驳回原因',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('已驳回: ${order['order_no']}'),
                  backgroundColor: AppTheme.dangerColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            child: const Text('确认驳回'),
          ),
        ],
      ),
    );
  }
}
