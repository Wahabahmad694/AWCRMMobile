import '../../../data/base_vm.dart';
import '../../../di_container.dart';
import '../../../models/response/activity_model.dart';
import '../../../repositories/activity_repository.dart';
import '../../../repositories/auth_repository.dart';

class ActivitiesViewModel extends BaseViewModel {
  final ActivityRepository _activityRepo = sl<ActivityRepository>();
  final AuthRepository _authRepo = sl<AuthRepository>();

  List<Activity> _activities = [];
  List<Activity> get activities => _activities;

  List<Reminder> _reminders = [];
  List<Reminder> get reminders => _reminders;

  int _selectedTab = 0; // 0: Activities, 1: Reminders
  int get selectedTab => _selectedTab;

  void selectTab(int index) {
    _selectedTab = index;
    notifyListeners();
  }

  Future<void> loadData({bool refresh = false}) async {
    setBusy(true);
    final isPrev = _authRepo.isPreviewMode;
    final results = await Future.wait([
      _activityRepo.getActivities(isPreview: isPrev),
      _activityRepo.getReminders(isPreview: isPrev),
    ]);

    final actRes = results[0];
    final remRes = results[1];

    if (actRes.isSuccess && actRes.data != null) {
      _activities = (actRes.data as dynamic).items as List<Activity>;
    }
    if (remRes.isSuccess && remRes.data != null) {
      _reminders = (remRes.data as dynamic).items as List<Reminder>;
    }

    setBusy(false);
  }

  Future<bool> createActivity(Map<String, dynamic> data) async {
    final result = await runBusyFuture(() => _activityRepo.createActivity(data));
    if (result != null && result.isSuccess) {
      await loadData(refresh: true);
      return true;
    }
    setError(result?.error ?? 'Failed to add activity.');
    return false;
  }

  Future<bool> createReminder(Map<String, dynamic> data) async {
    final result = await runBusyFuture(() => _activityRepo.createReminder(data));
    if (result != null && result.isSuccess) {
      await loadData(refresh: true);
      return true;
    }
    setError(result?.error ?? 'Failed to add reminder.');
    return false;
  }

  Future<void> completeActivity(String id, int version) async {
    await _activityRepo.completeActivity(id, version);
    await loadData(refresh: true);
  }
}
