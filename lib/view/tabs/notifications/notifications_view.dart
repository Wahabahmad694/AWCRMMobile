import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/extractor.dart';
import '../../widget/app_header.dart';
import '../../widget/empty_state_card.dart';
import 'notifications_vm.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotificationsViewModel()..loadNotifications(),
      child: Consumer<NotificationsViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: const AppHeader(
              title: 'Notifications',
              showBackButton: true,
            ),
            body: RefreshIndicator(
              onRefresh: () => vm.loadNotifications(refresh: true),
              color: AppColors.primary,
              child: vm.isBusy && vm.notifications.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : vm.notifications.isEmpty
                      ? const EmptyStateCard(
                          title: 'All caught up!',
                          description: 'You have no new alerts, inventory warnings, or order notifications.',
                          icon: Icons.notifications_none_outlined,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: vm.notifications.length,
                          itemBuilder: (context, index) {
                            final n = vm.notifications[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: n.isRead ? const Color(0xFFEFF3F8) : AppColors.primarySubtle,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.notifications_outlined,
                                    color: n.isRead ? AppColors.textMuted : AppColors.primary,
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  n.title,
                                  style: TextStyle(
                                    fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: n.body != null ? Text(n.body!, style: const TextStyle(fontSize: 11)) : null,
                                trailing: Text(
                                  Extractor.formatDate(n.createdAt),
                                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          );
        },
      ),
    );
  }
}
