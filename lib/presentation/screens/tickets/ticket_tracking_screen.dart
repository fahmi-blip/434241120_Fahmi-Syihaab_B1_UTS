import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/ticket_model.dart';
import '../../../data/providers/providers.dart';
import '../../../data/repositories/mock_ticket_repository.dart';
import '../../widgets/common/app_navbar.dart';

class TicketTrackingScreen extends ConsumerStatefulWidget {
  const TicketTrackingScreen({super.key});

  @override
  ConsumerState<TicketTrackingScreen> createState() =>
      _TicketTrackingScreenState();
}

class _TicketTrackingScreenState extends ConsumerState<TicketTrackingScreen> {
  late MockTicketRepository _repo;
  List<TicketModel> _tickets = [];
  bool _loading = true;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _repo = ref.read(ticketRepoProvider);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('user_role') ?? 'user';

      final tickets = await _repo.getTickets();
      // Filter: only active tickets (not closed)
      final activeTickets = tickets.where((t) => t.status != 'closed').toList();
      // Sort by updated date (most recent first)
      activeTickets.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      if (mounted) {
        setState(() {
          _tickets = activeTickets;
          _userRole = role;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.dark0 : AppTheme.surface1,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.dark0 : AppTheme.surface1,
        elevation: 0,
        title: Text(
          'Tracking Tiket',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isDark ? AppTheme.white : AppTheme.accent,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded,
                size: 20,
                color: isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondary),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDark ? AppTheme.white : AppTheme.accent))
          : _tickets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox_outlined,
                          size: 40,
                          color: isDark
                              ? AppTheme.textTertiaryDark
                              : AppTheme.textTertiary),
                      const SizedBox(height: 12),
                      Text(
                        'Tidak ada tiket aktif',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.white : AppTheme.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Semua tiket Anda sudah selesai',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: isDark ? AppTheme.white : AppTheme.accent,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: _tickets.length,
                    itemBuilder: (_, i) {
                      final t = _tickets[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TrackingCard(
                          ticket: t,
                          isDark: isDark,
                          isAdmin:
                              _userRole == 'admin' || _userRole == 'helpdesk',
                          onViewDetail: () => context.push('/tickets/${t.id}'),
                          onViewHistory: () =>
                              context.push('/tickets/${t.id}/history'),
                        ),
                      );
                    },
                  ),
                ),
      bottomNavigationBar: AppBottomNavBar(
        currentRoute: '/tracking',
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────

class _TrackingCard extends StatelessWidget {
  final TicketModel ticket;
  final bool isDark;
  final bool isAdmin;
  final VoidCallback onViewDetail;
  final VoidCallback onViewHistory;

  const _TrackingCard({
    required this.ticket,
    required this.isDark,
    required this.isAdmin,
    required this.onViewDetail,
    required this.onViewHistory,
  });

  Color _getStatusProgressColor() {
    switch (ticket.status) {
      case 'open':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  double _getStatusProgress() {
    switch (ticket.status) {
      case 'open':
        return 0.25;
      case 'in_progress':
        return 0.75;
      case 'resolved':
        return 1.0;
      default:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysSinceCreated = DateTime.now().difference(ticket.createdAt).inDays;

    return Container(
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
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.ticketNo,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ticket.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppTheme.white : AppTheme.black,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.statusColor(ticket.status),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        AppTheme.statusLabel(ticket.status),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Priority and dates
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.priorityColor(ticket.priority),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        AppTheme.priorityLabel(ticket.priority),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Dibuat ${DateFormat('dd MMM yyyy').format(ticket.createdAt)}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppTheme.textTertiaryDark
                              : AppTheme.textTertiary,
                        ),
                      ),
                    ),
                    Text(
                      '$daysSinceCreated hari lalu',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status Progress Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      '${(_getStatusProgress() * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _getStatusProgressColor(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _getStatusProgress(),
                    minHeight: 6,
                    backgroundColor:
                        isDark ? AppTheme.dark2 : AppTheme.surface1,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        _getStatusProgressColor()),
                  ),
                ),
              ],
            ),
          ),

          // Timeline steps
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: _StatusTimeline(ticket: ticket, isDark: isDark),
          ),

          // Divider
          Divider(
            height: 1,
            color: isDark ? AppTheme.dark3 : AppTheme.surface2,
          ),

          // Assigned To + Details
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                // Assigned to
                Icon(Icons.person_outline_rounded,
                    size: 14,
                    color: isDark
                        ? AppTheme.textTertiaryDark
                        : AppTheme.textTertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    ticket.assignee?.name ?? 'Not assigned',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: ticket.assignee == null
                          ? AppTheme.priorityHigh
                          : (isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondary),
                      fontWeight: ticket.assignee == null
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Action buttons
                GestureDetector(
                  onTap: onViewHistory,
                  child: Row(
                    children: [
                      Icon(Icons.history_rounded,
                          size: 14,
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondary),
                      const SizedBox(width: 2),
                      Text(
                        'History',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onViewDetail,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: isDark
                        ? AppTheme.textTertiaryDark
                        : AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────

class _StatusTimeline extends StatelessWidget {
  final TicketModel ticket;
  final bool isDark;

  const _StatusTimeline({required this.ticket, required this.isDark});

  bool _isStepActive(String status) {
    const steps = ['open', 'in_progress', 'resolved'];
    final currentIndex = steps.indexOf(ticket.status);
    final stepIndex = steps.indexOf(status);
    return stepIndex <= currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TimelineStep(
          label: 'Open',
          isActive: _isStepActive('open'),
          isDark: isDark,
        ),
        Expanded(
          child: Container(
            height: 2,
            color: _isStepActive('in_progress')
                ? AppTheme.statusColor('in_progress')
                : (isDark ? AppTheme.dark2 : AppTheme.surface1),
          ),
        ),
        _TimelineStep(
          label: 'In Progress',
          isActive: _isStepActive('in_progress'),
          isDark: isDark,
        ),
        Expanded(
          child: Container(
            height: 2,
            color: _isStepActive('resolved')
                ? AppTheme.statusColor('resolved')
                : (isDark ? AppTheme.dark2 : AppTheme.surface1),
          ),
        ),
        _TimelineStep(
          label: 'Resolved',
          isActive: _isStepActive('resolved'),
          isDark: isDark,
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────

class _TimelineStep extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isDark;

  const _TimelineStep({
    required this.label,
    required this.isActive,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 6,
          backgroundColor: isActive
              ? Colors.green
              : (isDark ? AppTheme.dark2 : AppTheme.surface1),
          child: isActive
              ? const Icon(Icons.check, size: 8, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: isActive
                ? (isDark ? AppTheme.white : AppTheme.black)
                : (isDark ? AppTheme.textTertiaryDark : AppTheme.textTertiary),
          ),
        ),
      ],
    );
  }
}
