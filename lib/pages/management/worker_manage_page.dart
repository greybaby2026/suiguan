import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../models/worker.dart';
import '../../widgets/error_state_widget.dart';

class WorkerManagePage extends StatefulWidget {
  const WorkerManagePage({super.key});

  @override
  State<WorkerManagePage> createState() => _WorkerManagePageState();
}

class _WorkerManagePageState extends State<WorkerManagePage> {
  final ApiService _api = ApiService.instance;
  final _searchController = TextEditingController();

  List<WorkerModel> _workers = [];
  List<WorkerModel> _filteredWorkers = [];
  bool _isLoading = true;
  dynamic _error;
  String _statusFilter = 'active';

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkers() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await _api.get(ApiConfig.workers);
      final data = response['data'] ?? response;
      List<dynamic> list;
      if (data is List) { list = data; }
      else if (data is Map && data.containsKey('data')) { list = data['data'] as List; }
      else { list = []; }
      _workers = list.map((e) => WorkerModel.fromJson(e as Map<String, dynamic>)).toList();
      _applyFilters();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() { _error = e; _isLoading = false; });
    }
  }

  void _applyFilters() {
    _filteredWorkers = _workers.where((w) {
      if (_statusFilter != 'all' && w.status != _statusFilter) return false;
      final keyword = _searchController.text.trim().toLowerCase();
      if (keyword.isNotEmpty) {
        return w.name.toLowerCase().contains(keyword) ||
            w.code.toLowerCase().contains(keyword) ||
            (w.phone?.toLowerCase().contains(keyword) ?? false);
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('工人管理')),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildStatusFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : _error != null
                    ? ErrorStateWidget(error: _error, onRetry: _loadWorkers)
                    : _filteredWorkers.isEmpty
                        ? _buildEmptyView()
                        : RefreshIndicator(
                            onRefresh: _loadWorkers,
                            color: AppTheme.primaryColor,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                              itemCount: _filteredWorkers.length,
                              itemBuilder: (context, index) => _buildWorkerCard(_filteredWorkers[index]),
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showWorkerFormDialog(),
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
        onChanged: (_) { _applyFilters(); setState(() {}); },
        decoration: InputDecoration(
          hintText: '搜索工号、姓名或手机号',
          prefixIcon: const Icon(Icons.search, color: AppTheme.textHint, size: 22),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear, color: AppTheme.textHint, size: 20), onPressed: () { _searchController.clear(); _applyFilters(); setState(() {}); })
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(children: [
        _buildFilterChip(label: '在职', value: 'active'),
        const SizedBox(width: 8),
        _buildFilterChip(label: '离职', value: 'resigned'),
        const SizedBox(width: 8),
        _buildFilterChip(label: '全部', value: 'all'),
      ]),
    );
  }

  Widget _buildFilterChip({required String label, required String value}) {
    final isActive = _statusFilter == value;
    return GestureDetector(
      onTap: () { setState(() => _statusFilter = value); _applyFilters(); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(color: isActive ? AppTheme.primaryColor : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isActive ? Colors.white : AppTheme.textSecondary)),
      ),
    );
  }

  Widget _buildWorkerCard(WorkerModel worker) {
    final isActive = worker.status == 'active';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: (isActive ? AppTheme.primaryColor : AppTheme.textHint).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(worker.name.isNotEmpty ? worker.name.substring(0, 1) : '?',
              style: TextStyle(color: isActive ? AppTheme.primaryColor : AppTheme.textHint, fontSize: 20, fontWeight: FontWeight.w700))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(worker.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: (isActive ? AppTheme.successColor : AppTheme.textHint).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(isActive ? '在职' : '离职', style: TextStyle(fontSize: 10, color: isActive ? AppTheme.successColor : AppTheme.textHint, fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Text('工号: ${worker.code}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  const SizedBox(width: 16),
                  Text(worker.skillTypeLabel, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                ]),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (action) => _handleAction(action, worker),
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryColor), const SizedBox(width: 8), const Text('编辑')])),
              PopupMenuItem(value: 'reset_pin', child: Row(children: [const Icon(Icons.vpn_key_outlined, size: 18, color: AppTheme.warningColor), const SizedBox(width: 8), const Text('重置PIN')])),
              PopupMenuItem(value: 'toggle', child: Row(children: [const Icon(Icons.swap_horiz, size: 18, color: AppTheme.infoColor), const SizedBox(width: 8), Text(isActive ? '设为离职' : '设为在职')])),
              PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerColor), const SizedBox(width: 8), const Text('删除', style: TextStyle(color: AppTheme.dangerColor))])),
            ],
          ),
        ],
      ),
    );
  }

  void _handleAction(String action, WorkerModel worker) {
    switch (action) {
      case 'edit': _showWorkerFormDialog(worker: worker); break;
      case 'reset_pin': _showResetPinDialog(worker); break;
      case 'toggle': _toggleStatus(worker); break;
      case 'delete': _showDeleteConfirm(worker); break;
    }
  }

  void _showWorkerFormDialog({WorkerModel? worker}) {
    final isEdit = worker != null;
    final nameCtrl = TextEditingController(text: worker?.name ?? '');
    final codeCtrl = TextEditingController(text: worker?.code ?? '');
    final phoneCtrl = TextEditingController(text: worker?.phone ?? '');
    String skillType = worker?.skillType ?? '综合';
    String status = worker?.status ?? 'active';
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEdit ? '编辑工人' : '新增工人'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '姓名 *', prefixIcon: Icon(Icons.person_outline))),
                const SizedBox(height: 12),
                TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: '工号 *', prefixIcon: Icon(Icons.badge_outlined))),
                const SizedBox(height: 12),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: '手机号', prefixIcon: Icon(Icons.phone_outlined)), keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: skillType,
                  decoration: const InputDecoration(labelText: '工种', prefixIcon: Icon(Icons.work_outline)),
                  items: const [
                    DropdownMenuItem(value: '裁剪', child: Text('裁剪')),
                    DropdownMenuItem(value: '缝制', child: Text('缝制')),
                    DropdownMenuItem(value: '整烫', child: Text('整烫')),
                    DropdownMenuItem(value: '检验', child: Text('检验')),
                    DropdownMenuItem(value: '包装', child: Text('包装')),
                    DropdownMenuItem(value: '综合', child: Text('综合')),
                  ],
                  onChanged: (v) => setDialogState(() => skillType = v ?? '综合'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: '状态', prefixIcon: Icon(Icons.toggle_on_outlined)),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('在职')),
                    DropdownMenuItem(value: 'resigned', child: Text('离职')),
                  ],
                  onChanged: (v) => setDialogState(() => status = v ?? 'active'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: isSubmitting ? null : () async {
              if (nameCtrl.text.trim().isEmpty || codeCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('姓名和工号不能为空'), backgroundColor: AppTheme.dangerColor));
                return;
              }
              setDialogState(() => isSubmitting = true);
              try {
                final data = {
                  'name': nameCtrl.text.trim(),
                  'code': codeCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                  'skill_type': skillType,
                  'status': status,
                };
                if (isEdit) {
                  await _api.put('${ApiConfig.workers}/${worker.id}', data: data);
                } else {
                  await _api.post(ApiConfig.workers, data: data);
                }
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? '已更新' : '已创建'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating));
                  _loadWorkers();
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

  Future<void> _toggleStatus(WorkerModel worker) async {
    final newStatus = worker.status == 'active' ? 'resigned' : 'active';
    try {
      await _api.put('${ApiConfig.workers}/${worker.id}', data: {'status': newStatus});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已${newStatus == 'active' ? '恢复在职' : '设为离职'}'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating));
        _loadWorkers();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败: $e'), backgroundColor: AppTheme.dangerColor, behavior: SnackBarBehavior.floating));
    }
  }

  void _showDeleteConfirm(WorkerModel worker) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('确认删除'),
        content: Text('确认删除工人 ${worker.name}（${worker.code}）？此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _api.delete('${ApiConfig.workers}/${worker.id}');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已删除'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating));
                  _loadWorkers();
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

  void _showResetPinDialog(WorkerModel worker) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('重置PIN'),
        content: Text('确认重置工人 ${worker.name}（${worker.code}）的PIN码？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final path = ApiConfig.replaceId(ApiConfig.workerResetPin, worker.id);
                final result = await _api.post(path);
                final newPin = result['data']?['pin'] ?? result['pin'] ?? '';
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text('PIN码已重置'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('工人 ${worker.name} 的新PIN码：'),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text(newPin.toString(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.primaryColor, letterSpacing: 4)),
                          ),
                          const SizedBox(height: 8),
                          const Text('请妥善保管，关闭后无法再次查看', style: TextStyle(fontSize: 12, color: AppTheme.textHint)),
                        ],
                      ),
                      actions: [TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('我知道了'))],
                    ),
                  );
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('重置失败: $e'), backgroundColor: AppTheme.dangerColor, behavior: SnackBarBehavior.floating));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningColor),
            child: const Text('确认重置'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.people_outline, size: 48, color: AppTheme.textHint),
      const SizedBox(height: 8),
      const Text('暂无工人数据', style: TextStyle(color: AppTheme.textHint)),
      const SizedBox(height: 8),
      Text('点击右下角按钮新增工人', style: TextStyle(color: AppTheme.textHint.withOpacity(0.7), fontSize: 13)),
    ]));
  }

}
