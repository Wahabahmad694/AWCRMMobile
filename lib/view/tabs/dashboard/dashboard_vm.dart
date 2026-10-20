import '../../../data/base_vm.dart';
import '../../../di_container.dart';
import '../../../models/response/dashboard_response.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/dashboard_repository.dart';

class DashboardViewModel extends BaseViewModel {
  final DashboardRepository _dashboardRepo = sl<DashboardRepository>();
  final AuthRepository _authRepo = sl<AuthRepository>();

  DashboardSummary _summary = const DashboardSummary();
  DashboardSummary get summary => _summary;

  String get organizationName => _authRepo.currentMembership?.name ?? 'Solution IO';
  bool get isPreview => _authRepo.isPreviewMode;

  Future<void> loadDashboard() async {
    setBusy(true);
    final result = await _dashboardRepo.getDashboardSummary(isPreview: isPreview);
    if (result.isSuccess && result.data != null) {
      _summary = result.data!;
      setBusy(false);
    } else {
      setError(result.error ?? 'Could not load dashboard data.');
      setBusy(false);
    }
  }

  Future<void> refresh() async {
    await loadDashboard();
  }
}
