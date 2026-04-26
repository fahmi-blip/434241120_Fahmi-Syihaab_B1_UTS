import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider untuk melacak halaman aktif dalam navigasi
final activeNavigationProvider = StateProvider<String>((ref) {
  return '/dashboard';
});

// Provider untuk mendapatkan item navigasi berdasarkan role
final navigationItemsProvider =
    FutureProvider<List<NavigationItem>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final role = prefs.getString('user_role') ?? 'user';

  if (role == 'user') {
    return [
      NavigationItem(
        route: '/dashboard',
        label: 'Dashboard',
        icon: 'dashboard',
        position: 0,
      ),
      NavigationItem(
        route: '/tickets',
        label: 'Tiket',
        icon: 'ticket',
        position: 1,
      ),
      NavigationItem(
        route: '/notifications',
        label: 'Notifikasi',
        icon: 'notification',
        position: 2,
      ),
      NavigationItem(
        route: '/profile',
        label: 'Profil',
        icon: 'profile',
        position: 3,
      ),
    ];
  } else {
    // Admin/Helpdesk
    return [
      NavigationItem(
        route: '/dashboard',
        label: 'Dashboard',
        icon: 'dashboard',
        position: 0,
      ),
      NavigationItem(
        route: '/tickets',
        label: 'Tiket',
        icon: 'ticket',
        position: 1,
      ),
      NavigationItem(
        route: '/tracking',
        label: 'Tracking',
        icon: 'tracking',
        position: 2,
      ),
      NavigationItem(
        route: '/profile',
        label: 'Profil',
        icon: 'profile',
        position: 3,
      ),
    ];
  }
});

class NavigationItem {
  final String route;
  final String label;
  final String icon;
  final int position;

  NavigationItem({
    required this.route,
    required this.label,
    required this.icon,
    required this.position,
  });
}
