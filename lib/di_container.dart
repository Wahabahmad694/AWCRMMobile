import 'package:get_it/get_it.dart';
import 'data/remote/api_service.dart';
import 'repositories/activity_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/customer_repository.dart';
import 'repositories/dashboard_repository.dart';
import 'repositories/expense_repository.dart';
import 'repositories/inventory_repository.dart';
import 'repositories/notification_repository.dart';
import 'repositories/order_repository.dart';
import 'repositories/product_repository.dart';
import 'repositories/payment_repository.dart';
import 'repositories/target_repository.dart';
import 'repositories/team_repository.dart';
import 'services/secure_storage_service.dart';
import 'utils/themeProvider.dart';

final sl = GetIt.instance;

Future<void> initDi() async {
  // 1. Core Services & Storage
  final storageService = SecureStorageService();
  sl.registerSingleton<SecureStorageService>(storageService);

  // 2. Network Client
  final apiService = ApiService(storageService: storageService);
  sl.registerSingleton<ApiService>(apiService);

  // 3. Theme Provider
  sl.registerLazySingleton<ThemeProvider>(() => ThemeProvider());

  // 4. Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepository(
        apiService: sl<ApiService>(),
        storageService: sl<SecureStorageService>(),
      ));

  sl.registerLazySingleton<DashboardRepository>(() => DashboardRepository(
        apiService: sl<ApiService>(),
      ));

  sl.registerLazySingleton<CustomerRepository>(() => CustomerRepository(
        apiService: sl<ApiService>(),
      ));

  sl.registerLazySingleton<OrderRepository>(() => OrderRepository(
        apiService: sl<ApiService>(),
      ));

  sl.registerLazySingleton<ProductRepository>(() => ProductRepository(
        apiService: sl<ApiService>(),
      ));

  sl.registerLazySingleton<InventoryRepository>(() => InventoryRepository(
        apiService: sl<ApiService>(),
      ));

  sl.registerLazySingleton<PaymentRepository>(() => PaymentRepository(
        apiService: sl<ApiService>(),
      ));

  sl.registerLazySingleton<ExpenseRepository>(() => ExpenseRepository(
        apiService: sl<ApiService>(),
      ));

  sl.registerLazySingleton<ActivityRepository>(() => ActivityRepository(
        apiService: sl<ApiService>(),
      ));

  sl.registerLazySingleton<TargetRepository>(() => TargetRepository(
        apiService: sl<ApiService>(),
      ));

  sl.registerLazySingleton<TeamRepository>(() => TeamRepository(
        apiService: sl<ApiService>(),
      ));

  sl.registerLazySingleton<NotificationRepository>(() => NotificationRepository(
        apiService: sl<ApiService>(),
      ));
}
