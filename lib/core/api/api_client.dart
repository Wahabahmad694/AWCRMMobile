import 'package:dio/dio.dart';

abstract class TokenStore {
  String? get access;
  Future<String?> get refresh;
  String? get organizationId;
  Future<void> save(String access, String refresh);
  Future<void> clear();
}

class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor(this.dio, this.tokens);
  final Dio dio;
  final TokenStore tokens; // access in memory, refresh in secure storage

  String? _tokenFromHeader(dynamic authHeader) {
    if (authHeader is String && authHeader.startsWith('Bearer ')) {
      return authHeader.substring(7);
    }
    return null;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final access = tokens.access;
    if (access != null && !options.headers.containsKey('Authorization')) {
      options.headers['Authorization'] = 'Bearer $access';
    }
    final org = tokens.organizationId;
    if (org != null && !options.headers.containsKey('X-Organization-Id')) {
      options.headers['X-Organization-Id'] = org;
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final code = err.response?.data is Map && err.response?.data['error'] is Map
        ? err.response?.data['error']['code']
        : null;
    final isAuthCall = err.requestOptions.path.startsWith('/auth/');
    if (err.response?.statusCode != 401 || isAuthCall || code != 'unauthorized') {
      return handler.next(err);
    }
    // QueuedInterceptor runs this once at a time, so a second 401 sees the
    // token the first one already refreshed.
    final headerToken = _tokenFromHeader(err.requestOptions.headers['Authorization']);
    if (tokens.access != null && tokens.access != headerToken) {
      err.requestOptions.headers['Authorization'] = 'Bearer ${tokens.access}';
      return handler.resolve(await dio.fetch(err.requestOptions));
    }
    try {
      final currentRefresh = await tokens.refresh;
      if (currentRefresh == null || currentRefresh.isEmpty) {
        await tokens.clear();
        return handler.next(err);
      }
      final res = await Dio(BaseOptions(
        baseUrl: dio.options.baseUrl,
        connectTimeout: dio.options.connectTimeout,
        receiveTimeout: dio.options.receiveTimeout,
        contentType: Headers.jsonContentType,
      )).post('/auth/refresh', data: {'refresh_token': currentRefresh});
      final data = res.data;
      if (data is Map && data['access_token'] is String && data['refresh_token'] is String) {
        await tokens.save(data['access_token'] as String, data['refresh_token'] as String);
        err.requestOptions.headers['Authorization'] = 'Bearer ${data['access_token']}';
        handler.resolve(await dio.fetch(err.requestOptions));
      } else {
        await tokens.clear();
        handler.next(err);
      }
    } on DioException catch (dioErr) {
      await tokens.clear(); // session_expired / refresh_token_reused
      handler.next(dioErr); // app routes to the login screen
    } catch (_) {
      await tokens.clear();
      handler.next(err);
    }
  }
}

class ApiFailure implements Exception {
  const ApiFailure(this.message, {this.code, this.statusCode, this.requestId,
    this.details, this.retryAfter});
  final String message;
  final String? code;
  final int? statusCode;
  final String? requestId;
  final Object? details;
  final Duration? retryAfter;

  factory ApiFailure.fromDio(DioException error) {
    final status = error.response?.statusCode;
    final body = error.response?.data;
    final payload = body is Map && body['error'] is Map ? body['error'] as Map : const {};
    final code = payload['code'] is String ? payload['code'] as String : null;
    final requestId = payload['request_id'] is String
        ? payload['request_id'] as String : error.response?.headers.value('x-request-id');
    final retrySeconds = int.tryParse(error.response?.headers.value('retry-after') ?? '');
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const ApiFailure('The request timed out. Check the result before retrying.');
    }
    if (error.type == DioExceptionType.connectionError) {
      return const ApiFailure('Cannot reach the server. Check your connection.');
    }
    final message = switch (code) {
      'permission_denied' => "You don't have access to this.",
      'subscription_required' => 'Your subscription is read-only. Contact your organization owner.',
      'version_conflict' => 'This record changed. Reload it before editing.',
      'invalid_state_transition' => 'This action is no longer available. Refresh the record.',
      'out_of_stock' => 'There is not enough stock for this action.',
      'idempotency_in_progress' => 'This action is still being processed. Check its status before retrying.',
      'idempotency_key_reused' => 'The action changed after submission. Review it before saving again.',
      'quota_exceeded' => 'Your usage limit has been reached.',
      'session_expired' || 'refresh_token_reused' => 'Your session has expired. Please sign in again.',
      _ => payload['message'] is String ? payload['message'] as String : switch (status) {
        400 || 422 => 'Please check the submitted information.',
        401 => 'Your session has expired. Please sign in again.',
        403 => "You don't have access to this.",
        404 => 'This record was not found.',
        409 => 'This record has changed. Reload it before continuing.',
        429 => 'Too many requests. Please try again later.',
        503 => 'Service busy. Please try again later.',
        _ => 'Something went wrong. Please try again.',
      },
    };
    return ApiFailure(message, code: code, statusCode: status,
      requestId: requestId, details: payload['details'],
      retryAfter: retrySeconds == null ? null : Duration(seconds: retrySeconds));
  }

  List<Map<String, dynamic>> get fieldErrors {
    if (details is Map && (details as Map)['fields'] is List) {
      final list = (details as Map)['fields'] as List;
      return list.whereType<Map>().map((m) => m.map((k, v) => MapEntry(k.toString(), v))).toList();
    }
    return const [];
  }

  int? get currentVersion {
    if (details is Map && (details as Map)['current_version'] is int) {
      return (details as Map)['current_version'] as int;
    }
    return null;
  }

  List<String> get allowedTransitions {
    if (details is Map && (details as Map)['allowed'] is List) {
      return ((details as Map)['allowed'] as List).whereType<String>().toList();
    }
    return const [];
  }

  List<Map<String, dynamic>> get outOfStockLines {
    if (details is Map && (details as Map)['lines'] is List) {
      final list = (details as Map)['lines'] as List;
      return list.whereType<Map>().map((m) => m.map((k, v) => MapEntry(k.toString(), v))).toList();
    }
    return const [];
  }

  @override
  String toString() => requestId == null ? message : '$message (Request ID: $requestId)';
}

