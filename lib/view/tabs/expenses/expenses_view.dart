import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../di_container.dart';
import '../../../models/response/expense_model.dart';
import '../../../repositories/auth_repository.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/extractor.dart';
import '../../../utils/string_helpers.dart';
import '../../widget/app_drawer.dart';
import '../../widget/app_header.dart';
import '../../widget/empty_state_card.dart';
import 'expenses_vm.dart';

class ExpensesView extends StatefulWidget {
  const ExpensesView({super.key});

  @override
  State<ExpensesView> createState() => _ExpensesViewState();
}

class _ExpensesViewState extends State<ExpensesView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final authRepo = sl<AuthRepository>();

    return ChangeNotifierProvider(
      create: (_) => ExpensesViewModel()..loadData(),
      child: Consumer<ExpensesViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: AppColors.background,
            appBar: AppHeader(
              title: 'Expenses',
              isSignedIn: authRepo.isSignedIn,
              userInitials: authRepo.currentUser?.name ?? 'AW',
            ),
            drawer: const AppDrawer(currentRoute: '/expenses'),
            floatingActionButton: FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () => _showAddExpenseDialog(context, vm),
            ),
            body: RefreshIndicator(
              onRefresh: () => vm.loadData(refresh: true),
              color: AppColors.primary,
              child: vm.isBusy && vm.expenses.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : vm.expenses.isEmpty
                      ? EmptyStateCard(
                          title: 'No expenses recorded',
                          description: 'Keep your operating costs, utilities, and vendor receipts organized in PKR.',
                          icon: Icons.receipt_long_outlined,
                          buttonText: 'Add Expense',
                          onPressed: () => _showAddExpenseDialog(context, vm),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                          itemCount: vm.expenses.length,
                          itemBuilder: (context, index) {
                            final exp = vm.expenses[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.violetIconBg,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.receipt_outlined, color: AppColors.violetIcon, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            exp.categoryName,
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                          ),
                                          if (exp.description != null && exp.description!.isNotEmpty)
                                            Text(
                                              exp.description!,
                                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                            ),
                                          Text(
                                            '${StringHelpers.titleCase(exp.method)} • ${Extractor.formatDate(exp.expenseDate)}',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      Extractor.formatPkr(exp.amountPaisa),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: AppColors.violetIcon,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          );
        },
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context, ExpensesViewModel vm) {
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    String method = 'cash';
    ExpenseCategory? selectedCat = vm.categories.isNotEmpty ? vm.categories.first : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (bContext) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(bContext).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Add Expense', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(bContext)),
                  ],
                ),
                const SizedBox(height: 14),
                if (vm.categories.isNotEmpty)
                  DropdownButtonFormField<ExpenseCategory>(
                    initialValue: selectedCat,
                    decoration: const InputDecoration(labelText: 'Category *'),
                    items: vm.categories.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                    onChanged: (c) => setModalState(() => selectedCat = c),
                  ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount (PKR) *', prefixText: 'Rs '),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: method,
                  decoration: const InputDecoration(labelText: 'Payment Method'),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                    DropdownMenuItem(value: 'easypaisa', child: Text('EasyPaisa')),
                    DropdownMenuItem(value: 'jazzcash', child: Text('JazzCash')),
                  ],
                  onChanged: (v) => setModalState(() => method = v ?? 'cash'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description / Purpose'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: refCtrl,
                  decoration: const InputDecoration(labelText: 'Receipt reference number (optional)'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(bContext);
                    final ok = await vm.createExpense({
                      'category_id': selectedCat?.id ?? 'cat-1',
                      'amount_paisa': Extractor.toPaisa(amountCtrl.text),
                      'expense_date': DateTime.now().toIso8601String().substring(0, 10),
                      'method': method,
                      if (descCtrl.text.isNotEmpty) 'description': descCtrl.text.trim(),
                      if (refCtrl.text.isNotEmpty) 'receipt_reference': refCtrl.text.trim(),
                    });
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Expense recorded successfully!')),
                      );
                    }
                  },
                  child: const Text('Save Expense'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
