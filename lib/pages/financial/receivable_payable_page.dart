import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../utils/number_utils.dart';

class ReceivablePayablePage extends StatefulWidget {
  const ReceivablePayablePage({super.key});

  @override
  State<ReceivablePayablePage> createState() => _ReceivablePayablePageState();
}

class _ReceivablePayablePageState extends State<ReceivablePayablePage> {
  final ApiService _api = ApiService.instance;
  Map<String, dynamic>? _data;
  bool _loading = true;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final result = await _api.get(ApiConfig.financialReceivablePayableNew);
      if (mounted) {
        setState(() {
          _data = result['data'] is Map<String, dynamic> ? result['data'] as Map<String, dynamic> : {};
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
      appBar: AppBar(title: const Text('应收应付')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : RefreshIndicator(
              onRefresh: _fetchData,
              color: AppTheme.primaryColor,
              child: Column(
                children: [
                  _buildSummaryCards(),
                  const SizedBox(height: 16),
                  _buildTabBar(),
                  Expanded(child: _tabIndex == 0 ? _buildReceivableList() : _buildPayableList()),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    final receivable = _data?['receivable'] as Map<String, dynamic>? ?? {};
    final payable = _data?['payable'] as Map<String, dynamic>? ?? {};
    final receivableTotal = safeToDouble(receivable['total']);
    final payableTotal = safeToDouble(payable['total']);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('应收总额', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text('¥${receivableTotal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.dangerColor, AppTheme.dangerColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('应付总额', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text('¥${payableTotal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _tabIndex == 0 ? AppTheme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '应收明细',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _tabIndex == 0 ? Colors.white : AppTheme.textSecondary,
                    fontWeight: _tabIndex == 0 ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _tabIndex == 1 ? AppTheme.dangerColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '应付明细',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _tabIndex == 1 ? Colors.white : AppTheme.textSecondary,
                    fontWeight: _tabIndex == 1 ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivableList() {
    final list = _data?['receivable_list'] as List? ?? [];
    if (list.isEmpty) {
      return const Center(child: Text('暂无应收数据', style: TextStyle(color: AppTheme.textHint)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index] as Map<String, dynamic>;
        return _buildListItem(
          name: item['customer_name'] ?? '',
          unpaid: safeToDouble(item['unpaid_amount']),
          paid: safeToDouble(item['paid_amount']),
          total: safeToDouble(item['total_amount']),
          isReceivable: true,
          onMark: () => _showMarkPaidSheet(context, item['id'], isReceivable: true),
        );
      },
    );
  }

  Widget _buildPayableList() {
    final list = _data?['payable_list'] as List? ?? [];
    if (list.isEmpty) {
      return const Center(child: Text('暂无应付数据', style: TextStyle(color: AppTheme.textHint)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index] as Map<String, dynamic>;
        return _buildListItem(
          name: item['supplier_name'] ?? '',
          unpaid: safeToDouble(item['unpaid_amount']),
          paid: safeToDouble(item['paid_amount']),
          total: safeToDouble(item['total_amount']),
          isReceivable: false,
          onMark: () => _showMarkPaidSheet(context, item['id'], isReceivable: false),
        );
      },
    );
  }

  Widget _buildListItem({
    required String name,
    required double unpaid,
    required double paid,
    required double total,
    required bool isReceivable,
    required VoidCallback onMark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              ),
              Text('¥${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('已${isReceivable ? '收' : '付'}', style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
                    Text('¥${paid.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, color: AppTheme.successColor, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('未${isReceivable ? '收' : '付'}', style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
                    Text('¥${unpaid.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, color: isReceivable ? AppTheme.warningColor : AppTheme.dangerColor, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              if (unpaid > 0)
                ElevatedButton(
                  onPressed: onMark,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isReceivable ? AppTheme.primaryColor : AppTheme.dangerColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(isReceivable ? '标记已收' : '标记已付', style: const TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMarkPaidSheet(BuildContext context, dynamic id, {required bool isReceivable}) {
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isReceivable ? '标记已收' : '标记已付',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                    IconButton(onPressed: () => Navigator.pop(sheetContext), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: isReceivable ? '收款金额' : '付款金额',
                    prefixText: '¥ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final amount = double.tryParse(amountController.text.trim());
                      if (amount == null || amount <= 0) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          const SnackBar(content: Text('请输入有效金额'), backgroundColor: AppTheme.dangerColor),
                        );
                        return;
                      }

                      try {
                        final endpoint = isReceivable
                            ? ApiConfig.financialReceivablePayableNew
                            : ApiConfig.financialReceivablePayableNew;
                        await _api.post('$endpoint/${id ?? 0}/${isReceivable ? 'mark-received' : 'mark-paid'}', data: {'amount': amount});

                        if (mounted) {
                          Navigator.pop(sheetContext);
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(content: Text('操作成功'), backgroundColor: AppTheme.successColor),
                          );
                          _fetchData();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(content: Text('操作失败，请重试'), backgroundColor: AppTheme.dangerColor),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isReceivable ? AppTheme.primaryColor : AppTheme.dangerColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('确认', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
