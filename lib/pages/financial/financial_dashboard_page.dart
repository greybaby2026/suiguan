import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../utils/number_utils.dart';

class FinancialDashboardPage extends StatefulWidget {
  const FinancialDashboardPage({super.key});

  @override
  State<FinancialDashboardPage> createState() => _FinancialDashboardPageState();
}

class _FinancialDashboardPageState extends State<FinancialDashboardPage> {
  final ApiService _api = ApiService.instance;
  Map<String, dynamic>? _dashboardData;
  List<dynamic> _trendData = [];
  List<dynamic> _reminders = [];
  List<dynamic> _recentRecords = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final result = await _api.get(ApiConfig.financialDashboard);
      if (mounted) {
        final data = result['data'] is Map<String, dynamic>
            ? result['data'] as Map<String, dynamic>
            : <String, dynamic>{};

        setState(() {
          _dashboardData = data;
          _trendData = data['trend'] is List ? data['trend'] as List : [];
          _reminders = data['reminders'] is List ? data['reminders'] as List : [];
          _recentRecords = data['recent_payments'] is List ? data['recent_payments'] as List : [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('财务驾驶舱')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : RefreshIndicator(
              onRefresh: _fetchData,
              color: AppTheme.primaryColor,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatCards(),
                  const SizedBox(height: 16),
                  _buildQuickActions(),
                  const SizedBox(height: 16),
                  if (_reminders.isNotEmpty) ...[
                    _buildReminders(),
                    const SizedBox(height: 16),
                  ],
                  _buildTrendChart(),
                  const SizedBox(height: 16),
                  _buildRecentRecords(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCards() {
    final summary = _dashboardData?['summary'] is Map<String, dynamic>
        ? _dashboardData!['summary'] as Map<String, dynamic>
        : <String, dynamic>{};

    final income = safeToDouble(summary['month_income']);
    final expense = safeToDouble(summary['month_expense']);
    final profit = safeToDouble(summary['month_profit']);
    final receivable = safeToDouble(summary['receivable_amount']);
    final payable = safeToDouble(summary['payable_amount']);
    final wagePending = safeToDouble(summary['pending_wages']);

    return Column(
      children: [
        Container(
          decoration: AppTheme.cardDecoration,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('本月概览', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _buildSummaryItem('本月收入', income, Colors.blue, Icons.trending_up)),
                  Container(width: 1, height: 40, color: AppTheme.border.withOpacity(0.3)),
                  Expanded(child: _buildSummaryItem('本月支出', expense, Colors.red, Icons.trending_down)),
                  Container(width: 1, height: 40, color: AppTheme.border.withOpacity(0.3)),
                  Expanded(child: _buildSummaryItem('本月利润', profit, Colors.green, Icons.analytics_outlined)),
                ],
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: AppTheme.border.withOpacity(0.3)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _buildSummaryItem('应收款', receivable, Colors.orange, Icons.arrow_forward)),
                  Container(width: 1, height: 40, color: AppTheme.border.withOpacity(0.3)),
                  Expanded(child: _buildSummaryItem('应付款', payable, Colors.purple, Icons.arrow_back)),
                  Container(width: 1, height: 40, color: AppTheme.border.withOpacity(0.3)),
                  Expanded(child: _buildSummaryItem('待发工资', wagePending, Colors.brown, Icons.account_balance_wallet_outlined)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, double value, Color color, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.9))),
          ],
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('¥${value.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showRecordBottomSheet(context, isExpense: true),
            icon: const Icon(Icons.remove_circle_outline, size: 18),
            label: const Text('记一笔支出'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showRecordBottomSheet(context, isExpense: false),
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('记一笔收款'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReminders() {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('待办提醒', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          ..._reminders.map<Widget>((item) {
            final data = item as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_outlined, size: 18, color: AppTheme.warningColor),
                  const SizedBox(width: 8),
                  Expanded(child: Text(data['message'] ?? '', style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('近6月收支趋势', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLegend(Colors.blue, '收入'),
              const SizedBox(width: 16),
              _buildLegend(Colors.red, '支出'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: _trendData.isEmpty
                ? const Center(child: Text('暂无趋势数据', style: TextStyle(color: AppTheme.textHint)))
                : CustomPaint(
                    size: Size.infinite,
                    painter: _BarChartPainter(
                      data: _trendData,
                      incomeColor: Colors.blue,
                      expenseColor: Colors.red,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildRecentRecords() {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('最近收付款记录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          if (_recentRecords.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('暂无记录', style: TextStyle(color: AppTheme.textHint))))
          else
            ..._recentRecords.take(5).map<Widget>((item) {
              final data = item as Map<String, dynamic>;
              final isIncome = (data['type'] ?? '') == 'receivable';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isIncome ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isIncome ? '收入' : '支出',
                        style: TextStyle(fontSize: 12, color: isIncome ? Colors.green : Colors.red, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['counterparty_name'] ?? data['category_label'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
                          Text(data['payment_date'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
                        ],
                      ),
                    ),
                    Text(
                      '${isIncome ? "+" : "-"}¥${safeToDouble(data['amount']).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isIncome ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  void _showRecordBottomSheet(BuildContext context, {required bool isExpense}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => _RecordBottomSheet(isExpense: isExpense),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<dynamic> data;
  final Color incomeColor;
  final Color expenseColor;

  _BarChartPainter({required this.data, required this.incomeColor, required this.expenseColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()..style = PaintingStyle.fill;
    final barWidth = (size.width / data.length - 20) / 2;
    final maxVal = data.fold<double>(0.0, (max, item) {
      final d = item as Map<String, dynamic>;
      return [
        max,
        safeToDouble(d['income']).abs(),
        safeToDouble(d['expense']).abs(),
      ].reduce((a, b) => a > b ? a : b);
    });

    if (maxVal <= 0) return;

    final chartHeight = size.height - 30;
    final groupWidth = size.width / data.length;

    for (int i = 0; i < data.length; i++) {
      final d = data[i] as Map<String, dynamic>;
      final income = safeToDouble(d['income']).abs();
      final expense = safeToDouble(d['expense']).abs();
      final x = i * groupWidth + 10;

      final incomeHeight = (income / maxVal) * chartHeight;
      paint.color = incomeColor.withOpacity(0.8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, chartHeight - incomeHeight, barWidth, incomeHeight), const Radius.circular(3)),
        paint,
      );

      final expenseHeight = (expense / maxVal) * chartHeight;
      paint.color = expenseColor.withOpacity(0.8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x + barWidth + 4, chartHeight - expenseHeight, barWidth, expenseHeight), const Radius.circular(3)),
        paint,
      );

      final tp = TextPainter(
        text: TextSpan(text: (d['month'] ?? '').substring(5), style: const TextStyle(fontSize: 10, color: AppTheme.textHint)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + barWidth / 2, chartHeight + 8));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _RecordBottomSheet extends StatefulWidget {
  final bool isExpense;

  const _RecordBottomSheet({required this.isExpense});

  @override
  State<_RecordBottomSheet> createState() => _RecordBottomSheetState();
}

class _RecordBottomSheetState extends State<_RecordBottomSheet> {
  final ApiService _api = ApiService.instance;
  final _formKey = GlobalKey<FormState>();
  final _counterpartController = TextEditingController();
  final _amountController = TextEditingController();
  final _remarkController = TextEditingController();

  String _type = 'payable';
  String _category = 'other';
  String _paymentMethod = 'cash';
  DateTime _date = DateTime.now();
  bool _submitting = false;

  final Map<String, String> _categoryMap = {
    '订单收款': 'order_income',
    '采购付款': 'purchase_payment',
    '工人工资': 'worker_salary',
    '其他': 'other',
  };

  final Map<String, String> _methodMap = {
    '现金': 'cash',
    '转账': 'transfer',
    '微信': 'wechat',
    '支付宝': 'alipay',
  };

  @override
  void initState() {
    super.initState();
    _type = widget.isExpense ? 'payable' : 'receivable';
    _category = widget.isExpense ? 'purchase_payment' : 'order_income';
  }

  @override
  void dispose() {
    _counterpartController.dispose();
    _amountController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      await _api.post(ApiConfig.paymentRecords, data: {
        'type': _type,
        'category': _category,
        'counterparty_name': _counterpartController.text.trim(),
        'amount': double.tryParse(_amountController.text.trim()) ?? 0,
        'payment_method': _paymentMethod,
        'payment_date': _date.toIso8601String().split('T').first,
        'remark': _remarkController.text.trim(),
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('记录成功'), backgroundColor: AppTheme.successColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('提交失败，请重试'), backgroundColor: AppTheme.dangerColor),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.isExpense ? '记一笔支出' : '记一笔收款',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _categoryMap.entries.firstWhere((e) => e.value == _category).key,
                decoration: const InputDecoration(labelText: '类别'),
                items: _categoryMap.keys.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _category = _categoryMap[v] ?? 'other'),
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _counterpartController, decoration: const InputDecoration(labelText: '对方名称'), validator: (v) => (v == null || v.trim().isEmpty) ? '请输入对方名称' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _amountController, decoration: const InputDecoration(labelText: '金额'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) => (v == null || double.tryParse(v) == null) ? '请输入有效金额' : null),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _methodMap.entries.firstWhere((e) => e.value == _paymentMethod).key,
                decoration: const InputDecoration(labelText: '支付方式'),
                items: _methodMap.keys.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setState(() => _paymentMethod = _methodMap[v] ?? 'cash'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('日期'),
                subtitle: Text(_date.toIso8601String().split('T').first),
                trailing: const Icon(Icons.calendar_today, size: 20),
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2030));
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _remarkController, decoration: const InputDecoration(labelText: '备注'), maxLines: 2),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isExpense ? AppTheme.dangerColor : AppTheme.successColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('提交', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
