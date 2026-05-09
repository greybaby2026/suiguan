import '../config/api_config.dart';
import '../models/user.dart';
import '../models/worker.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _api = ApiService.instance;
  final StorageService _storage = StorageService.instance;

  /// 工人登录：工号 + PIN（走统一 /auth/login）
  Future<Map<String, dynamic>> workerLogin({
    required String tenantCode,
    required String code,
    required String pin,
  }) async {
    final response = await _api.post(
      ApiConfig.authLogin,
      data: {
        'tenant_code': tenantCode,
        'code': code,
        'pin': pin,
      },
    );

    final data = response['data'] ?? response;
    await _persistLoginData(data, 'worker');
    return data;
  }

  /// 管理员登录：账号 + 密码（走统一 /auth/login）
  Future<Map<String, dynamic>> adminLogin({
    required String account,
    required String password,
    required String tenantCode,
  }) async {
    final response = await _api.post(
      ApiConfig.authLogin,
      data: {
        'tenant_code': tenantCode,
        'account': account,
        'password': password,
      },
    );

    final data = response['data'] ?? response;
    await _persistLoginData(data, 'admin');
    return data;
  }

  /// 平台超级管理员登录
  Future<Map<String, dynamic>> superAdminLogin({
    required String account,
    required String password,
  }) async {
    final response = await _api.post(
      ApiConfig.authLogin,
      data: {
        'tenant_code': 'platform',
        'account': account,
        'password': password,
      },
    );

    final data = response['data'] ?? response;
    await _persistLoginData(data, 'super_admin');
    return data;
  }

  /// 持久化登录数据到本地存储
  Future<void> _persistLoginData(Map<String, dynamic> data, String loginType) async {
    final token = data['token'] as String?;
    if (token == null) return;

    await _storage.saveToken(token);
    await _storage.saveLoginType(loginType);

    final userData = data['user'] as Map<String, dynamic>?;
    if (userData != null) {
      final user = UserModel.fromJson(userData);
      await _storage.saveUserId(user.id);
    }

    final tenantData = data['tenant'] as Map<String, dynamic>?;
    if (tenantData != null) {
      await _storage.saveTenantInfo(
        code: tenantData['tenant_code']?.toString() ?? '',
        tenantId: (tenantData['id'] as num).toInt(),
        name: tenantData['company_name']?.toString() ?? '',
      );
    }

    final workerData = data['worker'] as Map<String, dynamic>?;
    if (workerData != null) {
      final worker = WorkerModel.fromJson(workerData);
      await _storage.saveWorkerInfo(
        workerId: worker.id,
        code: worker.code,
        name: worker.name,
      );
    }

    final featuresData = data['features'];
    if (featuresData is List) {
      await _storage.saveFeatures(featuresData.cast<String>());
    }
  }

  Future<List<Map<String, dynamic>>> searchTenants(String keyword) async {
    final response = await _api.get(
      ApiConfig.authTenants,
      queryParameters: {'keyword': keyword},
    );

    final list = response['data'] ?? response;
    if (list is List) {
      return list.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<UserModel> getMe() async {
    final response = await _api.get(ApiConfig.me);
    final data = response['data'] ?? response;
    return UserModel.fromJson(data);
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {}
    await _storage.clearAuth();
  }
}
