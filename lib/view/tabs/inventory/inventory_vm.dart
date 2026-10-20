import '../../../data/base_vm.dart';
import '../../../di_container.dart';
import '../../../models/response/inventory_model.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/inventory_repository.dart';

class InventoryViewModel extends BaseViewModel {
  final InventoryRepository _inventoryRepo = sl<InventoryRepository>();
  final AuthRepository _authRepo = sl<AuthRepository>();

  List<StockLevel> _inventory = [];
  List<StockLevel> get inventory => _inventory;

  bool _showOnlyLowStock = false;
  bool get showOnlyLowStock => _showOnlyLowStock;

  List<StockLevel> get filteredInventory {
    if (!_showOnlyLowStock) return _inventory;
    return _inventory.where((item) => item.isLowStock).toList();
  }

  Future<void> loadInventory({bool refresh = false}) async {
    setBusy(true);
    final result = await _inventoryRepo.getInventory(isPreview: _authRepo.isPreviewMode);
    if (result.isSuccess && result.data != null) {
      _inventory = result.data!.items;
      setBusy(false);
    } else {
      setError(result.error ?? 'Failed to load inventory.');
      setBusy(false);
    }
  }

  void toggleLowStockFilter() {
    _showOnlyLowStock = !_showOnlyLowStock;
    notifyListeners();
  }

  Future<bool> adjustStock({required String productId, required int quantityChange, required String reason}) async {
    final result = await runBusyFuture(() => _inventoryRepo.adjustStock(
          reason: reason,
          lines: [
            {'product_id': productId, 'quantity_change': quantityChange.toString()},
          ],
        ));
    if (result != null && result.isSuccess) {
      await loadInventory(refresh: true);
      return true;
    }
    setError(result?.error ?? 'Failed to adjust stock.');
    return false;
  }
}
