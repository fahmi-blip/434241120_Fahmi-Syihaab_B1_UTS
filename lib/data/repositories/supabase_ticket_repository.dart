import 'dart:io';
import 'package:dio/dio.dart';
import '../models/ticket_model.dart';
import '../../core/services/api_client.dart';
import '../../core/services/supabase_service.dart';

class SupabaseTicketRepository {
  String get _userId => SupabaseService.currentUserId ?? '';

  /// Ambil semua tiket (filtered by role di server)
  Future<List<TicketModel>> getTickets({
    String? status,
    String? priority,
    String? search,
  }) async {
    try {
      final response = await ApiClient.dio.get('/tickets', queryParameters: {
        if (status != null && status != 'all') 'status': status,
        if (priority != null) 'priority': priority,
        if (search != null && search.isNotEmpty) 'search': search,
      });

      if (response.data['success'] == true) {
        final ticketsList = response.data['data']['tickets'] as List? ?? [];
        return ticketsList.map((e) => TicketModel.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Gagal mengambil tiket');
      }
    } catch (e) {
      print('❌ getTickets error: $e');
      throw Exception('Gagal mengambil daftar tiket dari server.');
    }
  }

  /// Ambil 1 tiket berdasarkan ID
  Future<TicketModel> getTicketById(String id) async {
    try {
      final response = await ApiClient.dio.get('/tickets/$id');

      if (response.data['success'] == true) {
        final ticketData = response.data['data'] as Map<String, dynamic>;
        return TicketModel.fromJson(ticketData);
      } else {
        throw Exception(response.data['message'] ?? 'Ticket tidak ditemukan');
      }
    } catch (e) {
      print('❌ getTicketById error: $e');
      throw Exception('Gagal mengambil detail tiket dari server.');
    }
  }

  /// Buat tiket baru
  Future<TicketModel> createTicket({
    required String title,
    required String description,
    String? category,
    String priority = 'medium',
  }) async {
    try {
      final response = await ApiClient.dio.post('/tickets', data: {
        'title': title,
        'description': description,
        'category': category ?? 'General',
        'priority': priority,
      });

      if (response.data['success'] == true) {
        final ticketData = response.data['data'] as Map<String, dynamic>;
        return TicketModel.fromJson(ticketData);
      } else {
        throw Exception(response.data['message'] ?? 'Gagal membuat tiket');
      }
    } catch (e) {
      print('❌ createTicket error: $e');
      throw Exception('Gagal membuat tiket baru.');
    }
  }

  /// Update status tiket
  Future<void> updateStatus(String ticketId, String status, String note) async {
    try {
      final response = await ApiClient.dio.put('/tickets/$ticketId', data: {
        'status': status,
        'note': note,
      });

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Gagal mengubah status');
      }
    } catch (e) {
      print('❌ updateStatus error: $e');
      throw Exception('Gagal mengubah status tiket.');
    }
  }

  /// Assign tiket ke helpdesk
  Future<void> assignTicket(String ticketId, String? helpdeskId) async {
    try {
      final response = await ApiClient.dio.put('/tickets/$ticketId', data: {
        'assigned_to': helpdeskId,
      });

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Gagal menugaskan tiket');
      }
    } catch (e) {
      print('❌ assignTicket error: $e');
      throw Exception('Gagal menugaskan tiket.');
    }
  }

  /// Tambah komentar
  Future<void> addComment(
    String ticketId,
    String content, {
    bool isInternal = false,
  }) async {
    try {
      final response = await ApiClient.dio.post('/tickets/$ticketId/comments', data: {
        'content': content,
        'is_internal': isInternal,
      });

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Gagal menambah komentar');
      }
    } catch (e) {
      print('❌ addComment error: $e');
      throw Exception('Gagal mengirim komentar.');
    }
  }

  /// Upload lampiran ke Express.js Server
  Future<Map<String, String>> uploadAttachment(
    String ticketId,
    File file,
    String fileName,
  ) async {
    try {
      final ext = fileName.split('.').last.toLowerCase();
      final mimeType = _getMimeType(ext);

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: DioMediaType.parse(mimeType),
        ),
      });

      final response = await ApiClient.dio.post(
        '/tickets/$ticketId/attachments',
        data: formData,
      );

      if (response.data['success'] == true) {
        final resData = response.data['data'] as Map<String, dynamic>;
        final url = resData['url']?.toString() ?? '';
        final path = resData['path']?.toString() ?? '';
        return {'url': url, 'path': path};
      } else {
        throw Exception(response.data['message'] ?? 'Upload gagal');
      }
    } catch (e) {
      print('❌ uploadAttachment error: $e');
      throw Exception('Gagal mengunggah lampiran.');
    }
  }

  /// Dashboard stats
  Future<Map<String, int>> getDashboardStats() async {
    try {
      final tickets = await getTickets(status: 'all');
      final stats = <String, int>{
        'total': tickets.length,
        'open': 0,
        'in_progress': 0,
        'resolved': 0,
        'closed': 0,
      };

      for (final t in tickets) {
        final s = t.status.toLowerCase();
        if (stats.containsKey(s)) {
          stats[s] = (stats[s] ?? 0) + 1;
        }
      }
      return stats;
    } catch (e) {
      print('❌ getDashboardStats error: $e');
      return {
        'total': 0,
        'open': 0,
        'in_progress': 0,
        'resolved': 0,
        'closed': 0,
      };
    }
  }

  /// Ambil notifikasi user
  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final response = await ApiClient.dio.get('/notifications');
      final list = response.data as List? ?? [];
      return List<Map<String, dynamic>>.from(list);
    } catch (e) {
      print('❌ getNotifications error: $e');
      return [];
    }
  }

  /// Tandai notifikasi sudah dibaca
  Future<void> markNotifRead(String id) async {
    try {
      await ApiClient.dio.put('/notifications/$id/read');
    } catch (e) {
      print('❌ markNotifRead error: $e');
    }
  }

  /// Ambil daftar helpdesk (untuk assign)
  Future<List<Map<String, dynamic>>> getHelpdeskList() async {
    try {
      final response = await ApiClient.dio.get('/auth/helpdesk');
      if (response.data['success'] == true) {
        final list = response.data['data'] as List? ?? [];
        return List<Map<String, dynamic>>.from(list);
      }
      return [];
    } catch (e) {
      print('❌ getHelpdeskList error: $e');
      return [];
    }
  }

  /// Ambil history tiket
  Future<List<Map<String, dynamic>>> getTicketHistory(String ticketId) async {
    try {
      final ticket = await getTicketById(ticketId);
      return ticket.history.map((h) => {
        'id': h.id,
        'ticket_id': h.ticketId,
        'changed_by': h.changedBy,
        'old_status': h.oldStatus,
        'new_status': h.newStatus,
        'note': h.note,
        'created_at': h.createdAt.toIso8601String(),
        'user': h.user != null ? {
          'id': h.user!.id,
          'name': h.user!.name,
        } : null,
      }).toList();
    } catch (e) {
      print('❌ getTicketHistory error: $e');
      return [];
    }
  }

  // ── Realtime Subscription Mocked (Bypassed) ──────────────────────────────────

  /// Listen perubahan tiket secara realtime (Mocked - updates handled via manual pulls)
  dynamic subscribeToTickets(Function(dynamic) onUpdate) {
    print('📡 subscribeToTickets called (Mocked/REST API Mode)');
    return null;
  }

  /// Listen notifikasi user secara realtime (Mocked)
  dynamic subscribeToNotifications(Function(dynamic) onNotif) {
    print('📡 subscribeToNotifications called (Mocked/REST API Mode)');
    return null;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

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
