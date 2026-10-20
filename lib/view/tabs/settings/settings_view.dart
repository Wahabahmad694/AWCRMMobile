import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../di_container.dart';
import '../../../repositories/auth_repository.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/string_helpers.dart';
import '../../widget/app_drawer.dart';
import '../../widget/app_header.dart';
import 'settings_vm.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final authRepo = sl<AuthRepository>();

    return ChangeNotifierProvider(
      create: (_) => SettingsViewModel()..loadSessions(),
      child: Consumer<SettingsViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: AppColors.background,
            appBar: AppHeader(
              title: 'Settings',
              isSignedIn: authRepo.isSignedIn,
              userInitials: authRepo.currentUser?.name ?? 'AW',
            ),
            drawer: const AppDrawer(currentRoute: '/settings'),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Profile & User Info Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD8E9FA),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          StringHelpers.initials(vm.user?.name ?? 'AW'),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vm.user?.name ?? 'AW CRM User',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              vm.user?.email ?? 'demo@awcrm.com',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                            if (vm.organization != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Org: ${vm.organization!.name} (${vm.organization!.role ?? "Admin"})',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Workspace & Organization Switcher Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Workspace & Organizations',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      if (vm.memberships.isEmpty)
                        const Text('Personal Workspace', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: vm.memberships.length,
                          separatorBuilder: (_, _) => const Divider(),
                          itemBuilder: (context, index) {
                            final m = vm.memberships[index];
                            final isActive = m.organizationId == vm.organization?.organizationId;
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                isActive ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                color: isActive ? AppColors.primary : AppColors.textMuted,
                              ),
                              title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              subtitle: Text('Role: ${m.role ?? "Member"}', style: const TextStyle(fontSize: 11)),
                              trailing: isActive
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.primarySubtle,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('Active', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                                    )
                                  : null,
                              onTap: () => vm.switchOrg(m.organizationId),
                            );
                          },
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Currency & Regional Setting Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Regional settings', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Currency', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          Text('Pakistani Rupee (PKR - Rs)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Timezone', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          Text('Asia/Karachi (PKT +05:00)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Sign Out Action Button
                ElevatedButton.icon(
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Sign out of Workspace'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.redIcon,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    await vm.logout();
                    if (context.mounted) context.go('/login');
                  },
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}
