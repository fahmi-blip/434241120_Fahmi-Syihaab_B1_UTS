import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ticket_model.dart';
import '../../core/services/supabase_service.dart';

class SupabaseTicketRepository {
  final _client = SupabaseService.client;

  String get _userId => SupabaseService.currentUserId ?? '';

  Future<String> get _userRole async {
    final profile = await _client
        .from('profiles')
        .select('role')
        .eq('id', _userId)
        .single();
    return profile['role'] as String? ?? 'user';
  }

  /// Ambil semua tiket (filtered by role)
  Future<List<TicketModel>> getTickets({
    String? status,
    String? priority,
    String? search,
  }) async {
    final role = await _userRole;

    var query = _client.from('tickets').select('''
      *,
      user:profiles!tickets_user_id_fkey(id, name, email, role),
      assignee:profiles!tickets_assigned_to_fkey(id, name, email, role),
      ticket_comments(
        id, content, user_id, created_at, is_internal,
        user:profiles(id, name, role)
      ),
      ticket_attachments(id, file_url, file_name, file_type, created_at),
      ticket_history(
        id, old_status, new_status, note, changed_by, created_at,
        user:profiles!ticket_history_changed_by_fkey(id, name)
      )
    ''');

    // Role-based filter sudah ditangani RLS, tapi untuk keamanan double:
    if (role == 'user') {
      query = query.eq('user_id', _userId);
    }

    // Filter opsional
    if (status != null && status != 'all') {
      query = query.eq('status', status);
    }
    if (priority != null) {
      query = query.eq('priority', priority);
    }
    if (search != null && search.isNotEmpty) {
      query = query.or(
        'title.ilike.%$search%,description.ilike.%$search%,ticket_no.ilike.%$search%',
      );
    }

    final data = await query.order('created_at', ascending: false);
    return data.map((e) => _mapToTicketModel(e)).toList();
  }

  /// Ambil 1 tiket berdasarkan ID
  Future<TicketModel> getTicketById(String id) async {
    final data = await _client.from('tickets').select('''
      *,
      user:profiles!tickets_user_id_fkey(id, name, email, role),
      assignee:profiles!tickets_assigned_to_fkey(id, name, email, role),
      ticket_comments(
        id, content, user_id, created_at, is_internal,
        user:profiles(id, name, role)
      ),
      ticket_attachments(id, file_url, file_name, file_type, created_at),
      ticket_history(
        id, old_status, new_status, note, changed_by, created_at,
        user:profiles!ticket_history_changed_by_fkey(id, name)
      )
    ''').eq('id', id).single();

    return _mapToTicketModel(data);
  }

  /// Buat tiket baru
  Future<TicketModel> createTicket({
    required String title,
    required String description,
    String? category,
    String priority = 'medium',
  }) async {
    final data = await _client
        .from('tickets')
        .insert({
          'title': title,
          'description': description,
          'category': category,
          'priority': priority,
          'status': 'open',
          'user_id': _userId,
          'ticket_no': 'TEMP', // akan di-override oleh trigger
        })
        .select()
        .single();

    return _mapToTicketModel(data);
  }

  /// Update status tiket
  Future<void> updateStatus(String ticketId, String status, String note) async {
    await _client.from('tickets').update({
      'status': status,
    }).eq('id', ticketId);

    // Tambah note ke history manual jika ada
    if (note.isNotEmpty) {
      await _client.from('ticket_history').insert({
        'ticket_id': ticketId,
        'changed_by': _userId,
        'new_status': status,
        'note': note,
      });
    }
  }

  /// Assign tiket ke helpdesk
  Future<void> assignTicket(String ticketId, String? helpdeskId) async {
    await _client.from('tickets').update({
      'assigned_to': helpdeskId,
    }).eq('id', ticketId);
  }

