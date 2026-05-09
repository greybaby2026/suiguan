import '../config/api_config.dart';
import '../models/warehouse.dart';
import '../models/inventory_item.dart';
import '../models/stock_movement.dart';
import 'api_service.dart';

class WarehouseService {
  final ApiService _api = ApiService.instance;

  Future<List<WarehouseModel>> getWarehouses() async {
    final response = await _api.get(ApiConfig.warehouses);
    final data = response['data'] ?? response;
    if (data is List) {
      return data.map((e) => WarehouseModel.fromJson(e)).toList();
    }
    if (data is Map && data.containsKey('data')) {
      final list = data['data'] as List;
      return list.map((e) => WarehouseModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<InventoryItemModel>> getInventories({
    int? warehouseId,
    String? itemType,
    String? keyword,
    int page = 1,
  }) async {
    final queryParams = <String, dynamic>{'page': page};
    if (warehouseId != null) queryParams['warehouse_id'] = warehouseId;
    if (itemType != null) queryParams['item_type'] = itemType;
    if (keyword != null) queryParams['keyword'] = keyword;

    final response = await _api.get(
      ApiConfig.inventories,
      queryParameters: queryParams,
    );

    final data = response['data'] ?? response;
    if (data is List) {
      return data.map((e) => InventoryItemModel.fromJson(e)).toList();
    }
    if (data is Map && data.containsKey('data')) {
      final list = data['data'] as List;
      return list.map((e) => InventoryItemModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<InventoryItemModel> getInventoryDetail(int id) async {
    final response = await _api.get('${ApiConfig.inventories}/$id');
    final data = response['data'] ?? response;
    return InventoryItemModel.fromJson(data);
  }

  Future<List<StockMovementModel>> getStockMovements({
    int? warehouseId,
    String? type,
    int page = 1,
  }) async {
    final queryParams = <String, dynamic>{'page': page};
    if (warehouseId != null) queryParams['warehouse_id'] = warehouseId;
    if (type != null) queryParams['type'] = type;

    final response = await _api.get(
      ApiConfig.stockMovements,
      queryParameters: queryParams,
    );

    final data = response['data'] ?? response;
    if (data is List) {
      return data.map((e) => StockMovementModel.fromJson(e)).toList();
    }
    if (data is Map && data.containsKey('data')) {
      final list = data['data'] as List;
      return list.map((e) => StockMovementModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<void> createStockMovement({
    required int warehouseId,
    required String itemType,
    required int itemId,
    required String type,
    required double quantity,
    String? remark,
  }) async {
    await _api.post(
      ApiConfig.stockMovements,
      data: {
        'warehouse_id': warehouseId,
        'item_type': itemType,
        'item_id': itemId,
        'type': type,
        'quantity': quantity,
        if (remark != null) 'remark': remark,
      },
    );
  }

  Future<InventoryItemModel> scanInventory(String code) async {
    final response = await _api.get(
      ApiConfig.inventories,
      queryParameters: {'keyword': code},
    );

    final data = response['data'] ?? response;
    if (data is List && data.isNotEmpty) {
      return InventoryItemModel.fromJson(data.first);
    }
    if (data is Map && data.containsKey('data')) {
      final list = data['data'] as List;
      if (list.isNotEmpty) {
        return InventoryItemModel.fromJson(list.first);
      }
    }
    throw Exception('未找到对应库存信息');
  }
}
