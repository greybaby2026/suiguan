import '../services/api_service.dart';
import 'package:flutter/foundation.dart';
import '../models/piece_record.dart';
import '../services/work_report_service.dart';

class WorkProvider extends ChangeNotifier {
  final WorkReportService _service = WorkReportService();

  List<PieceRecordModel> _pieceRecords = [];
  Map<String, dynamic>? _salary;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  List<PieceRecordModel> get pieceRecords => _pieceRecords;
  Map<String, dynamic>? get salary => _salary;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  Future<void> loadPieceRecords({
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _pieceRecords = await _service.getMyPieceRecords(
        status: status,
        startDate: startDate,
        endDate: endDate,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = ApiException.fromDynamic(e).friendlyMessage;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitPiece({
    required int processId,
    int? productionTaskId,
    int? productId,
    required double quantity,
    double defectQty = 0,
    required String workDate,
    String? remark,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      await _service.submitPiece(
        processId: processId,
        productionTaskId: productionTaskId,
        productId: productId,
        quantity: quantity,
        defectQty: defectQty,
        workDate: workDate,
        remark: remark,
      );
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiException.fromDynamic(e).friendlyMessage;
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadSalary({
    String? startDate,
    String? endDate,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _salary = await _service.getMySalary(
        startDate: startDate,
        endDate: endDate,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = ApiException.fromDynamic(e).friendlyMessage;
      _isLoading = false;
      notifyListeners();
    }
  }
}
