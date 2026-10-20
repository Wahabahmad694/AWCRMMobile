import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onOpenDrawer,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onOpenDrawer;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bottomNavBg,
        border: Border(top: BorderSide(color: AppColors.bottomNavBorder, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _navButton(0, 'Dashboard', Icons.dashboard_outlined, Icons.dashboard_rounded),
              _navButton(1, 'Customers', Icons.people_outline, Icons.people_rounded),
              _navButton(2, 'Orders', Icons.shopping_bag_outlined, Icons.shopping_bag_rounded),
              _navButton(3, 'AI Copilot', Icons.auto_awesome_outlined, Icons.auto_awesome_rounded),
              Expanded(
                child: InkWell(
                  onTap: onOpenDrawer,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_rounded, size: 21, color: AppColors.bottomNavUnselected),
                      SizedBox(height: 3),
                      Text(
                        'More',
                        style: TextStyle(
                          color: AppColors.bottomNavUnselected,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navButton(int index, String label, IconData unselectedIcon, IconData selectedIcon) {
    final isSelected = currentIndex == index;
    final color = isSelected ? AppColors.bottomNavSelected : AppColors.bottomNavUnselected;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSelected ? selectedIcon : unselectedIcon, size: 21, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
