import 'package:aw_crm/core/api/api_client.dart';
import 'package:aw_crm/core/api/formatters.dart';
import 'package:aw_crm/models/response/product_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('money formatting and exact integer paisa', () {
    expect(parsePaisa('1250.50'), 125050);
    expect(parsePaisa('0.05'), 5);
    expect(parsePaisa('12.345'), isNull);
    expect(parsePaisa('-1'), isNull);

    // Format for display only
    expect(rupees(125000), 'Rs 1,250');
    expect(rupees(125050), 'Rs 1,250.50');
    expect(formatPkr(500), 'Rs 5');
  });

  test('date helper formats YYYY-MM-DD for Asia/Karachi (UTC+5)', () {
    // 2026-10-19 01:00 UTC is 2026-10-19 06:00 in Karachi
    final utcMorning = DateTime.utc(2026, 10, 19, 1, 0);
    expect(formatKarachiDate(utcMorning), '2026-10-19');

    // 2026-10-19 20:00 UTC is 2026-10-20 01:00 in Karachi
    final utcNight = DateTime.utc(2026, 10, 19, 20, 0);
    expect(formatKarachiDate(utcNight), '2026-10-20');
  });

  test('idempotency key generates RFC 4122 v4 UUID', () {
    final key1 = generateIdempotencyKey();
    final key2 = generateIdempotencyKey();
    expect(key1, isNot(equals(key2)));
    final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
    expect(uuidRegex.hasMatch(key1), isTrue);
    expect(uuidRegex.hasMatch(key2), isTrue);
  });

  test('structured API errors retain code, request ID, retry delay and details', () {
    final request = RequestOptions(path: '/payments');
    final response = Response<dynamic>(
      requestOptions: request,
      statusCode: 409,
      headers: Headers.fromMap({'retry-after': ['3']}),
      data: {
        'error': {
          'code': 'idempotency_in_progress',
          'message': 'Processing',
          'request_id': 'req-123',
          'details': {
            'status': 'pending',
            'current_version': 4,
            'fields': [
              {'field': 'lines.0.quantity', 'message': 'Exceeds stock'}
            ],
            'allowed': ['confirm', 'cancel'],
            'lines': [
              {'product_id': 'prod_1', 'requested': '5', 'available': '2'}
            ]
          }
        }
      },
    );
    final failure = ApiFailure.fromDio(DioException(
      requestOptions: request,
      response: response,
      type: DioExceptionType.badResponse,
    ));
    expect(failure.code, 'idempotency_in_progress');
    expect(failure.requestId, 'req-123');
    expect(failure.retryAfter, const Duration(seconds: 3));
    expect(failure.currentVersion, 4);
    expect(failure.fieldErrors.length, 1);
    expect(failure.fieldErrors.first['field'], 'lines.0.quantity');
    expect(failure.allowedTransitions, ['confirm', 'cancel']);
    expect(failure.outOfStockLines.length, 1);
    expect(failure.outOfStockLines.first['available'], '2');
  });

  test('AuthInterceptor attaches Authorization and X-Organization-Id headers', () async {
    final dio = Dio();
    final mockTokens = _MockTokenStore(
      access: 'access-token-123',
      refreshVal: 'refresh-token-456',
      orgId: 'org-abc',
    );
    final interceptor = AuthInterceptor(dio, mockTokens);

    final options = RequestOptions(path: '/test');
    final handler = _TestRequestInterceptorHandler();
    interceptor.onRequest(options, handler);

    expect(handler.passedOptions?.headers['Authorization'], 'Bearer access-token-123');
    expect(handler.passedOptions?.headers['X-Organization-Id'], 'org-abc');
  });

  test('Product.fromJson parses string-encoded numbers without throwing', () {
    final json = {
      'id': 'prod_test',
      'name': 'Test Item',
      'price_paisa': '250000',
      'cost_price_paisa': '180000',
      'tax_rate_bps': '1600',
      'track_stock': 'true',
      'low_stock_level': '10',
      'stock_on_hand': '45',
      'version': '3',
    };

    final product = Product.fromJson(json);
    expect(product.id, 'prod_test');
    expect(product.pricePaisa, 250000);
    expect(product.costPricePaisa, 180000);
    expect(product.taxRateBps, 1600);
    expect(product.trackStock, isTrue);
    expect(product.lowStockLevel, 10);
    expect(product.stockOnHand, 45);
    expect(product.version, 3);
  });
}

class _MockTokenStore implements TokenStore {
  _MockTokenStore({this.access, this.refreshVal, this.orgId});
  @override
  String? access;
  String? refreshVal;
  String? orgId;

  @override
  Future<String?> get refresh async => refreshVal;

  @override
  String? get organizationId => orgId;

  @override
  Future<void> save(String access, String refresh) async {
    this.access = access;
    refreshVal = refresh;
  }

  @override
  Future<void> clear() async {
    access = null;
    refreshVal = null;
    orgId = null;
  }
}

class _TestRequestInterceptorHandler extends RequestInterceptorHandler {
  RequestOptions? passedOptions;

  @override
  void next(RequestOptions requestOptions) {
    passedOptions = requestOptions;
  }
}

