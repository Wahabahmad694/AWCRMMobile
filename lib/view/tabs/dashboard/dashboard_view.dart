import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../di_container.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/notification_repository.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/extractor.dart';
import '../../bottomNav/custom_bottom_nav.dart';
import '../../widget/app_drawer.dart';
import '../../widget/app_header.dart';
import '../../widget/empty_state_card.dart';
import '../../widget/metric_card.dart';
import '../../widget/sales_chart_widget.dart';
import '../../widget/status_badge.dart';
import 'dashboard_vm.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    final count = await sl<NotificationRepository>().getUnreadCount(
      isPreview: sl<AuthRepository>().isPreviewMode,
    );
    if (mounted) setState(() => _unreadNotifications = count);
  }

  @override
  Widget build(BuildContext context) {
    final authRepo = sl<AuthRepository>();

    return ChangeNotifierProvider(
      create: (_) => DashboardViewModel()..loadDashboard(),
      child: Consumer<DashboardViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: AppColors.background,
            appBar: AppHeader(
              title: 'Dashboard',
              isSignedIn: authRepo.isSignedIn,
              unreadNotifications: _unreadNotifications,
              userInitials: authRepo.currentUser?.name ?? 'AW',
            ),
            drawer: const AppDrawer(currentRoute: '/dashboard'),
            bottomNavigationBar: CustomBottomNav(
              currentIndex: 0,
              onTap: (index) {
                if (index == 1) context.go('/customers');
                if (index == 2) context.go('/orders');
                if (index == 3) context.go('/assistant');
              },
              onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            body: RefreshIndicator(
              onRefresh: () async {
                await vm.refresh();
                await _fetchUnreadCount();
              },
              color: AppColors.primary,
              child: vm.isBusy
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      children: [
                        // Page Heading & Eyebrow
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        vm.organizationName.toUpperCase(),
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      const Text(
                                        '  /  OVERVIEW',
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  RichText(
                                    text: const TextSpan(
                                      text: 'A clearer view of your business',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.6,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '.',
                                          style: TextStyle(color: AppColors.primary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Everything that matters, all in one place.',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Create order CTA button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Create an order'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => context.push('/orders/create'),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Business overview strip
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Business overview',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const Text(
                              'All amounts in PKR',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // 8 KPI Metric Cards Grid
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.15,
                          children: [
                            MetricCard(
                              title: 'Sales today',
                              value: Extractor.formatPkr(vm.summary.salesTodayPaisa),
                              subtitle: 'Net sales today',
                              icon: Icons.monetization_on_outlined,
                              iconColor: AppColors.blueIcon,
                              iconBgColor: AppColors.blueIconBg,
                            ),
                            MetricCard(
                              title: 'Orders today',
                              value: vm.summary.ordersToday.toString(),
                              subtitle: 'Orders placed today',
                              icon: Icons.shopping_bag_outlined,
                              iconColor: AppColors.violetIcon,
                              iconBgColor: AppColors.violetIconBg,
                              onTap: () => context.go('/orders'),
                            ),
                            MetricCard(
                              title: 'Sales this month',
                              value: Extractor.formatPkr(vm.summary.salesThisMonthPaisa),
                              subtitle: 'Month to date',
                              icon: Icons.trending_up_rounded,
                              iconColor: AppColors.tealIcon,
                              iconBgColor: AppColors.tealIconBg,
                            ),
                            MetricCard(
                              title: 'Orders this month',
                              value: vm.summary.ordersThisMonth.toString(),
                              subtitle: 'Month to date',
                              icon: Icons.inventory_2_outlined,
                              iconColor: AppColors.orangeIcon,
                              iconBgColor: AppColors.orangeIconBg,
                              onTap: () => context.go('/orders'),
                            ),
                            MetricCard(
                              title: 'Cash collected',
                              value: Extractor.formatPkr(vm.summary.cashCollectedPaisa),
                              subtitle: 'Collected this month',
                              icon: Icons.account_balance_wallet_outlined,
                              iconColor: AppColors.tealIcon,
                              iconBgColor: AppColors.tealIconBg,
                              onTap: () => context.go('/payments'),
                            ),
                            MetricCard(
                              title: 'Receivables',
                              value: Extractor.formatPkr(vm.summary.receivablesPaisa),
                              subtitle: 'Outstanding customer balances',
                              icon: Icons.call_received_rounded,
                              iconColor: AppColors.orangeIcon,
                              iconBgColor: AppColors.orangeIconBg,
                              onTap: () => context.go('/payments'),
                            ),
                            MetricCard(
                              title: 'Expenses',
                              value: Extractor.formatPkr(vm.summary.expensesPaisa),
                              subtitle: 'Business spending this month',
                              icon: Icons.receipt_long_outlined,
                              iconColor: AppColors.violetIcon,
                              iconBgColor: AppColors.violetIconBg,
                              onTap: () => context.go('/expenses'),
                            ),
                            MetricCard(
                              title: 'Operating profit',
                              value: Extractor.formatPkr(vm.summary.operatingProfitPaisa),
                              subtitle: 'Estimated · month to date',
                              icon: Icons.insights_rounded,
                              iconColor: AppColors.blueIcon,
                              iconBgColor: AppColors.blueIconBg,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Sales Performance Bezier Curve Chart
                        SalesChartWidget(
                          points: vm.summary.salesTrends,
                          onViewReports: () => context.go('/reports'),
                        ),

                        const SizedBox(height: 16),

                        // Inventory Watch Card
                        _buildInventoryWatchCard(context, vm),

                        const SizedBox(height: 16),

                        // Recent Orders Card
                        _buildRecentOrdersCard(context, vm),

                        const SizedBox(height: 16),

                        // AI Assistant Promo Card
                        _buildAiBanner(context),

                        const SizedBox(height: 30),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInventoryWatchCard(BuildContext context, DashboardViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inventory watch',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Keep your bestsellers ready',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
              Icon(Icons.inventory_2_outlined, color: AppColors.textMuted, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          if (vm.summary.lowStockAlerts.isEmpty)
            const EmptyStateCard(
              title: 'No low-stock alerts',
              description: 'Your low-stock products will be highlighted here, so you can plan ahead.',
              icon: Icons.inventory_outlined,
              compact: true,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vm.summary.lowStockAlerts.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final item = vm.summary.lowStockAlerts[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text(item.sku ?? 'No SKU', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.orangeIconBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${item.onHand} left',
                      style: const TextStyle(
                        color: AppColors.orangeIcon,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => context.go('/inventory'),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Explore inventory',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_outward_rounded, size: 14, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersCard(BuildContext context, DashboardViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent orders',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'The latest activity in your pipeline',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
              InkWell(
                onTap: () => context.go('/orders'),
                child: const Row(
                  children: [
                    Text('View all', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_outward_rounded, size: 14, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (vm.summary.recentOrders.isEmpty)
            const EmptyStateCard(
              title: 'Ready for your first order',
              description: 'Create an order to start tracking your sales and fulfillment.',
              icon: Icons.receipt_long_outlined,
              compact: true,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vm.summary.recentOrders.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final order = vm.summary.recentOrders[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primarySubtle,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 18),
                  ),
                  title: Text(
                    order.orderNumber,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                  ),
                  subtitle: Text(
                    order.customerName,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        Extractor.formatPkr(order.totalPaisa),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      StatusBadge(status: order.status),
                    ],
                  ),
                  onTap: () => context.push('/orders/${order.id}'),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAiBanner(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/assistant'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF052C49),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF164365)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF0C3855),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF62B3FF), size: 22),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your next business advantage',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Ask questions about stock, revenue & orders in Urdu or English.',
                    style: TextStyle(
                      color: Color(0xFFB9CEDB),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF62B3FF), size: 14),
          ],
        ),
      ),
    );
  }
}
