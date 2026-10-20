import '../../../data/base_vm.dart';
import '../../../di_container.dart';
import '../../../models/response/customer_model.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/customer_repository.dart';

class CustomersViewModel extends BaseViewModel {
  final CustomerRepository _customerRepo = sl<CustomerRepository>();
  final AuthRepository _authRepo = sl<AuthRepository>();

  List<Customer> _customers = [];
  List<Customer> get customers => _customers;

  int _page = 1;
  int get page => _page;
  bool _hasMore = false;
  bool get hasMore => _hasMore;
  int? _total;
  int? get total => _total;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String? _selectedType;
  String? get selectedType => _selectedType;

  Future<void> loadCustomers({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _customers = [];
    }

    setBusy(true);
    final result = await _customerRepo.getCustomers(
      page: _page,
      search: _searchQuery.isEmpty ? null : _searchQuery,
      type: _selectedType,
      isPreview: _authRepo.isPreviewMode,
    );

    if (result.isSuccess && result.data != null) {
      if (refresh || _page == 1) {
        _customers = result.data!.items;
      } else {
        _customers.addAll(result.data!.items);
      }
      _hasMore = result.data!.hasMore;
      _total = result.data!.total;
      setBusy(false);
    } else {
      setError(result.error ?? 'Failed to load customers.');
      setBusy(false);
    }
  }

  void search(String query) {
    _searchQuery = query;
    loadCustomers(refresh: true);
  }

  void filterByType(String? type) {
    _selectedType = type;
    loadCustomers(refresh: true);
  }

  Future<bool> createCustomer(Map<String, dynamic> data) async {
    final result = await runBusyFuture(() => _customerRepo.createCustomer(data));
    if (result != null && result.isSuccess) {
      await loadCustomers(refresh: true);
      return true;
    }
    setError(result?.error ?? 'Failed to create customer.');
    return false;
  }
}
