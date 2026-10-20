import '../../data/remote/api_result.dart';
import '../../data/remote/api_service.dart';
import '../../models/response/api_response.dart';
import '../../models/response/customer_model.dart';
import '../../utils/api_end_points.dart';
import '../../utils/extractor.dart';

class CustomerRepository {
  CustomerRepository({required ApiService apiService}) : _api = apiService;

  final ApiService _api;

  Future<ApiResult<PaginatedList<Customer>>> getCustomers({
    int page = 1,
    int limit = 20,
    String? search,
    String? type,
    bool isPreview = false,
  }) async {
    if (isPreview) {
      return ApiResult.success(PaginatedList(
        items: [
          const Customer(
            id: 'cust-1',
            name: 'Acme Traders',
            type: 'customer',
            businessName: 'Acme Corporation Ltd',
            phone: '+92 300 1234567',
            email: 'procurement@acme.com',
            city: 'Lahore',
            creditLimitPaisa: 50000000,
            balancePaisa: 12550,
          ),
          const Customer(
            id: 'cust-2',
            name: 'Bilal Enterprises',
            type: 'lead',
            phone: '+92 321 7654321',
            email: 'bilal@enterprises.pk',
            city: 'Karachi',
            creditLimitPaisa: 10000000,
            balancePaisa: 0,
          ),
        ],
        page: 1,
        limit: 20,
        total: 2,
      ));
    }

    final query = <String, dynamic>{'page': page, 'limit': limit};
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (type != null && type.isNotEmpty) query['type'] = type;

    final result = await _api.get(ApiEndPoints.customers, queryParameters: query);
    if (result.isSuccess) {
      final list = PaginatedList.fromJson(result.data, (json) => Customer.fromJson(json));
      return ApiResult.success(list);
    }
    return ApiResult.failure(result.error ?? 'Failed to load customers.');
  }

  Future<ApiResult<Customer>> getCustomer(String id) async {
    final result = await _api.get(ApiEndPoints.customer(id));
    if (result.isSuccess && result.data is Map) {
      return ApiResult.success(Customer.fromJson(Map<String, dynamic>.from(result.data as Map)));
    }
    return ApiResult.failure(result.error ?? 'Customer not found.');
  }

  Future<ApiResult<Customer>> createCustomer(Map<String, dynamic> data) async {
    final result = await _api.post(ApiEndPoints.customers, data: data);
    if (result.isSuccess && result.data is Map) {
      return ApiResult.success(Customer.fromJson(Map<String, dynamic>.from(result.data as Map)));
    }
    return ApiResult.failure(result.error ?? 'Failed to create customer.');
  }

  Future<ApiResult<Customer>> updateCustomer(String id, Map<String, dynamic> data) async {
    final result = await _api.patch(ApiEndPoints.customer(id), data: data);
    if (result.isSuccess && result.data is Map) {
      return ApiResult.success(Customer.fromJson(Map<String, dynamic>.from(result.data as Map)));
    }
    return ApiResult.failure(result.error ?? 'Failed to update customer.');
  }

  Future<ApiResult<bool>> archiveCustomer(String id, int expectedVersion) async {
    final result = await _api.post(ApiEndPoints.customerArchive(id), data: {'expected_version': expectedVersion});
    if (result.isSuccess) return const ApiResult.success(true);
    return ApiResult.failure(result.error ?? 'Failed to archive customer.');
  }

  Future<ApiResult<bool>> deleteCustomer(String id) async {
    final result = await _api.delete(ApiEndPoints.customer(id));
    if (result.isSuccess) return const ApiResult.success(true);
    return ApiResult.failure(result.error ?? 'Failed to delete customer.');
  }

  Future<ApiResult<List<CustomerLedgerEntry>>> getLedger(String customerId) async {
    final result = await _api.get(ApiEndPoints.customerLedger(customerId));
    if (result.isSuccess) {
      final items = Extractor.extractItems(result.data);
      return ApiResult.success(items.map((m) => CustomerLedgerEntry.fromJson(m)).toList());
    }
    return ApiResult.failure(result.error ?? 'Failed to load ledger.');
  }

  Future<ApiResult<bool>> addCustomerNote(String customerId, String note) async {
    final result = await _api.post(ApiEndPoints.customerNotes(customerId), data: {'body': note});
    if (result.isSuccess) return const ApiResult.success(true);
    return ApiResult.failure(result.error ?? 'Failed to add note.');
  }
}
