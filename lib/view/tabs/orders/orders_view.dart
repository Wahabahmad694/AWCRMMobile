import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../di_container.dart';
import '../../../models/response/order_model.dart';
import '../../../repositories/auth_repository.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/extractor.dart';
import '../../bottomNav/custom_bottom_nav.dart';
import '../../widget/app_drawer.dart';
import '../../widget/app_header.dart';
import '../../widget/empty_state_card.dart';
import '../../widget/status_badge.dart';
import 'orders_vm.dart';

class OrdersView extends StatefulWidget {
  const OrdersView({super.key});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final authRepo = sl<AuthRepository>();

    return ChangeNotifierProvider(
      create: (_) => OrdersViewModel()..loadOrders(),
      child: Consumer<OrdersViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: AppColors.background,
            appBar: AppHeader(
              title: 'Orders',
              isSignedIn: authRepo.isSignedIn,
              userInitials: authRepo.currentUser?.name ?? 'AW',
            ),
            drawer: const AppDrawer(currentRoute: '/orders'),
            bottomNavigationBar: CustomBottomNav(
              currentIndex: 2,
              onTap: (index) {
                if (index == 0) context.go('/dashboard');
                if (index == 1) context.go('/customers');
                if (index == 3) context.go('/assistant');
              },
              onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            floatingActionButton: FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Create Order', style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () => context.push('/orders/create'),
            ),
            body: RefreshIndicator(
              onRefresh: () => vm.loadOrders(refresh: true),
              color: AppColors.primary,
              child: Column(
                children: [
                  // Status Filter Scrollable Bar
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip('All', null, vm),
                          const SizedBox(width: 8),
                          _filterChip('Draft', 'draft', vm),
                          const SizedBox(width: 8),
                          _filterChip('Confirmed', 'confirmed', vm),
                          const SizedBox(width: 8),
                          _filterChip('Processing', 'processing', vm),
                          const SizedBox(width: 8),
                          _filterChip('Fulfilled', 'fulfilled', vm),
                          const SizedBox(width: 8),
                          _filterChip('Cancelled', 'cancelled', vm),
                        ],
                      ),
                    ),
                  ),

                  // Orders List
                  Expanded(
                    child: vm.isBusy && vm.orders.isEmpty
                        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                        : vm.orders.isEmpty
                            ? EmptyStateCard(
                                title: 'No orders found',
                                description: 'Create an order to start tracking sales, items, and fulfillment pipeline.',
                                icon: Icons.shopping_bag_outlined,
                                buttonText: 'Create an order',
                                onPressed: () => context.push('/orders/create'),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                                itemCount: vm.orders.length,
                                itemBuilder: (context, index) {
                                  final order = vm.orders[index];
                                  return _buildOrderCard(context, order, vm);
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

  Widget _filterChip(String label, String? status, OrdersViewModel vm) {
    final isSelected = vm.selectedStatus == status;
    return InkWell(
      onTap: () => vm.filterByStatus(status),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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

  Widget _buildOrderCard(BuildContext context, Order order, OrdersViewModel vm) {
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
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primarySubtle,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderNumber,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          order.customerName,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
                StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Line items preview
            if (order.lines.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    for (final line in order.lines.take(2))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${line.productName} × ${line.quantity}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              Extractor.formatPkr(line.totalPaisa),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total amount', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                    const SizedBox(height: 2),
                    Text(
                      Extractor.formatPkr(order.totalAmountPaisa),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),

                // Lifecycle Quick Transition Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (order.status == 'draft')
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () => vm.transitionOrder(order.id, 'confirm', order.version),
                        child: const Text('Confirm', style: TextStyle(fontSize: 11)),
                      ),
                    if (order.status == 'confirmed')
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orangeIcon,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () => vm.transitionOrder(order.id, 'process', order.version),
                        child: const Text('Process', style: TextStyle(fontSize: 11)),
                      ),
                    if (order.status == 'processing')
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.greenIcon,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () => vm.transitionOrder(order.id, 'fulfill', order.version),
                        child: const Text('Fulfill', style: TextStyle(fontSize: 11)),
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
}
