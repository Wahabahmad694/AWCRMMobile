import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../di_container.dart';
import '../../../repositories/auth_repository.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/extractor.dart';
import '../../../utils/string_helpers.dart';
import '../../widget/app_drawer.dart';
import '../../widget/app_header.dart';
import '../../widget/empty_state_card.dart';
import '../../widget/status_badge.dart';
import 'payments_vm.dart';

class PaymentsView extends StatefulWidget {
  const PaymentsView({super.key});

  @override
  State<PaymentsView> createState() => _PaymentsViewState();
}

class _PaymentsViewState extends State<PaymentsView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final authRepo = sl<AuthRepository>();

    return ChangeNotifierProvider(
      create: (_) => PaymentsViewModel()..loadData(),
      child: Consumer<PaymentsViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: AppColors.background,
            appBar: AppHeader(
              title: 'Payments',
              isSignedIn: authRepo.isSignedIn,
              userInitials: authRepo.currentUser?.name ?? 'AW',
            ),
            drawer: const AppDrawer(currentRoute: '/payments'),
            floatingActionButton: FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.payment_rounded, size: 20),
              label: const Text('Record Payment', style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () => _showRecordPaymentDialog(context, vm),
            ),
            body: RefreshIndicator(
              onRefresh: () => vm.loadData(refresh: true),
              color: AppColors.primary,
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => vm.selectTab(0),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: vm.selectedTab == 0 ? AppColors.primarySubtle : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Payment History',
                                style: TextStyle(
                                  color: vm.selectedTab == 0 ? AppColors.primary : AppColors.textSecondary,
                                  fontWeight: vm.selectedTab == 0 ? FontWeight.w800 : FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => vm.selectTab(1),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: vm.selectedTab == 1 ? AppColors.primarySubtle : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Receivables (${vm.receivables.length})',
                                style: TextStyle(
                                  color: vm.selectedTab == 1 ? AppColors.primary : AppColors.textSecondary,
                                  fontWeight: vm.selectedTab == 1 ? FontWeight.w800 : FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: vm.isBusy && vm.payments.isEmpty && vm.receivables.isEmpty
                        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                        : vm.selectedTab == 0
                            ? _buildPaymentsList(context, vm)
                            : _buildReceivablesList(context, vm),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentsList(BuildContext context, PaymentsViewModel vm) {
    if (vm.payments.isEmpty) {
      return EmptyStateCard(
        title: 'No payments recorded',
        description: 'Record incoming customer cash, bank transfer, EasyPaisa, or JazzCash payments.',
        icon: Icons.account_balance_wallet_outlined,
        buttonText: 'Record Payment',
        onPressed: () => _showRecordPaymentDialog(context, vm),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: vm.payments.length,
      itemBuilder: (context, index) {
        final payment = vm.payments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.greenIconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_downward_rounded, color: AppColors.greenIcon, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(payment.customerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(
                        '${StringHelpers.titleCase(payment.method)} • ${Extractor.formatDate(payment.receivedAt)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Extractor.formatPkr(payment.amountPaisa),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.greenIcon),
                    ),
                    const SizedBox(height: 4),
                    StatusBadge(status: payment.status),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceivablesList(BuildContext context, PaymentsViewModel vm) {
    if (vm.receivables.isEmpty) {
      return const EmptyStateCard(
        title: 'No outstanding receivables',
        description: 'All customer balances are settled. Great job keeping cash flow healthy!',
        icon: Icons.check_circle_outline_rounded,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: vm.receivables.length,
      itemBuilder: (context, index) {
        final item = vm.receivables[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.orangeIconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.call_received_rounded, color: AppColors.orangeIcon, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.customerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      if (item.phone != null)
                        Text(item.phone!, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Extractor.formatPkr(item.outstandingPaisa),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.orangeIcon),
                    ),
                    const SizedBox(height: 4),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _showRecordPaymentDialog(context, vm, preselectedCustomerId: item.customerId),
                      child: const Text('Collect', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRecordPaymentDialog(BuildContext context, PaymentsViewModel vm, {String? preselectedCustomerId}) {
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    String method = 'cash';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (bContext) => Padding(
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
                  const Text('Record Payment', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(bContext)),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (PKR) *', prefixText: 'Rs '),
                validator: (v) => v == null || v.trim().isEmpty ? 'Amount required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: method,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                  DropdownMenuItem(value: 'easypaisa', child: Text('EasyPaisa')),
                  DropdownMenuItem(value: 'jazzcash', child: Text('JazzCash')),
                  DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => method = v ?? 'cash',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: refCtrl,
                decoration: const InputDecoration(labelText: 'Reference number / Transaction ID (optional)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.pop(bContext);
                  final ok = await vm.recordPayment({
                    'customer_id': preselectedCustomerId ?? 'cust-1',
                    'amount_paisa': Extractor.toPaisa(amountCtrl.text),
                    'method': method,
                    if (refCtrl.text.isNotEmpty) 'reference': refCtrl.text.trim(),
                  });
                  if (ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payment recorded successfully!')),
                    );
                  }
                },
                child: const Text('Save Payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
