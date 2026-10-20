import '../../data/remote/api_result.dart';
import '../../data/remote/api_service.dart';
import '../../models/response/api_response.dart';
import '../../models/response/product_model.dart';
import '../../utils/api_end_points.dart';
import '../../utils/extractor.dart';

class ProductRepository {
  ProductRepository({required ApiService apiService}) : _api = apiService;

  final ApiService _api;

  Future<ApiResult<PaginatedList<Product>>> getProducts({
    int page = 1,
    int limit = 20,
    String? search,
    String? categoryId,
    bool isPreview = false,
  }) async {
    if (isPreview) {
      return ApiResult.success(PaginatedList(
        items: [
          const Product(
            id: 'prod-1',
            name: 'Commercial Steel Rod 10mm',
            sku: 'STL-ROD-10',
            categoryName: 'Hardware & Materials',
            unit: 'piece',
            pricePaisa: 12550,
            costPricePaisa: 9500,
            stockOnHand: 45,
            lowStockLevel: 10,
          ),
          const Product(
            id: 'prod-2',
            name: 'Heavy Duty Fastener Box (100pk)',
            sku: 'FST-BX-100',
            categoryName: 'Fasteners',
            unit: 'box',
            pricePaisa: 450000,
            costPricePaisa: 320000,
            stockOnHand: 8,
            lowStockLevel: 15,
          ),
        ],
        page: 1,
        limit: 20,
        total: 2,
      ));
    }

    final query = <String, dynamic>{'page': page, 'limit': limit};
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (categoryId != null && categoryId.isNotEmpty) query['category_id'] = categoryId;

    final result = await _api.get(ApiEndPoints.products, queryParameters: query);
    if (result.isSuccess) {
      final list = PaginatedList.fromJson(result.data, (json) => Product.fromJson(json));
      return ApiResult.success(list);
    }
    return ApiResult.failure(result.error ?? 'Failed to load products.');
  }

  Future<ApiResult<Product>> getProduct(String id) async {
    final result = await _api.get(ApiEndPoints.product(id));
    if (result.isSuccess && result.data is Map) {
      return ApiResult.success(Product.fromJson(Map<String, dynamic>.from(result.data as Map)));
    }
    return ApiResult.failure(result.error ?? 'Product not found.');
  }

  Future<ApiResult<Product>> createProduct(Map<String, dynamic> data) async {
    final result = await _api.post(ApiEndPoints.products, data: data);
    if (result.isSuccess && result.data is Map) {
      return ApiResult.success(Product.fromJson(Map<String, dynamic>.from(result.data as Map)));
    }
    return ApiResult.failure(result.error ?? 'Failed to create product.');
  }

  Future<ApiResult<Product>> updateProduct(String id, Map<String, dynamic> data) async {
    final result = await _api.patch(ApiEndPoints.product(id), data: data);
    if (result.isSuccess && result.data is Map) {
      return ApiResult.success(Product.fromJson(Map<String, dynamic>.from(result.data as Map)));
    }
    return ApiResult.failure(result.error ?? 'Failed to update product.');
  }

  Future<ApiResult<List<ProductCategory>>> getCategories() async {
    final result = await _api.get(ApiEndPoints.productCategories);
    if (result.isSuccess) {
      final items = Extractor.extractItems(result.data);
      return ApiResult.success(items.map((m) => ProductCategory.fromJson(m)).toList());
    }
    return ApiResult.failure(result.error ?? 'Failed to load categories.');
  }
}
