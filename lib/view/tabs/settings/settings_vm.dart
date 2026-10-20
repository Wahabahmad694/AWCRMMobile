import '../../../data/base_vm.dart';
import '../../../di_container.dart';
import '../../../models/response/auth_response.dart';
import '../../../repositories/auth_repository.dart';

class SettingsViewModel extends BaseViewModel {
  final AuthRepository _authRepo = sl<AuthRepository>();

  UserProfile? get user => _authRepo.currentUser;
  Membership? get organization => _authRepo.currentMembership;
  List<Membership> get memberships => _authRepo.memberships;
  bool get isPreview => _authRepo.isPreviewMode;

  List<SessionItem> _sessions = [];
  List<SessionItem> get sessions => _sessions;

  Future<void> loadSessions() async {
    if (isPreview) return;
    setBusy(true);
    _sessions = await _authRepo.getSessions();
    setBusy(false);
  }

  Future<void> switchOrg(String orgId) async {
    await _authRepo.switchOrganization(orgId);
    notifyListeners();
  }

  Future<String?> changePassword(String oldPass, String newPass) async {
    try {
      final msg = await _authRepo.changePassword(currentPassword: oldPass, newPassword: newPass);
      setSuccess(msg);
      return msg;
    } catch (e) {
      setError(e.toString());
      return null;
    }
  }

  Future<void> logout() async {
    await _authRepo.logout();
  }
}
