import '../../../data/base_vm.dart';
import '../../../di_container.dart';
import '../../../models/response/expense_model.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/expense_repository.dart';

class ExpensesViewModel extends BaseViewModel {
  final ExpenseRepository _expenseRepo = sl<ExpenseRepository>();
  final AuthRepository _authRepo = sl<AuthRepository>();

  List<Expense> _expenses = [];
  List<Expense> get expenses => _expenses;

  List<ExpenseCategory> _categories = [];
  List<ExpenseCategory> get categories => _categories;

  Future<void> loadData({bool refresh = false}) async {
    setBusy(true);
    final isPrev = _authRepo.isPreviewMode;
    final results = await Future.wait([
      _expenseRepo.getExpenses(isPreview: isPrev),
      _expenseRepo.getCategories(),
    ]);

    final expRes = results[0];
    final catRes = results[1];

    if (expRes.isSuccess && expRes.data != null) {
      _expenses = (expRes.data as dynamic).items as List<Expense>;
    }
    if (catRes.isSuccess && catRes.data != null) {
      _categories = catRes.data as List<ExpenseCategory>;
    }

    setBusy(false);
  }

  Future<bool> createExpense(Map<String, dynamic> data) async {
    final result = await runBusyFuture(() => _expenseRepo.createExpense(data));
    if (result != null && result.isSuccess) {
      await loadData(refresh: true);
      return true;
    }
    setError(result?.error ?? 'Failed to add expense.');
    return false;
  }
}
