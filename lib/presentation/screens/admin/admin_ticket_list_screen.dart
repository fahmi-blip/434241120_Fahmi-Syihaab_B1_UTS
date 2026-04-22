import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/ticket_model.dart';
import '../../../data/providers/providers.dart';
import '../../../data/repositories/mock_ticket_repository.dart';

class AdminTicketListScreen extends ConsumerStatefulWidget {
  const AdminTicketListScreen({super.key});

  @override
  ConsumerState<AdminTicketListScreen> createState() =>
      _AdminTicketListScreenState();
}

class _AdminTicketListScreenState extends ConsumerState<AdminTicketListScreen> {
  late MockTicketRepository _repo;
  final _search = TextEditingController();
  String? _filterStatus;
  String? _filterPriority;
  String? _filterAssigned;
  bool _showFilter = false;
  List<TicketModel> _allTickets = [];
  List<Map<String, dynamic>> _helpdeskList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repo = ref.read(ticketRepoProvider);
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Load all tickets (no user filter)
      final tickets = await _repo.getTickets();
      final helpdesk = await _repo.getHelpdeskList();
      if (mounted) {
        setState(() {
          _allTickets = tickets;
          _helpdeskList = helpdesk;
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

  List<TicketModel> _filtered(List<TicketModel> all) {
    var list = all;
    final q = _search.text.toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((t) =>
              t.title.toLowerCase().contains(q) ||
              t.ticketNo.toLowerCase().contains(q) ||
              t.description.toLowerCase().contains(q))
          .toList();
    }
    if (_filterStatus != null)
      list = list.where((t) => t.status == _filterStatus).toList();
    if (_filterPriority != null)
      list = list.where((t) => t.priority == _filterPriority).toList();
    if (_filterAssigned != null)
      list = list.where((t) => t.assignedTo == _filterAssigned).toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final list = _filtered(_allTickets);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.dark0 : AppTheme.surface1,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.dark0 : AppTheme.surface1,
        elevation: 0,
        title: Text(
          'Manajemen Tiket',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isDark ? AppTheme.white : AppTheme.black,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              size: 18, color: isDark ? AppTheme.white : AppTheme.black),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showFilter ? Icons.filter_list_off_rounded : Icons.tune_rounded,
              size: 20,
              color: _showFilter
                  ? (isDark ? AppTheme.white : AppTheme.black)
                  : (isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondary),
            ),
            onPressed: () => setState(() => _showFilter = !_showFilter),
          ),
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
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppTheme.white : AppTheme.black),
              decoration: InputDecoration(
                hintText: 'Cari tiket...',
                hintStyle: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppTheme.textTertiaryDark
                        : AppTheme.textTertiary),
                prefixIcon: Icon(Icons.search_rounded,
                    size: 18,
                    color: isDark
                        ? AppTheme.textTertiaryDark
                        : AppTheme.textTertiary),
                suffixIcon: _search.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () => setState(() => _search.clear()),
                        child: Icon(Icons.close_rounded,
                            size: 16,
                            color: isDark
                                ? AppTheme.textTertiaryDark
                                : AppTheme.textTertiary),
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppTheme.dark2 : AppTheme.surface0,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: isDark ? AppTheme.dark3 : AppTheme.surface2,
                      width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: isDark ? AppTheme.dark3 : AppTheme.surface2,
                      width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: isDark ? AppTheme.white : AppTheme.black,
                      width: 1),
                ),
              ),
            ),
          ),

          // Filter Panel
          if (_showFilter)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: isDark ? AppTheme.dark1 : AppTheme.surface0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filter',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppTheme.white : AppTheme.black)),
                      GestureDetector(
                        onTap: () => setState(() {
                          _filterStatus = null;
                          _filterPriority = null;
                          _filterAssigned = null;
                        }),
                        child: Text('Reset',
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppTheme.textSecondaryDark
                                    : AppTheme.textSecondary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Status Filter
                  Text('Status',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        ['open', 'in_progress', 'resolved', 'closed'].map((s) {
                      final sel = _filterStatus == s;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _filterStatus = sel ? null : s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppTheme.statusColor(s)
                                : (isDark ? AppTheme.dark2 : AppTheme.surface1),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            AppTheme.statusLabel(s),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  sel ? FontWeight.w700 : FontWeight.w500,
                              color: sel
                                  ? AppTheme.white
                                  : (isDark
                                      ? AppTheme.textSecondaryDark
                                      : AppTheme.textSecondary),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Priority Filter
                  Text('Prioritas',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['low', 'medium', 'high', 'critical'].map((p) {
                      final sel = _filterPriority == p;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _filterPriority = sel ? null : p),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppTheme.priorityColor(p)
                                : (isDark ? AppTheme.dark2 : AppTheme.surface1),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            AppTheme.priorityLabel(p),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  sel ? FontWeight.w700 : FontWeight.w500,
                              color: sel
                                  ? AppTheme.white
                                  : (isDark
                                      ? AppTheme.textSecondaryDark
                                      : AppTheme.textSecondary),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Assigned Filter
                  Text('Assigned to',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _filterAssigned == null
                              ? (isDark ? AppTheme.dark2 : AppTheme.surface1)
                              : AppTheme.statusColor('open'),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: GestureDetector(
                          onTap: () => setState(() => _filterAssigned = null),
                          child: Text(
                            'Semua',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _filterAssigned == null
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _filterAssigned == null
                                  ? (isDark
                                      ? AppTheme.textSecondaryDark
                                      : AppTheme.textSecondary)
                                  : AppTheme.white,
                            ),
                          ),
                        ),
                      ),
                      ..._helpdeskList.map((h) {
                        final sel = _filterAssigned == h['id'];
                        return GestureDetector(
                          onTap: () => setState(
                              () => _filterAssigned = sel ? null : h['id']),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppTheme.statusColor('in_progress')
                                  : (isDark
                                      ? AppTheme.dark2
                                      : AppTheme.surface1),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(
                              h['name'] ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    sel ? FontWeight.w700 : FontWeight.w500,
                                color: sel
                                    ? AppTheme.white
                                    : (isDark
                                        ? AppTheme.textSecondaryDark
                                        : AppTheme.textSecondary),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ],
              ),
            ),

          // List
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark ? AppTheme.white : AppTheme.black))
                : list.isEmpty
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
                              'Tidak ada tiket',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppTheme.white : AppTheme.black,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: isDark ? AppTheme.white : AppTheme.black,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          itemCount: list.length,
                          itemBuilder: (_, i) {
                            final t = list[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _AdminTicketCard(
                                ticket: t,
                                isDark: isDark,
                                onTap: () => context.push('/tickets/${t.id}'),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────

class _AdminTicketCard extends StatelessWidget {
  final TicketModel ticket;
  final bool isDark;
  final VoidCallback onTap;

  const _AdminTicketCard({
    required this.ticket,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.dark1 : AppTheme.surface0,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppTheme.dark3 : AppTheme.surface2,
            width: 0.5,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ticket Number and Status
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

            // Info Row
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
                    'From: ${ticket.user?.name ?? 'Unknown'}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd MMM').format(ticket.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppTheme.textTertiaryDark
                        : AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Assigned to
            Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 14,
                  color: isDark
                      ? AppTheme.textTertiaryDark
                      : AppTheme.textTertiary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    ticket.assignee?.name ?? 'Not assigned',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: ticket.assignee == null
                          ? (isDark
                              ? AppTheme.priorityHigh
                              : AppTheme.priorityHigh)
                          : (isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondary),
                      fontWeight: ticket.assignee == null
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: isDark
                      ? AppTheme.textTertiaryDark
                      : AppTheme.textTertiary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
