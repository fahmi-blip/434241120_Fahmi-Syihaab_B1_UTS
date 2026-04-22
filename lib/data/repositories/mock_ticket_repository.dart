import '../models/ticket_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MockTicketRepository {
  static const String _ticketsKey = 'tickets';
  static const String _notificationsKey = 'notifications';
  static const String _historyKey = 'ticket_history';

  // Static variables supaya semua instance pakai data yang sama
  static List<Map<String, dynamic>> _mockTickets = [];
  static List<Map<String, dynamic>> _mockNotifications = [];
  static List<Map<String, dynamic>> _mockHistory = [];

  /// Initialize data dummy jika belum ada
  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load tickets
    final ticketsJson = prefs.getString(_ticketsKey);
    if (ticketsJson != null) {
      MockTicketRepository._mockTickets = (json.decode(ticketsJson) as List)
          .cast<Map<String, dynamic>>();
    } else {
      MockTicketRepository._mockTickets = _getDefaultTickets();
      await _saveTickets();
    }

    // Load notifications
    final notifsJson = prefs.getString(_notificationsKey);
    if (notifsJson != null) {
      MockTicketRepository._mockNotifications = (json.decode(notifsJson) as List)
          .cast<Map<String, dynamic>>();
    } else {
      MockTicketRepository._mockNotifications = _getDefaultNotifications();
      await _saveNotifications();
    }

    // Load history
    final historyJson = prefs.getString(_historyKey);
    if (historyJson != null) {
      MockTicketRepository._mockHistory = (json.decode(historyJson) as List)
          .cast<Map<String, dynamic>>();
    } else {
      MockTicketRepository._mockHistory = _getDefaultHistory();
      await _saveHistory();
    }
  }

  List<Map<String, dynamic>> _getDefaultTickets() => [
    {
      'id': 'ticket-1',
      'ticket_no': 'TKT-001',
      'title': 'WiFi tidak bisa connect di lobby',
      'description': 'Sudah coba connect beberapa kali tapi selalu gagal. Padahal password sudah benar.',
      'category': 'Network',
      'priority': 'high',
      'status': 'open',
      'user_id': 'user-1',
      'user_name': 'Budi Santoso',
      'assigned_to': null,
      'created_at': '2026-04-15T10:30:00Z',
      'updated_at': '2026-04-15T10:30:00Z',
      'comments': [
        {
          'id': 'comment-1',
          'content': 'Mohon info, WiFi di lantai berapa?',
          'user_id': 'helpdesk-1',
          'user_name': 'Siti Helpdesk',
          'created_at': '2026-04-15T11:00:00Z',
        },
      ],
    },
    {
      'id': 'ticket-2',
      'ticket_no': 'TKT-002',
      'title': 'Printer lantai 2 paper jam',
      'description': 'Printer HP di lantai 2 macet, kertas nyangkut di dalam.',
      'category': 'Hardware',
      'priority': 'medium',
      'status': 'in_progress',
      'user_id': 'user-1',
      'user_name': 'Budi Santoso',
      'assigned_to': 'helpdesk-1',
      'created_at': '2026-04-14T09:00:00Z',
      'updated_at': '2026-04-15T08:00:00Z',
      'comments': [],
    },
    {
      'id': 'ticket-3',
      'ticket_no': 'TKT-003',
      'title': 'Lupa password email',
      'description': 'Saya lupa password email kantor, tolong reset ya.',
      'category': 'Account',
      'priority': 'low',
      'status': 'resolved',
      'user_id': 'user-1',
      'user_name': 'Budi Santoso',
      'assigned_to': 'helpdesk-1',
      'created_at': '2026-04-13T14:00:00Z',
      'updated_at': '2026-04-14T10:00:00Z',
      'comments': [
        {
          'id': 'comment-2',
          'content': 'Password sudah di-reset, silakan cek email.',
          'user_id': 'helpdesk-1',
          'user_name': 'Siti Helpdesk',
          'created_at': '2026-04-14T09:30:00Z',
        },
      ],
    },
    {
      'id': 'ticket-4',
      'ticket_no': 'TKT-004',
      'title': 'Monitor kedip-kedip',
      'description': 'Monitor di meja kerja saya kedip-kedip terus, kadang normal kadang gelap.',
      'category': 'Hardware',
      'priority': 'medium',
      'status': 'closed',
      'user_id': 'user-1',
      'user_name': 'Budi Santoso',
      'assigned_to': 'helpdesk-1',
      'created_at': '2026-04-10T08:00:00Z',
      'updated_at': '2026-04-12T16:00:00Z',
      'comments': [],
    },
    {
      'id': 'ticket-5',
      'ticket_no': 'TKT-005',
      'title': 'Request install software Photoshop',
      'description': 'Mohon install Adobe Photoshop untuk keperluan design marketing.',
      'category': 'Software',
      'priority': 'low',
      'status': 'open',
      'user_id': 'user-1',
      'user_name': 'Budi Santoso',
      'assigned_to': null,
      'created_at': '2026-04-16T13:00:00Z',
      'updated_at': '2026-04-16T13:00:00Z',
      'comments': [],
    },
  ];

  List<Map<String, dynamic>> _getDefaultNotifications() => [
    {
      'id': 'notif-1',
      'title': 'Tiket Baru',
      'message': 'Tiket TKT-005: Request install software Photoshop',
      'type': 'info',
      'is_read': false,
      'created_at': '2026-04-16T13:05:00Z',
      'ticket_id': 'ticket-5',
    },
    {
      'id': 'notif-2',
      'title': 'Status Tiket Diubah',
      'message': 'Tiket TKT-003: Lupa password email - Status sekarang: resolved',
      'type': 'success',
      'is_read': false,
      'created_at': '2026-04-14T10:00:00Z',
      'ticket_id': 'ticket-3',
    },
  ];

  List<Map<String, dynamic>> _getDefaultHistory() => [
    {
      'id': 'hist-1',
      'ticket_id': 'ticket-2',
      'old_status': 'open',
      'new_status': 'in_progress',
      'note': 'Tiket sedang diproses',
      'changed_by': 'helpdesk-1',
      'user_name': 'Siti Helpdesk',
      'created_at': '2026-04-15T08:00:00Z',
    },
    {
      'id': 'hist-2',
      'ticket_id': 'ticket-3',
      'old_status': 'open',
      'new_status': 'resolved',
      'note': 'Password sudah di-reset',
      'changed_by': 'helpdesk-1',
      'user_name': 'Siti Helpdesk',
      'created_at': '2026-04-14T10:00:00Z',
    },
  ];

  Future<void> _saveTickets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ticketsKey, json.encode(MockTicketRepository._mockTickets));
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notificationsKey, json.encode(MockTicketRepository._mockNotifications));
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_historyKey, json.encode(MockTicketRepository._mockHistory));
  }

  Future<String?> get _currentUserId async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<String> get _currentRole async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role') ?? 'user';
  }

  Future<bool> get _isAdmin async {
    final role = await _currentRole;
    return role == 'admin' || role == 'helpdesk';
  }

  /// Get all tickets
  Future<List<TicketModel>> getTickets() async {
    await _initData();
    await Future.delayed(const Duration(milliseconds: 300));

    final userId = await _currentUserId;
    final isAdmin = await _isAdmin;

    final filtered = isAdmin
        ? MockTicketRepository._mockTickets
        : MockTicketRepository._mockTickets.where((t) => t['user_id'] == userId).toList();

    return filtered.map((e) => _mapToTicketModel(e)).toList();
  }

  /// Get ticket by ID
  Future<TicketModel> getTicketById(String id) async {
    await _initData();
    await Future.delayed(const Duration(milliseconds: 200));

    final ticket = MockTicketRepository._mockTickets.firstWhere(
      (t) => t['id'] == id,
      orElse: () => throw Exception('Ticket not found'),
    );

    final ticketWithHistory = Map<String, dynamic>.from(ticket);
    ticketWithHistory['history'] = MockTicketRepository._mockHistory
        .where((h) => h['ticket_id'] == id)
        .map((h) => {
              ...h,
              'user': {'name': h['user_name']},
            })
        .toList();

    return _mapToTicketModel(ticketWithHistory);
  }

  /// Create new ticket
  Future<TicketModel> createTicket({
    required String title,
    required String description,
    String? category,
    String priority = 'medium',
  }) async {
    await _initData();
    await Future.delayed(const Duration(milliseconds: 400));

    final userId = await _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final role = await _currentRole;
    if (role != 'user') {
      throw Exception('Hanya user biasa yang dapat membuat tiket');
    }

    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_name') ?? 'User';

    final newTicket = {
      'id': 'ticket-${DateTime.now().millisecondsSinceEpoch}',
      'ticket_no': 'TKT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'status': 'open',
      'user_id': userId,
      'user_name': userName,
      'assigned_to': null,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'comments': [],
    };

    MockTicketRepository._mockTickets.insert(0, newTicket);
    await _saveTickets();

    return _mapToTicketModel(newTicket);
  }

  /// Update ticket status
  Future<void> updateStatus(String id, String status, String note) async {
    await _initData();
    await Future.delayed(const Duration(milliseconds: 300));

    final index = MockTicketRepository._mockTickets.indexWhere((t) => t['id'] == id);
    if (index == -1) throw Exception('Ticket not found');

    MockTicketRepository._mockTickets[index]['status'] = status;
    MockTicketRepository._mockTickets[index]['updated_at'] = DateTime.now().toIso8601String();

    final userId = await _currentUserId;
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_name') ?? 'User';

    MockTicketRepository._mockHistory.insert(0, {
      'id': 'hist-${DateTime.now().millisecondsSinceEpoch}',
      'ticket_id': id,
      'old_status': MockTicketRepository._mockTickets[index]['status'],
      'new_status': status,
      'note': note,
      'changed_by': userId,
      'user_name': userName,
      'created_at': DateTime.now().toIso8601String(),
    });

    await _saveTickets();
    await _saveHistory();
  }

  /// Assign ticket
  Future<void> assignTicket(String id, String assignTo) async {
    await _initData();
    await Future.delayed(const Duration(milliseconds: 200));

    final index = MockTicketRepository._mockTickets.indexWhere((t) => t['id'] == id);
    if (index == -1) throw Exception('Ticket not found');

    MockTicketRepository._mockTickets[index]['assigned_to'] = assignTo;
    MockTicketRepository._mockTickets[index]['updated_at'] = DateTime.now().toIso8601String();
    await _saveTickets();
  }

  /// Get ticket history
  Future<List<Map<String, dynamic>>> getTicketHistory(String ticketId) async {
    await _initData();
    await Future.delayed(const Duration(milliseconds: 100));

    return MockTicketRepository._mockHistory
        .where((h) => h['ticket_id'] == ticketId)
        .map((h) => {
              ...h,
              'users': {'name': h['user_name']},
            })
        .toList();
  }

  /// Add comment
  Future<void> addComment(String ticketId, String content) async {
    await _initData();
    await Future.delayed(const Duration(milliseconds: 200));

    final userId = await _currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_name') ?? 'User';

    final ticketIndex = MockTicketRepository._mockTickets.indexWhere((t) => t['id'] == ticketId);
    if (ticketIndex == -1) throw Exception('Ticket not found');

    final comments = MockTicketRepository._mockTickets[ticketIndex]['comments'] as List?;
    final newComment = {
      'id': 'comment-${DateTime.now().millisecondsSinceEpoch}',
      'content': content,
      'user_id': userId,
      'user_name': userName,
      'created_at': DateTime.now().toIso8601String(),
    };

    if (comments == null) {
      MockTicketRepository._mockTickets[ticketIndex]['comments'] = [newComment];
    } else {
      comments.add(newComment);
    }

    await _saveTickets();
  }

  /// Save attachment (mock)
  Future<void> saveAttachmentMetadata({
    required String ticketId,
    required String fileUrl,
    required String fileName,
    required String fileType,
  }) async {
    await _initData();
    await Future.delayed(const Duration(milliseconds: 200));
  }

  /// Get dashboard stats
  Future<Map<String, int>> getDashboardStats() async {
    await _initData();
    await Future.delayed(const Duration(milliseconds: 200));

    final isAdmin = await _isAdmin;
    final userId = await _currentUserId;

    final filtered = isAdmin
        ? MockTicketRepository._mockTickets
        : MockTicketRepository._mockTickets.where((t) => t['user_id'] == userId).toList();

    final stats = <String, int>{
      'total': filtered.length,
      'open': 0,
      'in_progress': 0,
      'resolved': 0,
      'closed': 0,
    };

    for (var ticket in filtered) {
      final status = ticket['status'] as String;
      stats[status] = (stats[status] ?? 0) + 1;
    }

    return stats;
  }

  /// Get notifications
  Future<List<dynamic>> getNotifications() async {
    await _initData();
    await Future.delayed(const Duration(milliseconds: 200));
    return MockTicketRepository._mockNotifications;
  }

  /// Get helpdesk list
  Future<List<Map<String, dynamic>>> getHelpdeskList() async {
    await Future.delayed(const Duration(milliseconds: 100));

    return [
      {'id': 'admin-1', 'name': 'Admin Helpdesk', 'email': 'admin@demo.com'},
      {'id': 'helpdesk-1', 'name': 'Siti Helpdesk', 'email': 'helpdesk@demo.com'},
    ];
  }

  /// Mark notification as read
  Future<void> markNotifRead(String id) async {
    await _initData();
    await Future.delayed(const Duration(milliseconds: 100));

    final index = MockTicketRepository._mockNotifications.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      MockTicketRepository._mockNotifications[index]['is_read'] = true;
      await _saveNotifications();
    }
  }

  /// Create notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    String? ticketId,
    String type = 'info',
  }) async {
    await _initData();

    MockTicketRepository._mockNotifications.insert(0, {
      'id': 'notif-${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'message': message,
      'type': type,
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    });
    await _saveNotifications();
  }

  /// Clear all data (untuk reset)
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ticketsKey);
    await prefs.remove(_notificationsKey);
    await prefs.remove(_historyKey);
    MockTicketRepository._mockTickets = [];
    MockTicketRepository._mockNotifications = [];
    MockTicketRepository._mockHistory = [];
  }

  TicketModel _mapToTicketModel(Map<String, dynamic> data) {
    final comments = data['comments'] as List?;
    final commentsWithUser = comments?.map((c) {
      final comment = Map<String, dynamic>.from(c);
      comment['user'] = {
        'name': c['user_name'] ?? 'Unknown',
        'id': c['user_id'],
      };
      return comment;
    }).toList();

    final history = data['history'] as List?;
    final historyWithUser = history?.map((h) {
      final hist = Map<String, dynamic>.from(h);
      if (hist['user'] == null) {
        hist['user'] = {'name': h['user_name'] ?? 'Unknown'};
      }
      return hist;
    }).toList();

    final json = {
      ...data,
      'comments': commentsWithUser ?? [],
      'history': historyWithUser ?? [],
    };

    return TicketModel.fromJson(json);
  }
}
