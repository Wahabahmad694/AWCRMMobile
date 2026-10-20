import '../../data/remote/api_result.dart';
import '../../data/remote/api_service.dart';
import '../../models/response/dashboard_response.dart';
import '../../utils/api_end_points.dart';
import '../../utils/extractor.dart';

class DashboardRepository {
  DashboardRepository({required ApiService apiService}) : _api = apiService;

  final ApiService _api;

  Future<ApiResult<DashboardSummary>> getDashboardSummary({bool isPreview = false}) async {
    if (isPreview) {
      return ApiResult.success(DashboardSummary.demo());
    }

    try {
      final summaryRes = await _api.get(ApiEndPoints.dashboardSummary);
      if (summaryRes.isFailure) {
        return ApiResult.failure(summaryRes.error ?? 'Failed to load dashboard summary.');
      }

      final summaryData = summaryRes.data is Map ? Map<String, dynamic>.from(summaryRes.data as Map) : <String, dynamic>{};
      DashboardSummary summary = DashboardSummary.fromJson(summaryData);

      // Concurrently fetch supplementary dashboard data (trends, low stock, recent orders, reminders)
      final results = await Future.wait([
        _api.get(ApiEndPoints.salesTrends),
        _api.get(ApiEndPoints.lowStock),
        _api.get(ApiEndPoints.orders, queryParameters: {'page': 1, 'limit': 5}),
        _api.get(ApiEndPoints.reminders, queryParameters: {'page': 1, 'limit': 5}),
      ]);

      final trendRes = results[0];
      final stockRes = results[1];
      final orderRes = results[2];
      final reminderRes = results[3];

      List<TrendPoint> trends = [];
      if (trendRes.isSuccess) {
        final items = Extractor.extractItems(trendRes.data);
        trends = items.map((m) => TrendPoint.fromJson(m)).toList();
      }

      List<LowStockAlert> lowStock = [];
      if (stockRes.isSuccess) {
        final items = Extractor.extractItems(stockRes.data);
        lowStock = items.map((m) => LowStockAlert.fromJson(m)).toList();
      }

      List<RecentOrder> recentOrders = [];
      if (orderRes.isSuccess) {
        final items = Extractor.extractItems(orderRes.data);
        recentOrders = items.map((m) => RecentOrder.fromJson(m)).toList();
      }

      List<FollowUpAlert> followUps = [];
      if (reminderRes.isSuccess) {
        final items = Extractor.extractItems(reminderRes.data);
        followUps = items.map((m) => FollowUpAlert.fromJson(m)).toList();
      }

      summary = summary.copyWith(
        salesTrends: trends,
        lowStockAlerts: lowStock,
        recentOrders: recentOrders,
        dueFollowUps: followUps,
      );

      return ApiResult.success(summary);
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }
}
