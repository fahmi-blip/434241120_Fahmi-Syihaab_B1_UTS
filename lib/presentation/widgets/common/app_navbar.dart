import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/providers.dart';

class AppBottomNavBar extends ConsumerWidget {
  final String currentRoute;
  final VoidCallback? onCreateTicket;

  const AppBottomNavBar({
    super.key,
    required this.currentRoute,
    this.onCreateTicket,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    final authState = ref.watch(authNotifierProvider);
    final userRole = authState.user?.role ?? 'user';
    final activeTrackingCount = ref.watch(activeTrackingCountProvider);
    final isUser = userRole == 'user';

    if (isUser) {
      return _UserBottomNav(
        currentRoute: currentRoute,
        isDark: isDark,
        onCreateTicket: onCreateTicket,
        activeTrackingCount: activeTrackingCount,
      );
    } else {
      return _AdminBottomNav(
        currentRoute: currentRoute,
        isDark: isDark,
        activeTrackingCount: activeTrackingCount,
      );
    }
  }
}

// Navbar untuk user biasa (dengan FAB create tiket)
class _UserBottomNav extends ConsumerWidget {
  final String currentRoute;
  final bool isDark;
  final VoidCallback? onCreateTicket;
  final int activeTrackingCount;

  const _UserBottomNav({
    required this.currentRoute,
    required this.isDark,
    required this.onCreateTicket,
    required this.activeTrackingCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.dark1 : AppTheme.surface0,
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.dark3 : AppTheme.surface2,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.grid_view_rounded,
                label: 'Dashboard',
                active: currentRoute == '/dashboard',
                onTap: () => context.go('/dashboard'),
                isDark: isDark,
              ),
              _NavItem(
                icon: Icons.manage_accounts_rounded,
                label: 'Tiket',
                active: currentRoute.startsWith('/tickets'),
                onTap: () => context.go('/tickets'),
                isDark: isDark,
              ),
              // FAB center
              GestureDetector(
                onTap: onCreateTicket ?? () => context.go('/tickets/create'),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.white : AppTheme.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: 22,
                    color: isDark ? AppTheme.black : AppTheme.white,
                  ),
                ),
              ),
              _NavItem(
                icon: Icons.track_changes_rounded,
                label: 'Tracking',
                active: currentRoute == '/tracking' || currentRoute.startsWith('/admin/tracking'),
                onTap: () => context.go('/tracking'),
                isDark: isDark,
                badgeCount: activeTrackingCount,
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profil',
                active: currentRoute == '/profile',
                onTap: () => context.go('/profile'),
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Navbar untuk admin/helpdesk (tanpa FAB, evenly distributed)
class _AdminBottomNav extends ConsumerWidget {
  final String currentRoute;
  final bool isDark;
  final int activeTrackingCount;

  const _AdminBottomNav({
    required this.currentRoute,
    required this.isDark,
    required this.activeTrackingCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.dark1 : AppTheme.surface0,
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.dark3 : AppTheme.surface2,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.grid_view_rounded,
                label: 'Dashboard',
                active: currentRoute == '/dashboard',
                onTap: () => context.go('/dashboard'),
                isDark: isDark,
              ),
              _NavItem(
                icon: Icons.manage_accounts_rounded,
                label: 'Tiket',
                active: currentRoute.startsWith('/tickets') ||
                    currentRoute == '/admin/tickets',
                onTap: () => context.go('/admin/tickets'),
                isDark: isDark,
              ),
              _NavItem(
                icon: Icons.track_changes_rounded,
                label: 'Tracking',
                active: currentRoute.startsWith('/tracking') ||
                    currentRoute == '/admin/tracking',
                onTap: () => context.go('/tracking'),
                isDark: isDark,
                badgeCount: activeTrackingCount,
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profil',
                active: currentRoute == '/profile',
                onTap: () => context.go('/profile'),
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool isDark;
  final int? badgeCount;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    required this.isDark,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? (isDark ? AppTheme.white : AppTheme.accent)
        : (isDark ? AppTheme.textTertiaryDark : AppTheme.textTertiary);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 22, color: color),
                if (badgeCount != null && badgeCount! > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        badgeCount! > 9 ? '9+' : badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
