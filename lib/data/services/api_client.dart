import 'package:dio/dio.dart';
import '../storage/token_storage.dart';
import '../storage/device_storage.dart';
import '../../core/config/app_config.dart';

/// Main API client with authentication interceptors
class ApiClient {
  late final Dio _dio;
  late final Dio _refreshDio; // Separate Dio for refresh requests (no interceptors)
  final TokenStorage _tokenStorage;
  final DeviceStorage _deviceStorage;

  ApiClient({
    required TokenStorage tokenStorage,
    required DeviceStorage deviceStorage,
  })  : _tokenStorage = tokenStorage,
        _deviceStorage = deviceStorage {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiUrl,
        connectTimeout: Duration(seconds: AppConfig.apiTimeoutSeconds),
        receiveTimeout: Duration(seconds: AppConfig.apiTimeoutSeconds * 2),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Separate Dio for refresh - no interceptors to avoid recursion
    _refreshDio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiUrl,
        connectTimeout: Duration(seconds: AppConfig.apiTimeoutSeconds),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(
        tokenStorage: _tokenStorage,
        deviceStorage: _deviceStorage,
        refreshDio: _refreshDio,
        dio: _dio,
      ),
      _LoggingInterceptor(),
    ]);
  }

  Dio get dio => _dio;
}

/// Authentication interceptor for automatic token handling
class _AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;
  final DeviceStorage _deviceStorage;
  final Dio _refreshDio; // Separate Dio for refresh (no interceptors)
  final Dio _dio;

  _AuthInterceptor({
    required TokenStorage tokenStorage,
    required DeviceStorage deviceStorage,
    required Dio refreshDio,
    required Dio dio,
  })  : _tokenStorage = tokenStorage,
        _deviceStorage = deviceStorage,
        _refreshDio = refreshDio,
        _dio = dio;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for login endpoints
    if (_isAuthEndpoint(options.path)) {
      return handler.next(options);
    }

    final token = await _tokenStorage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Don't auto-refresh for auth endpoints - let auth errors propagate
    if (_isAuthEndpoint(err.requestOptions.path)) {
      return handler.next(err);
    }

    if (err.response?.statusCode == 401) {
      // Try to refresh token via device login
      final success = await _refreshToken();

      if (success) {
        // Retry the original request
        final token = await _tokenStorage.getToken();
        err.requestOptions.headers['Authorization'] = 'Bearer $token';

        try {
          final response = await _dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          return handler.next(err);
        }
      }
    }

    return handler.next(err);
  }

  bool _isAuthEndpoint(String path) {
    return path.contains('/auth/device-register') ||
        path.contains('/auth/login') ||
        path.contains('/auth/register');
  }

  Future<bool> _refreshToken() async {
    try {
      final creds = await _deviceStorage.getOrCreateCredentials();
      // Use _refreshDio (no interceptors) to avoid recursion
      final response = await _refreshDio.post(
        '/auth/device-register',
        data: {
          'device_id': creds.deviceId,
          'secret_key': creds.secretKey,
        },
      );

      if (response.statusCode == 200) {
        final token = response.data['access_token'] as String;
        await _tokenStorage.saveToken(token);
        print('🔄 Token refreshed successfully');
        return true;
      }
    } catch (e) {
      print('❌ Token refresh failed: $e');
    }

    return false;
  }
}

/// Logging interceptor for debugging
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('🌐 [${options.method}] ${options.path}');
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('✅ [${response.statusCode}] ${response.requestOptions.path}');
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('❌ [${err.response?.statusCode}] ${err.requestOptions.path}');
    print('   Error: ${err.message}');
    return handler.next(err);
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  factory ApiException.fromDioError(DioException error) {
    String message;
    int? statusCode = error.response?.statusCode;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Превышено время ожидания соединения';
        break;
      case DioExceptionType.badResponse:
        final data = error.response?.data;
        if (data is Map && data['detail'] != null) {
          message = data['detail'].toString();
        } else {
          message = 'Ошибка сервера: $statusCode';
        }
        break;
      case DioExceptionType.cancel:
        message = 'Запрос отменён';
        break;
      case DioExceptionType.connectionError:
        message = 'Нет соединения с сервером';
        break;
      default:
        message = 'Произошла неизвестная ошибка';
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      data: error.response?.data,
    );
  }

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}
