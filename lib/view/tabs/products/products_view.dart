import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../di_container.dart';
import '../../../models/response/product_model.dart';
import '../../../repositories/auth_repository.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/extractor.dart';
import '../../widget/app_drawer.dart';
import '../../widget/app_header.dart';
import '../../widget/empty_state_card.dart';
import 'products_vm.dart';

class ProductsView extends StatefulWidget {
  const ProductsView({super.key});

  @override
  State<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<ProductsView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authRepo = sl<AuthRepository>();

    return ChangeNotifierProvider(
      create: (_) => ProductsViewModel()..loadProducts(),
      child: Consumer<ProductsViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: AppColors.background,
            appBar: AppHeader(
              title: 'Products',
              isSignedIn: authRepo.isSignedIn,
              userInitials: authRepo.currentUser?.name ?? 'AW',
            ),
            drawer: const AppDrawer(currentRoute: '/products'),
            floatingActionButton: FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_box_outlined, size: 20),
              label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () => _showAddProductDialog(context, vm),
            ),
            body: RefreshIndicator(
              onRefresh: () => vm.loadProducts(refresh: true),
              color: AppColors.primary,
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search products by name or SKU…',
                        prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  vm.search('');
                                },
                              )
                            : null,
                      ),
                      onChanged: vm.search,
                    ),
                  ),
                  Expanded(
                    child: vm.isBusy && vm.products.isEmpty
                        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                        : vm.products.isEmpty
                            ? EmptyStateCard(
                                title: 'No products found',
                                description: 'Add your products and services with PKR pricing and stock alerts.',
                                icon: Icons.inventory_2_outlined,
                                buttonText: 'Add Product',
                                onPressed: () => _showAddProductDialog(context, vm),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                                itemCount: vm.products.length,
                                itemBuilder: (context, index) {
                                  final p = vm.products[index];
                                  return _buildProductCard(context, p);
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

  Widget _buildProductCard(BuildContext context, Product p) {
    final isLowStock = p.lowStockLevel != null && p.stockOnHand <= p.lowStockLevel!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF5FC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                      ),
                      if (p.sku != null && p.sku!.isNotEmpty)
                        Text(
                          'SKU: ${p.sku}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLowStock ? AppColors.orangeIconBg : AppColors.greenIconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${p.stockOnHand} on hand',
                    style: TextStyle(
                      color: isLowStock ? AppColors.orangeIcon : AppColors.greenIcon,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
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
                    const Text('Sale Price', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                    Text(
                      Extractor.formatPkr(p.pricePaisa),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primary),
                    ),
                  ],
                ),
                if (p.costPricePaisa > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Cost', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                      Text(
                        Extractor.formatPkr(p.costPricePaisa),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context, ProductsViewModel vm) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final skuCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '10');
    final lowCtrl = TextEditingController(text: '5');

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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Add Product', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(bContext)),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Product Name *'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: skuCtrl,
                  decoration: const InputDecoration(labelText: 'SKU / Code (e.g. PRD-001)'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Selling Price (PKR) *'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: costCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Cost (PKR)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: stockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Initial Stock'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: lowCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Low Stock Alert Level'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(bContext);
                    final ok = await vm.createProduct({
                      'name': nameCtrl.text.trim(),
                      if (skuCtrl.text.isNotEmpty) 'sku': skuCtrl.text.trim(),
                      'price_paisa': Extractor.toPaisa(priceCtrl.text),
                      'cost_price_paisa': Extractor.toPaisa(costCtrl.text),
                      'low_stock_level': int.tryParse(lowCtrl.text) ?? 5,
                    });
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Product added successfully!')),
                      );
                    }
                  },
                  child: const Text('Save Product'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
