import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/providers/providers.dart';
import '../../widgets/common/app_navbar.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    // Refresh unread count when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationNotifierProvider.notifier).refresh();
    });
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? 'user';
    if (mounted) setState(() => _userRole = role);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final ticketsState = ref.watch(ticketsProvider);
    final stats = ticketsState.stats;
    final unreadCount = ref.watch(notificationNotifierProvider);

    // Debug: print unread count
    print('🔔 Dashboard build - unreadCount: $unreadCount');

    return Scaffold(
      backgroundColor: isDark ? AppTheme.dark0 : AppTheme.surface1,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(ticketsProvider.notifier).refresh();
            await ref.read(notificationNotifierProvider.notifier).refresh();
          },
          color: isDark ? AppTheme.white : AppTheme.black,
          child: CustomScrollView(
            slivers: [
              // ── Header ───────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Dashboard',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.8,
                              color: isDark ? AppTheme.white : AppTheme.black,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => context.push('/notifications'),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.dark2 : AppTheme.surface0,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color:
                                    isDark ? AppTheme.dark3 : AppTheme.surface2,
                                width: 0.5),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Center(
                                child: Icon(
                                  Icons.notifications_outlined,
                                  size: 20,
                                  color:
                                      isDark ? AppTheme.white : AppTheme.black,
                                ),
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      unreadCount > 9
                                          ? '9+'
                                          : unreadCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        height: 1,
                                      ),
                                    ),
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

              // ── Stats Cards ───────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: ticketsState.isLoading
                      ? const _StatsShimmer()
                      : _StatsRow(stats: stats, isDark: isDark),
                ),
              ),

              // ── Chart Section ─────────────────────────────────────────────
              // if (!ticketsState.isLoading && stats.isNotEmpty)
              //   SliverToBoxAdapter(
              //     child: Padding(
              //       padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              //       child: _ChartCard(stats: stats, isDark: isDark),
              //     ),
              //   ),

              // ── Action Buttons ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _ActionButtons(
                    isDark: isDark,
                    canAccessAdmin:
                        _userRole == 'admin' || _userRole == 'helpdesk',
                    onTrackingTap: () => context.go('/tracking'),
                    onAdminTap: () => context.go('/admin/tickets'),
                  ),
                ),
              ),

              // ── Recent Tickets ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tiket Terbaru',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                          color: isDark ? AppTheme.white : AppTheme.black,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/tickets'),
                        child: Text(
                          'Lihat Semua',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppTheme.textSecondaryDark
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (ticketsState.isLoading)
                const SliverToBoxAdapter(child: SizedBox(height: 80))
              else if (ticketsState.tickets.isEmpty)
                SliverToBoxAdapter(
                  child: _EmptyDashboard(isDark: isDark),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final t = ticketsState.tickets[i];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        child: _TicketRow(
                          id: t.ticketNo,
                          title: t.title,
                          status: t.status,
                          priority: t.priority,
                          isDark: isDark,
                          onTap: () => context.push('/tickets/${t.id}'),
                        ),
                      );
                    },
                    childCount: (ticketsState.tickets.length).clamp(0, 5),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentRoute: '/dashboard',
        onCreateTicket: () => context.push('/tickets/create'),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Selamat Pagi 🌤';
    if (h < 17) return 'Selamat Siang ☀️';
    return 'Selamat Malam 🌙';
  }
}

// ── Stat cards ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final Map<String, int> stats;
  final bool isDark;
  const _StatsRow({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total',
                value: '${stats['total'] ?? 0}',
                isDark: isDark,
                accent: isDark ? AppTheme.white : AppTheme.black,
                bg: isDark ? AppTheme.dark2 : AppTheme.surface0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Open',
                value: '${stats['open'] ?? 0}',
                isDark: isDark,
                accent: AppTheme.statusOpen,
                bg: AppTheme.statusOpenBg,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'In Progress',
                value: '${stats['in_progress'] ?? 0}',
                isDark: isDark,
                accent: AppTheme.statusInProgress,
                bg: AppTheme.statusInProgressBg,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Resolved',
                value: '${stats['resolved'] ?? 0}',
                isDark: isDark,
                accent: AppTheme.statusResolved,
                bg: AppTheme.statusResolvedBg,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final Color bg;
  final bool isDark;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.accent,
      required this.bg,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.dark1 : bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppTheme.dark3 : AppTheme.surface2, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color:
                  isDark ? AppTheme.textTertiaryDark : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsShimmer extends StatelessWidget {
  const _StatsShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: List.generate(
          4,
          (_) => Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.dark2 : AppTheme.surface2,
                  borderRadius: BorderRadius.circular(14),
                ),
              )),
    );
  }
}

// ── Chart ─────────────────────────────────────────────────────────────────────

// class _ChartCard extends StatelessWidget {
//   final Map<String, int> stats;
//   final bool isDark;
//   const _ChartCard({required this.stats, required this.isDark});

//   @override
//   Widget build(BuildContext context) {
//     final total = (stats['open'] ?? 0) +
//         (stats['in_progress'] ?? 0) +
//         (stats['resolved'] ?? 0) +
//         (stats['closed'] ?? 0);
//     if (total == 0) return const SizedBox.shrink();

