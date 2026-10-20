import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../di_container.dart';
import '../../../models/response/customer_model.dart';
import '../../../models/response/product_model.dart';
import '../../../repositories/customer_repository.dart';
import '../../../repositories/order_repository.dart';
import '../../../repositories/product_repository.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/extractor.dart';
import '../../widget/app_header.dart';

class OrderCreateView extends StatefulWidget {
  const OrderCreateView({super.key});

  @override
  State<OrderCreateView> createState() => _OrderCreateViewState();
}

class _OrderCreateViewState extends State<OrderCreateView> {
  final _formKey = GlobalKey<FormState>();
  final _customerRepo = sl<CustomerRepository>();
  final _productRepo = sl<ProductRepository>();
  final _orderRepo = sl<OrderRepository>();

  List<Customer> _customers = [];
  List<Product> _products = [];
  bool _loadingInitial = true;
  bool _submitting = false;

  Customer? _selectedCustomer;
  final List<_LineItemDraft> _lines = [];
  final _discountController = TextEditingController(text: '0');
  final _deliveryFeeController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  bool _confirmImmediately = false;

  @override
  void initState() {
    super.initState();
    _loadPrerequisites();
  }

  Future<void> _loadPrerequisites() async {
    final custRes = await _customerRepo.getCustomers(limit: 50, isPreview: true);
    final prodRes = await _productRepo.getProducts(limit: 50, isPreview: true);

    if (mounted) {
      setState(() {
        _loadingInitial = false;
        _customers = custRes.data?.items ?? [];
        _products = prodRes.data?.items ?? [];
        if (_customers.isNotEmpty) _selectedCustomer = _customers.first;
        if (_products.isNotEmpty) {
          _lines.add(_LineItemDraft(
            product: _products.first,
            quantity: 1,
            unitPriceRupees: _products.first.pricePaisa / 100.0,
          ));
        }
      });
    }
  }

  double get _subtotal {
    return _lines.fold(0.0, (sum, item) => sum + (item.quantity * item.unitPriceRupees));
  }

  double get _total {
    final discount = double.tryParse(_discountController.text) ?? 0.0;
    final fee = double.tryParse(_deliveryFeeController.text) ?? 0.0;
    return (_subtotal - discount + fee).clamp(0.0, double.infinity);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(
        title: 'Create Order',
        showBackButton: true,
      ),
      body: _loadingInitial
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Customer Selection Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Customer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<Customer>(
                          initialValue: _selectedCustomer,
                          decoration: const InputDecoration(labelText: 'Select customer *'),
                          items: _customers.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Text('${c.name} (${c.city ?? "General"})'),
                            );
                          }).toList(),
                          onChanged: (c) => setState(() => _selectedCustomer = c),
                          validator: (c) => c == null ? 'Customer is required' : null,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Line Items Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Items & Products', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            TextButton.icon(
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add product'),
                              onPressed: () {
                                if (_products.isNotEmpty) {
                                  setState(() {
                                    _lines.add(_LineItemDraft(
                                      product: _products.first,
                                      quantity: 1,
                                      unitPriceRupees: _products.first.pricePaisa / 100.0,
                                    ));
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_lines.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: Text('Add at least one product item.')),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _lines.length,
                            separatorBuilder: (_, _) => const Divider(height: 24),
                            itemBuilder: (context, index) {
                              final line = _lines[index];
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: DropdownButtonFormField<Product>(
                                      initialValue: line.product,
                                      isExpanded: true,
                                      decoration: const InputDecoration(labelText: 'Product'),
                                      items: _products.map((p) {
                                        return DropdownMenuItem(
                                          value: p,
                                          child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                        );
                                      }).toList(),
                                      onChanged: (p) {
                                        if (p != null) {
                                          setState(() {
                                            line.product = p;
                                            line.unitPriceRupees = p.pricePaisa / 100.0;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 1,
                                    child: TextFormField(
                                      initialValue: line.quantity.toString(),
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(labelText: 'Qty'),
                                      onChanged: (v) {
                                        setState(() {
                                          line.quantity = int.tryParse(v) ?? 1;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      initialValue: line.unitPriceRupees.toStringAsFixed(2),
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(labelText: 'Price'),
                                      onChanged: (v) {
                                        setState(() {
                                          line.unitPriceRupees = double.tryParse(v) ?? 0.0;
                                        });
                                      },
                                    ),
                                  ),
                                  if (_lines.length > 1)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppColors.redIcon, size: 20),
                                      onPressed: () => setState(() => _lines.removeAt(index)),
                                    ),
                                ],
                              );
                            },
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Pricing & Notes Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _discountController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Discount (PKR)'),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _deliveryFeeController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Delivery fee (PKR)'),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 2,
                          decoration: const InputDecoration(labelText: 'Order notes / instructions'),
                        ),
                        const SizedBox(height: 10),
                        CheckboxListTile(
                          value: _confirmImmediately,
                          title: const Text('Confirm order immediately', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (v) => setState(() => _confirmImmediately = v ?? false),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Order Total Summary Strip
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.drawerBackground,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Grand Total', style: TextStyle(color: AppColors.drawerTextMuted, fontSize: 11)),
                            Text('PKR (incl. adjustments)', style: TextStyle(color: Colors.white70, fontSize: 10)),
                          ],
                        ),
                        Text(
                          'Rs ${_total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Submit CTA
                  ElevatedButton(
                    onPressed: _submitting
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate() || _selectedCustomer == null || _lines.isEmpty) return;
                            setState(() => _submitting = true);

                            final payload = {
                              'customer_id': _selectedCustomer!.id,
                              'lines': _lines.map((l) => {
                                    'product_id': l.product.id,
                                    'quantity': l.quantity,
                                    'unit_price_paisa': Extractor.toPaisa(l.unitPriceRupees),
                                  }).toList(),
                              'discount_paisa': Extractor.toPaisa(_discountController.text),
                              'delivery_fee_paisa': Extractor.toPaisa(_deliveryFeeController.text),
                              if (_notesController.text.isNotEmpty) 'notes': _notesController.text,
                              'confirm': _confirmImmediately,
                            };

                            final messenger = ScaffoldMessenger.of(context);
                            final router = GoRouter.of(context);
                            final res = await _orderRepo.createOrder(payload);
                            if (!mounted) return;
                            setState(() => _submitting = false);

                            if (res.isSuccess) {
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Order created successfully!')),
                              );
                              router.pop();
                            } else {
                              messenger.showSnackBar(
                                SnackBar(content: Text(res.error ?? 'Failed to create order')),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _submitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save and Place Order', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}

class _LineItemDraft {
  Product product;
  int quantity;
  double unitPriceRupees;

  _LineItemDraft({
    required this.product,
    required this.quantity,
    required this.unitPriceRupees,
  });
}