  /// Tambah komentar
  Future<void> addComment(
    String ticketId,
    String content, {
    bool isInternal = false,
  }) async {
    await _client.from('ticket_comments').insert({
      'ticket_id': ticketId,
      'user_id': _userId,
      'content': content,
      'is_internal': isInternal,
    });
  }

  /// Upload lampiran ke Supabase Storage
  Future<Map<String, String>> uploadAttachment(
    String ticketId,
    File file,
    String fileName,
  ) async {
    final path = '$_userId/$ticketId/$fileName';
    final ext = fileName.split('.').last.toLowerCase();
    final mimeType = _getMimeType(ext);

    await _client.storage.from('ticket-attachments').upload(
          path,
          file,
          fileOptions: FileOptions(contentType: mimeType, upsert: true),
        );

    final url = _client.storage.from('ticket-attachments').getPublicUrl(path);

    // Simpan metadata ke tabel
    await _client.from('ticket_attachments').insert({
      'ticket_id': ticketId,
      'user_id': _userId,
      'file_name': fileName,
      'file_url': url,
      'file_type': mimeType,
      'file_size': await file.length(),
    });

    return {'url': url, 'path': path};
  }

  /// Dashboard stats
  Future<Map<String, int>> getDashboardStats() async {
    final role = await _userRole;

    var query = _client.from('tickets').select('status');
    if (role == 'user') query = query.eq('user_id', _userId);

    final data = await query;
    final stats = <String, int>{
      'total': data.length,
      'open': 0,
      'in_progress': 0,
      'resolved': 0,
      'closed': 0,
    };
    for (final t in data) {
      final s = t['status'] as String;
      stats[s] = (stats[s] ?? 0) + 1;
    }
    return stats;
  }

  /// Ambil notifikasi user
  Future<List<Map<String, dynamic>>> getNotifications() async {
    final data = await _client
        .from('notifications')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Tandai notifikasi sudah dibaca
  Future<void> markNotifRead(String id) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', id);
  }

  /// Ambil daftar helpdesk (untuk assign)
  Future<List<Map<String, dynamic>>> getHelpdeskList() async {
    final data = await _client
        .from('profiles')
        .select('id, name, email')
        .inFilter('role', ['admin', 'helpdesk']);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Ambil history tiket
  Future<List<Map<String, dynamic>>> getTicketHistory(String ticketId) async {
    final data = await _client
        .from('ticket_history')
        .select('*, user:profiles!ticket_history_changed_by_fkey(id, name)')
        .eq('ticket_id', ticketId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  // ── Realtime Subscription ──────────────────────────────────────────────────

  /// Listen perubahan tiket secara realtime
  RealtimeChannel subscribeToTickets(Function(dynamic) onUpdate) {
    return _client
        .channel('tickets_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tickets',
          callback: (payload) => onUpdate(payload),
        )
        .subscribe();
  }

  /// Listen notifikasi user secara realtime
  RealtimeChannel subscribeToNotifications(Function(dynamic) onNotif) {
    return _client
        .channel('notifications_$_userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _userId,
          ),
          callback: (payload) => onNotif(payload),
        )
        .subscribe();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  TicketModel _mapToTicketModel(Map<String, dynamic> data) {
    final comments = (data['ticket_comments'] as List? ?? []).map((c) {
      final map = Map<String, dynamic>.from(c);
      map['ticket_id'] = data['id'];
      return map;
    }).toList();

    final attachments = (data['ticket_attachments'] as List? ?? []).map((a) {
      final map = Map<String, dynamic>.from(a);
      map['ticket_id'] = data['id'];
      return map;
    }).toList();

    final history = (data['ticket_history'] as List? ?? []).map((h) {
      final map = Map<String, dynamic>.from(h);
      map['ticket_id'] = data['id'];
      return map;
    }).toList();

    return TicketModel.fromJson({
      ...data,
      'comments': comments,
      'attachments': attachments,
      'history': history,
    });
  }

  String _getMimeType(String ext) {
    const map = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    };
    return map[ext] ?? 'application/octet-stream';
  }
}
