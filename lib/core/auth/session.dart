import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;

  factory UserProfile.fromJson(Map<String, dynamic> data) => UserProfile(
        id: data['id']?.toString() ?? '',
        name: data['name']?.toString() ?? 'User',
        email: data['email']?.toString() ?? '',
        phone: data['phone']?.toString(),
      );
}

class Membership {
  const Membership({
    required this.organizationId,
    required this.name,
    required this.permissions,
    this.role,
    this.subscriptionStatus,
  });

  final String organizationId;
  final String name;
  final Set<String> permissions;
  final String? role;
  final String? subscriptionStatus;

  factory Membership.fromJson(Map data) {
    final organization = data['organization'];
    final org = organization is Map ? organization : const {};
    final id = data['organization_id'] ?? org['id'];
    if (id is! String) throw const FormatException('Missing organization ID');
    final permissions = data['permissions'];
    final status = org['subscription_status'] ?? data['subscription_status'];
    return Membership(
      organizationId: id,
      name: org['name'] is String ? org['name'] as String : 'Organization',
      permissions: permissions is List ? permissions.whereType<String>().toSet() : <String>{},
      role: data['role']?.toString(),
      subscriptionStatus: status?.toString(),
    );
  }
}

class AuthSession {
  const AuthSession({
    required this.id,
    this.userAgent,
    this.ipAddress,
    this.createdAt,
    this.lastActiveAt,
    this.isCurrent = false,
  });

  final String id;
  final String? userAgent;
  final String? ipAddress;
  final DateTime? createdAt;
  final DateTime? lastActiveAt;
  final bool isCurrent;

  factory AuthSession.fromJson(Map<String, dynamic> data) {
    DateTime? parseDate(dynamic val) {
      if (val is String && val.isNotEmpty) {
        try {
          return DateTime.parse(val).toLocal();
        } catch (_) {}
      }
      return null;
    }

    return AuthSession(
      id: data['id']?.toString() ?? '',
      userAgent: data['user_agent']?.toString() ?? data['device']?.toString(),
      ipAddress: data['ip_address']?.toString() ?? data['ip']?.toString(),
      createdAt: parseDate(data['created_at']),
      lastActiveAt: parseDate(data['last_active_at'] ?? data['last_seen_at']),
      isCurrent: data['is_current'] == true || data['current'] == true,
    );
  }
}

