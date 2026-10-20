import '../../data/remote/api_result.dart';
import '../../data/remote/api_service.dart';
import '../../models/response/api_response.dart';
import '../../models/response/expense_model.dart';
import '../../utils/api_end_points.dart';
import '../../utils/extractor.dart';

class ExpenseRepository {
  ExpenseRepository({required ApiService apiService}) : _api = apiService;

  final ApiService _api;

  Future<ApiResult<PaginatedList<Expense>>> getExpenses({
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

    final result = await _api.get(ApiEndPoints.expenses, queryParameters: {'page': page, 'limit': limit});
    if (result.isSuccess) {
      final list = PaginatedList.fromJson(result.data, (json) => Expense.fromJson(json));
      return ApiResult.success(list);
    }
    return ApiResult.failure(result.error ?? 'Failed to load expenses.');
  }

  Future<ApiResult<List<ExpenseCategory>>> getCategories() async {
    final result = await _api.get(ApiEndPoints.expenseCategories);
    if (result.isSuccess) {
      final items = Extractor.extractItems(result.data);
      return ApiResult.success(items.map((m) => ExpenseCategory.fromJson(m)).toList());
    }
    return ApiResult.failure(result.error ?? 'Failed to load expense categories.');
  }

  Future<ApiResult<Expense>> createExpense(Map<String, dynamic> data) async {
    final result = await _api.post(ApiEndPoints.expenses, data: data);
    if (result.isSuccess && result.data is Map) {
      return ApiResult.success(Expense.fromJson(Map<String, dynamic>.from(result.data as Map)));
    }
    return ApiResult.failure(result.error ?? 'Failed to add expense.');
  }

  Future<ApiResult<bool>> voidExpense(String id, int version, String reason) async {
    final result = await _api.post(ApiEndPoints.expenseVoid(id), data: {
      'expected_version': version,
      'reason': reason,
    });
    if (result.isSuccess) return const ApiResult.success(true);
    return ApiResult.failure(result.error ?? 'Failed to void expense.');
  }
}
