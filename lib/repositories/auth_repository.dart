import 'dart:convert';

import '../../data/remote/api_result.dart';
import '../../data/remote/api_service.dart';
import '../../models/response/auth_response.dart';
import '../../services/secure_storage_service.dart';
import '../../utils/api_end_points.dart';

class AuthRepository {
  AuthRepository({
    required ApiService apiService,
    required SecureStorageService storageService,
  }) : _api = apiService,
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
      orElse: () =>
          memberships.firstOrNull ??
          const Membership(
            organizationId: '',
            name: 'Organization',
            permissions: {},
          ),
    );
  }

  bool get isSignedIn => currentUser != null && !isPreviewMode;

  Future<void> _cacheProfile() => _storage.saveUserCache(
    userJson: jsonEncode(currentUser?.toJson() ?? const {}),
    membershipsJson: jsonEncode(
      memberships.map((item) => item.toJson()).toList(),
    ),
  );

  Map<String, dynamic> _record(dynamic value) {
    if (value is! Map) return {};
    final map = Map<String, dynamic>.from(value);
    return map['data'] is Map
        ? Map<String, dynamic>.from(map['data'] as Map)
        : map;
  }

  List<dynamic> _list(dynamic value) {
    if (value is List) return value;
    if (value is Map) {
      for (final key in ['items', 'memberships', 'results', 'data']) {
        if (value[key] is List) return value[key] as List;
      }
    }
    return const [];
  }

  Future<void> _saveAuth(AuthResult auth) async {
    if (auth.accessToken.isEmpty ||
        auth.refreshToken.isEmpty ||
        auth.user.id.isEmpty) {
      throw const FormatException(
        'The server returned an incomplete login response.',
      );
    }
    currentUser = auth.user;
    memberships = auth.memberships;
    if (memberships.isNotEmpty) {
      final selected =
          memberships
              .where((item) => item.organizationId == activeOrganizationId)
              .firstOrNull ??
          memberships.first;
      activeOrganizationId = selected.organizationId;
    } else {
      activeOrganizationId = null;
    }
    await _storage.saveTokens(
      accessToken: auth.accessToken,
      refreshToken: auth.refreshToken,
    );
    if (activeOrganizationId != null) {
      await _storage.saveOrganizationId(activeOrganizationId!);
    } else {
      await _storage.clearOrganizationId();
    }
    _api.setTokens(
      accessToken: auth.accessToken,
      organizationId: activeOrganizationId,
    );
    await _cacheProfile();
    await _storage.setPreviewMode(false);
    isPreviewMode = false;
  }

  Future<ApiResult<AuthResult>> login({
    required String identifier,
    required String password,
  }) async {
    final result = await _api.post(
      ApiEndPoints.login,
      data: {'identifier': identifier.trim(), 'password': password},
    );

    if (result.isSuccess && result.data is Map) {
      try {
        final auth = AuthResult.fromJson(
          Map<String, dynamic>.from(result.data as Map),
        );
        await _saveAuth(auth);
        return ApiResult.success(auth);
      } catch (error) {
        return ApiResult.failure(error.toString());
      }
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
    final result = await _api.post(
      ApiEndPoints.register,
      data: {
        'name': name.trim(),
        'email': email.trim(),
        if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
        'organization_name': organizationName.trim(),
        'password': password,
      },
    );

    if (result.isSuccess && result.data is Map) {
      try {
        final auth = AuthResult.fromJson(
          Map<String, dynamic>.from(result.data as Map),
        );
        await _saveAuth(auth);
        return ApiResult.success(auth);
      } catch (error) {
        return ApiResult.failure(error.toString());
      }
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
    await _cacheProfile();
  }

  Future<bool> restoreSession() async {
    final preview = await _storage.getPreviewMode();
    if (preview) {
      await enterPreviewMode();
      return true;
    }

    final token = await _storage.getAccessToken();
    final refreshToken = await _storage.getRefreshToken();
    if ((token == null || token.isEmpty) &&
        (refreshToken == null || refreshToken.isEmpty)) {
      await _storage.clearAll();
      return false;
    }

    activeOrganizationId = await _storage.getOrganizationId();
    final cachedUser = await _storage.getCachedUser();
    if (cachedUser != null && cachedUser['id'] != null) {
      currentUser = UserProfile.fromJson(cachedUser);
      memberships = (await _storage.getCachedMemberships())
          .map(Membership.fromJson)
          .toList();
    }
    _api.setTokens(accessToken: token, organizationId: activeOrganizationId);

    var meRes = token == null || token.isEmpty
        ? const ApiResult.failure('Access token missing.', statusCode: 401)
        : await _api.get(ApiEndPoints.authMe);
    if (meRes.isFailure && meRes.statusCode == 401) {
      if (await _api.refreshAccessToken())
        meRes = await _api.get(ApiEndPoints.authMe);
    }

    if (meRes.isSuccess && meRes.data is Map) {
      var profile = _record(meRes.data);
      if (profile['user'] is Map)
        profile = Map<String, dynamic>.from(profile['user'] as Map);
      if (profile['id'] == null) {
        await _clearSession();
        return false;
      }
      currentUser = UserProfile.fromJson(profile);
      final orgRes = await _api.get(ApiEndPoints.organizations);
      if (orgRes.isSuccess) {
        memberships = _list(orgRes.data)
            .whereType<Map>()
            .map((m) => Membership.fromJson(Map<String, dynamic>.from(m)))
            .where((m) => m.organizationId.isNotEmpty)
            .toList();
        if (memberships.isNotEmpty &&
            !memberships.any((m) => m.organizationId == activeOrganizationId)) {
          activeOrganizationId = memberships.first.organizationId;
          await _storage.saveOrganizationId(activeOrganizationId!);
          _api.setTokens(organizationId: activeOrganizationId);
        }
      }
      await _cacheProfile();
      return true;
    }

    if (meRes.statusCode == 401 || meRes.statusCode == 403) {
      await _clearSession();
      return false;
    }
    // Cached identity supports offline startup; the data screens report API connectivity normally.
    return currentUser != null;
  }

  Future<void> _clearSession() async {
    await _storage.clearAll();
    currentUser = null;
    memberships = [];
    activeOrganizationId = null;
    isPreviewMode = false;
    _api.setTokens(accessToken: null, organizationId: null);
  }

  Future<String> forgotPassword(String identifier) async {
    final res = await _api.post(
      ApiEndPoints.forgotPassword,
      data: {'identifier': identifier.trim()},
    );
    if (res.isSuccess) {
      return 'If an account exists, password reset instructions have been sent.';
    }
    throw res.error ?? 'Could not process forgot password request.';
  }

  Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final res = await _api.post(
      ApiEndPoints.resetPassword,
      data: {'token': token.trim(), 'password': newPassword},
    );
    if (res.isSuccess) {
      return 'Password has been successfully reset. You can now log in.';
    }
    throw res.error ?? 'Could not reset password.';
  }

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await _api.post(
      ApiEndPoints.changePassword,
      data: {'current_password': currentPassword, 'new_password': newPassword},
    );
    if (res.isSuccess) {
      return 'Password updated successfully.';
    }
    throw res.error ?? 'Could not change password.';
  }

  Future<List<SessionItem>> getSessions() async {
    final res = await _api.get(ApiEndPoints.sessions);
    if (res.isSuccess && res.data is List) {
      return (res.data as List)
          .whereType<Map>()
          .map((m) => SessionItem.fromJson(Map<String, dynamic>.from(m)))
          .toList();
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
    await _clearSession();
  }
}
