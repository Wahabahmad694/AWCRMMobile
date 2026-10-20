import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../di_container.dart';
import '../../repositories/auth_repository.dart';
import '../../utils/app_colors.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.currentRoute});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final authRepo = sl<AuthRepository>();
    final org = authRepo.currentMembership;
    final memberships = authRepo.memberships;

    return Drawer(
      backgroundColor: AppColors.drawerBackground,
      child: SafeArea(
        child: Column(
          children: [
            // Brand Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'AW',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'AW CRM',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                letterSpacing: -0.4,
                              ),
                            ),
                            SizedBox(width: 5),
                            Text(
                              'WORKSPACE',
                              style: TextStyle(
                                color: Color(0xFF62B3FF),
                                fontWeight: FontWeight.w800,
                                fontSize: 9,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Built for your next chapter',
                          style: TextStyle(
                            color: AppColors.drawerTextMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Organization Switcher
            if (memberships.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.drawerCardBg,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppColors.drawerCardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.business_rounded, size: 16, color: Color(0xFF62B3FF)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          org?.name ?? 'Personal Workspace',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (memberships.length > 1)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.unfold_more_rounded, size: 16, color: Colors.white70),
                          tooltip: 'Switch organization',
                          onSelected: (id) {
                            authRepo.switchOrganization(id);
                            Navigator.of(context).pop();
                            context.go('/dashboard');
                          },
                          itemBuilder: (_) => [
                            for (final m in memberships)
                              PopupMenuItem(
                                value: m.organizationId,
                                child: Text(m.name),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // Nav List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _groupCaption('WORKSPACE'),
                  _navItem(context, 'Dashboard', '/dashboard', Icons.dashboard_outlined),
                  _navItem(context, 'Customers', '/customers', Icons.people_outline),
                  _navItem(context, 'Orders', '/orders', Icons.shopping_bag_outlined),
                  _navItem(context, 'Products', '/products', Icons.inventory_2_outlined),
                  _navItem(context, 'Inventory', '/inventory', Icons.warehouse_outlined),

                  const SizedBox(height: 12),
                  _groupCaption('BUSINESS'),
                  _navItem(context, 'Payments', '/payments', Icons.account_balance_wallet_outlined),
                  _navItem(context, 'Sales targets', '/targets', Icons.track_changes_outlined),
                  _navItem(context, 'Expenses', '/expenses', Icons.receipt_long_outlined),
                  _navItem(context, 'Reports', '/reports', Icons.bar_chart_outlined),

                  const SizedBox(height: 12),
                  _groupCaption('MANAGE'),
                  _navItem(context, 'Activities', '/activities', Icons.checklist_outlined),
                  _navItem(context, 'Team', '/team', Icons.manage_accounts_outlined),
                  _navItem(context, 'AI Assistant', '/assistant', Icons.auto_awesome_outlined, isAi: true),
                  _navItem(context, 'Settings', '/settings', Icons.settings_outlined),
                ],
              ),
            ),

            // AI Banner in Sidebar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  context.go('/assistant');
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.drawerCardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.drawerCardBorder),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: Color(0xFF62B3FF), size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'A smarter way to work',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Meet your future AI copilot ↗',
                              style: TextStyle(
                                color: AppColors.drawerTextMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Profile / Sign-out Block
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF164365), width: 1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD8E9FA),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      authRepo.currentUser != null ? authRepo.currentUser!.name.substring(0, 1).toUpperCase() : 'AW',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authRepo.currentUser?.name ?? 'AW CRM',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          authRepo.currentUser?.email ?? 'Business workspace',
                          style: const TextStyle(
                            color: AppColors.drawerTextMuted,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 18),
                    tooltip: 'Sign out',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Sign out?'),
                          content: const Text('Are you sure you want to sign out from this workspace?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign out')),
                          ],
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        Navigator.of(context).pop();
                        await authRepo.logout();
                        if (context.mounted) context.go('/login');
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupCaption(String caption) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Text(
        caption,
        style: const TextStyle(
          color: AppColors.drawerTextMuted,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    String label,
    String route,
    IconData icon, {
    bool isAi = false,
  }) {
    final active = currentRoute == route || (route != '/dashboard' && currentRoute.startsWith(route));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          if (!active) {
            context.go(route);
          }
        },
        borderRadius: BorderRadius.circular(9),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.drawerItemActive : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: active
                ? const Border(left: BorderSide(color: AppColors.drawerAccentBorder, width: 3.5))
                : null,
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: active ? Colors.white : const Color(0xFFB9CEDB)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: active ? Colors.white : const Color(0xFFB9CEDB),
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
              if (isAi)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C3855),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF2A5875)),
                  ),
                  child: const Text(
                    'AI',
                    style: TextStyle(
                      color: Color(0xFF62B3FF),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              if (active) ...[
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, size: 14, color: Colors.white70),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
