import 'package:e_ticketing_helpdesk/data/datasources/api/base_api_service.dart';
import 'package:e_ticketing_helpdesk/data/models/requests/ticket_request.dart';
import 'package:e_ticketing_helpdesk/data/models/responses/ticket_response.dart';
import 'package:e_ticketing_helpdesk/data/models/ticket_model.dart';

/// Ticket API Service
///
/// Handles all ticket related API calls
///
/// Endpoints:
/// - GET /api/tickets
/// - GET /api/tickets/:id
/// - POST /api/tickets
/// - PUT /api/tickets/:id
/// - DELETE /api/tickets/:id
/// - POST /api/tickets/:id/comments
/// - GET /api/tickets/:id/comments
class TicketApiService extends BaseApiService {
  /// Get all tickets dengan filtering
  ///
  /// GET /api/tickets?status=open&priority=high&search=login&limit=20&offset=0
  ///
  /// Query Parameters:
  /// - status: open, in_progress, resolved, closed (optional)
  /// - priority: high, medium, low, critical (optional)
  /// - search: search by title/description/ticket_no (optional)
  /// - category: category filter (optional)
  /// - assigned_to: filter by assignee user_id (optional)
  /// - limit: pagination limit (default: 20)
  /// - offset: pagination offset (default: 0)
  ///
  /// Response 200:
  /// ```json
  /// {
  ///   "tickets": [...],
  ///   "total": 10,
  ///   "limit": 20,
  ///   "offset": 0
  /// }
  /// ```
  ///
  /// Response 401: Unauthorized
  /// Response 400: Bad Request
  Future<TicketsResponse> getTickets({
    String? status,
    String? priority,
    String? search,
    String? category,
    String? assignedTo,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      requireAuth();

      logApiCall('GET', '/api/tickets', params: {
        'status': status,
        'priority': priority,
        'search': search,
        'category': category,
        'assigned_to': assignedTo,
        'limit': limit,
        'offset': offset,
      });

      final role = await getUserRole();

      var query = client.from('tickets').select('''
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

      // Role-based filter (RLS di database level)
      if (role == 'user') {
        query = query.eq('user_id', userId);
      }

      // Apply filters
      if (status != null && status != 'all') {
        query = query.eq('status', status);
      }
      if (priority != null) {
        query = query.eq('priority', priority);
      }
      if (category != null) {
        query = query.eq('category', category);
      }
      if (assignedTo != null) {
        query = query.eq('assigned_to', assignedTo);
      }
      if (search != null && search.isNotEmpty) {
        query = query.or(
          'title.ilike.%$search%,description.ilike.%$search%,ticket_no.ilike.%$search%',
        );
      }

      // Get total count
      final countQuery = query;
      final countResult = await countQuery;
      final total = (countResult as List).length;

      // Apply pagination & ordering
      final data = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final tickets = (data as List)
          .map((e) => TicketModel.fromJson(e as Map<String, dynamic>))
          .toList();

      logApiResponse('/api/tickets', tickets);

      return TicketsResponse(
        tickets: tickets,
        total: total,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      throw handleError(e,
          customMessage: 'Gagal mengambil tiket: ${e.toString()}');
    }
  }

  /// Get single ticket by ID
  ///
  /// GET /api/tickets/:id
  ///
  /// Response 200:
  /// ```json
  /// {
  ///   "id": "ticket-123",
  ///   "ticket_no": "TKT-001",
  ///   "title": "Cannot login",
  ///   "status": "open",
  ///   "priority": "high",
  ///   "user": {...},
  ///   "assignee": {...},
  ///   "comments": [...],
  ///   "attachments": [...]
  /// }
  /// ```
  ///
  /// Response 404: Not Found
  /// Response 401: Unauthorized
  Future<TicketModel> getTicketById(String id) async {
    try {
      requireAuth();

      logApiCall('GET', '/api/tickets/:id', params: {'id': id});

      final data = await client.from('tickets').select('''
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

      final ticket = TicketModel.fromJson(data as Map<String, dynamic>);

      logApiResponse('/api/tickets/:id', ticket);

      return ticket;
    } catch (e) {
      throw handleError(e,
          customMessage: 'Gagal mengambil tiket: ${e.toString()}');
    }
  }

  /// Create new ticket
  ///
  /// POST /api/tickets
  ///
  /// Request:
  /// ```json
  /// {
  ///   "title": "Cannot login",
  ///   "description": "I cannot login to the system",
  ///   "category": "technical",
  ///   "priority": "high"
  /// }
  /// ```
  ///
  /// Response 201: Created
  /// ```json
  /// {
  ///   "id": "ticket-123",
  ///   "ticket_no": "TKT-001",
  ///   "title": "Cannot login",
  ///   "status": "open",
  ///   "priority": "high",
  ///   "created_at": "2024-01-15T10:00:00Z"
  /// }
  /// ```
  ///
  /// Response 400: Bad Request
  /// Response 401: Unauthorized
  Future<TicketModel> createTicket(CreateTicketRequest request) async {
    try {
      requireAuth();

      logApiCall('POST', '/api/tickets', params: request.toJson());

      final data = await client
          .from('tickets')
          .insert({
            'title': request.title,
            'description': request.description,
            'category': request.category,
            'priority': request.priority,
            'status': 'open',
            'user_id': userId,
          })
          .select()
          .single();

      final ticket = TicketModel.fromJson(data as Map<String, dynamic>);

      logApiResponse('/api/tickets', ticket);

      return ticket;
    } catch (e) {
      throw handleError(e,
          customMessage: 'Gagal membuat tiket: ${e.toString()}');
    }
  }

  /// Update ticket
  ///
  /// PUT /api/tickets/:id
  ///
  /// Request:
  /// ```json
  /// {
  ///   "title": "Cannot login - UPDATED",
  ///   "status": "in_progress",
  ///   "priority": "critical",
  ///   "assigned_to": "user-id-123"
  /// }
  /// ```
  ///
  /// Response 200:
  /// ```json
  /// {
  ///   "id": "ticket-123",
  ///   "ticket_no": "TKT-001",
  ///   "title": "Cannot login - UPDATED",
  ///   "status": "in_progress",
  ///   "priority": "critical",
  ///   "updated_at": "2024-01-15T11:00:00Z"
  /// }
  /// ```
  ///
  /// Response 400: Bad Request
  /// Response 404: Not Found
  /// Response 401: Unauthorized
  Future<TicketModel> updateTicket(
      String id, UpdateTicketRequest request) async {
    try {
      requireAuth();

      logApiCall('PUT', '/api/tickets/:id', params: request.toJson());

      final updateData = request.toJson();
      updateData['updated_at'] = DateTime.now().toIso8601String();

      final data = await client
          .from('tickets')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      final ticket = TicketModel.fromJson(data as Map<String, dynamic>);

      logApiResponse('/api/tickets/:id', ticket);

      return ticket;
    } catch (e) {
      throw handleError(e,
          customMessage: 'Gagal mengupdate tiket: ${e.toString()}');
    }
  }

  /// Delete ticket
  ///
  /// DELETE /api/tickets/:id
  ///
  /// Response 200:
  /// ```json
  /// {
  ///   "message": "Ticket deleted successfully"
  /// }
  /// ```
  ///
  /// Response 404: Not Found
  /// Response 401: Unauthorized
  Future<void> deleteTicket(String id) async {
    try {
      requireAuth();

      logApiCall('DELETE', '/api/tickets/:id', params: {'id': id});

      await client.from('tickets').delete().eq('id', id);

      logApiResponse('/api/tickets/:id', null);
    } catch (e) {
      throw handleError(e,
          customMessage: 'Gagal menghapus tiket: ${e.toString()}');
    }
  }

  /// Add comment to ticket
  ///
  /// POST /api/tickets/:id/comments
  ///
  /// Request:
  /// ```json
  /// {
  ///   "content": "Please check this issue",
  ///   "is_internal": false
  /// }
  /// ```
  ///
  /// Response 201: Created
  /// ```json
  /// {
  ///   "id": "comment-123",
  ///   "content": "Please check this issue",
  ///   "user_id": "user-123",
  ///   "created_at": "2024-01-15T10:00:00Z"
  /// }
  /// ```
  ///
  /// Response 400: Bad Request
  /// Response 404: Not Found (ticket tidak ditemukan)
  /// Response 401: Unauthorized
  Future<CommentModel> addComment(
      String ticketId, AddCommentRequest request) async {
    try {
      requireAuth();

      logApiCall('POST', '/api/tickets/:id/comments', params: {
        'ticket_id': ticketId,
        ...request.toJson(),
      });

      final data = await client
          .from('ticket_comments')
          .insert({
            'ticket_id': ticketId,
            'user_id': userId,
            'content': request.content,
            'is_internal': request.isInternal,
          })
          .select()
          .single();

      final comment = CommentModel.fromJson(data as Map<String, dynamic>);

      logApiResponse('/api/tickets/:id/comments', comment);

      return comment;
    } catch (e) {
      throw handleError(e,
          customMessage: 'Gagal menambah komentar: ${e.toString()}');
    }
  }

  /// Get comments for a ticket
  ///
  /// GET /api/tickets/:id/comments
  ///
  /// Query Parameters:
  /// - include_internal: include internal notes (default: false for regular users)
  ///
  /// Response 200:
  /// ```json
  /// {
  ///   "comments": [...],
  ///   "total": 5
  /// }
  /// ```
  ///
  /// Response 404: Not Found (ticket tidak ditemukan)
  /// Response 401: Unauthorized
  Future<List<CommentModel>> getComments(String ticketId,
      {bool includeInternal = false}) async {
    try {
      requireAuth();

      logApiCall('GET', '/api/tickets/:id/comments',
          params: {'ticket_id': ticketId, 'include_internal': includeInternal});

      var query = client.from('ticket_comments').select('''
        *,
        user:profiles(id, name, role)
      ''').eq('ticket_id', ticketId);

      // Regular users tidak bisa lihat internal notes
      final role = await getUserRole();
      if (role == 'user' && !includeInternal) {
        query = query.eq('is_internal', false);
      }

      final data = await query.order('created_at', ascending: true);

      final comments = (data as List)
          .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
          .toList();

      logApiResponse('/api/tickets/:id/comments', comments);

      return comments;
    } catch (e) {
      throw handleError(e, customMessage: 'Gagal mengambil komentar: ${e.toString()}');
    }
  }
}