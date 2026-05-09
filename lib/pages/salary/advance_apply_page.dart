import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';

/// 预支申请页
class AdvanceApplyPage extends StatefulWidget {
  const AdvanceApplyPage({super.key});

  @override
  State<AdvanceApplyPage> createState() => _AdvanceApplyPageState();
}

class _AdvanceApplyPageState extends State<AdvanceApplyPage> {
  final ApiService _api = ApiService.instance;
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _remarkController = TextEditingController();

  String _selectedType = 'cash'; // cash / transfer
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('申请预支')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 金额输入
              _buildSectionTitle('预支金额'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return '请输入预支金额';
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) return '请输入有效金额';
                  return null;
                },
                decoration: const InputDecoration(
                  hintText: '请输入预支金额',
                  prefixText: '¥ ',
                  prefixStyle: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 类型选择
              _buildSectionTitle('预支类型'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTypeOption(
                      icon: Icons.money_outlined,
                      label: '现金',
                      value: 'cash',
                      isSelected: _selectedType == 'cash',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTypeOption(
                      icon: Icons.swap_horiz_outlined,
                      label: '转账',
                      value: 'transfer',
                      isSelected: _selectedType == 'transfer',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 备注
              _buildSectionTitle('备注'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _remarkController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: '请输入备注信息（选填）',
                ),
              ),
              const SizedBox(height: 40),

              // 提交按钮
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          '提交申请',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// 区块标题
  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        if (title.contains('必填'))
          const Text(
            ' *',
            style: TextStyle(color: AppTheme.dangerColor, fontSize: 15),
          ),
      ],
    );
  }

  /// 类型选项卡片
  Widget _buildTypeOption({
    required IconData icon,
    required String label,
    required String value,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 提交申请
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final amount = double.parse(_amountController.text);
      await _api.post(
        ApiConfig.workerApplyAdvance,
        data: {
          'amount': amount,
          'type': _selectedType,
          if (_remarkController.text.isNotEmpty) 'remark': _remarkController.text,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('预支申请已提交，请等待审批'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('提交失败: ${_parseError(e)}'),
            backgroundColor: AppTheme.dangerColor,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// 解析错误信息
  String _parseError(dynamic e) {
    final msg = ApiException.fromDynamic(e).friendlyMessage;
    if (msg.contains('网络') || msg.contains('Connection')) {
      return '网络连接失败，请检查网络';
    }
    // 尝试提取 ApiException 中的 message
    final match = RegExp(r'message[:\s]+(.+)').firstMatch(msg);
    if (match != null) return match.group(1) ?? msg;
    return msg.length > 50 ? '${msg.substring(0, 50)}...' : msg;
  }
}
