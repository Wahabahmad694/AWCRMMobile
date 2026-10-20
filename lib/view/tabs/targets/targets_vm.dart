import '../../../data/base_vm.dart';
import '../../../di_container.dart';
import '../../../models/response/target_model.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/target_repository.dart';

class TargetsViewModel extends BaseViewModel {
  final TargetRepository _targetRepo = sl<TargetRepository>();
  final AuthRepository _authRepo = sl<AuthRepository>();

  List<SalesTarget> _targets = [];
  List<SalesTarget> get targets => _targets;

  Future<void> loadTargets({bool refresh = false}) async {
    setBusy(true);
    final result = await _targetRepo.getTargets(isPreview: _authRepo.isPreviewMode);
    if (result.isSuccess && result.data != null) {
      _targets = result.data!.items;
      setBusy(false);
    } else {
      setError(result.error ?? 'Failed to load targets.');
      setBusy(false);
    }
  }

  Future<bool> createTarget(Map<String, dynamic> data) async {
    final result = await runBusyFuture(() => _targetRepo.createTarget(data));
    if (result != null && result.isSuccess) {
      await loadTargets(refresh: true);
      return true;
    }
    setError(result?.error ?? 'Failed to create target.');
    return false;
  }
}
