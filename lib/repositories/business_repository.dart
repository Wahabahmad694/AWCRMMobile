import 'package:dio/dio.dart';

import '../data/remote/api_service.dart';
import '../data/remote/api_result.dart';

/// Business endpoints use the same authenticated, organization-scoped client.
class BusinessRepository {
  BusinessRepository(this.api);
  final ApiService api;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async =>
      _unwrapResult(await api.get(path, queryParameters: query));

  Future<dynamic> save(
    String path,
    Map<String, dynamic> body, {
    bool patch = false,
    required String idempotencyKey,
  }) async {
    final options = Options(headers: {'Idempotency-Key': idempotencyKey});
    return _unwrapResult(
      patch
          ? await api.patch(path, data: body, options: options)
          : await api.post(path, data: body, options: options),
    );
  }

  dynamic _unwrapResult(ApiResult<dynamic> result) {
    if (result.isFailure) {
      throw BusinessFailure(result.error ?? 'Could not complete the request.');
    }
    final data = result.data;
    return data is Map && data['data'] != null ? data['data'] : data;
  }

  static Map<String, dynamic> record(dynamic data) =>
      data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};

  static List<Map<String, dynamic>> rows(dynamic data) {
    if (data is Map) {
      for (final key in ['items', 'rows', 'accounts', 'results', 'data']) {
        if (data[key] is List) return rows(data[key]);
      }
    }
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    throw const BusinessFailure(
      'The server returned an unexpected list response.',
    );
  }

  static String text(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '—',
  }) {
    for (final key in keys) {
      dynamic value = data;
      for (final part in key.split('.')) {
        value = value is Map ? value[part] : null;
      }
      if (value != null && value.toString().isNotEmpty) return value.toString();
    }
    return fallback;
  }
}

class BusinessFailure implements Exception {
  const BusinessFailure(this.message);
  final String message;
  @override
  String toString() => message;
}
