import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/sharedKeys.dart';

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: SharedKeys.accessToken, value: accessToken);
    await _storage.write(key: SharedKeys.refreshToken, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: SharedKeys.accessToken);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: SharedKeys.refreshToken);
  }

  Future<void> saveOrganizationId(String orgId) async {
    await _storage.write(key: SharedKeys.organizationId, value: orgId);
  }

  Future<String?> getOrganizationId() async {
    return await _storage.read(key: SharedKeys.organizationId);
  }

  Future<void> setPreviewMode(bool enabled) async {
    await _storage.write(key: SharedKeys.previewMode, value: enabled ? 'true' : 'false');
  }

  Future<bool> getPreviewMode() async {
    final val = await _storage.read(key: SharedKeys.previewMode);
    return val == 'true';
  }

  Future<void> clearAll() async {
    await _storage.delete(key: SharedKeys.accessToken);
    await _storage.delete(key: SharedKeys.refreshToken);
    await _storage.delete(key: SharedKeys.organizationId);
    await _storage.delete(key: SharedKeys.previewMode);
  }
}
