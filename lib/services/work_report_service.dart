import '../config/api_config.dart';
import '../models/piece_record.dart';
import 'api_service.dart';

class WorkReportService {
  final ApiService _api = ApiService.instance;

  Future<Map<String, dynamic>> submitPiece({
    required int processId,
    int? productionTaskId,
    int? productId,
    required double quantity,
    double defectQty = 0,
    required String workDate,
    String? remark,
  }) async {
    final response = await _api.post(
      ApiConfig.workerSubmitPiece,
      data: {
        'process_id': processId,
        if (productionTaskId != null) 'production_task_id': productionTaskId,
        if (productId != null) 'product_id': productId,
        'quantity': quantity,
        'defect_qty': defectQty,
        'work_date': workDate,
        if (remark != null) 'remark': remark,
      },
    );
    return response['data'] ?? response;
  }

  Future<List<PieceRecordModel>> getMyPieceRecords({
    String? status,
    String? startDate,
    String? endDate,
    int page = 1,
  }) async {
    final queryParams = <String, dynamic>{'page': page};
    if (status != null) queryParams['status'] = status;
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;

    final response = await _api.get(
      ApiConfig.workerMyPieceRecords,
      queryParameters: queryParams,
    );

    final data = response['data'] ?? response;
    if (data is List) {
      return data.map((e) => PieceRecordModel.fromJson(e)).toList();
    }
    if (data is Map && data.containsKey('data')) {
      final list = data['data'] as List;
      return list.map((e) => PieceRecordModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> getMySalary({
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, dynamic>{};
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;

    final response = await _api.get(
      ApiConfig.workerMySalary,
      queryParameters: queryParams,
    );
    return response['data'] ?? response;
  }

  Future<Map<String, dynamic>> submitWorkReport({
    required int productionTaskId,
    required double quantity,
    double defectQty = 0,
    String? remark,
  }) async {
    final response = await _api.post(
      ApiConfig.workReports,
      data: {
        'production_task_id': productionTaskId,
        'quantity': quantity,
        'defect_qty': defectQty,
        if (remark != null) 'remark': remark,
        'reported_at': DateTime.now().toIso8601String(),
      },
    );
    return response['data'] ?? response;
  }
}
