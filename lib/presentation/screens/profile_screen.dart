import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/user_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/theme_service.dart';
import '../../../data/providers/providers.dart';
import '../widgets/common/app_navbar.dart';

/// Clean Profile Screen - iOS Style
/// No gradients, minimal design
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _theme = ThemeService();
  UserModel? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final authRepo = ref.read(authRepoProvider);
    final userId = await authRepo.getUserId();
    final name = await authRepo.getUserName();
    final email = await authRepo.getUserEmail();
    final role = await authRepo.getRole();

    setState(() {
      _user = UserModel(
        id: userId ?? '1',
        name: name ?? 'Demo User',
        email: email ?? 'demo@example.com',
        role: role ?? 'user',
        createdAt: DateTime.now(),
      );
      _loading = false;
    });
  }

  Future<void> _logout() async {
    final isDark = context.isDark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.dark1 : AppTheme.surface0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.dark2 : AppTheme.surface1,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.logout_rounded,
                color: AppTheme.priorityHigh,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Keluar?',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.white : AppTheme.black),
            ),
          ],
        ),
        content: Text(
          'Anda akan keluar dari akun ini.',
          style: TextStyle(
              fontSize: 14,
              color:
                  isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal',
                style: TextStyle(
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar',
                style: TextStyle(
                    color: AppTheme.priorityHigh, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).logout();
      if (mounted) context.go('/login');
    }
  }

  String _getRoleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrator';
      case 'helpdesk':
        return 'Helpdesk Staff';
      default:
        return 'User';
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    if (_loading) {
      return Scaffold(
        backgroundColor: isDark ? AppTheme.dark0 : AppTheme.surface1,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.white : AppTheme.accent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDark ? AppTheme.black : AppTheme.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Memuat profil...',
                style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.dark0 : AppTheme.surface1,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: isDark ? AppTheme.dark0 : AppTheme.accent,
                child: SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Avatar
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.black : AppTheme.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              _getInitials(_user?.name ?? 'U'),
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppTheme.white : AppTheme.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Name
                        Text(
                          _user?.name ?? 'User',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppTheme.white : AppTheme.white,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Email
                        Text(
                          _user?.email ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppTheme.white.withValues(alpha: 0.7)
                                : AppTheme.white.withValues(alpha: 0.7),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Role Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.dark4.withValues(alpha: 0.2)
                                : AppTheme.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _getRoleLabel(_user?.role ?? 'user'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppTheme.white : AppTheme.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tampilan
                  _SectionLabel('TAMPILAN', isDark),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.dark1 : AppTheme.surface0,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: isDark ? AppTheme.dark3 : AppTheme.surface2,
                          width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.dark2 : AppTheme.surface1,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.dark_mode_outlined,
                              size: 16,
                              color: isDark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('Mode Gelap',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppTheme.white
                                      : AppTheme.black)),
                        ),
                        AnimatedBuilder(
                          animation: _theme,
                          builder: (_, __) {
                            final on = _theme.themeMode == ThemeMode.dark;
                            return GestureDetector(
                              onTap: () => _theme.toggleTheme(),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 44,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: on
                                      ? (isDark
                                          ? AppTheme.white
                                          : AppTheme.accent)
                                      : (isDark
                                          ? AppTheme.dark3
                                          : AppTheme.surface3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: AnimatedAlign(
                                  duration: const Duration(milliseconds: 180),
                                  alignment: on
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.all(2),
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: on
                                            ? (isDark
                                                ? AppTheme.black
                                                : AppTheme.white)
                                            : AppTheme.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Akun
                  _SectionLabel('AKUN', isDark),
                  const SizedBox(height: 8),
                  _MenuCard(isDark: isDark, items: [
                    _MenuItem(
                        icon: Icons.lock_outline_rounded,
                        label: 'Ganti Password',
                        isDark: isDark,
                        onTap: () => context.push('/reset-password')),
                  ]),
                  const SizedBox(height: 20),

                  // Aplikasi
                  _SectionLabel('APLIKASI', isDark),
                  const SizedBox(height: 8),
                  _MenuCard(isDark: isDark, items: [
                    _MenuItem(
                        icon: Icons.new_releases_outlined,
                        label: 'Versi',
                        value: '1.0.0',
                        isDark: isDark),
                    _MenuItem(
                        icon: Icons.help_outline_rounded,
                        label: 'Bantuan',
                        isDark: isDark,
                        onTap: _showHelp),
                    _MenuItem(
                        icon: Icons.privacy_tip_outlined,
                        label: 'Kebijakan Privasi',
                        isDark: isDark,
                        onTap: _showPrivacy),
                  ]),
                  const SizedBox(height: 20),

                  // Logout
                  GestureDetector(
                    onTap: _logout,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.dark1 : AppTheme.surface0,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: isDark ? AppTheme.dark3 : AppTheme.surface2,
                            width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEB),
                                borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.logout_rounded,
                                size: 16, color: AppTheme.priorityHigh),
                          ),
                          const SizedBox(width: 12),
                          const Text('Keluar dari Akun',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.priorityHigh)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text('© 2024 E-Ticketing Helpdesk',
                        style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppTheme.textTertiaryDark
                                : AppTheme.textTertiary)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentRoute: '/profile',
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bantuan',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'Untuk membuat tiket, tap tombol + di halaman tiket. Isi judul, deskripsi, dan kirim.',
            style: TextStyle(height: 1.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('OK'))
        ],
      ),
    );
  }

  void _showPrivacy() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kebijakan Privasi',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'Data Anda disimpan aman dan tidak dibagikan ke pihak ketiga.',
            style: TextStyle(height: 1.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('OK'))
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _SectionLabel(this.text, this.isDark);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? AppTheme.textTertiaryDark : AppTheme.textTertiary,
            letterSpacing: 0.8),
      );
}

class _MenuCard extends StatelessWidget {
  final bool isDark;
  final List<_MenuItem> items;
  const _MenuCard({required this.isDark, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.dark1 : AppTheme.surface0,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppTheme.dark3 : AppTheme.surface2, width: 0.5),
      ),
      child: Column(
        children: List.generate(
            items.length,
            (i) => Column(children: [
                  items[i],
                  if (i < items.length - 1)
                    Divider(
                        height: 0,
                        thickness: 0.5,
                        indent: 52,
                        color: isDark ? AppTheme.dark3 : AppTheme.surface2),
                ])),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final bool isDark;
  final VoidCallback? onTap;
  const _MenuItem(
      {required this.icon,
      required this.label,
      required this.isDark,
      this.value,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: isDark ? AppTheme.dark2 : AppTheme.surface1,
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon,
                  size: 16,
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppTheme.white : AppTheme.black))),
            if (value != null)
              Text(value!,
                  style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondary)),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded,
                  size: 18,
                  color: isDark
                      ? AppTheme.textTertiaryDark
                      : AppTheme.textTertiary),
          ],
        ),
      ),
    );
  }
}
