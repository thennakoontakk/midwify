import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 20),
                child: Text(
                  'MENU',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey500,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              _DrawerItem(
                icon: Icons.show_chart_rounded,
                label: 'Dashboard',
                isSelected: currentRoute == '/dashboard',
                onTap: () => _navigate(context, '/dashboard'),
              ),
              _DrawerItem(
                icon: Icons.groups_outlined,
                label: 'Patients',
                isSelected: currentRoute == '/patients',
                onTap: () => _navigate(context, '/patients'),
              ),
              const SizedBox(height: 16),
              _DrawerItem(
                icon: Icons.warning_amber_rounded,
                label: 'New Risk Analysis',
                isSelected: currentRoute == '/maternal-health',
                onTap: () => _navigate(context, '/maternal-health'),
              ),
              _DrawerItem(
                icon: Icons.monitor_heart_outlined,
                label: 'Fetal Health Scan',
                isSelected: currentRoute == '/fetal-health',
                onTap: () => _navigate(context, '/fetal-health'),
              ),
              const SizedBox(height: 16),
              _DrawerItem(
                icon: Icons.camera_alt_outlined,
                label: 'AR Photo Capture',
                isSelected: currentRoute == '/ar-capture',
                onTap: () => _navigate(context, '/ar-capture'),
              ),
              const SizedBox(height: 16),
              _DrawerItem(
                icon: Icons.view_in_ar_outlined,
                label: 'VR Training',
                isSelected: currentRoute == '/vr-training',
                onTap: () => _navigate(context, '/vr-training'),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _DrawerItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  isHighlighted: true,
                  isSelected: currentRoute == '/profile',
                  onTap: () {
                    Navigator.pop(context);
                    if (currentRoute != '/profile') {
                      Navigator.pushReplacementNamed(context, '/profile');
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, String route) {
    Navigator.pop(context);
    if (currentRoute != route) {
      Navigator.pushReplacementNamed(context, route);
    }
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isHighlighted;
  final VoidCallback? onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
    this.isHighlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isHighlighted || isSelected
        ? AppColors.primary
        : AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: isSelected && !isHighlighted
            ? BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
