import '../../../data/base_vm.dart';
import '../../../di_container.dart';
import '../../../models/response/team_model.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/team_repository.dart';

class TeamViewModel extends BaseViewModel {
  final TeamRepository _teamRepo = sl<TeamRepository>();
  final AuthRepository _authRepo = sl<AuthRepository>();

  List<TeamMember> _members = [];
  List<TeamMember> get members => _members;

  Future<void> loadMembers({bool refresh = false}) async {
    setBusy(true);
    final orgId = _authRepo.activeOrganizationId ?? 'demo-org';
    final result = await _teamRepo.getMembers(orgId, isPreview: _authRepo.isPreviewMode);

    if (result.isSuccess && result.data != null) {
      _members = result.data!;
      setBusy(false);
    } else {
      setError(result.error ?? 'Failed to load team members.');
      setBusy(false);
    }
  }

  Future<bool> inviteMember({String? email, String? phone, required String role}) async {
    final orgId = _authRepo.activeOrganizationId ?? 'demo-org';
    final result = await runBusyFuture(() => _teamRepo.inviteMember(
          orgId,
          email: email,
          phone: phone,
          role: role,
        ));
    if (result != null && result.isSuccess) {
      await loadMembers(refresh: true);
      return true;
    }
    setError(result?.error ?? 'Failed to send invite.');
    return false;
  }
}
