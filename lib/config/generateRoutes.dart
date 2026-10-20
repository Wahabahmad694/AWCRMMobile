// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../repositories/auth_repository.dart';
import '../view/auth/login/login_view.dart';
import '../view/tabs/activities/activities_view.dart';
import '../view/tabs/ai_assistant/assistant_view.dart';
import '../view/tabs/customers/customer_detail_view.dart';
import '../view/tabs/customers/customers_view.dart';
import '../view/tabs/dashboard/dashboard_view.dart';
import '../view/tabs/expenses/expenses_view.dart';
import '../view/tabs/inventory/inventory_view.dart';
import '../view/tabs/notifications/notifications_view.dart';
import '../view/tabs/orders/order_create_view.dart';
import '../view/tabs/orders/orders_view.dart';
import '../view/tabs/payments/payments_view.dart';
import '../view/tabs/products/products_view.dart';
import '../view/tabs/reports/reports_view.dart';
import '../view/tabs/settings/settings_view.dart';
import '../view/tabs/targets/targets_view.dart';
import '../view/tabs/team/team_view.dart';

class RouteGenerator {
  static GoRouter createRouter(AuthRepository authRepo) {
    return GoRouter(
      initialLocation: '/dashboard',
      redirect: (context, state) {
        final signedIn = authRepo.isSignedIn || authRepo.isPreviewMode;
        final onLogin = state.matchedLocation == '/login';

        if (!signedIn && !onLogin) {
          return '/login';
        }
        if (signedIn && onLogin) {
          return '/dashboard';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginView(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardView(),
        ),
        GoRoute(
          path: '/customers',
          builder: (context, state) => const CustomersView(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) => CustomerDetailView(
                customerId: state.pathParameters['id'] ?? '',
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/orders',
          builder: (context, state) => const OrdersView(),
          routes: [
            GoRoute(
              path: 'create',
              builder: (context, state) => const OrderCreateView(),
            ),
          ],
        ),
        GoRoute(
          path: '/products',
          builder: (context, state) => const ProductsView(),
        ),
        GoRoute(
          path: '/inventory',
          builder: (context, state) => const InventoryView(),
        ),
        GoRoute(
          path: '/payments',
          builder: (context, state) => const PaymentsView(),
        ),
        GoRoute(
          path: '/expenses',
          builder: (context, state) => const ExpensesView(),
        ),
        GoRoute(
          path: '/targets',
          builder: (context, state) => const TargetsView(),
        ),
        GoRoute(
          path: '/activities',
          builder: (context, state) => const ActivitiesView(),
        ),
        GoRoute(
          path: '/team',
          builder: (context, state) => const TeamView(),
        ),
        GoRoute(
          path: '/assistant',
          builder: (context, state) => const AssistantView(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsView(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsView(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsView(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text('Route not found: ${state.uri}'),
        ),
      ),
    );
  }
}
