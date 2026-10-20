import '../../data/remote/api_result.dart';
import '../../data/remote/api_service.dart';
import '../../models/response/api_response.dart';
import '../../models/response/order_model.dart';
import '../../utils/api_end_points.dart';

class OrderRepository {
  OrderRepository({required ApiService apiService}) : _api = apiService;

  final ApiService _api;

  Future<ApiResult<PaginatedList<Order>>> getOrders({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    bool isPreview = false,
  }) async {
    if (isPreview) {
      return ApiResult.success(PaginatedList(
        items: [
          const Order(
            id: 'ord-1',
            orderNumber: 'ORD-2026-0001',
            customerId: 'cust-1',
            customerName: 'Acme Traders',
            status: 'confirmed',
            channel: 'offline',
            totalAmountPaisa: 12550,
            paidAmountPaisa: 0,
            lines: [
              OrderLine(
                id: 'line-1',
                productId: 'prod-1',
                productName: 'Commercial Steel Rod 10mm',
                quantity: 1,
                unitPricePaisa: 12550,
                totalPaisa: 12550,
              ),
            ],
          ),
        ],
        page: 1,
        limit: 20,
        total: 1,
      ));
    }

    final query = <String, dynamic>{'page': page, 'limit': limit};
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (status != null && status.isNotEmpty) query['status'] = status;

    final result = await _api.get(ApiEndPoints.orders, queryParameters: query);
    if (result.isSuccess) {
      final list = PaginatedList.fromJson(result.data, (json) => Order.fromJson(json));
      return ApiResult.success(list);
    }
    return ApiResult.failure(result.error ?? 'Failed to load orders.');
  }

  Future<ApiResult<Order>> getOrder(String id) async {
    final result = await _api.get(ApiEndPoints.order(id));
    if (result.isSuccess && result.data is Map) {
      return ApiResult.success(Order.fromJson(Map<String, dynamic>.from(result.data as Map)));
    }
    return ApiResult.failure(result.error ?? 'Order not found.');
  }

  Future<ApiResult<Order>> createOrder(Map<String, dynamic> data) async {
    final result = await _api.post(ApiEndPoints.orders, data: data);
    if (result.isSuccess && result.data is Map) {
      return ApiResult.success(Order.fromJson(Map<String, dynamic>.from(result.data as Map)));
    }
    return ApiResult.failure(result.error ?? 'Failed to create order.');
  }

  Future<ApiResult<bool>> confirmOrder(String id, int version) async {
    final result = await _api.post(ApiEndPoints.orderConfirm(id), data: {'expected_version': version});
    if (result.isSuccess) return const ApiResult.success(true);
    return ApiResult.failure(result.error ?? 'Failed to confirm order.');
  }

  Future<ApiResult<bool>> processOrder(String id, int version) async {
    final result = await _api.post(ApiEndPoints.orderProcess(id), data: {'expected_version': version});
    if (result.isSuccess) return const ApiResult.success(true);
    return ApiResult.failure(result.error ?? 'Failed to process order.');
  }

  Future<ApiResult<bool>> fulfillOrder(String id, int version) async {
    final result = await _api.post(ApiEndPoints.orderFulfill(id), data: {'expected_version': version});
    if (result.isSuccess) return const ApiResult.success(true);
    return ApiResult.failure(result.error ?? 'Failed to fulfill order.');
  }

  Future<ApiResult<bool>> cancelOrder(String id, int version, String reason) async {
    final result = await _api.post(ApiEndPoints.orderCancel(id), data: {
      'expected_version': version,
      'reason': reason,
    });
    if (result.isSuccess) return const ApiResult.success(true);
    return ApiResult.failure(result.error ?? 'Failed to cancel order.');
  }
}
