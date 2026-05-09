import '../config/api_config.dart';
import '../models/production_task.dart';
import '../models/production_order.dart';
import '../models/dashboard.dart';
import 'api_service.dart';

class ProductionService {
  final ApiService _api = ApiService.instance;

  Future<DashboardStats> getDashboardStats() async {
    final response = await _api.get(ApiConfig.dashboardStatistics);
    final data = response['data'] ?? response;
    return DashboardStats.fromJson(data);
  }

  Future<List<OrderStatusItem>> getOrderStatusDistribution() async {
    final response = await _api.get(ApiConfig.dashboardOrderStatus);
    final data = response['data'] ?? response;
    if (data is List) {
      return data.map((e) => OrderStatusItem.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<ProductionProgressItem>> getProductionProgress() async {
    final response = await _api.get(ApiConfig.dashboardProductionProgress);
    final data = response['data'] ?? response;
    if (data is List) {
      return data.map((e) => ProductionProgressItem.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<ProductionTaskModel>> getMyTasks() async {
    final response = await _api.get(ApiConfig.workerMyTasks);
    final data = response['data'] ?? response;
    if (data is List) {
      return data.map((e) => ProductionTaskModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> getProductionOrders({
    int page = 1,
    int pageSize = 10,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (status != null) queryParams['status'] = status;

    final response = await _api.get(
      ApiConfig.productionOrders,
      queryParameters: queryParams,
    );
    return response;
  }

  Future<ProductionOrderModel> getProductionOrderDetail(int id) async {
    final response = await _api.get('${ApiConfig.productionOrders}/$id');
    final data = response['data'] ?? response;
    return ProductionOrderModel.fromJson(data);
  }

  Future<void> scheduleProduction(int id, {
    required int processRouteId,
    String? plannedStart,
    String? plannedEnd,
  }) async {
    final data = <String, dynamic>{
      'process_route_id': processRouteId,
    };
    if (plannedStart != null) data['planned_start_date'] = plannedStart;
    if (plannedEnd != null) data['planned_end_date'] = plannedEnd;
    await _api.post(
      ApiConfig.replaceId(ApiConfig.productionOrderSchedule, id),
      data: data,
    );
  }

  Future<void> startProduction(int id) async {
    await _api.post(
      ApiConfig.replaceId(ApiConfig.productionOrderStart, id),
    );
  }

  Future<void> completeProduction(int id, {bool force = false}) async {
    await _api.post(
      ApiConfig.replaceId(ApiConfig.productionOrderComplete, id),
      data: force ? {'force': true} : null,
    );
  }

  Future<void> cancelProduction(int id) async {
    await _api.post(
      ApiConfig.replaceId(ApiConfig.productionOrderCancel, id),
    );
  }
}
