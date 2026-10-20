import '../../data/remote/api_result.dart';
import '../../data/remote/api_service.dart';
import '../../models/response/api_response.dart';
import '../../models/response/inventory_model.dart';
import '../../utils/api_end_points.dart';
import '../../utils/extractor.dart';

class InventoryRepository {
  InventoryRepository({required ApiService apiService}) : _api = apiService;

  final ApiService _api;

  Future<ApiResult<PaginatedList<StockLevel>>> getInventory({
    int page = 1,
    int limit = 20,
    bool isPreview = false,
  }) async {
    if (isPreview) {
      return ApiResult.success(PaginatedList(
        items: [
          const StockLevel(
            productId: 'prod-1',
            productName: 'Commercial Steel Rod 10mm',
            sku: 'STL-ROD-10',
            onHand: 45,
            lowStockLevel: 10,
            unitCostPaisa: 9500,
            valuationPaisa: 427500,
          ),
          const StockLevel(
            productId: 'prod-2',
            productName: 'Heavy Duty Fastener Box (100pk)',
            sku: 'FST-BX-100',
            onHand: 8,
            lowStockLevel: 15,
            unitCostPaisa: 320000,
            valuationPaisa: 2560000,
          ),
        ],
        page: 1,
        limit: 20,
        total: 2,
      ));
    }

    final result = await _api.get(ApiEndPoints.inventory, queryParameters: {'page': page, 'limit': limit});
    if (result.isSuccess) {
      final list = PaginatedList.fromJson(result.data, (json) => StockLevel.fromJson(json));
      return ApiResult.success(list);
    }
    return ApiResult.failure(result.error ?? 'Failed to load inventory.');
  }

  Future<ApiResult<List<StockLevel>>> getLowStock() async {
    final result = await _api.get(ApiEndPoints.lowStock);
    if (result.isSuccess) {
      final items = Extractor.extractItems(result.data);
      return ApiResult.success(items.map((m) => StockLevel.fromJson(m)).toList());
    }
    return ApiResult.failure(result.error ?? 'Failed to load low stock items.');
  }

  Future<ApiResult<bool>> adjustStock({
    required String reason,
    required List<Map<String, dynamic>> lines,
  }) async {
    final result = await _api.post(ApiEndPoints.inventoryAdjustments, data: {
      'reason': reason,
      'lines': lines,
    });
    if (result.isSuccess) return const ApiResult.success(true);
    return ApiResult.failure(result.error ?? 'Failed to adjust stock.');
  }
}
