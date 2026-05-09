import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../widgets/error_state_widget.dart';

class OutsourcingPartnerPage extends StatefulWidget {
  const OutsourcingPartnerPage({super.key});

  @override
  State<OutsourcingPartnerPage> createState() => _OutsourcingPartnerPageState();
}

class _OutsourcingPartnerPageState extends State<OutsourcingPartnerPage> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  dynamic _error;
  List<Map<String, dynamic>> _partners = [];

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPartners() async {
    setState(() => _isLoading = true);
    try {
      final params = <String, dynamic>{};
      if (_searchController.text.trim().isNotEmpty) {
        params['name'] = _searchController.text.trim();
      }
      final result = await ApiService.instance.get(
        ApiConfig.outsourcingPartners,
        queryParameters: params.isNotEmpty ? params : null,
      );
      final data = result['data'];
      final list = data is List ? data : (data is Map ? (data['list'] ?? data['items'] ?? []) : []);
      setState(() {
        _partners = list.cast<Map<String, dynamic>>();
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showPartnerFormDialog({Map<String, dynamic>? partner}) {
    final isEdit = partner != null;
    final nameCtrl = TextEditingController(text: partner?['name'] ?? '');
    final contactCtrl = TextEditingController(text: partner?['contact_person'] ?? '');
    final phoneCtrl = TextEditingController(text: partner?['contact_phone'] ?? '');
    final addressCtrl = TextEditingController(text: partner?['address'] ?? '');
    final remarkCtrl = TextEditingController(text: partner?['remark'] ?? '');
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEdit ? '编辑接纳单位' : '新增接纳单位'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: '单位名称 *',
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contactCtrl,
                    decoration: const InputDecoration(
                      labelText: '联系人',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: '联系电话',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(
                      labelText: '地址',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: remarkCtrl,
                    decoration: const InputDecoration(
                      labelText: '备注',
                      prefixIcon: Icon(Icons.note_outlined),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('请输入单位名称'), backgroundColor: AppTheme.dangerColor),
                        );
                        return;
                      }
                      setDialogState(() => isSubmitting = true);
                      try {
                        final data = {
                          'name': nameCtrl.text.trim(),
                          'contact_person': contactCtrl.text.trim().isEmpty ? null : contactCtrl.text.trim(),
                          'contact_phone': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                          'address': addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
                          'remark': remarkCtrl.text.trim().isEmpty ? null : remarkCtrl.text.trim(),
                        };
                        if (isEdit) {
                          await ApiService.instance.put('${ApiConfig.outsourcingPartners}/${partner!['id']}', data: data);
                        } else {
                          await ApiService.instance.post(ApiConfig.outsourcingPartners, data: data);
                        }
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(isEdit ? '已更新' : '已创建'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating),
                          );
                          _loadPartners();
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('操作失败: $e'), backgroundColor: AppTheme.dangerColor, behavior: SnackBarBehavior.floating),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              child: isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isEdit ? '保存' : '创建'),
            ),
          ],
        );
      }),
    );
  }

  void _showDeleteConfirm(Map<String, dynamic> partner) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('确认删除'),
        content: Text('确认删除接纳单位「${partner['name']}」？此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService.instance.delete('${ApiConfig.outsourcingPartners}/${partner['id']}');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已删除'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating),
                  );
                  _loadPartners();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('删除失败: $e'), backgroundColor: AppTheme.dangerColor, behavior: SnackBarBehavior.floating),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('接纳单位管理')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索单位名称',
                prefixIcon: const Icon(Icons.search, size: 22),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _loadPartners();
                  },
                ),
              ),
              onSubmitted: (_) => _loadPartners(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : _error != null
                    ? ErrorStateWidget(error: _error, onRetry: _loadPartners)
                    : _partners.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            onRefresh: _loadPartners,
                            color: AppTheme.primaryColor,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                              itemCount: _partners.length,
                              itemBuilder: (context, index) => _buildPartnerCard(_partners[index]),
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPartnerFormDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.business_outlined, size: 48, color: AppTheme.textHint),
          const SizedBox(height: 8),
          const Text('暂无接纳单位', style: TextStyle(color: AppTheme.textHint)),
        ],
      ),
    );
  }

  Widget _buildPartnerCard(Map<String, dynamic> partner) {
    final isActive = partner['status'] == 'active' || partner['status'] == 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  partner['name'] ?? '',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.successColor.withOpacity(0.1) : AppTheme.dangerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isActive ? '启用' : '禁用',
                  style: TextStyle(fontSize: 12, color: isActive ? AppTheme.successColor : AppTheme.dangerColor, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                onSelected: (action) {
                  if (action == 'edit') _showPartnerFormDialog(partner: partner);
                  if (action == 'delete') _showDeleteConfirm(partner);
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryColor), SizedBox(width: 8), Text('编辑')])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerColor), SizedBox(width: 8), Text('删除', style: TextStyle(color: AppTheme.dangerColor))])),
                ],
              ),
            ],
          ),
          if (partner['code'] != null) ...[
            const SizedBox(height: 4),
            Text('编码: ${partner['code']}', style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
          ],
          if (partner['contact_person'] != null || partner['contact_phone'] != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (partner['contact_person'] != null) ...[
                  const Icon(Icons.person_outline, size: 14, color: AppTheme.textHint),
                  const SizedBox(width: 2),
                  Text(partner['contact_person'], style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(width: 8),
                ],
                if (partner['contact_phone'] != null) ...[
                  const Icon(Icons.phone_outlined, size: 14, color: AppTheme.textHint),
                  const SizedBox(width: 2),
                  Text(partner['contact_phone'], style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
