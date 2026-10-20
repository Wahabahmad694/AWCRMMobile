import '../../data/remote/api_result.dart';
import '../../data/remote/api_service.dart';
import '../../models/response/api_response.dart';
import '../../models/response/notification_model.dart';
import '../../utils/api_end_points.dart';
import '../../utils/extractor.dart';

class NotificationRepository {
  NotificationRepository({required ApiService apiService}) : _api = apiService;

  final ApiService _api;

  Future<ApiResult<PaginatedList<NotificationItem>>> getNotifications({
    int page = 1,
    int limit = 20,
    bool isPreview = false,
  }) async {
    if (isPreview) {
      return ApiResult.success(const PaginatedList(
        items: [],
        page: 1,
        limit: 20,
        total: 0,
      ));
    }

    final result = await _api.get(ApiEndPoints.notifications, queryParameters: {'page': page, 'limit': limit});
    if (result.isSuccess) {
      final list = PaginatedList.fromJson(result.data, (json) => NotificationItem.fromJson(json));
      return ApiResult.success(list);
    }
    return ApiResult.failure(result.error ?? 'Failed to load notifications.');
  }

  Future<int> getUnreadCount({bool isPreview = false}) async {
    if (isPreview) return 0;
    final result = await _api.get(ApiEndPoints.notificationsUnreadCount);
    if (result.isSuccess && result.data is Map) {
      return Extractor.asInt(result.data['unread_count'] ?? result.data['count']);
    }
    return 0;
  }

  Future<void> markAllAsRead() async {
    await _api.post(ApiEndPoints.notificationsReadAll);
  }
}
