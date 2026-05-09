import '../utils/number_utils.dart';

class PieceRecordModel {
  final int id;
  final int? workerId;
  final String? processName;
  final double quantity;
  final double unitPrice;
  final double amount;
  final double defectQty;
  final String? workDate;
  final String status;
  final String? remark;
  final String? createdAt;
  final String? rejectReason;

  PieceRecordModel({
    required this.id,
    this.workerId,
    this.processName,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
    required this.defectQty,
    this.workDate,
    required this.status,
    this.remark,
    this.createdAt,
    this.rejectReason,
  });

  factory PieceRecordModel.fromJson(Map<String, dynamic> json) {
    return PieceRecordModel(
      id: json['id'] ?? 0,
      workerId: json['worker_id'],
      processName: json['process_name'] ?? json['process']?['name'],
      quantity: safeToDouble(json['quantity']),
      unitPrice: safeToDouble(json['piece_price'] ?? json['unit_price']),
      amount: safeToDouble(json['amount']),
      defectQty: safeToDouble(json['defect_qty']),
      workDate: json['work_date'],
      status: json['status'] ?? 'pending',
      remark: json['remark'],
      createdAt: json['created_at'],
      rejectReason: json['reject_reason'],
    );
  }

  String get statusLabel {
    const map = {
      'pending': '待审核',
      'approved': '已通过',
      'rejected': '已驳回',
    };
    return map[status] ?? '未知';
  }

  int get statusColor {
    const map = {
      'pending': 0xFFF59E0B,
      'approved': 0xFF10B981,
      'rejected': 0xFFEF4444,
    };
    return map[status] ?? 0xFF64748B;
  }
}
