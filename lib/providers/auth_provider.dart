import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/worker.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storage = StorageService.instance;

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;
  WorkerModel? _worker;
  String _loginType = 'worker';
  String _savedTenantCode = '';
  List<String> _features = [];

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  WorkerModel? get worker => _worker;
  String get loginType => _loginType;
  bool get isWorker => _loginType == 'worker';
  bool get isAdmin => _loginType == 'admin' || _loginType == 'super_admin';
  String get savedTenantCode => _savedTenantCode;
  List<String> get features => _features;

  bool hasFeature(String featureKey) {
    if (_loginType == 'super_admin') return true;
    if (_loginType == 'worker') return true;
    if (_features.isEmpty) return true;
    return _features.contains(featureKey);
  }

  bool hasAnyFeature(List<String> featureKeys) {
    if (_loginType == 'super_admin') return true;
    if (_loginType == 'worker') return true;
    if (_features.isEmpty) return true;
    return featureKeys.any((key) => _features.contains(key));
  }

  Future<void> checkAuth() async {
    final loggedIn = await _storage.isLoggedIn();
    if (loggedIn) {
      _loginType = _storage.loginType ?? 'worker';
      _savedTenantCode = _storage.tenantCode ?? '';
      _features = _storage.features;
      if (_loginType == 'worker') {
        _worker = WorkerModel(
          id: _storage.workerId ?? 0,
          code: _storage.workerCode ?? '',
          name: _storage.workerName ?? '',
          status: 'active',
        );
      }
      _isAuthenticated = true;
    }
    notifyListeners();
  }

  Future<bool> workerLogin({
    required String tenantCode,
    required String code,
    required String pin,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _authService.workerLogin(
        tenantCode: tenantCode,
        code: code,
        pin: pin,
      );

      final workerData = data['worker'] as Map<String, dynamic>?;
      if (workerData != null) {
        _worker = WorkerModel.fromJson(workerData);
      }

      final featuresData = data['features'];
      if (featuresData is List) {
        _features = featuresData.cast<String>();
      }

      _savedTenantCode = tenantCode;
      _isAuthenticated = true;
      _loginType = 'worker';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> adminLogin({
    required String account,
    required String password,
    required String tenantCode,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _authService.adminLogin(
        account: account,
        password: password,
        tenantCode: tenantCode,
      );

      final featuresData = data['features'];
      if (featuresData is List) {
        _features = featuresData.cast<String>();
      }

      _savedTenantCode = tenantCode;
      _isAuthenticated = true;
      _loginType = 'admin';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshFeatures() async {
    try {
      final api = ApiService.instance;
      final response = await api.get(ApiConfig.subscriptionCurrent);
      final data = response['data'] ?? response;
      final planData = data['plan'];
      if (planData != null && planData is Map<String, dynamic>) {
        final featuresList = planData['features'];
        if (featuresList is List) {
          _features = featuresList
              .whereType<Map<String, dynamic>>()
              .where((f) => f['enabled'] == true)
              .map((f) => f['key'].toString())
              .toList();
          await _storage.saveFeatures(_features);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('刷新features失败: $e');
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _isAuthenticated = false;
    _worker = null;
    _error = null;
    _features = [];
    notifyListeners();
  }

  String _parseError(dynamic e) {
    final apiError = ApiException.fromDynamic(e);
    if (apiError.isAuthError) return '账号或密码错误';
    if (apiError.code == 404) return '企业不存在';
    return apiError.friendlyMessage;
  }
}
