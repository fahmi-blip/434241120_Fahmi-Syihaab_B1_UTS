import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/theme_service.dart';

class SettingScreen extends ConsumerStatefulWidget {
  const SettingScreen({super.key});

  @override
  ConsumerState<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends ConsumerState<SettingScreen> {
  final _theme = ThemeService();
  
  bool _pushNotifications = true;
  bool _ticketNotifications = true;
  bool _soundEnabled = true;
  String _language = 'Bahasa Indonesia';
  String _accentColorName = 'Default Blue';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('setting_push_notif') ?? true;
      _ticketNotifications = prefs.getBool('setting_ticket_notif') ?? true;
      _soundEnabled = prefs.getBool('setting_sound') ?? true;
      _language = prefs.getString('setting_language') ?? 'Bahasa Indonesia';
      _accentColorName = prefs.getString('setting_accent') ?? 'Default Blue';
      _loading = false;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  void _showLanguageSelector() {
    final isDark = context.isDark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.dark1 : AppTheme.surface0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Pilih Bahasa',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: isDark ? AppTheme.white : AppTheme.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LanguageOption(
              label: 'Bahasa Indonesia',
              selected: _language == 'Bahasa Indonesia',
              isDark: isDark,
              onTap: () {
                setState(() => _language = 'Bahasa Indonesia');
                _saveSetting('setting_language', 'Bahasa Indonesia');
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
            _LanguageOption(
              label: 'English',
              selected: _language == 'English',
              isDark: isDark,
              onTap: () {
                setState(() => _language = 'English');
                _saveSetting('setting_language', 'English');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAccentColorSelector() {
    final isDark = context.isDark;
    final colors = [
      {'name': 'Default Blue', 'color': Colors.blue},
      {'name': 'Teal Green', 'color': Colors.teal},
      {'name': 'Elegant Purple', 'color': Colors.deepPurple},
      {'name': 'Orange Sunset', 'color': Colors.orange},
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.dark1 : AppTheme.surface0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Warna Aksen',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: isDark ? AppTheme.white : AppTheme.black,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: colors.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = colors[index];
              final isSelected = _accentColorName == item['name'];
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                tileColor: isDark ? AppTheme.dark2 : AppTheme.surface1,
                leading: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: item['color'] as Color,
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(
                  item['name'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isDark ? AppTheme.white : AppTheme.black,
                  ),
                ),
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle_rounded,
                        color: isDark ? AppTheme.white : AppTheme.accent,
                        size: 20,
                      )
                    : null,
                onTap: () {
                  setState(() => _accentColorName = item['name'] as String);
                  _saveSetting('setting_accent', item['name'] as String);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _clearCache() async {
    final isDark = context.isDark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.dark1 : AppTheme.surface0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Cache?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: isDark ? AppTheme.white : AppTheme.black,
          ),
        ),
        content: Text(
          'Ini akan menghapus file sementara lokal dan memuat ulang data saat dibutuhkan.',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: TextStyle(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Hapus',
              style: TextStyle(
                color: AppTheme.priorityHigh,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache aplikasi berhasil dibersihkan'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    if (_loading) {
      return Scaffold(
        backgroundColor: isDark ? AppTheme.dark0 : AppTheme.surface1,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.dark0 : AppTheme.surface1,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.dark0 : AppTheme.surface0,
        elevation: 0.5,
        title: Text(
          'Pengaturan',
          style: TextStyle(
            color: isDark ? AppTheme.white : AppTheme.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme & Accent
            _SectionLabel('TAMPILAN & TEMA', isDark),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.dark1 : AppTheme.surface0,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppTheme.dark3 : AppTheme.surface2,
                  width: 0.5,
                ),
              ),
              child: Column(
                children: [
                  // Dark Mode Switch Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const _IconContainer(
                          icon: Icons.dark_mode_outlined,
                          bgColor: Color.fromARGB(255, 248, 249, 251),
                          iconColor: Color.fromARGB(255, 98, 102, 106),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Mode Gelap',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppTheme.white : AppTheme.black,
                            ),
                          ),
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
                                      ? (isDark ? AppTheme.white : AppTheme.accent)
                                      : (isDark ? AppTheme.dark3 : AppTheme.surface3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: AnimatedAlign(
                                  duration: const Duration(milliseconds: 180),
                                  alignment: on ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.all(2),
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: on
                                            ? (isDark ? AppTheme.black : AppTheme.white)
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
                  const _Divider(),
                  // Accent Color Selection
                  _SettingItemTile(
                    icon: Icons.palette_outlined,
                    iconBgColor: Color.fromARGB(255, 248, 249, 251),
                    iconColor: Color.fromARGB(255, 98, 102, 106),
                    label: 'Warna Aksen',
                    value: _accentColorName,
                    isDark: isDark,
                    onTap: _showAccentColorSelector,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Notification Settings
            _SectionLabel('NOTIFIKASI', isDark),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.dark1 : AppTheme.surface0,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppTheme.dark3 : AppTheme.surface2,
                  width: 0.5,
                ),
              ),
              child: Column(
                children: [
                  _SettingSwitchTile(
                    icon: Icons.notifications_none_rounded,
                    iconBgColor: Color.fromARGB(255, 248, 249, 251),
                    iconColor: Color.fromARGB(255, 98, 102, 106),
                    label: 'Notifikasi Push',
                    value: _pushNotifications,
                    isDark: isDark,
                    onChanged: (val) {
                      setState(() => _pushNotifications = val);
                      _saveSetting('setting_push_notif', val);
                    },
                  ),
                  const _Divider(),
                  _SettingSwitchTile(
                    icon: Icons.assignment_turned_in_outlined,
                    iconBgColor: Color.fromARGB(255, 248, 249, 251),
                    iconColor: Color.fromARGB(255, 98, 102, 106),
                    label: 'Update Tiket Baru',
                    value: _ticketNotifications,
                    isDark: isDark,
                    onChanged: (val) {
                      setState(() => _ticketNotifications = val);
                      _saveSetting('setting_ticket_notif', val);
                    },
                  ),
                  const _Divider(),
                  _SettingSwitchTile(
                    icon: Icons.volume_up_outlined,
                    iconBgColor: Color.fromARGB(255, 248, 249, 251),
                    iconColor: Color.fromARGB(255, 98, 102, 106),
                    label: 'Suara Notifikasi',
                    value: _soundEnabled,
                    isDark: isDark,
                    onChanged: (val) {
                      setState(() => _soundEnabled = val);
                      _saveSetting('setting_sound', val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Language & Cache
            _SectionLabel('BAHASA & SISTEM', isDark),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.dark1 : AppTheme.surface0,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppTheme.dark3 : AppTheme.surface2,
                  width: 0.5,
                ),
              ),
              child: Column(
                children: [
                  _SettingItemTile(
                    icon: Icons.language_rounded,
                    iconBgColor: Color.fromARGB(255, 248, 249, 251),
                    iconColor: Color.fromARGB(255, 98, 102, 106),
                    label: 'Bahasa',
                    value: _language,
                    isDark: isDark,
                    onTap: _showLanguageSelector,
                  ),
                  const _Divider(),
                  _SettingItemTile(
                    icon: Icons.cleaning_services_outlined,
                    iconBgColor: Color.fromARGB(255, 248, 249, 251),
                    iconColor: Color.fromARGB(255, 98, 102, 106),
                    label: 'Bersihkan Cache',
                    isDark: isDark,
                    onTap: _clearCache,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            
            Center(
              child: Column(
                children: [
                  Text(
                    'E-Ticketing Helpdesk',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Teknik Informatika UNAIR',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppTheme.textTertiaryDark : AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDialog(String title, String content) {
    final isDark = context.isDark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.dark1 : AppTheme.surface0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: isDark ? AppTheme.white : AppTheme.black,
          ),
        ),
        content: Text(
          content,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
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
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: isDark ? AppTheme.textTertiaryDark : AppTheme.textTertiary,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _IconContainer extends StatelessWidget {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  const _IconContainer({
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: iconColor),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Padding(
      padding: const EdgeInsets.only(left: 60),
      child: Divider(
        color: isDark ? AppTheme.dark3.withValues(alpha: 0.3) : AppTheme.surface2,
        height: 1,
        thickness: 0.5,
      ),
    );
  }
}

class _SettingItemTile extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String label;
  final String? value;
  final bool isDark;
  final VoidCallback? onTap;

  const _SettingItemTile({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.label,
    this.value,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _IconContainer(icon: icon, bgColor: iconBgColor, iconColor: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppTheme.white : AppTheme.black,
                ),
              ),
            ),
            if (value != null) ...[
              Text(
                value!,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
            ],
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: isDark ? AppTheme.textTertiaryDark : AppTheme.textTertiary,
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingSwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String label;
  final bool value;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _SettingSwitchTile({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _IconContainer(icon: icon, bgColor: iconBgColor, iconColor: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? AppTheme.white : AppTheme.black,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44,
              height: 24,
              decoration: BoxDecoration(
                color: value
                    ? (isDark ? AppTheme.white : AppTheme.accent)
                    : (isDark ? AppTheme.dark3 : AppTheme.surface3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 180),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: value
                          ? (isDark ? AppTheme.black : AppTheme.white)
                          : AppTheme.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      tileColor: isDark ? AppTheme.dark2 : AppTheme.surface1,
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: isDark ? AppTheme.white : AppTheme.black,
        ),
      ),
      trailing: selected
          ? Icon(
              Icons.check_circle_rounded,
              color: isDark ? AppTheme.white : AppTheme.accent,
              size: 20,
            )
          : null,
      onTap: onTap,
    );
  }
}
