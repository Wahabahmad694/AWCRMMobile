import '../../../data/base_vm.dart';
import '../../../di_container.dart';
import '../../../models/response/order_model.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/order_repository.dart';

class OrdersViewModel extends BaseViewModel {
  final OrderRepository _orderRepo = sl<OrderRepository>();
  final AuthRepository _authRepo = sl<AuthRepository>();

  List<Order> _orders = [];
  List<Order> get orders => _orders;

  int _page = 1;
  int get page => _page;
  int? _total;
  int? get total => _total;

  String? _selectedStatus;
  String? get selectedStatus => _selectedStatus;

  Future<void> loadOrders({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _orders = [];
    }

    setBusy(true);
    final result = await _orderRepo.getOrders(
      page: _page,
      status: _selectedStatus,
      isPreview: _authRepo.isPreviewMode,
    );

    if (result.isSuccess && result.data != null) {
      _orders = result.data!.items;
      _total = result.data!.total;
      setBusy(false);
    } else {
      setError(result.error ?? 'Failed to load orders.');
      setBusy(false);
    }
  }

  void filterByStatus(String? status) {
    _selectedStatus = status;
    loadOrders(refresh: true);
  }

  Future<bool> createOrder(Map<String, dynamic> data) async {
    final result = await runBusyFuture(() => _orderRepo.createOrder(data));
    if (result != null && result.isSuccess) {
      await loadOrders(refresh: true);
      return true;
    }
    setError(result?.error ?? 'Failed to create order.');
    return false;
  }

  Future<bool> transitionOrder(String orderId, String action, int version, {String? reason}) async {
    setBusy(true);
    bool ok = false;
    switch (action) {
      case 'confirm':
        final res = await _orderRepo.confirmOrder(orderId, version);
        ok = res.isSuccess;
        break;
      case 'process':
        final res = await _orderRepo.processOrder(orderId, version);
        ok = res.isSuccess;
        break;
      case 'fulfill':
        final res = await _orderRepo.fulfillOrder(orderId, version);
        ok = res.isSuccess;
        break;
      case 'cancel':
        final res = await _orderRepo.cancelOrder(orderId, version, reason ?? 'Cancelled by user');
        ok = res.isSuccess;
        break;
    }
    if (ok) {
      await loadOrders(refresh: true);
      return true;
    }
    setError('Failed to $action order.');
    setBusy(false);
    return false;
  }
}
