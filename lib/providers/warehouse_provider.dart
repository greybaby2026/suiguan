import '../services/api_service.dart';
import 'package:flutter/foundation.dart';
import '../models/warehouse.dart';
import '../models/inventory_item.dart';
import '../models/stock_movement.dart';
import '../services/warehouse_service.dart';

class WarehouseProvider extends ChangeNotifier {
  final WarehouseService _service = WarehouseService();

  List<WarehouseModel> _warehouses = [];
  List<InventoryItemModel> _inventories = [];
  List<StockMovementModel> _movements = [];
  bool _isLoading = false;
  bool _isScanning = false;
  String? _error;
  InventoryItemModel? _scannedItem;

  List<WarehouseModel> get warehouses => _warehouses;
  List<InventoryItemModel> get inventories => _inventories;
  List<StockMovementModel> get movements => _movements;
  bool get isLoading => _isLoading;
  bool get isScanning => _isScanning;
  String? get error => _error;
  InventoryItemModel? get scannedItem => _scannedItem;

  Future<void> loadWarehouses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _warehouses = await _service.getWarehouses();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = ApiException.fromDynamic(e).friendlyMessage;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadInventories({int? warehouseId, String? itemType, String? keyword}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _inventories = await _service.getInventories(
        warehouseId: warehouseId,
        itemType: itemType,
        keyword: keyword,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = ApiException.fromDynamic(e).friendlyMessage;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStockMovements({int? warehouseId, String? type}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _movements = await _service.getStockMovements(
        warehouseId: warehouseId,
        type: type,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = ApiException.fromDynamic(e).friendlyMessage;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> scanItem(String code) async {
    _isScanning = true;
    _error = null;
    _scannedItem = null;
    notifyListeners();

    try {
      _scannedItem = await _service.scanInventory(code);
      _isScanning = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiException.fromDynamic(e).friendlyMessage;
      _isScanning = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createMovement({
    required int warehouseId,
    required String itemType,
    required int itemId,
    required String type,
    required double quantity,
    String? remark,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.createStockMovement(
        warehouseId: warehouseId,
        itemType: itemType,
        itemId: itemId,
        type: type,
        quantity: quantity,
        remark: remark,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiException.fromDynamic(e).friendlyMessage;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
