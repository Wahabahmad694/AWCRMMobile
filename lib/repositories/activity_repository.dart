import '../../data/remote/api_result.dart';
import '../../data/remote/api_service.dart';
import '../../models/response/activity_model.dart';
import '../../models/response/api_response.dart';
import '../../utils/api_end_points.dart';

class ActivityRepository {
  ActivityRepository({required ApiService apiService}) : _api = apiService;

  final ApiService _api;

  Future<ApiResult<PaginatedList<Activity>>> getActivities({
    int page = 1,
    int limit = 20,
    bool isPreview = false,
  }) async {
    if (isPreview) {
      return ApiResult.success(const PaginatedList(
        items: [
          Activity(
            id: 'act-1',
            type: 'call',
            subject: 'Follow-up regarding steel order',
            body: 'Customer inquired about delivery schedule.',
            customerName: 'Acme Traders',
          ),
        ],
        page: 1,
        limit: 20,
        total: 1,
      ));
    }

    final result = await _api.get(ApiEndPoints.activities, queryParameters: {'page': page, 'limit': limit});
    if (result.isSuccess) {
      final list = PaginatedList.fromJson(result.data, (json) => Activity.fromJson(json));
      return ApiResult.success(list);
    }
    return ApiResult.failure(result.error ?? 'Failed to load activities.');
  }

  Future<ApiResult<PaginatedList<Reminder>>> getReminders({
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

    final result = await _api.get(ApiEndPoints.reminders, queryParameters: {'page': page, 'limit': limit});
    if (result.isSuccess) {
      final list = PaginatedList.fromJson(result.data, (json) => Reminder.fromJson(json));
      return ApiResult.success(list);
    }
    return ApiResult.failure(result.error ?? 'Failed to load reminders.');
  }

  Future<ApiResult<bool>> createActivity(Map<String, dynamic> data) async {
    final result = await _api.post(ApiEndPoints.activities, data: data);
    if (result.isSuccess) return const ApiResult.success(true);
    return ApiResult.failure(result.error ?? 'Failed to create activity.');
  }

  Future<ApiResult<bool>> completeActivity(String id, int version) async {
    final result = await _api.post(ApiEndPoints.activityComplete(id), data: {'expected_version': version});
    if (result.isSuccess) return const ApiResult.success(true);
    return ApiResult.failure(result.error ?? 'Failed to complete activity.');
  }

  Future<ApiResult<bool>> createReminder(Map<String, dynamic> data) async {
    final result = await _api.post(ApiEndPoints.reminders, data: data);
    if (result.isSuccess) return const ApiResult.success(true);
    return ApiResult.failure(result.error ?? 'Failed to create reminder.');
  }
}
