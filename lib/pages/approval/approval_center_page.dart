import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../widgets/error_state_widget.dart';

/// 审批中心页（按类型隔离）
/// 顶部4个类型Tab：订单审批、采购审批、计件审批、预支审批
/// 每个Tab下显示对应类型的待审批列表
class ApprovalCenterPage extends StatefulWidget {
  const ApprovalCenterPage({super.key});

  @override
  State<ApprovalCenterPage> createState() => _ApprovalCenterPageState();
}

class _ApprovalCenterPageState extends State<ApprovalCenterPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  // 四种审批类型的数据
  List<Map<String, dynamic>> _orderApprovals = [];
  List<Map<String, dynamic>> _purchaseApprovals = [];
  List<Map<String, dynamic>> _pieceApprovals = [];
  List<Map<String, dynamic>> _advanceApprovals = [];

  // 审批类型定义
  static const List<Map<String, dynamic>> _approvalTypes = [
    {
      'key': 'order',
      'label': '订单审批',
      'icon': Icons.receipt_long_outlined,
      'color': AppTheme.primaryColor,
    },
    {
      'key': 'purchase',
      'label': '采购审批',
      'icon': Icons.shopping_cart_outlined,
      'color': AppTheme.accentColor,
    },
    {
      'key': 'piece',
      'label': '计件审批',
      'icon': Icons.engineering_outlined,
      'color': AppTheme.warningColor,
    },
    {
      'key': 'advance',
      'label': '预支审批',
      'icon': Icons.account_balance_wallet_outlined,
      'color': AppTheme.successColor,
    },
  ];

  bool _hasError = false;
  dynamic _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _approvalTypes.length, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 加载所有审批数据
  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      dynamic orderResult, purchaseResult, pieceResult, advanceResult;

      try {
        orderResult = await ApiService.instance.get(ApiConfig.orders, queryParameters: {'status': 'pending'});
      } catch (_) {}
      try {
        purchaseResult = await ApiService.instance.get(ApiConfig.purchaseOrders, queryParameters: {'status': 'pending'});
      } catch (_) {}
      try {
        pieceResult = await ApiService.instance.get(ApiConfig.workerPieceRecords, queryParameters: {'status': 'pending'});
      } catch (_) {}
      try {
        advanceResult = await ApiService.instance.get(ApiConfig.workerAdvances, queryParameters: {'status': 1});
      } catch (_) {}

      setState(() {
        _orderApprovals = _parseList(orderResult);
        _purchaseApprovals = _parseList(purchaseResult);
        _pieceApprovals = _parseList(pieceResult);
        _advanceApprovals = _parseList(advanceResult);
        _hasError = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _error = e;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _parseList(dynamic response) {
    if (response is List) {
      return response.cast<Map<String, dynamic>>();
    }
    if (response is Map) {
      final data = response['data'];
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
    }
    return [];
  }

  Map<String, String> _getDisplayInfo(Map<String, dynamic> item, int tabIndex) {
    switch (tabIndex) {
      case 0:
        return {
          'title': '订单 ${item['order_no'] ?? item['id'] ?? ''}',
          'subtitle': '客户：${item['customer']?['name'] ?? item['customer_name'] ?? '-'} | 金额：¥${_formatAmount(item['total_amount'])}',
          'time': _formatDate(item['created_at']),
        };
      case 1:
        return {
          'title': '采购单 ${item['order_no'] ?? item['id'] ?? ''}',
          'subtitle': '供应商：${item['supplier']?['name'] ?? item['supplier_name'] ?? '-'} | 金额：¥${_formatAmount(item['total_amount'])}',
          'time': _formatDate(item['created_at']),
        };
      case 2:
        return {
          'title': '${item['worker']?['name'] ?? item['worker_name'] ?? '-'} 计件记录',
          'subtitle': '${item['process']?['name'] ?? item['process_name'] ?? '-'} | ${item['quantity'] ?? 0}件 | ¥${_formatAmount(item['amount'])}',
          'time': _formatDate(item['work_date'] ?? item['created_at']),
        };
      case 3:
        return {
          'title': '${item['worker']?['name'] ?? item['worker_name'] ?? '-'} 预支申请',
          'subtitle': '预支金额：¥${_formatAmount(item['amount'])}',
          'time': _formatDate(item['advance_date'] ?? item['created_at']),
        };
      default:
        return {};
    }
  }

  String _formatAmount(dynamic value) {
    if (value == null) return '0.00';
    return (value is num ? value : double.tryParse(value.toString()) ?? 0).toStringAsFixed(2);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.month}-${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr.length > 16 ? dateStr.substring(0, 16) : dateStr;
    }
  }

  /// 获取当前Tab对应的数据
  List<Map<String, dynamic>> _getDataForTab(int index) {
    switch (index) {
      case 0:
        return _orderApprovals;
      case 1:
        return _purchaseApprovals;
      case 2:
        return _pieceApprovals;
      case 3:
        return _advanceApprovals;
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('审批中心'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          tabs: _approvalTypes.map((type) {
            return Tab(text: type['label'] as String);
          }).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _hasError
              ? ErrorStateWidget(error: _error, onRetry: _loadAllData)
              : TabBarView(
              controller: _tabController,
              children: List.generate(_approvalTypes.length, (index) {
                return _buildApprovalList(index);
              }),
            ),
    );
  }

  /// 构建审批列表
  Widget _buildApprovalList(int tabIndex) {
    final data = _getDataForTab(tabIndex);
    final typeConfig = _approvalTypes[tabIndex];
    final typeColor = typeConfig['color'] as Color;
    final typeIcon = typeConfig['icon'] as IconData;

    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(typeIcon, size: 48, color: AppTheme.textHint),
            const SizedBox(height: 8),
            Text(
              '暂无${typeConfig['label']}',
              style: const TextStyle(color: AppTheme.textHint),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: data.length,
        itemBuilder: (context, index) {
          final item = data[index];
          final displayInfo = _getDisplayInfo(item, tabIndex);
          return _ApprovalCard(
            title: displayInfo['title'] ?? '',
            subtitle: displayInfo['subtitle'] ?? '',
            time: displayInfo['time'] ?? '',
            typeColor: typeColor,
            typeIcon: typeIcon,
            onApprove: () => _handleApprove(item, tabIndex),
            onReject: () => _handleReject(item, tabIndex),
          );
        },
      ),
    );
  }

  /// 通过审批
  Future<void> _handleApprove(Map<String, dynamic> item, int tabIndex) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('审批确认'),
        content: Text('确认通过「${item['title']}」？'),
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

    if (confirmed == true) {
      try {
        final id = item['id'];
        switch (tabIndex) {
          case 0:
            await ApiService.instance.post(
              ApiConfig.replaceId(ApiConfig.orderApprove, id),
            );
            break;
          case 1:
            await ApiService.instance.post(
              ApiConfig.replaceId(ApiConfig.purchaseOrderApprove, id),
            );
            break;
          case 2:
            await ApiService.instance.post(
              ApiConfig.workerPieceRecordsApprove,
              data: {'ids': [id]},
            );
            break;
          case 3:
            await ApiService.instance.post(
              ApiConfig.replaceId(ApiConfig.workerAdvanceApprove, id),
            );
            break;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已通过: ${item['title']}'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
        _loadAllData();
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

  /// 驳回审批（需要填写原因）
  void _handleReject(Map<String, dynamic> item, int tabIndex) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('驳回原因'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '驳回「${item['title']}」',
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '请输入驳回原因（必填）',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              reasonController.dispose();
              Navigator.pop(context);
            },
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('请填写驳回原因'),
                    backgroundColor: AppTheme.warningColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                );
                return;
              }
              Navigator.pop(context);
              reasonController.dispose();

              try {
                final id = item['id'];
                switch (tabIndex) {
                  case 0:
                    await ApiService.instance.post(
                      ApiConfig.replaceId(ApiConfig.orderReject, id),
                      data: {'reason': reason},
                    );
                    break;
                  case 1:
                    await ApiService.instance.post(
                      ApiConfig.replaceId(ApiConfig.purchaseOrderReject, id),
                      data: {'reason': reason},
                    );
                    break;
                  case 2:
                    await ApiService.instance.post(
                      ApiConfig.workerPieceRecordsReject,
                      data: {'ids': [id], 'reject_reason': reason},
                    );
                    break;
                  case 3:
                    await ApiService.instance.post(
                      ApiConfig.replaceId(ApiConfig.workerAdvanceReject, id),
                      data: {'reject_reason': reason},
                    );
                    break;
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('已驳回: ${item['title']}'),
                      backgroundColor: AppTheme.dangerColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                }
                _loadAllData();
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
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            child: const Text('确认驳回'),
          ),
        ],
      ),
    );
  }
}

/// 审批卡片组件
class _ApprovalCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final Color typeColor;
  final IconData typeIcon;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ApprovalCard({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.typeColor,
    required this.typeIcon,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部：图标 + 标题 + 时间
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(typeIcon, color: typeColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                time,
                style: const TextStyle(fontSize: 11, color: AppTheme.textHint),
              ),
            ],
          ),
          // 副标题
          Padding(
            padding: const EdgeInsets.only(left: 52, top: 4),
            child: Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 12),
          // 操作按钮
          Padding(
            padding: const EdgeInsets.only(left: 52),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.dangerColor,
                      side: const BorderSide(color: AppTheme.dangerColor),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('通过', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
