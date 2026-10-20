import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/string_helpers.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.isSignedIn = true,
    this.unreadNotifications = 0,
    this.userInitials = 'AW',
    this.showBackButton = false,
  });

  final String title;
  final bool isSignedIn;
  final int unreadNotifications;
  final String userInitials;
  final bool showBackButton;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              // Left: Back button or Hamburger menu
              if (showBackButton)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
                  onPressed: () => Navigator.of(context).maybePop(),
                  tooltip: 'Back',
                )
              else
                Builder(
                  builder: (scaffoldContext) => IconButton(
                    icon: const Icon(Icons.menu_rounded, size: 24, color: AppColors.textPrimary),
                    onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
                    tooltip: 'Menu',
                  ),
                ),

              const SizedBox(width: 4),

              // Breadcrumb: Workspace > Section
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Workspace',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Right: Status pill, Currency, Notifications, Avatar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSignedIn ? AppColors.connectedPillBg : AppColors.pillBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSignedIn ? AppColors.connectedPillBorder : AppColors.pillBorder,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isSignedIn ? AppColors.connectedPillDot : AppColors.pillDot,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isSignedIn ? 'Live' : 'Preview',
                      style: TextStyle(
                        color: isSignedIn ? AppColors.connectedPillText : AppColors.pillText,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Currency Pill
              const Text(
                'PKR',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(width: 6),

              // Notifications bell with badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, size: 20, color: AppColors.textSecondary),
                    onPressed: () => context.push('/notifications'),
                    tooltip: 'Notifications',
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                  if (unreadNotifications > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text(
                          unreadNotifications > 9 ? '9+' : unreadNotifications.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 6),

              // Profile Avatar
              GestureDetector(
                onTap: () => context.push('/settings'),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD8E9FA),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    StringHelpers.initials(userInitials),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
