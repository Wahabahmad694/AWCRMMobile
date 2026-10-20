import '../../data/remote/api_result.dart';
import '../../data/remote/api_service.dart';
import '../../models/response/team_model.dart';
import '../../utils/api_end_points.dart';
import '../../utils/extractor.dart';

class TeamRepository {
  TeamRepository({required ApiService apiService}) : _api = apiService;

  final ApiService _api;

  Future<ApiResult<List<TeamMember>>> getMembers(String orgId, {bool isPreview = false}) async {
    if (isPreview) {
      return ApiResult.success(const [
        TeamMember(
          id: 'mem-1',
          name: 'Wahab Ahmad',
          email: 'wahab@solutionio.pk',
          role: 'owner',
          status: 'active',
        ),
      ]);
    }

    final result = await _api.get(ApiEndPoints.members(orgId));
    if (result.isSuccess) {
      final items = Extractor.extractItems(result.data);
      return ApiResult.success(items.map((m) => TeamMember.fromJson(m)).toList());
    }
    return ApiResult.failure(result.error ?? 'Failed to load team members.');
  }

  Future<ApiResult<bool>> inviteMember(String orgId, {String? email, String? phone, required String role}) async {
    final result = await _api.post(ApiEndPoints.invitations(orgId), data: {
      if (email != null && email.isNotEmpty) 'email': email,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'role': role,
    });
    if (result.isSuccess) return const ApiResult.success(true);
    return ApiResult.failure(result.error ?? 'Failed to send invitation.');
  }
}