//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: isDark ? AppTheme.dark1 : AppTheme.surface0,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//             color: isDark ? AppTheme.dark3 : AppTheme.surface2, width: 0.5),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Distribusi Status',
//             style: TextStyle(
//               fontSize: 15,
//               fontWeight: FontWeight.w600,
//               color: isDark ? AppTheme.white : AppTheme.black,
//             ),
//           ),
//           const SizedBox(height: 20),
//           SizedBox(
//             height: 160,
//             child: Row(
//               children: [
//                 Expanded(
//                   child: PieChart(
//                     PieChartData(
//                       sectionsSpace: 2,
//                       centerSpaceRadius: 36,
//                       sections: [
//                         if ((stats['open'] ?? 0) > 0)
//                           PieChartSectionData(
//                             value: (stats['open'] ?? 0).toDouble(),
//                             color: AppTheme.statusOpen,
//                             radius: 52,
//                             title: '',
//                           ),
//                         if ((stats['in_progress'] ?? 0) > 0)
//                           PieChartSectionData(
//                             value: (stats['in_progress'] ?? 0).toDouble(),
//                             color: AppTheme.statusInProgress,
//                             radius: 52,
//                             title: '',
//                           ),
//                         if ((stats['resolved'] ?? 0) > 0)
//                           PieChartSectionData(
//                             value: (stats['resolved'] ?? 0).toDouble(),
//                             color: AppTheme.statusResolved,
//                             radius: 52,
//                             title: '',
//                           ),
//                         if ((stats['closed'] ?? 0) > 0)
//                           PieChartSectionData(
//                             value: (stats['closed'] ?? 0).toDouble(),
//                             color: AppTheme.statusClosed,
//                             radius: 52,
//                             title: '',
//                           ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 20),
//                 Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     if ((stats['open'] ?? 0) > 0)
//                       _Dot('Open', AppTheme.statusOpen, stats['open']!),
//                     if ((stats['in_progress'] ?? 0) > 0)
//                       _Dot('In Progress', AppTheme.statusInProgress,
//                           stats['in_progress']!),
//                     if ((stats['resolved'] ?? 0) > 0)
//                       _Dot('Resolved', AppTheme.statusResolved,
//                           stats['resolved']!),
//                     if ((stats['closed'] ?? 0) > 0)
//                       _Dot('Closed', AppTheme.statusClosed, stats['closed']!),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _Dot extends StatelessWidget {
//   final String label;
//   final Color color;
//   final int count;
//   const _Dot(this.label, this.color, this.count);

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 10),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 8,
//             height: 8,
//             decoration: BoxDecoration(color: color, shape: BoxShape.circle),
//           ),
//           const SizedBox(width: 8),
//           Text(
//             '$label  $count',
//             style: TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w500,
//               color: context.isDark
//                   ? AppTheme.textSecondaryDark
//                   : AppTheme.textSecondary,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// ── Ticket Row ────────────────────────────────────────────────────────────────

class _TicketRow extends StatelessWidget {
  final String id;
  final String title;
  final String status;
  final String priority;
  final bool isDark;
  final VoidCallback? onTap;
  const _TicketRow(
      {required this.id,
      required this.title,
      required this.status,
      required this.priority,
      required this.isDark,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.dark1 : AppTheme.surface0,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDark ? AppTheme.dark3 : AppTheme.surface2, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.statusBgColor(status, isDark: isDark),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                status == 'resolved'
                    ? Icons.check_rounded
                    : status == 'in_progress'
                        ? Icons.pending_rounded
                        : status == 'closed'
                            ? Icons.lock_outline_rounded
                            : Icons.inbox_rounded,
                size: 18,
                color: AppTheme.statusColor(status),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.white : AppTheme.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '#$id',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppTheme.textTertiaryDark
                          : AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _StatusChip(status: status, isDark: isDark),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final bool isDark;
  const _StatusChip({required this.status, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.statusBgColor(status, isDark: isDark),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        AppTheme.statusLabel(status),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppTheme.statusColor(status),
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

// ── Empty ─────────────────────────────────────────────────────────────────────

class _EmptyDashboard extends StatelessWidget {
  final bool isDark;
  const _EmptyDashboard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.dark1 : AppTheme.surface0,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark ? AppTheme.dark3 : AppTheme.surface2, width: 0.5),
        ),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 36,
              color: isDark ? AppTheme.textTertiaryDark : AppTheme.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada tiket',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.white : AppTheme.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Buat tiket pertama Anda',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action Buttons ────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final bool isDark;
  final bool canAccessAdmin;
  final VoidCallback onTrackingTap;
  final VoidCallback onAdminTap;
  const _ActionButtons({
    required this.isDark,
    required this.canAccessAdmin,
    required this.onTrackingTap,
    required this.onAdminTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Tracking Button
        Expanded(
          child: GestureDetector(
            onTap: onTrackingTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.dark2 : AppTheme.surface0,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppTheme.dark3 : AppTheme.surface2,
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.track_changes_rounded,
                    size: 20,
                    color: AppTheme.statusInProgress,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tracking',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.white : AppTheme.black,
                    ),
                  ),
                  Text(
                    'Monitor tiket aktif',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? AppTheme.textTertiaryDark
                          : AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Admin Button (only for admin/helpdesk)
        if (canAccessAdmin)
          Expanded(
            child: GestureDetector(
              onTap: onAdminTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.dark2 : AppTheme.surface0,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppTheme.dark3 : AppTheme.surface2,
                    width: 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.manage_accounts_rounded,
                      size: 20,
                      color: AppTheme.priorityHigh,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Manajemen',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.white : AppTheme.black,
                      ),
                    ),
                    Text(
                      'Atur semua tiket',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? AppTheme.textTertiaryDark
                            : AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
