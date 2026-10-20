import '../../utils/extractor.dart';

class DashboardSummary {
  final int salesTodayPaisa;
  final int ordersToday;
  final int salesThisMonthPaisa;
  final int ordersThisMonth;
  final int cashCollectedPaisa;
  final int receivablesPaisa;
  final int expensesPaisa;
  final int operatingProfitPaisa;

  final List<TrendPoint> salesTrends;
  final List<LowStockAlert> lowStockAlerts;
  final List<RecentOrder> recentOrders;
  final List<FollowUpAlert> dueFollowUps;

  const DashboardSummary({
    this.salesTodayPaisa = 0,
    this.ordersToday = 0,
    this.salesThisMonthPaisa = 0,
    this.ordersThisMonth = 0,
    this.cashCollectedPaisa = 0,
    this.receivablesPaisa = 0,
    this.expensesPaisa = 0,
    this.operatingProfitPaisa = 0,
    this.salesTrends = const [],
    this.lowStockAlerts = const [],
    this.recentOrders = const [],
    this.dueFollowUps = const [],
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final today = json['today'] is Map ? json['today'] as Map : const {};
    final month = json['month_to_date'] is Map ? json['month_to_date'] as Map : const {};
    final receivables = json['receivables'] is Map ? json['receivables'] as Map : const {};

    return DashboardSummary(
      salesTodayPaisa: Extractor.asInt(today['net_sales_paisa'] ?? json['sales_today_paisa']),
      ordersToday: Extractor.asInt(today['orders'] ?? json['orders_today']),
      salesThisMonthPaisa: Extractor.asInt(month['net_sales_paisa'] ?? json['sales_this_month_paisa']),
      ordersThisMonth: Extractor.asInt(month['orders'] ?? json['orders_this_month']),
      cashCollectedPaisa: Extractor.asInt(month['net_collected_paisa'] ?? json['cash_collected_paisa']),
      receivablesPaisa: Extractor.asInt(receivables['outstanding_paisa'] ?? json['receivables_paisa']),
      expensesPaisa: Extractor.asInt(month['expenses_paisa'] ?? json['expenses_paisa']),
      operatingProfitPaisa: Extractor.asInt(month['estimated_operating_profit_paisa'] ?? json['operating_profit_paisa']),
      salesTrends: [],
      lowStockAlerts: [],
      recentOrders: [],
      dueFollowUps: [],
    );
  }

  DashboardSummary copyWith({
    int? salesTodayPaisa,
    int? ordersToday,
    int? salesThisMonthPaisa,
    int? ordersThisMonth,
    int? cashCollectedPaisa,
    int? receivablesPaisa,
    int? expensesPaisa,
    int? operatingProfitPaisa,
    List<TrendPoint>? salesTrends,
    List<LowStockAlert>? lowStockAlerts,
    List<RecentOrder>? recentOrders,
    List<FollowUpAlert>? dueFollowUps,
  }) {
    return DashboardSummary(
      salesTodayPaisa: salesTodayPaisa ?? this.salesTodayPaisa,
      ordersToday: ordersToday ?? this.ordersToday,
      salesThisMonthPaisa: salesThisMonthPaisa ?? this.salesThisMonthPaisa,
      ordersThisMonth: ordersThisMonth ?? this.ordersThisMonth,
      cashCollectedPaisa: cashCollectedPaisa ?? this.cashCollectedPaisa,
      receivablesPaisa: receivablesPaisa ?? this.receivablesPaisa,
      expensesPaisa: expensesPaisa ?? this.expensesPaisa,
      operatingProfitPaisa: operatingProfitPaisa ?? this.operatingProfitPaisa,
      salesTrends: salesTrends ?? this.salesTrends,
      lowStockAlerts: lowStockAlerts ?? this.lowStockAlerts,
      recentOrders: recentOrders ?? this.recentOrders,
      dueFollowUps: dueFollowUps ?? this.dueFollowUps,
    );
  }

  /// Demo snapshot matching the user's web screenshot
  factory DashboardSummary.demo() {
    return DashboardSummary(
      salesTodayPaisa: 12550, // Rs 125.50
      ordersToday: 1,
      salesThisMonthPaisa: 12550, // Rs 125.50
      ordersThisMonth: 1,
      cashCollectedPaisa: 0, // Rs 0.00
      receivablesPaisa: 12550, // Rs 125.50
      expensesPaisa: 0, // Rs 0.00
      operatingProfitPaisa: 12550, // Rs 125.50
      salesTrends: [
        const TrendPoint(label: '10-01', valuePaisa: 0),
        const TrendPoint(label: '10-04', valuePaisa: 0),
        const TrendPoint(label: '10-07', valuePaisa: 0),
        const TrendPoint(label: '10-10', valuePaisa: 0),
        const TrendPoint(label: '10-13', valuePaisa: 0),
        const TrendPoint(label: '10-16', valuePaisa: 0),
        const TrendPoint(label: '10-19', valuePaisa: 12550),
        const TrendPoint(label: '10-22', valuePaisa: 0),
        const TrendPoint(label: '10-25', valuePaisa: 0),
        const TrendPoint(label: '10-28', valuePaisa: 0),
        const TrendPoint(label: '10-31', valuePaisa: 0),
      ],
      lowStockAlerts: [],
      recentOrders: [
        const RecentOrder(
          id: 'ord-1',
          orderNumber: 'ORD-2026-0001',
          customerName: 'Acme Traders',
          status: 'confirmed',
          totalPaisa: 12550,
        ),
      ],
      dueFollowUps: [],
    );
  }
}

class TrendPoint {
  final String label;
  final int valuePaisa;

