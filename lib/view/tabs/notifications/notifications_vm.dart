import '../../../data/base_vm.dart';
import '../../../di_container.dart';
import '../../../models/response/notification_model.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/notification_repository.dart';

class NotificationsViewModel extends BaseViewModel {
  final NotificationRepository _notifRepo = sl<NotificationRepository>();
  final AuthRepository _authRepo = sl<AuthRepository>();

  List<NotificationItem> _notifications = [];
  List<NotificationItem> get notifications => _notifications;

  Future<void> loadNotifications({bool refresh = false}) async {
    setBusy(true);
    final result = await _notifRepo.getNotifications(isPreview: _authRepo.isPreviewMode);
    if (result.isSuccess && result.data != null) {
      _notifications = result.data!.items;
      setBusy(false);
    } else {
      setError(result.error ?? 'Failed to load notifications.');
      setBusy(false);
    }
  }

  Future<void> markAllAsRead() async {
    await _notifRepo.markAllAsRead();
    await loadNotifications(refresh: true);
  }
}
