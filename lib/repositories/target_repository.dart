import '../../data/remote/api_result.dart';
import '../../data/remote/api_service.dart';
import '../../models/response/api_response.dart';
import '../../models/response/target_model.dart';
import '../../utils/api_end_points.dart';

class TargetRepository {
  TargetRepository({required ApiService apiService}) : _api = apiService;

  final ApiService _api;

  Future<ApiResult<PaginatedList<SalesTarget>>> getTargets({
    int page = 1,
    int limit = 20,
    bool isPreview = false,
  }) async {
    if (isPreview) {
      return ApiResult.success(const PaginatedList(
        items: [
          SalesTarget(
            id: 'target-1',
            name: 'October Sales Goal',
            amountPaisa: 50000000, // Rs 500,000.00
            currentSalesPaisa: 12550, // Rs 125.50
            month: '2026-10',
          ),
        ],
        page: 1,
        limit: 20,
        total: 1,
      ));
    }

    final result = await _api.get(ApiEndPoints.targets, queryParameters: {'page': page, 'limit': limit});
    if (result.isSuccess) {
      final list = PaginatedList.fromJson(result.data, (json) => SalesTarget.fromJson(json));
      return ApiResult.success(list);
    }
    return ApiResult.failure(result.error ?? 'Failed to load targets.');
  }

  Future<ApiResult<bool>> createTarget(Map<String, dynamic> data) async {
    final result = await _api.post(ApiEndPoints.targets, data: data);
    if (result.isSuccess) return const ApiResult.success(true);
    return ApiResult.failure(result.error ?? 'Failed to create target.');
  }
}
