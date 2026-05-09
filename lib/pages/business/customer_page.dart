import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../widgets/error_state_widget.dart';

class CustomerPage extends StatefulWidget {
  const CustomerPage({super.key});

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  final ApiService _api = ApiService.instance;
  final _searchController = TextEditingController();
  String _filterLevel = 'all';
  bool _isLoading = true;
  dynamic _error;
  List<Map<String, dynamic>> _customers = [];

  static const List<Map<String, String>> _levelTabs = [
    {'label': '全部', 'value': 'all'},
    {'label': 'VIP', 'value': 'vip'},
    {'label': 'A级', 'value': 'a'},
    {'label': 'B级', 'value': 'b'},
    {'label': 'C级', 'value': 'c'},
  ];

  static const Map<String, Color> _levelColors = {
    'vip': Color(0xFFFFB800),
    'a': AppTheme.primaryColor,
    'b': AppTheme.accentColor,
    'c': AppTheme.textSecondary,
  };

  static const Map<String, String> _levelLabels = {
    'vip': 'VIP',
    'a': 'A级',
    'b': 'B级',
    'c': 'C级',
  };

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final params = <String, dynamic>{};
      if (_filterLevel != 'all') params['level'] = _filterLevel;
      if (_searchController.text.trim().isNotEmpty) {
        params['keyword'] = _searchController.text.trim();
      }
      final response = await _api.get(
        ApiConfig.customers,
        queryParameters: params.isNotEmpty ? params : null,
      );
      final data = response['data'] ?? response;
      List<dynamic> list;
      if (data is List) { list = data; }
      else if (data is Map && data.containsKey('data')) { list = data['data'] as List; }
      else { list = []; }
      setState(() { _customers = list.cast<Map<String, dynamic>>(); _isLoading = false; });
    } catch (e) {
      setState(() { _error = e; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('客户列表')),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildLevelFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : _error != null
                    ? ErrorStateWidget(error: _error, onRetry: _loadCustomers)
                    : _customers.isEmpty
                        ? _buildEmptyView()
                        : RefreshIndicator(
                            onRefresh: _loadCustomers,
                            color: AppTheme.primaryColor,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                              itemCount: _customers.length,
                              itemBuilder: (context, index) => _buildCard(_customers[index]),
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
      ]),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => _loadCustomers(),
        decoration: InputDecoration(
          hintText: '搜索客户名称',
          prefixIcon: const Icon(Icons.search, color: AppTheme.textHint, size: 22),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear, color: AppTheme.textHint, size: 20), onPressed: () { _searchController.clear(); _loadCustomers(); })
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildLevelFilter() {
    return Container(
      height: 40,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _levelTabs.map((tab) {
          final isActive = _filterLevel == tab['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () { setState(() => _filterLevel = tab['value']!); _loadCustomers(); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.primaryColor : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(tab['label']!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isActive ? Colors.white : AppTheme.textSecondary)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final level = item['level'] ?? 'c';
    final levelColor = _levelColors[level] ?? AppTheme.textSecondary;
    final levelLabel = _levelLabels[level] ?? 'C级';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: levelColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text((item['name'] ?? '客').substring(0, 1), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: levelColor))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(item['name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: levelColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(levelLabel, style: TextStyle(fontSize: 11, color: levelColor, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: AppTheme.textHint),
                    const SizedBox(width: 4),
                    Text(item['contact_name'] ?? item['contact'] ?? '', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    const SizedBox(width: 12),
                    const Icon(Icons.phone_outlined, size: 14, color: AppTheme.textHint),
                    const SizedBox(width: 4),
                    Text(item['phone'] ?? '', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 14, color: AppTheme.textHint),
                    const SizedBox(width: 4),
                    Text('历史订单: ${item['order_count'] ?? 0}笔', style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (action) => _handleAction(action, item),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryColor), SizedBox(width: 8), Text('编辑')])),
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerColor), SizedBox(width: 8), Text('删除', style: TextStyle(color: AppTheme.dangerColor))])),
            ],
          ),
        ],
      ),
    );
  }

  void _handleAction(String action, Map<String, dynamic> item) {
    switch (action) {
      case 'edit': _showFormDialog(item: item); break;
      case 'delete': _showDeleteConfirm(item); break;
    }
  }

  void _showFormDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    final nameCtrl = TextEditingController(text: item?['name'] ?? '');
    final contactNameCtrl = TextEditingController(text: item?['contact_name'] ?? item?['contact'] ?? '');
    final phoneCtrl = TextEditingController(text: item?['phone'] ?? '');
    final emailCtrl = TextEditingController(text: item?['email'] ?? '');
    final addressCtrl = TextEditingController(text: item?['address'] ?? '');
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEdit ? '编辑客户' : '新增客户'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '名称 *', prefixIcon: Icon(Icons.business_outlined))),
                const SizedBox(height: 12),
                TextField(controller: contactNameCtrl, decoration: const InputDecoration(labelText: '联系人', prefixIcon: Icon(Icons.person_outline))),
                const SizedBox(height: 12),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: '手机号', prefixIcon: Icon(Icons.phone_outlined)), keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: '邮箱', prefixIcon: Icon(Icons.email_outlined)), keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: '地址', prefixIcon: Icon(Icons.location_on_outlined)), maxLines: 2),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: isSubmitting ? null : () async {
              if (nameCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('名称不能为空'), backgroundColor: AppTheme.dangerColor));
                return;
              }
              setDialogState(() => isSubmitting = true);
              try {
                final data = <String, dynamic>{
                  'name': nameCtrl.text.trim(),
                  'contact_name': contactNameCtrl.text.trim().isEmpty ? null : contactNameCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                  'email': emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                  'address': addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
                };
                if (isEdit) {
                  await _api.put('${ApiConfig.customers}/${item['id']}', data: data);
                } else {
                  await _api.post(ApiConfig.customers, data: data);
                }
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? '已更新' : '已创建'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating));
                  _loadCustomers();
                }
              } catch (e) {
                setDialogState(() => isSubmitting = false);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败: $e'), backgroundColor: AppTheme.dangerColor, behavior: SnackBarBehavior.floating));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: isSubmitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(isEdit ? '保存' : '创建'),
          ),
        ],
      )),
    );
  }

  void _showDeleteConfirm(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('确认删除'),
        content: Text('确认删除客户 ${item['name'] ?? ''}？此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _api.delete('${ApiConfig.customers}/${item['id']}');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已删除'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating));
                  _loadCustomers();
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

  Widget _buildEmptyView() {
    return Center(child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.group_outlined, size: 48, color: AppTheme.textHint),
        const SizedBox(height: 8),
        const Text('暂无客户数据', style: TextStyle(color: AppTheme.textHint)),
        const SizedBox(height: 8),
        Text('点击右下角按钮新增客户', style: TextStyle(color: AppTheme.textHint.withOpacity(0.7), fontSize: 13)),
      ],
    ));
  }

}
