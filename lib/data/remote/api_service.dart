import 'package:dio/dio.dart';

import '../../services/secure_storage_service.dart';
import '../../utils/api_end_points.dart';
import '../../utils/app_constants.dart';
import 'api_result.dart';

class ApiService {
  ApiService({String? baseUrl, required SecureStorageService storageService})
    : _storage = storageService,
      _dio = Dio(
        BaseOptions(
          baseUrl:
              baseUrl ??
              const String.fromEnvironment(
                'API_URL',
                defaultValue: ApiEndPoints.defaultBaseUrl,
              ),
          connectTimeout: AppConstants.connectTimeout,
          receiveTimeout: AppConstants.receiveTimeout,
          contentType: Headers.jsonContentType,
          headers: {'Accept': 'application/json'},
        ),
      ) {
    _dio.interceptors.add(
      _AuthInterceptor(
        dio: _dio,
        storage: _storage,
        onSessionExpired: () => onSessionExpired?.call(),
      ),
    );
  }

  final Dio _dio;
  final SecureStorageService _storage;
  String? inMemoryAccessToken;
  String? inMemoryOrganizationId;
  void Function()? onSessionExpired;

  Dio get dio => _dio;

  void setTokens({String? accessToken, String? organizationId}) {
    inMemoryAccessToken = accessToken;
    if (organizationId != null) {
      inMemoryOrganizationId = organizationId;
    }
  }

  Future<bool> refreshAccessToken() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      // Use a separate client so refreshing cannot recursively trigger auth handling.
      final response = await Dio(
        BaseOptions(
          baseUrl: _dio.options.baseUrl,
          connectTimeout: _dio.options.connectTimeout,
          receiveTimeout: _dio.options.receiveTimeout,
          contentType: Headers.jsonContentType,
          headers: {'Accept': 'application/json'},
        ),
      ).post(ApiEndPoints.refresh, data: {'refresh_token': refreshToken});
      final data = response.data;
      if (data is! Map ||
          data['access_token'] is! String ||
          (data['refresh_token'] != null && data['refresh_token'] is! String)) {
        return false;
      }
      final access = data['access_token'] as String;
      final refresh = (data['refresh_token'] as String?) ?? refreshToken;
      await _storage.saveTokens(accessToken: access, refreshToken: refresh);
      setTokens(accessToken: access);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<ApiResult<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return ApiResult.success(response.data);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  Future<ApiResult<dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return ApiResult.success(response.data);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  Future<ApiResult<dynamic>> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return ApiResult.success(response.data);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  Future<ApiResult<dynamic>> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return ApiResult.success(response.data);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  ApiResult<dynamic> _handleDioError(DioException error) {
    final status = error.response?.statusCode;
    final body = error.response?.data;
    String? code;
    String message = 'Something went wrong. Please try again.';

    if (body is Map && body['error'] is Map) {
      final errMap = body['error'] as Map;
      code = errMap['code']?.toString();
      message = errMap['message']?.toString() ?? message;
    } else if (body is Map && body['message'] is String) {
      message = body['message'] as String;
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      message = 'The request timed out. Please check your internet connection.';
    } else if (error.type == DioExceptionType.connectionError) {
      message =
          'Cannot reach the server. Please check your internet connection.';
    }

    return ApiResult.failure(message, statusCode: status, errorCode: code);
  }
}

class _AuthInterceptor extends QueuedInterceptor {
  _AuthInterceptor({
    required this.dio,
    required this.storage,
    required this.onSessionExpired,
  });

  final Dio dio;
  final SecureStorageService storage;
  final void Function() onSessionExpired;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await storage.getAccessToken();
    if (token != null && !options.headers.containsKey('Authorization')) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    final orgId = await storage.getOrganizationId();
    if (orgId != null && !options.headers.containsKey('X-Organization-Id')) {
      options.headers['X-Organization-Id'] = orgId;
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final isAuth = err.requestOptions.path.startsWith('/auth/');

    if (status != 401 || isAuth) {
      return handler.next(err);
    }

    try {
      final refreshToken = await storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await storage.clearAll();
        onSessionExpired();
        return handler.next(err);
      }

      final refreshRes = await Dio(
        BaseOptions(
          baseUrl: dio.options.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          contentType: Headers.jsonContentType,
        ),
      ).post(ApiEndPoints.refresh, data: {'refresh_token': refreshToken});

      final data = refreshRes.data;
      if (data is Map && data['access_token'] is String) {
        final newAccess = data['access_token'] as String;
        final newRefresh = (data['refresh_token'] as String?) ?? refreshToken;
        await storage.saveTokens(
          accessToken: newAccess,
          refreshToken: newRefresh,
        );
        // Keep in-memory auth state aligned with the rotated token too.

        err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
        final cloneReq = await dio.fetch(err.requestOptions);
        return handler.resolve(cloneReq);
      } else {
        await storage.clearAll();
        onSessionExpired();
        return handler.next(err);
      }
    } on DioException catch (refreshError) {
      // A failed refresh caused by a network/server problem is temporary. Keep
      // the cached session so startup can retry when the API is reachable.
      final refreshStatus = refreshError.response?.statusCode;
      if (refreshStatus == 401 || refreshStatus == 403) {
        await storage.clearAll();
        onSessionExpired();
      }
      return handler.next(err);
    } catch (_) {
      return handler.next(err);
    }
  }
}
