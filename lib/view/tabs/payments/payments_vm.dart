import '../../../data/base_vm.dart';
import '../../../di_container.dart';
import '../../../models/response/payment_model.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/payment_repository.dart';

class PaymentsViewModel extends BaseViewModel {
  final PaymentRepository _paymentRepo = sl<PaymentRepository>();
  final AuthRepository _authRepo = sl<AuthRepository>();

  List<Payment> _payments = [];
  List<Payment> get payments => _payments;

  List<Receivable> _receivables = [];
  List<Receivable> get receivables => _receivables;

  int _selectedTab = 0; // 0: Payments, 1: Receivables
  int get selectedTab => _selectedTab;

  void selectTab(int index) {
    _selectedTab = index;
    notifyListeners();
  }

  Future<void> loadData({bool refresh = false}) async {
    setBusy(true);
    final isPrev = _authRepo.isPreviewMode;
    final results = await Future.wait([
      _paymentRepo.getPayments(isPreview: isPrev),
      _paymentRepo.getReceivables(isPreview: isPrev),
    ]);

    final payRes = results[0];
    final recRes = results[1];

    if (payRes.isSuccess && payRes.data != null) {
      _payments = (payRes.data as dynamic).items as List<Payment>;
    }
    if (recRes.isSuccess && recRes.data != null) {
      _receivables = recRes.data as List<Receivable>;
    }

    setBusy(false);
  }

  Future<bool> recordPayment(Map<String, dynamic> data) async {
    final result = await runBusyFuture(() => _paymentRepo.recordPayment(data));
    if (result != null && result.isSuccess) {
      await loadData(refresh: true);
      return true;
    }
    setError(result?.error ?? 'Failed to record payment.');
    return false;
  }
}
