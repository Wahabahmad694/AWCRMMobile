class ApiEndPoints {
  ApiEndPoints._();

  // Base API configuration
  static const String defaultBaseUrl = 'https://aw-crm-mu.vercel.app/api/v1';

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String logoutAll = '/auth/logout-all';
  static const String forgotPassword = '/auth/password/forgot';
  static const String resetPassword = '/auth/password/reset';
  static const String changePassword = '/auth/password/change';
  static const String authMe = '/auth/me';
  static const String sessions = '/auth/sessions';
  static String revokeSession(String id) => '/auth/sessions/$id';

  // Organization & Team
  static const String organizations = '/organizations';
  static String organization(String id) => '/organizations/$id';
  static String members(String orgId) => '/organizations/$orgId/members';
  static String member(String orgId, String memberId) => '/organizations/$orgId/members/$memberId';
  static String invitations(String orgId) => '/organizations/$orgId/invitations';
  static const String acceptInvitation = '/invitations/accept';

  // Subscription
  static const String subscription = '/subscription';

  // Dashboard & Analytics
  static const String dashboardSummary = '/dashboard/summary';
  static const String salesSummary = '/sales/summary';
  static const String salesTrends = '/sales/trends';
  static const String salesByCustomer = '/sales/by-customer';
  static const String salesByProduct = '/sales/by-product';
  static const String salesInactiveCustomers = '/sales/inactive-customers';

  // Customers
  static const String customers = '/customers';
  static String customer(String id) => '/customers/$id';
  static String customerArchive(String id) => '/customers/$id/archive';
  static String customerRestore(String id) => '/customers/$id/restore';
  static String customerActivities(String id) => '/customers/$id/activities';
  static String customerNotes(String id) => '/customers/$id/notes';
  static String customerOrders(String id) => '/customers/$id/orders';
  static String customerLedger(String id) => '/customers/$id/ledger';
  static String customerPayments(String id) => '/customers/$id/payments';

  // Products & Categories
  static const String products = '/products';
  static String product(String id) => '/products/$id';
  static String productArchive(String id) => '/products/$id/archive';
  static String productRestore(String id) => '/products/$id/restore';
  static const String productCategories = '/product-categories';
  static String productCategory(String id) => '/product-categories/$id';

  // Inventory
  static const String inventory = '/inventory';
  static const String lowStock = '/inventory/low-stock';
  static const String inventoryValuation = '/inventory/valuation';
  static const String inventoryMovements = '/inventory/movements';
  static const String inventoryAdjustments = '/inventory/adjustments';
  static const String inventoryStocktakes = '/inventory/stocktakes';
  static String productInventory(String productId) => '/inventory/$productId';

  // Orders
  static const String orders = '/orders';
  static String order(String id) => '/orders/$id';
  static String orderConfirm(String id) => '/orders/$id/confirm';
  static String orderProcess(String id) => '/orders/$id/process';
  static String orderFulfill(String id) => '/orders/$id/fulfill';
  static String orderCancel(String id) => '/orders/$id/cancel';
  static String orderReturn(String id) => '/orders/$id/return';
  static String orderPayments(String id) => '/orders/$id/payments';
  static String orderActivities(String id) => '/orders/$id/activities';

  // Payments & Receivables
  static const String payments = '/payments';
  static String payment(String id) => '/payments/$id';
  static const String paymentSummary = '/payments/summary';
  static String paymentReverse(String id) => '/payments/$id/reverse';
  static const String refunds = '/refunds';
  static const String receivables = '/receivables';

  // Expenses
  static const String expenses = '/expenses';
  static String expense(String id) => '/expenses/$id';
  static const String expenseSummary = '/expenses/summary';
  static String expenseVoid(String id) => '/expenses/$id/void';
  static const String expenseCategories = '/expense-categories';

  // Targets
  static const String targets = '/targets';
  static String target(String id) => '/targets/$id';
  static String targetProgress(String id) => '/targets/$id/progress';
  static String targetArchive(String id) => '/targets/$id/archive';

  // Activities & Reminders
  static const String activities = '/activities';
  static String activity(String id) => '/activities/$id';
  static String activityComplete(String id) => '/activities/$id/complete';
  static const String reminders = '/reminders';
  static String reminder(String id) => '/reminders/$id';

  // Notifications
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static String notificationRead(String id) => '/notifications/$id/read';
  static const String notificationsReadAll = '/notifications/read-all';
  static const String notificationPreferences = '/notification-preferences';

  // AI Chat
  static const String aiChat = '/ai/chat';
}
