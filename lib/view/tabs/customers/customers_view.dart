import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../di_container.dart';
import '../../../models/response/customer_model.dart';
import '../../../repositories/auth_repository.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/extractor.dart';
import '../../../utils/string_helpers.dart';
import '../../bottomNav/custom_bottom_nav.dart';
import '../../widget/app_drawer.dart';
import '../../widget/app_header.dart';
import '../../widget/empty_state_card.dart';
import '../../widget/status_badge.dart';
import 'customers_vm.dart';

class CustomersView extends StatefulWidget {
  const CustomersView({super.key});

  @override
  State<CustomersView> createState() => _CustomersViewState();
}

class _CustomersViewState extends State<CustomersView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authRepo = sl<AuthRepository>();

    return ChangeNotifierProvider(
      create: (_) => CustomersViewModel()..loadCustomers(),
      child: Consumer<CustomersViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: AppColors.background,
            appBar: AppHeader(
              title: 'Customers',
              isSignedIn: authRepo.isSignedIn,
              userInitials: authRepo.currentUser?.name ?? 'AW',
            ),
            drawer: const AppDrawer(currentRoute: '/customers'),
            bottomNavigationBar: CustomBottomNav(
              currentIndex: 1,
              onTap: (index) {
                if (index == 0) context.go('/dashboard');
                if (index == 2) context.go('/orders');
                if (index == 3) context.go('/assistant');
              },
              onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            floatingActionButton: FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_outlined, size: 20),
              label: const Text('Add Customer', style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () => _showAddCustomerDialog(context, vm),
            ),
            body: RefreshIndicator(
              onRefresh: () => vm.loadCustomers(refresh: true),
              color: AppColors.primary,
              child: Column(
                children: [
                  // Search & Filter Header
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search customer by name, phone, or code…',
                            prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      vm.search('');
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          onChanged: vm.search,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _filterChip('All', null, vm),
                            const SizedBox(width: 8),
                            _filterChip('Customers', 'customer', vm),
                            const SizedBox(width: 8),
                            _filterChip('Leads', 'lead', vm),
                            const Spacer(),
                            if (vm.total != null)
                              Text(
                                '${vm.total} records',
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Customer List
                  Expanded(
                    child: vm.isBusy && vm.customers.isEmpty
                        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                        : vm.customers.isEmpty
                            ? EmptyStateCard(
                                title: vm.searchQuery.isEmpty ? 'Your customers start here' : 'No matching customers',
                                description: vm.searchQuery.isEmpty
                                    ? 'Add your first customer or business lead to manage orders, payments, and ledgers.'
                                    : 'Try searching with a different term.',
                                icon: Icons.people_outline,
                                buttonText: vm.searchQuery.isEmpty ? 'Add Customer' : null,
                                onPressed: () => _showAddCustomerDialog(context, vm),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                                itemCount: vm.customers.length,
                                itemBuilder: (context, index) {
                                  final customer = vm.customers[index];
                                  return _buildCustomerCard(context, customer);
                                },
                              ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _filterChip(String label, String? type, CustomersViewModel vm) {
    final isSelected = vm.selectedType == type;
    return InkWell(
      onTap: () => vm.filterByType(type),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySubtle : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, Customer customer) {
    final hasBalance = customer.balancePaisa > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/customers/${customer.id}'),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primarySubtle,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      StringHelpers.initials(customer.name),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        if (customer.businessName != null && customer.businessName!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              customer.businessName!,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  StatusBadge(status: customer.type),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Outstanding balance',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Extractor.formatPkr(customer.balancePaisa),
                        style: TextStyle(
                          color: hasBalance ? AppColors.orangeIcon : AppColors.greenIcon,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  if (customer.phone != null && customer.phone!.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          customer.phone!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context, CustomersViewModel vm) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final businessCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final limitCtrl = TextEditingController();
    String type = 'customer';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add Customer / Lead',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(bottomSheetContext)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Customer'),
                        selected: type == 'customer',
                        onSelected: (_) => setModalState(() => type = 'customer'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Lead'),
                        selected: type == 'lead',
                        onSelected: (_) => setModalState(() => type = 'lead'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Contact / Customer Name *'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: businessCtrl,
                    decoration: const InputDecoration(labelText: 'Business Name (optional)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone number (e.g. +92 300 1234567)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email address'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: cityCtrl,
                          decoration: const InputDecoration(labelText: 'City'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: limitCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Credit Limit (PKR)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      Navigator.pop(bottomSheetContext);
                      final ok = await vm.createCustomer({
                        'name': nameCtrl.text.trim(),
                        'type': type,
                        if (businessCtrl.text.isNotEmpty) 'business_name': businessCtrl.text.trim(),
                        if (phoneCtrl.text.isNotEmpty) 'phone': phoneCtrl.text.trim(),
                        if (emailCtrl.text.isNotEmpty) 'email': emailCtrl.text.trim(),
                        if (cityCtrl.text.isNotEmpty) 'city': cityCtrl.text.trim(),
                        'credit_limit_paisa': Extractor.toPaisa(limitCtrl.text),
                      });
                      if (ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Customer added successfully!')),
                        );
                      }
                    },
                    child: const Text('Save Customer'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
