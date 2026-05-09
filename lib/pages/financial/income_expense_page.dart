import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../utils/number_utils.dart';

class IncomeExpensePage extends StatefulWidget {
  const IncomeExpensePage({super.key});

  @override
  State<IncomeExpensePage> createState() => _IncomeExpensePageState();
}

class _IncomeExpensePageState extends State<IncomeExpensePage> {
  final ApiService _api = ApiService.instance;
  List<dynamic> _records = [];
  bool _loading = true;
  bool _loadingMore = false;
  int _currentPage = 1;
  int _totalPages = 1;
  int _total = 0;
  String _typeFilter = 'all';
  DateTimeRange? _dateRange;

  bool get _hasMore => _currentPage < _totalPages;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _currentPage = 1;
    });

    try {
      final params = <String, dynamic>{'page': 1, 'per_page': 15};
      if (_typeFilter != 'all') params['type'] = _typeFilter;
      if (_dateRange != null) {
        params['start_date'] = _dateRange!.start.toIso8601String().split('T').first;
        params['end_date'] = _dateRange!.end.toIso8601String().split('T').first;
      }

      final result = await _api.get(ApiConfig.financialIncomeExpense, queryParameters: params);
      final data = result['data'] is List ? result['data'] as List : [];
      final pagination = result['pagination'] as Map<String, dynamic>?;

      if (mounted) {
        setState(() {
          _records = data;
          _total = pagination?['total'] ?? data.length;
          _totalPages = pagination?['last_page'] ?? (data.length >= 15 ? 2 : 1);
          _currentPage = 1;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final params = <String, dynamic>{'page': nextPage, 'per_page': 15};
      if (_typeFilter != 'all') params['type'] = _typeFilter;
      if (_dateRange != null) {
        params['start_date'] = _dateRange!.start.toIso8601String().split('T').first;
        params['end_date'] = _dateRange!.end.toIso8601String().split('T').first;
      }

      final result = await _api.get(ApiConfig.financialIncomeExpense, queryParameters: params);
      final data = result['data'] is List ? result['data'] as List : [];
      final pagination = result['pagination'] as Map<String, dynamic>?;

      if (mounted) {
        setState(() {
          _records = [..._records, ...data];
          _currentPage = nextPage;
          if (pagination != null) {
            _total = pagination['total'] ?? _records.length;
            _totalPages = pagination['last_page'] ?? 1;
          }
          _loadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      _fetchData();
    }
  }

  void _clearDateRange() {
    setState(() => _dateRange = null);
    _fetchData();
  }

  void _showRecordBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => _IncomeExpenseRecordSheet(onSuccess: _fetchData),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('收支明细')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showRecordBottomSheet,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : _records.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.textHint),
                            const SizedBox(height: 12),
                            const Text('暂无收支记录', style: TextStyle(color: AppTheme.textHint, fontSize: 15)),
                            const SizedBox(height: 8),
                            Text('点击右下角 + 按钮添加记录', style: TextStyle(color: AppTheme.textHint.withOpacity(0.7), fontSize: 13)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchData,
                        color: AppTheme.primaryColor,
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification is ScrollEndNotification && notification.metrics.pixels >= notification.metrics.maxScrollExtent - 100) {
                              _loadMore();
                            }
                            return false;
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _records.length + (_loadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _records.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor))),
                                );
                              }
                              return _buildRecordItem(_records[index] as Map<String, dynamic>);
                            },
                          ),
                        ),
                      ),
          ),
          _buildPageInfo(),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                _buildFilterChip('全部', 'all'),
                const SizedBox(width: 6),
                _buildFilterChip('收入', 'receivable'),
                const SizedBox(width: 6),
                _buildFilterChip('支出', 'payable'),
              ],
            ),
          ),
          GestureDetector(
            onTap: _pickDateRange,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _dateRange != null ? AppTheme.primaryColor.withOpacity(0.1) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.date_range, size: 16, color: _dateRange != null ? AppTheme.primaryColor : AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    _dateRange != null
                        ? '${_dateRange!.start.month}/${_dateRange!.start.day}-${_dateRange!.end.month}/${_dateRange!.end.day}'
                        : '日期',
                    style: TextStyle(fontSize: 12, color: _dateRange != null ? AppTheme.primaryColor : AppTheme.textSecondary),
                  ),
                  if (_dateRange != null) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: _clearDateRange,
                      child: const Icon(Icons.close, size: 14, color: AppTheme.primaryColor),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final selected = _typeFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _typeFilter = value);
        _fetchData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 13, color: selected ? Colors.white : AppTheme.textSecondary, fontWeight: selected ? FontWeight.w600 : FontWeight.normal),
        ),
      ),
    );
  }

  Widget _buildRecordItem(Map<String, dynamic> data) {
    final isIncome = (data['type'] ?? '') == 'receivable';
    final categoryLabel = data['category_label'] ?? data['category'] ?? '';
    final counterpartyName = data['counterparty_name'] ?? '';
    final paymentDate = data['payment_date'] ?? '';
    final paymentMethod = _paymentMethodLabel(data['payment_method'] ?? '');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(14),
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
                Row(
                  children: [
                    Text(categoryLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
                    if (counterpartyName.isNotEmpty && counterpartyName != '-') ...[
                      const SizedBox(width: 8),
                      Expanded(child: Text(counterpartyName, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary), overflow: TextOverflow.ellipsis)),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (paymentDate.isNotEmpty) Text(paymentDate, style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
                    if (paymentMethod.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(paymentMethod, style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
                    ],
                  ],
                ),
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
  }

  String _paymentMethodLabel(String method) {
    const map = {'cash': '现金', 'transfer': '转账', 'wechat': '微信', 'alipay': '支付宝'};
    return map[method] ?? method;
  }

  Widget _buildPageInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border.withOpacity(0.5))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('共 $_total 条', style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
                  icon: const Icon(Icons.chevron_left, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('$_currentPage/$_totalPages', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
                ),
                IconButton(
                  onPressed: _hasMore ? () => _goToPage(_currentPage + 1) : null,
                  icon: const Icon(Icons.chevron_right, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _goToPage(int page) async {
    setState(() => _loading = true);
    try {
      final params = <String, dynamic>{'page': page, 'per_page': 15};
      if (_typeFilter != 'all') params['type'] = _typeFilter;
      if (_dateRange != null) {
        params['start_date'] = _dateRange!.start.toIso8601String().split('T').first;
        params['end_date'] = _dateRange!.end.toIso8601String().split('T').first;
      }

      final result = await _api.get(ApiConfig.financialIncomeExpense, queryParameters: params);
      final data = result['data'] is List ? result['data'] as List : [];
      final pagination = result['pagination'] as Map<String, dynamic>?;

      if (mounted) {
        setState(() {
          _records = data;
          _currentPage = page;
          _total = pagination?['total'] ?? data.length;
          _totalPages = pagination?['last_page'] ?? 1;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _IncomeExpenseRecordSheet extends StatefulWidget {
  final VoidCallback onSuccess;

  const _IncomeExpenseRecordSheet({required this.onSuccess});

  @override
  State<_IncomeExpenseRecordSheet> createState() => _IncomeExpenseRecordSheetState();
}

class _IncomeExpenseRecordSheetState extends State<_IncomeExpenseRecordSheet> {
  final ApiService _api = ApiService.instance;
  final _formKey = GlobalKey<FormState>();
  final _counterpartController = TextEditingController();
  final _amountController = TextEditingController();
  final _remarkController = TextEditingController();

  String _type = 'payable';
  String _category = 'purchase_payment';
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
    _type = 'payable';
    _category = 'purchase_payment';
  }

  @override
  void dispose() {
    _counterpartController.dispose();
    _amountController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  void _switchType(bool isExpense) {
    setState(() {
      _type = isExpense ? 'payable' : 'receivable';
      _category = isExpense ? 'purchase_payment' : 'order_income';
    });
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
        Navigator.pop(context);
        widget.onSuccess();
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
    final isExpense = _type == 'payable';
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
                  const Text('记一笔', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('收入'),
                    selected: !isExpense,
                    onSelected: (_) => _switchType(false),
                    selectedColor: Colors.green.withOpacity(0.2),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('支出'),
                    selected: isExpense,
                    onSelected: (_) => _switchType(true),
                    selectedColor: Colors.red.withOpacity(0.2),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                    backgroundColor: isExpense ? AppTheme.dangerColor : AppTheme.successColor,
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
