import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/error_state_widget.dart';
import '../../utils/number_utils.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final ApiService _api = ApiService.instance;

  Map<String, dynamic>? _currentPlan;
  List<Map<String, dynamic>> _historyRecords = [];
  List<Map<String, dynamic>> _planList = [];
  bool _isLoading = true;
  bool _planLoading = false;
  bool _payLoading = false;
  dynamic _error;

  String _selectedPlanId = '';
  String _billingCycle = 'monthly';
  String _payType = 'alipay';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      try {
        final currentResult = await _api.get(ApiConfig.subscriptionCurrent);
        final currentData = currentResult['data'] ?? currentResult;
        if (currentData is Map<String, dynamic> && currentData.isNotEmpty) {
          _currentPlan = currentData;
        } else if (currentData is Map && currentData.isNotEmpty) {
          _currentPlan = Map<String, dynamic>.from(currentData);
        }
      } catch (e) {}

      try {
        final historyResult = await _api.get(ApiConfig.subscriptionHistory);
        final historyData = historyResult['data'] ?? historyResult;
        if (historyData is List) {
          _historyRecords = historyData.cast<Map<String, dynamic>>();
        } else if (historyData is Map && historyData.containsKey('data')) {
          _historyRecords = (historyData['data'] as List).cast<Map<String, dynamic>>();
        }
      } catch (e) {}

      if (mounted) {
        await context.read<AuthProvider>().refreshFeatures();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPlans() async {
    setState(() => _planLoading = true);
    try {
      final result = await _api.get(ApiConfig.subscriptionPlans, queryParameters: {'is_active': 1, 'page_size': 100});
      final data = result['data'] ?? result;
      if (data is List) {
        _planList = data.cast<Map<String, dynamic>>();
      } else if (data is Map && data.containsKey('list')) {
        _planList = (data['list'] as List).cast<Map<String, dynamic>>();
      } else if (data is Map && data.containsKey('items')) {
        _planList = (data['items'] as List).cast<Map<String, dynamic>>();
      }
      if (_planList.isNotEmpty && _selectedPlanId.isEmpty) {
        _selectedPlanId = _planList.first['id']?.toString() ?? '';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取套餐列表失败: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      setState(() => _planLoading = false);
    }
  }

  Map<String, dynamic>? get _selectedPlan {
    if (_selectedPlanId.isEmpty) return null;
    try {
      return _planList.firstWhere((p) => p['id']?.toString() == _selectedPlanId);
    } catch (_) {
      return null;
    }
  }

  double get _purchaseAmount {
    final plan = _selectedPlan;
    if (plan == null) return 0;
    return _billingCycle == 'yearly'
        ? safeToDouble(plan['price_yearly'])
        : safeToDouble(plan['price_monthly']);
  }

  Future<bool> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Future<void> _handlePurchase() async {
    if (_selectedPlanId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择套餐'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _payLoading = true);
    try {
      final result = await _api.post(ApiConfig.paymentCreate, data: {
        'plan_id': int.parse(_selectedPlanId),
        'billing_cycle': _billingCycle,
        'pay_type': _payType,
        'device': 'mobile',
      });

      final data = result['data'] ?? result;
      final payUrl = data['pay_url']?.toString() ?? '';

      if (payUrl.isNotEmpty) {
        Navigator.of(context).pop();
        final opened = await _openUrl(payUrl);
        if (mounted) {
          await context.read<AuthProvider>().refreshFeatures();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(opened ? '已跳转到支付页面，支付完成后请返回查看' : '支付链接已复制到剪贴板，请在浏览器中打开'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建支付订单失败: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      setState(() => _payLoading = false);
    }
  }

  void _showPurchaseDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _PurchasePage(
          onPurchase: (planId, cycle, payType) async {
            _selectedPlanId = planId;
            _billingCycle = cycle;
            _payType = payType;
            await _handlePurchase();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('订阅管理')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _error != null
              ? ErrorStateWidget(error: _error, onRetry: _loadData)
              : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCurrentPlanCard(),
                    const SizedBox(height: 20),
                    _buildUsageSection(),
                    const SizedBox(height: 20),
                    _buildActionButtons(),
                    const SizedBox(height: 24),
                    _buildHistorySection(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCurrentPlanCard() {
    if (_currentPlan == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.cardDecoration,
        child: Column(
          children: [
            const Icon(Icons.info_outline, size: 40, color: AppTheme.textHint),
            const SizedBox(height: 12),
            const Text('暂无活跃订阅', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            const Text('请购买套餐开始使用', style: TextStyle(fontSize: 13, color: AppTheme.textHint)),
          ],
        ),
      );
    }

    final planName = _currentPlan?['plan_name'] ?? _currentPlan?['plan']?['name'] ?? '基础版';
    final expiresAt = _currentPlan?['expires_at'] ?? _currentPlan?['expire_date'] ?? _currentPlan?['end_date'] ?? '';
    final modules = _currentPlan?['modules'] ?? _currentPlan?['plan']?['modules'] ?? [];
    final isActive = _currentPlan?['status'] == 'active' || _currentPlan?['is_active'] == true;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.gradientDecoration(
        colors: isActive
            ? [AppTheme.primaryColor, AppTheme.primaryDark]
            : [AppTheme.textHint, AppTheme.textSecondary],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(planName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Text(isActive ? '生效中' : '已过期', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (expiresAt.isNotEmpty)
            Text('到期时间: ${_formatDate(expiresAt)}', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
          if (modules.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 12),
            const Text('功能模块', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: (modules is List ? modules : [])
                  .map<Widget>((m) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                        child: Text(m is Map ? (m['name'] ?? m.toString()) : m.toString(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUsageSection() {
    final usages = _currentPlan?['usage'] ?? {};
    final usageItems = <Map<String, dynamic>>[];
    if (usages is Map) {
      usages.forEach((key, value) {
        if (value is Map) {
          usageItems.add(Map<String, dynamic>.from(value));
        } else if (value is num) {
          usageItems.add({'name': _usageNameMap(key), 'used': value.toInt(), 'limit': _currentPlan?['limits']?[key] ?? 0});
        }
      });
    }
    if (usageItems.isEmpty) {
      usageItems.addAll([
        {'name': '用户数', 'used': _currentPlan?['user_count'] ?? 0, 'limit': _currentPlan?['user_limit'] ?? 10},
        {'name': '工单数', 'used': _currentPlan?['order_count'] ?? 0, 'limit': _currentPlan?['order_limit'] ?? 100},
        {'name': '存储空间', 'used': _currentPlan?['storage_used'] ?? 0, 'limit': _currentPlan?['storage_limit'] ?? 1},
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text('用量统计', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecoration,
          child: Column(
            children: usageItems.asMap().entries.map((entry) {
              final isLast = entry.key == usageItems.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                child: _buildUsageBar(name: entry.value['name'] ?? '', used: safeToDouble(entry.value['used']), limit: safeToDouble(entry.value['limit'])),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _usageNameMap(String key) {
    const map = {'users': '用户数', 'orders': '工单数', 'storage': '存储空间(GB)', 'workers': '工人数', 'products': '产品数'};
    return map[key] ?? key;
  }

  Widget _buildUsageBar({required String name, required double used, required double limit}) {
    final ratio = limit > 0 ? used / limit : 0.0;
    final isWarning = ratio > 0.8;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(name, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
        Text('${used.toInt()}/${limit.toInt()}', style: TextStyle(fontSize: 13, color: isWarning ? AppTheme.warningColor : AppTheme.textSecondary, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: ratio.clamp(0.0, 1.0), backgroundColor: const Color(0xFFF1F5F9), valueColor: AlwaysStoppedAnimation<Color>(isWarning ? AppTheme.warningColor : AppTheme.primaryColor), minHeight: 8)),
    ]);
  }

  Widget _buildActionButtons() {
    return Row(children: [
      Expanded(
        child: ElevatedButton(
          onPressed: _showPurchaseDialog,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('续费/升级', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ),
      if (_currentPlan == null) ...[
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: _showPurchaseDialog,
            style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primaryColor, side: const BorderSide(color: AppTheme.primaryColor), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('购买套餐', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    ]);
  }

  Widget _buildHistorySection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(
        padding: EdgeInsets.only(left: 4, bottom: 12),
        child: Text('历史记录', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      ),
      if (_historyRecords.isEmpty)
        Container(
          padding: const EdgeInsets.all(32),
          decoration: AppTheme.cardDecoration,
          child: const Center(child: Column(children: [
            Icon(Icons.receipt_long_outlined, size: 40, color: AppTheme.textHint),
            SizedBox(height: 8),
            Text('暂无订阅记录', style: TextStyle(color: AppTheme.textHint)),
          ])),
        )
      else
        ..._historyRecords.map((record) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: AppTheme.cardDecoration,
              child: Row(children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.infoColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.receipt_outlined, color: AppTheme.infoColor, size: 20)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(record['plan_name'] ?? record['plan']?['name'] ?? '订阅记录', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(_formatDate(record['created_at'] ?? record['start_date'] ?? ''), style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
                ])),
                Text('¥${safeToDouble(record['amount']).toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
              ]),
            )),
    ]);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr.length > 10 ? dateStr.substring(0, 10) : dateStr;
    }
  }
}

class _PurchasePage extends StatefulWidget {
  final Future<void> Function(String planId, String cycle, String payType) onPurchase;

  const _PurchasePage({
    required this.onPurchase,
  });

  @override
  State<_PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<_PurchasePage> {
  final ApiService _api = ApiService.instance;

  List<Map<String, dynamic>> _planList = [];
  bool _planLoading = true;
  String _selectedPlanId = '';
  String _billingCycle = 'monthly';
  String _payType = 'alipay';
  bool _payLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() => _planLoading = true);
    try {
      final result = await _api.get(ApiConfig.subscriptionPlans, queryParameters: {'is_active': 1, 'page_size': 100});
      final data = result['data'] ?? result;
      if (data is List) {
        _planList = data.cast<Map<String, dynamic>>();
      } else if (data is Map && data.containsKey('list')) {
        _planList = (data['list'] as List).cast<Map<String, dynamic>>();
      } else if (data is Map && data.containsKey('items')) {
        _planList = (data['items'] as List).cast<Map<String, dynamic>>();
      }
      if (_planList.isNotEmpty && _selectedPlanId.isEmpty) {
        _selectedPlanId = _planList.first['id']?.toString() ?? '';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取套餐列表失败: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _planLoading = false);
    }
  }

  Map<String, dynamic>? get _selectedPlan {
    if (_selectedPlanId.isEmpty) return null;
    try {
      return _planList.firstWhere((p) => p['id']?.toString() == _selectedPlanId);
    } catch (_) {
      return null;
    }
  }

  double get _purchaseAmount {
    final plan = _selectedPlan;
    if (plan == null) return 0;
    return _billingCycle == 'yearly'
        ? safeToDouble(plan['price_yearly'])
        : safeToDouble(plan['price_monthly']);
  }

  Future<void> _handlePurchase() async {
    if (_selectedPlanId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择套餐'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _payLoading = true);
    try {
      await widget.onPurchase(_selectedPlanId, _billingCycle, _payType);
    } finally {
      if (mounted) setState(() => _payLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('购买/续费套餐')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('选择套餐', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  const SizedBox(height: 10),
                  if (_planLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppTheme.primaryColor)))
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedPlanId.isEmpty ? null : _selectedPlanId,
                      decoration: InputDecoration(
                        hintText: '请选择套餐',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: _planList.map((plan) => DropdownMenuItem<String>(
                        value: plan['id']?.toString() ?? '',
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(plan['display_name'] ?? plan['name'] ?? '', style: const TextStyle(fontSize: 15)),
                          Text('¥${safeToDouble(plan['price_monthly']).toStringAsFixed(0)}/月', style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
                        ]),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedPlanId = val ?? ''),
                    ),
                  const SizedBox(height: 24),
                  const Text('计费周期', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _buildOptionChip(_billingCycle == 'monthly', '月付', () => setState(() => _billingCycle = 'monthly'))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildOptionChip(_billingCycle == 'yearly', '年付', () => setState(() => _billingCycle = 'yearly'))),
                  ]),
                  const SizedBox(height: 24),
                  const Text('支付方式', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _buildPayTypeOption('alipay', '支付宝', Icons.account_balance_wallet)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildPayTypeOption('wxpay', '微信支付', Icons.chat_bubble)),
                  ]),
                  if (_selectedPlan != null) ...[
                    const SizedBox(height: 30),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(children: [
                        const Text('应付金额', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                        const SizedBox(height: 8),
                        Text('¥${_purchaseAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
                        Text('/ ${_billingCycle == 'monthly' ? '月' : '年'}', style: const TextStyle(fontSize: 14, color: AppTheme.textHint)),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.only(left: 20, right: 20, top: 12, bottom: MediaQuery.of(context).padding.bottom + 12),
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, -2))]),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _selectedPlanId.isEmpty || _payLoading ? null : _handlePurchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _payLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('确认支付 ¥${_purchaseAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionChip(bool selected, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey[100],
          border: Border.all(color: selected ? AppTheme.primaryColor : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: selected ? AppTheme.primaryColor : AppTheme.textSecondary))),
      ),
    );
  }

  Widget _buildPayTypeOption(String value, String label, IconData icon) {
    final selected = _payType == value;
    return InkWell(
      onTap: () => setState(() => _payType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey[100],
          border: Border.all(color: selected ? AppTheme.primaryColor : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: selected ? AppTheme.primaryColor : AppTheme.textHint),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: selected ? AppTheme.primaryColor : AppTheme.textSecondary)),
        ])),
      ),
    );
  }
}
