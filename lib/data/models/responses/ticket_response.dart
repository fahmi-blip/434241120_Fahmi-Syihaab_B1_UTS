import '../ticket_model.dart';

/// Response model untuk Get Tickets endpoint
///
/// GET /api/tickets?status=open&priority=high
/// Response 200:
/// ```json
/// {
///   "success": true,
///   "message": "Tickets retrieved successfully",
///   "data": {
///     "tickets": [...],
///     "total": 10,
///     "limit": 20,
///     "offset": 0
///   }
/// }
/// ```
class TicketsResponse {
  final List<TicketModel> tickets;
  final int total;
  final int limit;
  final int offset;

  TicketsResponse({
    required this.tickets,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory TicketsResponse.fromJson(Map<String, dynamic> json) =>
      TicketsResponse(
        tickets: (json['tickets'] as List? ?? [])
            .map((e) => TicketModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: (json['total'] as int?) ?? 0,
        limit: (json['limit'] as int?) ?? 20,
        offset: (json['offset'] as int?) ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'tickets': tickets.map((t) => {
          'id': t.id,
          'ticketNo': t.ticketNo,
          'title': t.title,
          'description': t.description,
          'category': t.category,
          'priority': t.priority,
          'status': t.status,
          'userId': t.userId,
          'assignedTo': t.assignedTo,
          'createdAt': t.createdAt.toIso8601String(),
          'updatedAt': t.updatedAt.toIso8601String(),
        }).toList(),
        'total': total,
        'limit': limit,
        'offset': offset,
      };

  @override
  String toString() =>
      'TicketsResponse(total: $total, tickets: ${tickets.length}, limit: $limit)';
}

/// Response model untuk Get Ticket By ID endpoint
///
/// GET /api/tickets/:id
/// Response 200:
/// ```json
/// {
///   "success": true,
///   "message": "Ticket retrieved successfully",
///   "data": {
///     "id": "ticket-123",
///     "ticket_no": "TKT-001",
///     "title": "Cannot login",
///     "description": "...",
///     "status": "open",
///     "priority": "high",
///     "user": {...},
///     "assignee": {...},
///     "comments": [...],
///     "attachments": [...]
///   }
/// }
/// ```
class TicketDetailResponse {
  final TicketModel ticket;

  TicketDetailResponse({required this.ticket});

  factory TicketDetailResponse.fromJson(Map<String, dynamic> json) =>
      TicketDetailResponse(
        ticket: TicketModel.fromJson(json),
      );

  Map<String, dynamic> toJson() => {
        'id': ticket.id,
        'ticket_no': ticket.ticketNo,
        'title': ticket.title,
        'status': ticket.status,
        'priority': ticket.priority,
      };

  @override
  String toString() => 'TicketDetailResponse(ticket: ${ticket.ticketNo})';
}

/// Response model untuk Create Ticket endpoint
///
/// POST /api/tickets
/// Response 201:
/// ```json
/// {
///   "success": true,
///   "message": "Ticket created successfully",
///   "data": {
///     "id": "ticket-123",
///     "ticket_no": "TKT-001",
///     "title": "Cannot login",
///     "status": "open",
///     "priority": "high",
///     "created_at": "2024-01-15T10:00:00Z"
///   }
/// }
/// ```
class CreateTicketResponse {
  final String id;
  final String ticketNo;
  final String title;
  final String status;
  final String priority;
  final DateTime createdAt;

  CreateTicketResponse({
    required this.id,
    required this.ticketNo,
    required this.title,
    required this.status,
    required this.priority,
    required this.createdAt,
  });

  factory CreateTicketResponse.fromJson(Map<String, dynamic> json) =>
      CreateTicketResponse(
        id: json['id']?.toString() ?? '',
        ticketNo: json['ticket_no']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        status: json['status']?.toString() ?? 'open',
        priority: json['priority']?.toString() ?? 'medium',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'ticket_no': ticketNo,
        'title': title,
        'status': status,
        'priority': priority,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  String toString() =>
      'CreateTicketResponse(id: $id, ticketNo: $ticketNo, title: $title)';
}

/// Response model untuk Update Ticket endpoint
///
/// PUT /api/tickets/:id
/// Response 200:
/// ```json
/// {
///   "success": true,
///   "message": "Ticket updated successfully",
///   "data": {
///     "id": "ticket-123",
///     "ticket_no": "TKT-001",
///     "title": "Cannot login - UPDATED",
///     "status": "in_progress",
///     "priority": "critical",
///     "updated_at": "2024-01-15T11:00:00Z"
///   }
/// }
/// ```
class UpdateTicketResponse {
  final String id;
  final String ticketNo;
  final String title;
  final String status;
  final String priority;
  final DateTime updatedAt;

  UpdateTicketResponse({
    required this.id,
    required this.ticketNo,
    required this.title,
    required this.status,
    required this.priority,
    required this.updatedAt,
  });

  factory UpdateTicketResponse.fromJson(Map<String, dynamic> json) =>
      UpdateTicketResponse(
        id: json['id']?.toString() ?? '',
        ticketNo: json['ticket_no']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        priority: json['priority']?.toString() ?? '',
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'ticket_no': ticketNo,
        'title': title,
        'status': status,
        'priority': priority,
        'updated_at': updatedAt.toIso8601String(),
      };

  @override
  String toString() =>
      'UpdateTicketResponse(id: $id, status: $status, priority: $priority)';
}

/// Response model untuk Delete Ticket endpoint
///
/// DELETE /api/tickets/:id
/// Response 200:
/// ```json
/// {
///   "success": true,
///   "message": "Ticket deleted successfully"
/// }
/// ```
class DeleteTicketResponse {
  final String message;
  final DateTime timestamp;

  DeleteTicketResponse({
    required this.message,
    required this.timestamp,
  });

  factory DeleteTicketResponse.fromJson(Map<String, dynamic> json) =>
      DeleteTicketResponse(
        message: json['message']?.toString() ?? 'Ticket deleted successfully',
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'])
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'message': message,
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  String toString() => 'DeleteTicketResponse(message: $message)';
}
