import '../../../data/base_vm.dart';
import '../../../di_container.dart';
import '../../../models/response/product_model.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/product_repository.dart';

class ProductsViewModel extends BaseViewModel {
  final ProductRepository _productRepo = sl<ProductRepository>();
  final AuthRepository _authRepo = sl<AuthRepository>();

  List<Product> _products = [];
  List<Product> get products => _products;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  Future<void> loadProducts({bool refresh = false}) async {
    setBusy(true);
    final result = await _productRepo.getProducts(
      search: _searchQuery.isEmpty ? null : _searchQuery,
      isPreview: _authRepo.isPreviewMode,
    );

    if (result.isSuccess && result.data != null) {
      _products = result.data!.items;
      setBusy(false);
    } else {
      setError(result.error ?? 'Failed to load products.');
      setBusy(false);
    }
  }

  void search(String q) {
    _searchQuery = q;
    loadProducts(refresh: true);
  }

  Future<bool> createProduct(Map<String, dynamic> data) async {
    final result = await runBusyFuture(() => _productRepo.createProduct(data));
    if (result != null && result.isSuccess) {
      await loadProducts(refresh: true);
      return true;
    }
    setError(result?.error ?? 'Failed to add product.');
    return false;
  }
}
