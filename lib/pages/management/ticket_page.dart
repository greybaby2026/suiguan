import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../widgets/error_state_widget.dart';

/// 工单支持页
class TicketPage extends StatefulWidget {
  const TicketPage({super.key});

  @override
  State<TicketPage> createState() => _TicketPageState();
}

class _TicketPageState extends State<TicketPage> {
  final ApiService _api = ApiService.instance;

  List<Map<String, dynamic>> _tickets = [];
  bool _isLoading = true;
  dynamic _error;
  String _statusFilter = 'all'; // all / pending / processing / closed

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  /// 加载工单列表
  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final queryParams = <String, dynamic>{};
      if (_statusFilter != 'all') {
        queryParams['status'] = _statusFilter;
      }

      final response = await _api.get(
        ApiConfig.tickets,
        queryParameters: queryParams,
      );

      final data = response['data'] ?? response;
      if (data is List) {
        _tickets = data.cast<Map<String, dynamic>>();
      } else if (data is Map && data.containsKey('data')) {
        _tickets = (data['data'] as List).cast<Map<String, dynamic>>();
      } else {
        _tickets = [];
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('工单支持')),
      body: Column(
        children: [
          _buildStatusFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : _error != null
                    ? ErrorStateWidget(error: _error, onRetry: _loadTickets)
                    : _tickets.isEmpty
                        ? _buildEmptyView()
                        : RefreshIndicator(
                            onRefresh: _loadTickets,
                            color: AppTheme.primaryColor,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                              itemCount: _tickets.length,
                              itemBuilder: (context, index) {
                                return _buildTicketCard(_tickets[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
      // 新建工单按钮
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTicketDialog,
        tooltip: '新建工单',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 状态筛选栏
  Widget _buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _buildFilterChip(label: '全部', value: 'all'),
          const SizedBox(width: 8),
          _buildFilterChip(label: '待处理', value: 'pending', color: AppTheme.warningColor),
          const SizedBox(width: 8),
          _buildFilterChip(label: '处理中', value: 'processing', color: AppTheme.infoColor),
          const SizedBox(width: 8),
          _buildFilterChip(label: '已关闭', value: 'closed', color: AppTheme.textHint),
        ],
      ),
    );
  }

  /// 筛选芯片
  Widget _buildFilterChip({
    required String label,
    required String value,
    Color? color,
  }) {
    final isActive = _statusFilter == value;
    final activeColor = color ?? AppTheme.primaryColor;

    return GestureDetector(
      onTap: () {
        setState(() => _statusFilter = value);
        _loadTickets();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? activeColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  /// 工单卡片
  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final type = ticket['type'] ?? 'other';
    final title = ticket['title'] ?? ticket['subject'] ?? '工单';
    final status = ticket['status'] ?? 'pending';
    final createdAt = ticket['created_at'] ?? '';

    const typeLabels = {
      'bug': '缺陷',
      'consult': '咨询',
      'billing': '计费',
      'data': '数据',
      'other': '其他',
    };
    const typeIcons = {
      'bug': Icons.bug_report_outlined,
      'consult': Icons.help_outline,
      'billing': Icons.payment_outlined,
      'data': Icons.storage_outlined,
      'other': Icons.article_outlined,
    };
    const typeColors = {
      'bug': AppTheme.dangerColor,
      'consult': AppTheme.warningColor,
      'billing': AppTheme.infoColor,
      'data': AppTheme.primaryColor,
      'other': AppTheme.textSecondary,
    };
    const statusLabels = {
      'pending': '待处理',
      'processing': '处理中',
      'closed': '已关闭',
    };
    const statusColors = {
      'pending': AppTheme.warningColor,
      'processing': AppTheme.infoColor,
      'closed': AppTheme.textHint,
    };

    final typeColor = typeColors[type] ?? AppTheme.textSecondary;
    final statusColor = statusColors[status] ?? AppTheme.textSecondary;
    final typeIcon = typeIcons[type] ?? Icons.article_outlined;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 类型图标
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(typeIcon, color: typeColor, size: 22),
          ),
          const SizedBox(width: 12),
          // 信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 类型标签
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        typeLabels[type] ?? type,
                        style: TextStyle(
                          fontSize: 10,
                          color: typeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // 状态标签
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusLabels[status] ?? status,
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  _formatDate(createdAt),
                  style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 新建工单弹窗
  void _showCreateTicketDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedType = 'consult';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('新建工单'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('类型', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildTypeChip(
                      label: '咨询',
                      value: 'consult',
                      isSelected: selectedType == 'consult',
                      onTap: () => setDialogState(() => selectedType = 'consult'),
                    ),
                    _buildTypeChip(
                      label: '缺陷',
                      value: 'bug',
                      isSelected: selectedType == 'bug',
                      onTap: () => setDialogState(() => selectedType = 'bug'),
                    ),
                    _buildTypeChip(
                      label: '计费',
                      value: 'billing',
                      isSelected: selectedType == 'billing',
                      onTap: () => setDialogState(() => selectedType = 'billing'),
                    ),
                    _buildTypeChip(
                      label: '数据',
                      value: 'data',
                      isSelected: selectedType == 'data',
                      onTap: () => setDialogState(() => selectedType = 'data'),
                    ),
                    _buildTypeChip(
                      label: '其他',
                      value: 'other',
                      isSelected: selectedType == 'other',
                      onTap: () => setDialogState(() => selectedType = 'other'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 标题
                const Text('标题', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(hintText: '请输入工单标题'),
                ),
                const SizedBox(height: 16),
                // 内容
                const Text('详细描述', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                TextField(
                  controller: contentController,
                  maxLines: 4,
                  decoration: const InputDecoration(hintText: '请描述您遇到的问题或需求'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('请输入工单标题'),
                      backgroundColor: AppTheme.dangerColor,
                    ),
                  );
                  return;
                }
                Navigator.pop(context);
                await _createTicket(
                  type: selectedType,
                  title: titleController.text.trim(),
                  content: contentController.text.trim(),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              child: const Text('提交'),
            ),
          ],
        ),
      ),
    );
  }

  /// 类型选择芯片
  Widget _buildTypeChip({
    required String label,
    required String value,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  /// 创建工单
  Future<void> _createTicket({
    required String type,
    required String title,
    required String content,
  }) async {
    try {
      await _api.post(
        ApiConfig.tickets,
        data: {
          'type': type,
          'title': title,
          'content': content,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('工单已创建'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
          ),
        );
        _loadTickets();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('创建失败: $e'),
            backgroundColor: AppTheme.dangerColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 空状态
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.support_agent_outlined, size: 48, color: AppTheme.textHint),
          const SizedBox(height: 8),
          const Text('暂无工单记录', style: TextStyle(color: AppTheme.textHint)),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮新建工单',
            style: TextStyle(color: AppTheme.textHint.withOpacity(0.7), fontSize: 13),
          ),
        ],
      ),
    );
  }

  /// 格式化日期
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr.length > 16 ? dateStr.substring(0, 16) : dateStr;
    }
  }
}
