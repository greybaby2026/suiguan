import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/work_provider.dart';
import '../../providers/production_provider.dart';

class WorkReportPage extends StatefulWidget {
  const WorkReportPage({super.key});

  @override
  State<WorkReportPage> createState() => _WorkReportPageState();
}

class _WorkReportPageState extends State<WorkReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _defectQtyController = TextEditingController();
  final _remarkController = TextEditingController();
  int? _selectedTaskId;
  int? _selectedProcessId;
  String _workDate = DateTime.now().toIso8601String().split('T').first;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductionProvider>().loadMyTasks();
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _defectQtyController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  double get _availableQty {
    if (_selectedTaskId == null) return 0;
    final tasks = context.read<ProductionProvider>().myTasks;
    final task = tasks.where((t) => t.id == _selectedTaskId).firstOrNull;
    return task?.availableQty ?? 0;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final workProvider = context.read<WorkProvider>();
    final success = await workProvider.submitPiece(
      processId: _selectedProcessId!,
      productionTaskId: _selectedTaskId,
      quantity: double.parse(_quantityController.text),
      defectQty: double.tryParse(_defectQtyController.text) ?? 0,
      workDate: _workDate,
      remark: _remarkController.text.trim().isEmpty ? null : _remarkController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('报工提交成功'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(workProvider.error ?? '提交失败'),
          backgroundColor: AppTheme.dangerColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productionProvider = context.watch<ProductionProvider>();
    final workProvider = context.watch<WorkProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('报工')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTaskSelector(productionProvider),
              if (_selectedTaskId != null) ...[
                const SizedBox(height: 12),
                _buildTaskInfo(),
              ],
              const SizedBox(height: 16),
              _buildDateSelector(),
              const SizedBox(height: 16),
              _buildQuantityInput(),
              const SizedBox(height: 16),
              _buildDefectInput(),
              const SizedBox(height: 16),
              _buildRemarkInput(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: workProvider.isSubmitting ? null : _submit,
                  child: workProvider.isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('提交报工'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskSelector(ProductionProvider provider) {
    final tasks = provider.myTasks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '生产任务',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedTaskId,
              isExpanded: true,
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('选择生产任务', style: TextStyle(color: AppTheme.textHint)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              items: tasks.map((task) {
                final available = task.availableQty > 0
                    ? ' (可报${task.availableQty.toStringAsFixed(0)}件)'
                    : ' (已满)';
                return DropdownMenuItem<int>(
                  value: task.id,
                  child: Text(
                    '${task.processName ?? "任务${task.id}"} - ${task.quantity.toStringAsFixed(0)}件$available',
                    style: TextStyle(
                      fontSize: 14,
                      color: task.availableQty > 0 ? AppTheme.textPrimary : AppTheme.textHint,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTaskId = value;
                  _quantityController.clear();
                  if (value != null) {
                    final task = tasks.where((t) => t.id == value).firstOrNull;
                    _selectedProcessId = task?.processId;
                  }
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskInfo() {
    final tasks = context.read<ProductionProvider>().myTasks;
    final task = tasks.where((t) => t.id == _selectedTaskId).firstOrNull;
    if (task == null) return const SizedBox.shrink();

    final isFull = task.availableQty <= 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isFull ? AppTheme.dangerColor.withOpacity(0.06) : AppTheme.primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isFull ? AppTheme.dangerColor.withOpacity(0.2) : AppTheme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (task.orderNo != null)
            Text('工单: ${task.orderNo}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          if (task.productName != null) ...[
            const SizedBox(height: 4),
            Text('产品: ${task.productName}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              _buildInfoChip('计划', '${task.quantity.toStringAsFixed(0)}件', AppTheme.primaryColor),
              const SizedBox(width: 12),
              _buildInfoChip('已完成', '${task.completedQty.toStringAsFixed(0)}件', AppTheme.successColor),
              const SizedBox(width: 12),
              _buildInfoChip('待审核', '${task.pendingQty.toStringAsFixed(0)}件', AppTheme.warningColor),
              const SizedBox(width: 12),
              _buildInfoChip(
                '可报工',
                '${task.availableQty.toStringAsFixed(0)}件',
                isFull ? AppTheme.dangerColor : AppTheme.infoColor,
              ),
            ],
          ),
          if (isFull) ...[
            const SizedBox(height: 8),
            const Text(
              '⚠ 该任务已无可报工数量',
              style: TextStyle(fontSize: 13, color: AppTheme.dangerColor, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '工作日期',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.parse(_workDate),
              firstDate: DateTime(2024),
              lastDate: DateTime.now(),
              locale: const Locale('zh', 'CN'),
            );
            if (date != null) {
              setState(() => _workDate = date.toIso8601String().split('T').first);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 20, color: AppTheme.textSecondary),
                const SizedBox(width: 12),
                Text(
                  _workDate,
                  style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right, color: AppTheme.textHint),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityInput() {
    final available = _availableQty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _quantityController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: '请输入完成数量',
            labelText: '完成数量',
            prefixIcon: const Icon(Icons.check_circle_outline),
            suffixText: _selectedTaskId != null ? '/ ${available.toStringAsFixed(0)}件' : null,
            helperText: _selectedTaskId != null
                ? '本次最多可报 ${available.toStringAsFixed(0)} 件'
                : '请先选择生产任务',
            helperStyle: TextStyle(
              fontSize: 12,
              color: available > 0 ? AppTheme.infoColor : AppTheme.dangerColor,
            ),
          ),
          validator: (v) {
            if (v?.isEmpty == true) return '请输入完成数量';
            if (double.tryParse(v!) == null) return '请输入有效数字';
            if (double.parse(v) <= 0) return '数量必须大于0';
            if (_selectedTaskId != null && double.parse(v) > _availableQty) {
              return '超出可报工数量（最多${_availableQty.toStringAsFixed(0)}件）';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDefectInput() {
    return TextFormField(
      controller: _defectQtyController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        hintText: '次品数量（可选）',
        labelText: '次品数量',
        prefixIcon: Icon(Icons.error_outline),
      ),
    );
  }

  Widget _buildRemarkInput() {
    return TextFormField(
      controller: _remarkController,
      maxLines: 3,
      decoration: const InputDecoration(
        hintText: '备注（可选）',
        labelText: '备注',
        alignLabelWithHint: true,
      ),
    );
  }
}
