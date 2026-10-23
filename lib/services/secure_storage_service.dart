import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/sharedKeys.dart';

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: SharedKeys.accessToken, value: accessToken);
    await _storage.write(key: SharedKeys.refreshToken, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: SharedKeys.accessToken);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: SharedKeys.refreshToken);
  }

  Future<void> saveUserCache({
    required String userJson,
    required String membershipsJson,
  }) async {
    await _storage.write(key: SharedKeys.userProfile, value: userJson);
    await _storage.write(key: SharedKeys.memberships, value: membershipsJson);
  }

  Future<Map<String, dynamic>?> getCachedUser() async {
    final value = await _storage.read(key: SharedKeys.userProfile);
    if (value == null || value.isEmpty) return null;
    try {
      final decoded = jsonDecode(value);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } on FormatException {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getCachedMemberships() async {
    final value = await _storage.read(key: SharedKeys.memberships);
    if (value == null || value.isEmpty) return [];
    try {
      final decoded = jsonDecode(value);
      return decoded is List
          ? decoded
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : [];
    } on FormatException {
      return [];
    }
  }

  Future<void> saveOrganizationId(String orgId) async {
    await _storage.write(key: SharedKeys.organizationId, value: orgId);
  }

  Future<String?> getOrganizationId() async {
    return await _storage.read(key: SharedKeys.organizationId);
  }

  Future<void> clearOrganizationId() =>
      _storage.delete(key: SharedKeys.organizationId);

  Future<void> setPreviewMode(bool enabled) async {
    await _storage.write(
      key: SharedKeys.previewMode,
      value: enabled ? 'true' : 'false',
    );
  }

  Future<bool> getPreviewMode() async {
    final val = await _storage.read(key: SharedKeys.previewMode);
    return val == 'true';
  }

  Future<bool> getOnboardingSeen() async =>
      await _storage.read(key: 'awc_onboarding_seen') == 'true';

  Future<void> setOnboardingSeen() =>
      _storage.write(key: 'awc_onboarding_seen', value: 'true');

  Future<void> clearAll() async {
    await _storage.delete(key: SharedKeys.accessToken);
    await _storage.delete(key: SharedKeys.refreshToken);
    await _storage.delete(key: SharedKeys.organizationId);
    await _storage.delete(key: SharedKeys.previewMode);
    await _storage.delete(key: SharedKeys.userProfile);
    await _storage.delete(key: SharedKeys.memberships);
  }
}
