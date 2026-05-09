import '../services/api_service.dart';
import 'package:flutter/foundation.dart';
import '../models/production_task.dart';
import '../models/production_order.dart';
import '../models/dashboard.dart';
import '../services/production_service.dart';

class ProductionProvider extends ChangeNotifier {
  final ProductionService _service = ProductionService();

  DashboardStats? _stats;
  List<OrderStatusItem> _orderStatus = [];
  List<ProductionProgressItem> _progress = [];
  List<ProductionTaskModel> _myTasks = [];
  List<ProductionOrderModel> _orders = [];
  bool _isLoading = false;
  String? _error;

  DashboardStats? get stats => _stats;
  List<OrderStatusItem> get orderStatus => _orderStatus;
  List<ProductionProgressItem> get progress => _progress;
  List<ProductionTaskModel> get myTasks => _myTasks;
  List<ProductionOrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 独立请求，单个失败不影响其他请求
      final statsResult = await _service.getDashboardStats().catchError((e) => DashboardStats());
      final orderStatusResult = await _service.getOrderStatusDistribution().catchError((e) => <OrderStatusItem>[]);
      final progressResult = await _service.getProductionProgress().catchError((e) => <ProductionProgressItem>[]);

      _stats = statsResult;
      _orderStatus = orderStatusResult;
      _progress = progressResult;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = ApiException.fromDynamic(e).friendlyMessage;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      _myTasks = await _service.getMyTasks();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = ApiException.fromDynamic(e).friendlyMessage;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadOrders({String? status}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _service.getProductionOrders(status: status);
      final data = response['data'] ?? response;
      if (data is List) {
        _orders = data.map((e) => ProductionOrderModel.fromJson(e)).toList();
      } else if (data is Map && data.containsKey('data')) {
        final list = data['data'] as List;
        _orders = list.map((e) => ProductionOrderModel.fromJson(e)).toList();
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = ApiException.fromDynamic(e).friendlyMessage;
      _isLoading = false;
      notifyListeners();
    }
  }
}
