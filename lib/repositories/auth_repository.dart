import '../../data/remote/api_result.dart';
import '../../data/remote/api_service.dart';
import '../../models/response/auth_response.dart';
import '../../services/secure_storage_service.dart';
import '../../utils/api_end_points.dart';

class AuthRepository {
  AuthRepository({
    required ApiService apiService,
    required SecureStorageService storageService,
  })  : _api = apiService,
        _storage = storageService;

  final ApiService _api;
  final SecureStorageService _storage;

  UserProfile? currentUser;
  List<Membership> memberships = [];
  String? activeOrganizationId;
  bool isPreviewMode = false;

  Membership? get currentMembership {
    if (activeOrganizationId == null) return memberships.firstOrNull;
    return memberships.firstWhere(
      (m) => m.organizationId == activeOrganizationId,
      orElse: () => memberships.firstOrNull ?? const Membership(organizationId: '', name: 'Organization', permissions: {}),
    );
  }

  bool get isSignedIn => currentUser != null && !isPreviewMode;

  Future<ApiResult<AuthResult>> login({
    required String identifier,
    required String password,
  }) async {
    final result = await _api.post(ApiEndPoints.login, data: {
      'identifier': identifier.trim(),
      'password': password,
    });

    if (result.isSuccess && result.data is Map) {
      final auth = AuthResult.fromJson(Map<String, dynamic>.from(result.data as Map));
      await _storage.saveTokens(
        accessToken: auth.accessToken,
        refreshToken: auth.refreshToken,
      );
      currentUser = auth.user;
      memberships = auth.memberships;

      if (memberships.isNotEmpty) {
        activeOrganizationId = memberships.first.organizationId;
        await _storage.saveOrganizationId(activeOrganizationId!);
        _api.setTokens(accessToken: auth.accessToken, organizationId: activeOrganizationId);
      } else {
        _api.setTokens(accessToken: auth.accessToken);
      }

      await _storage.setPreviewMode(false);
      isPreviewMode = false;
      return ApiResult.success(auth);
    }
    return ApiResult.failure(result.error ?? 'Invalid email or password.');
  }

  Future<ApiResult<AuthResult>> register({
    required String name,
    required String email,
    String? phone,
    required String organizationName,
    required String password,
  }) async {
    final result = await _api.post(ApiEndPoints.register, data: {
      'name': name.trim(),
      'email': email.trim(),
      if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
      'organization_name': organizationName.trim(),
      'password': password,
    });

    if (result.isSuccess && result.data is Map) {
      final auth = AuthResult.fromJson(Map<String, dynamic>.from(result.data as Map));
      await _storage.saveTokens(accessToken: auth.accessToken, refreshToken: auth.refreshToken);
      currentUser = auth.user;
      memberships = auth.memberships;
      if (memberships.isNotEmpty) {
        activeOrganizationId = memberships.first.organizationId;
        await _storage.saveOrganizationId(activeOrganizationId!);
      }
      _api.setTokens(accessToken: auth.accessToken, organizationId: activeOrganizationId);
      await _storage.setPreviewMode(false);
      isPreviewMode = false;
      return ApiResult.success(auth);
    }
    return ApiResult.failure(result.error ?? 'Registration failed.');
  }

  Future<void> enterPreviewMode() async {
    isPreviewMode = true;
    await _storage.setPreviewMode(true);
    currentUser = const UserProfile(
      id: 'demo-user',
      name: 'Demo Admin',
      email: 'demo@awcrm.com',
    );
    memberships = [
      const Membership(
        organizationId: 'demo-org',
        name: 'Solution IO',
        permissions: {'*'},
        role: 'owner',
      ),
    ];
    activeOrganizationId = 'demo-org';
  }

  Future<void> switchOrganization(String organizationId) async {
    activeOrganizationId = organizationId;
    await _storage.saveOrganizationId(organizationId);
    _api.setTokens(organizationId: organizationId);
  }

  Future<bool> restoreSession() async {
    final preview = await _storage.getPreviewMode();
    if (preview) {
      await enterPreviewMode();
      return true;
    }

    final token = await _storage.getAccessToken();
    if (token == null) return false;

    activeOrganizationId = await _storage.getOrganizationId();
    _api.setTokens(accessToken: token, organizationId: activeOrganizationId);

    final meRes = await _api.get(ApiEndPoints.authMe);
    if (meRes.isSuccess && meRes.data is Map) {
      final data = Map<String, dynamic>.from(meRes.data as Map);
      currentUser = UserProfile.fromJson(data);

      final orgRes = await _api.get(ApiEndPoints.organizations);
      if (orgRes.isSuccess) {
        final list = orgRes.data is List ? (orgRes.data as List).whereType<Map>().map((m) => Membership.fromJson(Map<String, dynamic>.from(m))).toList() : <Membership>[];
        memberships = list;
        if (activeOrganizationId == null && memberships.isNotEmpty) {
          activeOrganizationId = memberships.first.organizationId;
          await _storage.saveOrganizationId(activeOrganizationId!);
          _api.setTokens(organizationId: activeOrganizationId);
        }
      }
      return true;
    }
    return false;
  }

  Future<String> forgotPassword(String identifier) async {
    final res = await _api.post(ApiEndPoints.forgotPassword, data: {'identifier': identifier.trim()});
    if (res.isSuccess) {
      return 'If an account exists, password reset instructions have been sent.';
    }
    throw res.error ?? 'Could not process forgot password request.';
  }

  Future<String> resetPassword({required String token, required String newPassword}) async {
    final res = await _api.post(ApiEndPoints.resetPassword, data: {
      'token': token.trim(),
      'password': newPassword,
    });
    if (res.isSuccess) {
      return 'Password has been successfully reset. You can now log in.';
    }
    throw res.error ?? 'Could not reset password.';
  }

  Future<String> changePassword({required String currentPassword, required String newPassword}) async {
    final res = await _api.post(ApiEndPoints.changePassword, data: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
    if (res.isSuccess) {
      return 'Password updated successfully.';
    }
    throw res.error ?? 'Could not change password.';
  }

  Future<List<SessionItem>> getSessions() async {
    final res = await _api.get(ApiEndPoints.sessions);
    if (res.isSuccess && res.data is List) {
      return (res.data as List).whereType<Map>().map((m) => SessionItem.fromJson(Map<String, dynamic>.from(m))).toList();
    }
    return [];
  }

  Future<void> revokeSession(String id) async {
    await _api.delete(ApiEndPoints.revokeSession(id));
  }

  Future<void> logout() async {
    try {
      await _api.post(ApiEndPoints.logout);
    } catch (_) {}
    currentUser = null;
    memberships = [];
    activeOrganizationId = null;
    isPreviewMode = false;
    await _storage.clearAll();
  }
}
