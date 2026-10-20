import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../di_container.dart';
import '../../../models/response/inventory_model.dart';
import '../../../repositories/auth_repository.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/extractor.dart';
import '../../widget/app_drawer.dart';
import '../../widget/app_header.dart';
import '../../widget/empty_state_card.dart';
import 'inventory_vm.dart';

class InventoryView extends StatefulWidget {
  const InventoryView({super.key});

  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final authRepo = sl<AuthRepository>();

    return ChangeNotifierProvider(
      create: (_) => InventoryViewModel()..loadInventory(),
      child: Consumer<InventoryViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: AppColors.background,
            appBar: AppHeader(
              title: 'Inventory',
              isSignedIn: authRepo.isSignedIn,
              userInitials: authRepo.currentUser?.name ?? 'AW',
            ),
            drawer: const AppDrawer(currentRoute: '/inventory'),
            body: RefreshIndicator(
              onRefresh: () => vm.loadInventory(refresh: true),
              color: AppColors.primary,
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('All stock items'),
                          selected: !vm.showOnlyLowStock,
                          onSelected: (_) => vm.toggleLowStockFilter(),
                          selectedColor: AppColors.primarySubtle,
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Low stock alerts'),
                          selected: vm.showOnlyLowStock,
                          onSelected: (_) => vm.toggleLowStockFilter(),
                          selectedColor: AppColors.orangeIconBg,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: vm.isBusy && vm.inventory.isEmpty
                        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                        : vm.filteredInventory.isEmpty
                            ? EmptyStateCard(
                                title: vm.showOnlyLowStock ? 'No low stock alerts' : 'Inventory is empty',
                                description: vm.showOnlyLowStock
                                    ? 'All product stock levels are above the minimum threshold.'
                                    : 'Add products with inventory tracking to see live levels.',
                                icon: Icons.warehouse_outlined,
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                                itemCount: vm.filteredInventory.length,
                                itemBuilder: (context, index) {
                                  final item = vm.filteredInventory[index];
                                  return _buildStockCard(context, item, vm);
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

  Widget _buildStockCard(BuildContext context, StockLevel item, InventoryViewModel vm) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                      ),
                      if (item.sku != null)
                        Text('SKU: ${item.sku}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.isLowStock ? AppColors.orangeIconBg : AppColors.greenIconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${item.onHand} in stock',
                    style: TextStyle(
                      color: item.isLowStock ? AppColors.orangeIcon : AppColors.greenIcon,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
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
                    const Text('Valuation (at cost)', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                    Text(
                      Extractor.formatPkr(item.valuationPaisa),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.tune_rounded, size: 14),
                  label: const Text('Adjust'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  onPressed: () => _showAdjustStockDialog(context, item, vm),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAdjustStockDialog(BuildContext context, StockLevel item, InventoryViewModel vm) {
    final formKey = GlobalKey<FormState>();
    final changeCtrl = TextEditingController(text: '0');
    final reasonCtrl = TextEditingController(text: 'Physical inventory audit');

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
                  Text('Adjust Stock: ${item.productName}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(bContext)),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: changeCtrl,
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                decoration: const InputDecoration(
                  labelText: 'Quantity change (+/-) *',
                  hintText: 'e.g. 5 or -2',
                ),
                validator: (v) => v == null || int.tryParse(v) == null ? 'Valid integer required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonCtrl,
                decoration: const InputDecoration(labelText: 'Reason for adjustment *'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Reason is required' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.pop(bContext);
                  final ok = await vm.adjustStock(
                    productId: item.productId,
                    quantityChange: int.parse(changeCtrl.text),
                    reason: reasonCtrl.text.trim(),
                  );
                  if (ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Stock adjusted successfully!')),
                    );
                  }
                },
                child: const Text('Confirm Adjustment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