class ApiClient {
  ApiClient(String baseUrl, {TokenStore? tokenStore})
      : dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
          contentType: Headers.jsonContentType,
          headers: {'Accept': 'application/json'},
        )) {
    if (tokenStore != null) {
      attachTokenStore(tokenStore);
    }
  }

  final Dio dio;
  TokenStore? _tokens;
  String? _fallbackAccessToken;
  String? _fallbackOrgId;
  void Function()? onSessionExpired;
  void Function()? onSubscriptionRequired;
  Future<bool> Function()? refreshSession;

  void attachTokenStore(TokenStore tokenStore) {
    _tokens = tokenStore;
    dio.interceptors.removeWhere((i) => i is AuthInterceptor);
    dio.interceptors.add(AuthInterceptor(dio, tokenStore));
  }

  String? get accessToken => _tokens?.access ?? _fallbackAccessToken;
  set accessToken(String? val) {
    _fallbackAccessToken = val;
  }

  String? get organizationId => _tokens?.organizationId ?? _fallbackOrgId;
  set organizationId(String? val) {
    _fallbackOrgId = val;
  }

  Options _buildOptions(String? idempotencyKey) {
    final headers = <String, String>{};
    if (_tokens == null) {
      if (_fallbackAccessToken != null) headers['Authorization'] = 'Bearer $_fallbackAccessToken';
      if (_fallbackOrgId != null) headers['X-Organization-Id'] = _fallbackOrgId!;
    }
    if (idempotencyKey != null) {
      headers['Idempotency-Key'] = idempotencyKey;
    }
    return Options(headers: headers);
  }

  Object? _applyExpectedVersion(Object? data, int? expectedVersion) {
    if (expectedVersion == null) return data;
    if (data is Map) {
      return {...data, 'expected_version': expectedVersion};
    }
    return data;
  }

  Future<Response<dynamic>> _execute(Future<Response<dynamic>> Function() fn) async {
    try {
      return await fn();
    } on DioException catch (e) {
      final failure = ApiFailure.fromDio(e);
      if (failure.code == 'subscription_required') {
        onSubscriptionRequired?.call();
      }
      if (failure.code == 'session_expired' || failure.code == 'refresh_token_reused') {
        onSessionExpired?.call();
      }
      throw failure;
    }
  }

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? query}) =>
      _execute(() => dio.get<dynamic>(path, queryParameters: query, options: _buildOptions(null)));

  Future<Response<dynamic>> post(String path, Object? data, {String? idempotencyKey}) =>
      _execute(() => dio.post<dynamic>(path, data: data, options: _buildOptions(idempotencyKey)));

  Future<Response<dynamic>> patch(String path, Object? data, {String? idempotencyKey, int? expectedVersion}) {
    final payload = _applyExpectedVersion(data, expectedVersion);
    return _execute(() => dio.patch<dynamic>(path, data: payload, options: _buildOptions(idempotencyKey)));
  }

  Future<Response<dynamic>> put(String path, Object? data, {String? idempotencyKey, int? expectedVersion}) {
    final payload = _applyExpectedVersion(data, expectedVersion);
    return _execute(() => dio.put<dynamic>(path, data: payload, options: _buildOptions(idempotencyKey)));
  }

  Future<Response<dynamic>> delete(String path, {Object? data}) =>
      _execute(() => dio.delete<dynamic>(path, data: data, options: _buildOptions(null)));
}

