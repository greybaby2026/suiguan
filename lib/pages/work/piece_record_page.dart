import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/work_provider.dart';
import '../../models/piece_record.dart';

class PieceRecordPage extends StatefulWidget {
  const PieceRecordPage({super.key});

  @override
  State<PieceRecordPage> createState() => _PieceRecordPageState();
}

class _PieceRecordPageState extends State<PieceRecordPage> {
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkProvider>().loadPieceRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    final workProvider = context.watch<WorkProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('计件记录')),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: workProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : workProvider.pieceRecords.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox_outlined, size: 48, color: AppTheme.textHint),
                            SizedBox(height: 8),
                            Text('暂无记录', style: TextStyle(color: AppTheme.textHint)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => context.read<WorkProvider>().loadPieceRecords(
                              status: _filterStatus,
                            ),
                        color: AppTheme.primaryColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: workProvider.pieceRecords.length,
                          itemBuilder: (context, index) {
                            return _buildRecordCard(workProvider.pieceRecords[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          _FilterChip(
            label: '全部',
            isSelected: _filterStatus == null,
            onTap: () {
              setState(() => _filterStatus = null);
              context.read<WorkProvider>().loadPieceRecords();
            },
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: '待审核',
            isSelected: _filterStatus == 'pending',
            color: AppTheme.warningColor,
            onTap: () {
              setState(() => _filterStatus = 'pending');
              context.read<WorkProvider>().loadPieceRecords(status: 'pending');
            },
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: '已通过',
            isSelected: _filterStatus == 'approved',
            color: AppTheme.successColor,
            onTap: () {
              setState(() => _filterStatus = 'approved');
              context.read<WorkProvider>().loadPieceRecords(status: 'approved');
            },
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: '已驳回',
            isSelected: _filterStatus == 'rejected',
            color: AppTheme.dangerColor,
            onTap: () {
              setState(() => _filterStatus = 'rejected');
              context.read<WorkProvider>().loadPieceRecords(status: 'rejected');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(PieceRecordModel record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  record.processName ?? '工序',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Color(record.statusColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  record.statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(record.statusColor),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _InfoItem(label: '数量', value: '${record.quantity.toStringAsFixed(0)}件'),
              const SizedBox(width: 20),
              _InfoItem(label: '单价', value: '¥${record.unitPrice.toStringAsFixed(2)}'),
              const SizedBox(width: 20),
              _InfoItem(
                label: '金额',
                value: '¥${record.amount.toStringAsFixed(2)}',
                valueColor: AppTheme.primaryColor,
              ),
            ],
          ),
          if (record.defectQty > 0) ...[
            const SizedBox(height: 6),
            Text(
              '次品: ${record.defectQty.toStringAsFixed(0)}件',
              style: const TextStyle(fontSize: 12, color: AppTheme.dangerColor),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                record.workDate ?? '',
                style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
              ),
              if (record.rejectReason != null)
                Text(
                  '驳回原因: ${record.rejectReason}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.dangerColor),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppTheme.primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : const Color(0xFFF1F5F9),
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
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