  const TrendPoint({required this.label, required this.valuePaisa});

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    final label = json['period_start'] ?? json['period'] ?? json['date'] ?? '';
    final val = Extractor.asInt(json['net_sales_paisa']);
    return TrendPoint(
      label: Extractor.formatShortDate(label),
      valuePaisa: val,
    );
  }
}

class LowStockAlert {
  final String id;
  final String productName;
  final String? sku;
  final int onHand;
  final int? lowStockLevel;

  const LowStockAlert({
    required this.id,
    required this.productName,
    this.sku,
    required this.onHand,
    this.lowStockLevel,
  });

  factory LowStockAlert.fromJson(Map<String, dynamic> json) {
    final prod = json['product'] is Map ? json['product'] as Map : const {};
    return LowStockAlert(
      id: json['id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? prod['name']?.toString() ?? json['name']?.toString() ?? 'Product',
      sku: json['sku']?.toString() ?? prod['sku']?.toString(),
      onHand: Extractor.asInt(json['on_hand'] ?? json['quantity']),
      lowStockLevel: Extractor.asNullableInt(json['low_stock_level']),
    );
  }
}

class RecentOrder {
  final String id;
  final String orderNumber;
  final String customerName;
  final String status;
  final int totalPaisa;

  const RecentOrder({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.status,
    required this.totalPaisa,
  });

  factory RecentOrder.fromJson(Map<String, dynamic> json) {
    final cust = json['customer'] is Map ? json['customer'] as Map : const {};
    return RecentOrder(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? json['number']?.toString() ?? 'Order',
      customerName: json['customer_name']?.toString() ?? cust['name']?.toString() ?? 'Customer',
      status: json['status']?.toString() ?? 'pending',
      totalPaisa: Extractor.asInt(json['total_amount_paisa'] ?? json['total_paisa']),
    );
  }
}

class FollowUpAlert {
  final String id;
  final String title;
  final DateTime? dueAt;

  const FollowUpAlert({required this.id, required this.title, this.dueAt});

  factory FollowUpAlert.fromJson(Map<String, dynamic> json) {
    DateTime? d;
    if (json['due_at'] != null) {
      try {
        d = DateTime.parse(json['due_at'].toString()).toLocal();
      } catch (_) {}
    }
    return FollowUpAlert(
      id: json['id']?.toString() ?? '',
      title: json['subject']?.toString() ?? json['title']?.toString() ?? 'Follow-up',
      dueAt: d,
    );
  }
}
