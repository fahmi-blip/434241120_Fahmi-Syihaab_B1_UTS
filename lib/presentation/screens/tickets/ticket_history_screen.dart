import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/ticket_model.dart';
import '../../../data/providers/providers.dart';
import '../../../data/repositories/mock_ticket_repository.dart';

class TicketHistoryScreen extends ConsumerStatefulWidget {
  final String ticketId;
  const TicketHistoryScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketHistoryScreen> createState() =>
      _TicketHistoryScreenState();
}

class _TicketHistoryScreenState extends ConsumerState<TicketHistoryScreen> {
  late MockTicketRepository _repo;
  TicketModel? _ticket;
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repo = ref.read(ticketRepoProvider);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final t = await _repo.getTicketById(widget.ticketId);
      final h = await _repo.getTicketHistory(widget.ticketId);
      if (mounted) {
        setState(() {
          _ticket = t;
          _history = h;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              size: 18, color: isDark ? AppTheme.white : AppTheme.accent),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Riwayat Tiket',
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
          : _ticket == null
              ? Center(
                  child: Text('Tiket tidak ditemukan',
                      style: TextStyle(
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondary)))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: isDark ? AppTheme.white : AppTheme.accent,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      // Ticket Summary Card
                      _TicketSummaryCard(ticket: _ticket!, isDark: isDark),
                      const SizedBox(height: 24),

                      // Current Status
                      Text(
                        'Status Saat Ini',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _CurrentStatusCard(ticket: _ticket!, isDark: isDark),
                      const SizedBox(height: 24),

                      // History Timeline
                      Text(
                        'Timeline Aktivitas',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_history.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              'Belum ada perubahan',
                              style: TextStyle(
                                color: isDark
                                    ? AppTheme.textTertiaryDark
                                    : AppTheme.textTertiary,
                              ),
                            ),
                          ),
                        )
                      else
                        Column(
                          children: List.generate(_history.length, (i) {
                            final h = _history[i];
                            final isLast = i == _history.length - 1;
                            return _HistoryTimelineItem(
                              history: h,
                              isDark: isDark,
                              isLast: isLast,
                            );
                          }),
                        ),
                    ],
                  ),
                ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────

class _TicketSummaryCard extends StatelessWidget {
  final TicketModel ticket;
  final bool isDark;
  const _TicketSummaryCard({required this.ticket, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.dark1 : AppTheme.surface0,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppTheme.dark3 : AppTheme.surface2,
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 4),
                    Text(
                      ticket.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.white : AppTheme.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          Divider(
            height: 1,
            color: isDark ? AppTheme.dark3 : AppTheme.surface2,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _InfoItem(
                  label: 'Dibuat',
                  value:
                      DateFormat('dd MMM yyyy, HH:mm').format(ticket.createdAt),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoItem(
                  label: 'Diperbarui',
                  value:
                      DateFormat('dd MMM yyyy, HH:mm').format(ticket.updatedAt),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────

class _CurrentStatusCard extends StatelessWidget {
  final TicketModel ticket;
  final bool isDark;
  const _CurrentStatusCard({required this.ticket, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.dark1 : AppTheme.surface0,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppTheme.dark3 : AppTheme.surface2,
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Status Terkini',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.statusBgColor(ticket.status, isDark: isDark),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.statusColor(ticket.status),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 6,
                  backgroundColor: AppTheme.statusColor(ticket.status),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTheme.statusLabel(ticket.status),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.white : AppTheme.black,
                        ),
                      ),
                      if (ticket.assignee != null)
                        Text(
                          'Ditangani oleh: ${ticket.assignee!.name}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppTheme.textSecondaryDark
                                : AppTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Prioritas: ${AppTheme.priorityLabel(ticket.priority)} | Kategori: ${ticket.category ?? '-'}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.textTertiaryDark : AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────

class _HistoryTimelineItem extends StatelessWidget {
  final Map<String, dynamic> history;
  final bool isDark;
  final bool isLast;

  const _HistoryTimelineItem({
    required this.history,
    required this.isDark,
    required this.isLast,
  });

  String _getChangeLabel(String? oldStatus, String? newStatus) {
    if (oldStatus == null && newStatus != null) {
      return 'Status diubah menjadi ${AppTheme.statusLabel(newStatus)}';
    }
    if (oldStatus != null && newStatus != null) {
      return '${AppTheme.statusLabel(oldStatus)} → ${AppTheme.statusLabel(newStatus)}';
    }
    return 'Update';
  }

  IconData _getChangeIcon(String? oldStatus, String? newStatus) {
    if (oldStatus != null && newStatus != null) {
      return Icons.sync_alt_rounded;
    }
    return Icons.info_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final createdAt = history['created_at'] != null
        ? DateTime.parse(history['created_at'].toString())
        : DateTime.now();
    final note = history['note'] ?? '';
    final changedBy = history['changed_by'] ?? 'System';
    final oldStatus = history['old_status'];
    final newStatus = history['new_status'];

    return Column(
      children: [
        // Timeline item
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline circle + line
            Column(
              children: [
                CircleAvatar(
                  radius: 8,
                  backgroundColor: AppTheme.statusColor(newStatus ?? 'open'),
                  child: Icon(
                    _getChangeIcon(oldStatus, newStatus),
                    size: 12,
                    color: Colors.white,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: isDark ? AppTheme.dark3 : AppTheme.surface2,
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getChangeLabel(oldStatus, newStatus),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.white : AppTheme.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (note.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.dark2 : AppTheme.surface0,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark ? AppTheme.dark3 : AppTheme.surface2,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          note,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppTheme.textSecondaryDark
                                : AppTheme.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 12,
                          color: isDark
                              ? AppTheme.textTertiaryDark
                              : AppTheme.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            changedBy,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppTheme.textTertiaryDark
                                  : AppTheme.textTertiary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd MMM, HH:mm').format(createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppTheme.textTertiaryDark
                                : AppTheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _InfoItem({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.textTertiaryDark : AppTheme.textTertiary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? AppTheme.white : AppTheme.black,
          ),
        ),
      ],
    );
  }
}
