import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'storage_service.dart';

class ApiService {
  static ApiService? _instance;
  late final Dio _dio;
  final StorageService _storage = StorageService.instance;

  ApiService._() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onResponse: _onResponse,
      onError: _onError,
    ));
  }

  static ApiService get instance {
    _instance ??= ApiService._();
    return _instance!;
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  void _onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    handler.next(response);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      await _storage.clearAuth();
    }

    if (err.response?.data is Map<String, dynamic>) {
      final data = err.response!.data as Map<String, dynamic>;
      handler.next(DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: ApiException(
          code: data['code'] ?? err.response?.statusCode ?? -1,
          message: data['message'] ?? err.message ?? '请求失败',
        ),
      ));
      return;
    }

    handler.next(err);
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get(
      path,
      queryParameters: queryParameters,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.delete(
      path,
      queryParameters: queryParameters,
    );
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(Response response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      if (data['code'] == 0 || data['success'] == true) {
        final unwrapped = _unwrapPaginatedData(data);
        return unwrapped;
      }
      throw ApiException(
        code: data['code'] ?? -1,
        message: data['message'] ?? '请求失败',
      );
    }
    return {'data': data};
  }

  Map<String, dynamic> _unwrapPaginatedData(Map<String, dynamic> response) {
    final dataField = response['data'];
    if (dataField is Map<String, dynamic> && dataField.containsKey('list')) {
      final list = dataField['list'];
      final pagination = dataField['pagination'];
      return {
        'code': response['code'],
        'message': response['message'],
        'data': list,
        if (pagination != null) 'pagination': pagination,
      };
    }
    return response;
  }
}

class ApiException implements Exception {
  final int code;
  final String message;

  ApiException({required this.code, required this.message});

  bool get isSubscriptionError => code == 40302;
  bool get isFeatureError => code == 40303;
  bool get isPermissionError => code == 40301;
  bool get isAuthError => code == 40101;

  String get friendlyMessage {
    if (isFeatureError) return '当前套餐未包含此功能';
    if (isSubscriptionError) return '订阅已过期，请联系管理员续费';
    if (isPermissionError) return '暂无权限访问';
    if (isAuthError) return '登录已过期，请重新登录';
    return message;
  }

  static ApiException fromDynamic(dynamic e) {
    if (e is DioException) {
      final error = e.error;
      if (error is ApiException) return error;
      if (e.response?.data is Map<String, dynamic>) {
        final data = e.response!.data as Map<String, dynamic>;
        return ApiException(
          code: data['code'] ?? e.response?.statusCode ?? -1,
          message: data['message'] ?? '请求失败',
        );
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return ApiException(code: -1, message: '网络连接超时，请重试');
      }
      if (e.type == DioExceptionType.connectionError) {
        return ApiException(code: -1, message: '网络连接失败，请检查网络');
      }
      return ApiException(code: -1, message: '请求失败，请重试');
    }
    if (e is ApiException) return e;
    return ApiException(code: -1, message: '操作失败，请重试');
  }

  @override
  String toString() => 'ApiException($code): $message';
}
