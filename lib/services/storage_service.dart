import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static StorageService? _instance;
  SharedPreferences? _prefs;

  StorageService._();

  static StorageService get instance {
    _instance ??= StorageService._();
    return _instance!;
  }

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static const String _keyToken = 'auth_token';
  static const String _keyWorkerId = 'worker_id';
  static const String _keyWorkerCode = 'worker_code';
  static const String _keyWorkerName = 'worker_name';
  static const String _keyWorkerPhone = 'worker_phone';
  static const String _keyTenantCode = 'tenant_code';
  static const String _keyTenantId = 'tenant_id';
  static const String _keyTenantName = 'tenant_name';
  static const String _keyUserId = 'user_id';
  static const String _keyLoginType = 'login_type';
  static const String _keyFeatures = 'subscription_features';

  Future<void> saveToken(String token) async {
    final p = await prefs;
    await p.setString(_keyToken, token);
  }

  Future<String?> getToken() async {
    final p = await prefs;
    return p.getString(_keyToken);
  }

  Future<void> saveWorkerInfo({
    required int workerId,
    required String code,
    required String name,
    String? phone,
  }) async {
    final p = await prefs;
    await p.setInt(_keyWorkerId, workerId);
    await p.setString(_keyWorkerCode, code);
    await p.setString(_keyWorkerName, name);
    if (phone != null) await p.setString(_keyWorkerPhone, phone);
  }

  Future<void> saveTenantInfo({
    required String code,
    required int tenantId,
    required String name,
  }) async {
    final p = await prefs;
    await p.setString(_keyTenantCode, code);
    await p.setInt(_keyTenantId, tenantId);
    await p.setString(_keyTenantName, name);
  }

  Future<void> saveUserId(int userId) async {
    final p = await prefs;
    await p.setInt(_keyUserId, userId);
  }

  Future<void> saveLoginType(String type) async {
    final p = await prefs;
    await p.setString(_keyLoginType, type);
  }

  Future<void> saveFeatures(List<String> features) async {
    final p = await prefs;
    await p.setString(_keyFeatures, jsonEncode(features));
  }

  List<String> get features {
    final str = _prefs?.getString(_keyFeatures);
    if (str == null || str.isEmpty) return [];
    try {
      final list = jsonDecode(str) as List;
      return list.cast<String>();
    } catch (_) {
      return [];
    }
  }

  int? get workerId => _prefs?.getInt(_keyWorkerId);
  String? get workerCode => _prefs?.getString(_keyWorkerCode);
  String? get workerName => _prefs?.getString(_keyWorkerName);
  String? get workerPhone => _prefs?.getString(_keyWorkerPhone);
  String? get tenantCode => _prefs?.getString(_keyTenantCode);
  int? get tenantId => _prefs?.getInt(_keyTenantId);
  String? get tenantName => _prefs?.getString(_keyTenantName);
  int? get userId => _prefs?.getInt(_keyUserId);
  String? get loginType => _prefs?.getString(_keyLoginType);

  Future<void> clearAuth() async {
    final p = await prefs;
    await p.remove(_keyToken);
    await p.remove(_keyWorkerId);
    await p.remove(_keyWorkerCode);
    await p.remove(_keyWorkerName);
    await p.remove(_keyWorkerPhone);
    await p.remove(_keyTenantCode);
    await p.remove(_keyTenantId);
    await p.remove(_keyTenantName);
    await p.remove(_keyUserId);
    await p.remove(_keyLoginType);
    await p.remove(_keyFeatures);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
