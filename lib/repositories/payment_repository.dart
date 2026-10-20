import '../../data/remote/api_result.dart';
import '../../data/remote/api_service.dart';
import '../../models/response/api_response.dart';
import '../../models/response/payment_model.dart';
import '../../utils/api_end_points.dart';
import '../../utils/extractor.dart';

class PaymentRepository {
  PaymentRepository({required ApiService apiService}) : _api = apiService;

  final ApiService _api;

  Future<ApiResult<PaginatedList<Payment>>> getPayments({
    int page = 1,
    int limit = 20,
    bool isPreview = false,
  }) async {
    if (isPreview) {
      return ApiResult.success(const PaginatedList(
        items: [],
        page: 1,
        limit: 20,
        total: 0,
      ));
    }

    final result = await _api.get(ApiEndPoints.payments, queryParameters: {'page': page, 'limit': limit});
    if (result.isSuccess) {
      final list = PaginatedList.fromJson(result.data, (json) => Payment.fromJson(json));
      return ApiResult.success(list);
    }
    return ApiResult.failure(result.error ?? 'Failed to load payments.');
  }

  Future<ApiResult<List<Receivable>>> getReceivables({bool isPreview = false}) async {
    if (isPreview) {
      return ApiResult.success([
        const Receivable(
          customerId: 'cust-1',
          customerName: 'Acme Traders',
          phone: '+92 300 1234567',
          outstandingPaisa: 12550,
          invoiceCount: 1,
        ),
      ]);
    }

    final result = await _api.get(ApiEndPoints.receivables);
    if (result.isSuccess) {
      final items = Extractor.extractItems(result.data);
      return ApiResult.success(items.map((m) => Receivable.fromJson(m)).toList());
    }
    return ApiResult.failure(result.error ?? 'Failed to load receivables.');
  }

  Future<ApiResult<bool>> recordPayment(Map<String, dynamic> data) async {
    final result = await _api.post(ApiEndPoints.payments, data: data);
    if (result.isSuccess) return const ApiResult.success(true);
    return ApiResult.failure(result.error ?? 'Failed to record payment.');
  }

  Future<ApiResult<bool>> reversePayment(String paymentId, String reason) async {
    final result = await _api.post(ApiEndPoints.paymentReverse(paymentId), data: {'reason': reason});
    if (result.isSuccess) return const ApiResult.success(true);
    return ApiResult.failure(result.error ?? 'Failed to reverse payment.');
  }
}