class Session extends ChangeNotifier implements TokenStore {
  Session(this.api, {FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage() {
    api.attachTokenStore(this);
    api.refreshSession = refreshSession;
    api.onSessionExpired = expire;
    api.onSubscriptionRequired = () {
      readOnly = true;
      notifyListeners();
    };
  }

  final ApiClient api;
  final FlutterSecureStorage _storage;
  String? _webRefreshToken;
  String? _accessToken;
  String? _organizationId;

  static const _refreshKey = 'refresh_token';
  static const _organizationKey = 'organization_id';

  bool restoring = true;
  bool busy = false;
  bool signedIn = false;
  bool previewMode = false;
  bool readOnly = false;
  String? error;
  ApiFailure? lastFailure;

  UserProfile? user;
  List<Membership> memberships = [];

  @override
  String? get access => _accessToken;

  @override
  Future<String?> get refresh => _readRefresh();

  @override
  String? get organizationId => _organizationId;

  Membership? get currentMembership {
    for (final item in memberships) {
      if (item.organizationId == organizationId) return item;
    }
    return null;
  }

  Future<String?> _readRefresh() async =>
      kIsWeb ? _webRefreshToken : _storage.read(key: _refreshKey);

  @override
  Future<void> save(String access, String refresh) =>
      _saveTokens({'access_token': access, 'refresh_token': refresh});

  @override
  Future<void> clear() => _clear();

  Future<void> _saveTokens(Map data) async {
    final access = data['access_token'];
    final refresh = data['refresh_token'];
    if (access is! String || refresh is! String || access.isEmpty || refresh.isEmpty) {
      throw const FormatException('Invalid authentication response');
    }
    if (kIsWeb) {
      _webRefreshToken = refresh;
    } else {
      await _storage.write(key: _refreshKey, value: refresh);
    }
    _accessToken = access;
    api.accessToken = access;
  }

  Future<void> restore() async {
    try {
      if (await _readRefresh() != null && await refreshSession()) {
        await loadProfile();
      }
    } catch (_) {
      await _clear();
    } finally {
      restoring = false;
      notifyListeners();
    }
  }

  Future<bool> refreshSession() async {
    final token = await _readRefresh();
    if (token == null) return false;
    try {
      // Use raw Dio so a refresh failure cannot recursively invoke AuthInterceptor.
      final response = await api.dio.post<dynamic>(
        '/auth/refresh',
        data: {'refresh_token': token},
      );
      if (response.data is! Map) throw const FormatException('Invalid refresh response');
      await _saveTokens(response.data as Map);
      return true;
    } catch (_) {
      await _clear();
      return false;
    }
  }

  Future<void> loadProfile() async {
    final response = await api.get('/auth/me');
    final data = response.data;
    if (data is! Map) throw const FormatException('Invalid profile response');

    if (data['user'] is Map) {
      user = UserProfile.fromJson(Map<String, dynamic>.from(data['user'] as Map));
    }

    final raw = data['memberships'];
    memberships = raw is List ? raw.whereType<Map>().map(Membership.fromJson).toList() : [];

    final remembered = await _storage.read(key: _organizationKey);
    final choice = memberships.any((m) => m.organizationId == remembered)
        ? remembered
        : (memberships.isEmpty ? null : memberships.first.organizationId);
    _organizationId = choice;
    api.organizationId = choice;

    // Check subscription status of chosen membership or root organization
    final org = data['organization'] is Map ? data['organization'] as Map : const {};
    final status = currentMembership?.subscriptionStatus ?? org['subscription_status']?.toString();
    if (status == 'suspended' || status == 'expired' || status == 'past_due') {
      readOnly = true;
    } else {
      readOnly = false;
    }

    signedIn = true;
    previewMode = false;
    notifyListeners();
  }

  Future<bool> signIn(String identifier, String password) async {
    if (busy) return false;
    busy = true;
    error = null;
    lastFailure = null;
    notifyListeners();
    try {
      final response = await api.post('/auth/login', {
        'identifier': identifier.trim(),
        'password': password,
      });
      if (response.data is! Map) throw const FormatException('Invalid login response');
      await _saveTokens(response.data as Map);
      await loadProfile();
      return true;
    } on ApiFailure catch (failure) {
      await _clear();
      lastFailure = failure;
      error = failure.statusCode == 401
          ? 'The credentials are incorrect.'
          : failure.message;
      return false;
    } catch (e) {
      await _clear();
      error = 'Sign-in could not be completed: $e';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    String? phone,
    required String password,
    required String organizationName,
  }) async {
    if (busy) return false;
    busy = true;
    error = null;
    lastFailure = null;
    notifyListeners();
    try {
      final payload = <String, dynamic>{
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'organization_name': organizationName.trim(),
      };
      if (phone != null && phone.trim().isNotEmpty) {
        payload['phone'] = phone.trim();
      }
      final response = await api.post('/auth/register', payload);
      if (response.data is! Map) throw const FormatException('Invalid register response');
      await _saveTokens(response.data as Map);
      await loadProfile();
      return true;
    } on ApiFailure catch (failure) {
      await _clear();
      lastFailure = failure;
      error = failure.message;
      return false;
    } catch (e) {
      await _clear();
      error = 'Registration could not be completed: $e';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<String> forgotPassword(String identifier) async {
    try {
      final response = await api.post('/auth/password/forgot', {
        'identifier': identifier.trim(),
        'email': identifier.trim(),
      });
      final data = response.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      return 'If an account exists, a password reset link has been sent.';
    } on ApiFailure catch (failure) {
      lastFailure = failure;
      throw failure.message;
    } catch (e) {
      throw 'Unable to send reset instructions: $e';
    }
  }

  Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await api.post('/auth/password/reset', {
        'token': token.trim(),
        'new_password': newPassword,
        'password': newPassword,
      });
      final data = response.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      return 'Password has been reset successfully. Please sign in.';
    } on ApiFailure catch (failure) {
      lastFailure = failure;
      throw failure.message;
    } catch (e) {
      throw 'Unable to reset password: $e';
    }
  }

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await api.post('/auth/password/change', {
        'current_password': currentPassword,
        'new_password': newPassword,
      });
      final data = response.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      return 'Password changed successfully.';
    } on ApiFailure catch (failure) {
      lastFailure = failure;
      throw failure.message;
    } catch (e) {
      throw 'Failed to change password: $e';
    }
  }

  Future<List<AuthSession>> getSessions() async {
    try {
      final response = await api.get('/auth/sessions');
      final data = response.data;
      List rawList;
      if (data is List) {
        rawList = data;
      } else if (data is Map && data['sessions'] is List) {
        rawList = data['sessions'] as List;
      } else if (data is Map && data['items'] is List) {
        rawList = data['items'] as List;
      } else {
        rawList = [];
      }
      return rawList
          .whereType<Map>()
          .map((m) => AuthSession.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } on ApiFailure catch (failure) {
      lastFailure = failure;
      throw failure.message;
    } catch (e) {
      throw 'Failed to load sessions: $e';
    }
  }

  Future<void> revokeSession(String sessionId) async {
    try {
      await api.delete('/auth/sessions/$sessionId');
    } on ApiFailure catch (failure) {
      lastFailure = failure;
      throw failure.message;
    } catch (e) {
      throw 'Failed to revoke session: $e';
    }
  }

  Future<void> switchOrganization(String id) async {
    if (!memberships.any((membership) => membership.organizationId == id)) return;
    _organizationId = id;
    api.organizationId = id;
    await _storage.write(key: _organizationKey, value: id);

    final status = currentMembership?.subscriptionStatus;
    if (status == 'suspended' || status == 'expired' || status == 'past_due') {
      readOnly = true;
    } else {
      readOnly = false;
    }
    notifyListeners();
  }

  Future<void> _clear() async {
    _webRefreshToken = null;
    await _storage.delete(key: _refreshKey);
    _accessToken = null;
    _organizationId = null;
    api.accessToken = null;
    api.organizationId = null;
    user = null;
    memberships = [];
    signedIn = false;
    readOnly = false;
    notifyListeners();
  }

  void expire() {
    _clear();
  }

  Future<void> signOut() async {
    if (signedIn) {
      try {
        await api.post('/auth/logout', null);
      } catch (_) {
        /* Local logout still proceeds even if network drops */
      }
    }
    await _clear();
    previewMode = false;
    notifyListeners();
  }

  void enterPreview() {
    _accessToken = null;
    _organizationId = null;
    api.accessToken = null;
    api.organizationId = null;
    user = null;
    error = null;
    lastFailure = null;
    previewMode = true;
    notifyListeners();
  }
}

