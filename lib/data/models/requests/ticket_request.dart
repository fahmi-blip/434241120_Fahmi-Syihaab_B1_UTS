/// Request model untuk Create Ticket endpoint
///
/// POST /api/tickets
/// ```json
/// {
///   "title": "Cannot login",
///   "description": "I cannot login to the system",
///   "category": "technical",
///   "priority": "high"
/// }
/// ```
class CreateTicketRequest {
  final String title;
  final String description;
  final String? category;
  final String priority; // high, medium, low, critical

  CreateTicketRequest({
    required this.title,
    required this.description,
    this.category,
    this.priority = 'medium',
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'category': category,
        'priority': priority,
        'status': 'open', // Default status saat buat ticket baru
      };

  @override
  String toString() =>
      'CreateTicketRequest(title: $title, category: $category, priority: $priority)';
}

/// Request model untuk Update Ticket endpoint
///
/// PUT /api/tickets/:id
/// ```json
/// {
///   "title": "Cannot login - UPDATED",
///   "description": "Updated description",
///   "status": "in_progress",
///   "priority": "critical",
///   "assigned_to": "user-id-123"
/// }
/// ```
class UpdateTicketRequest {
  final String? title;
  final String? description;
  final String? status; // open, in_progress, resolved, closed
  final String? priority; // high, medium, low, critical
  final String? category;
  final String? assignedTo;

  UpdateTicketRequest({
    this.title,
    this.description,
    this.status,
    this.priority,
    this.category,
    this.assignedTo,
  });

  Map<String, dynamic> toJson() => {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (status != null) 'status': status,
        if (priority != null) 'priority': priority,
        if (category != null) 'category': category,
        if (assignedTo != null) 'assigned_to': assignedTo,
      };

  @override
  String toString() =>
      'UpdateTicketRequest(title: $title, status: $status, priority: $priority)';
}

/// Request model untuk Add Comment endpoint
///
/// POST /api/tickets/:id/comments
/// ```json
/// {
///   "content": "Please check this issue",
///   "is_internal": false
/// }
/// ```
class AddCommentRequest {
  final String content;
  final bool isInternal; // true = internal note, false = visible ke user

  AddCommentRequest({
    required this.content,
    this.isInternal = false,
  });

  Map<String, dynamic> toJson() => {
        'content': content,
        'is_internal': isInternal,
      };

  @override
  String toString() =>
      'AddCommentRequest(content: $content, isInternal: $isInternal)';
}

/// Request model untuk Filter Tickets endpoint
///
/// GET /api/tickets?status=open&priority=high&search=login
class FilterTicketsRequest {
  final String? status;
  final String? priority;
  final String? search;
  final String? category;
  final String? assignedTo;
  final int? limit;
  final int? offset;

  FilterTicketsRequest({
    this.status,
    this.priority,
    this.search,
    this.category,
    this.assignedTo,
    this.limit = 20,
    this.offset = 0,
  });

  Map<String, dynamic> toQueryMap() => {
        if (status != null) 'status': status,
        if (priority != null) 'priority': priority,
        if (search != null) 'search': search,
        if (category != null) 'category': category,
        if (assignedTo != null) 'assigned_to': assignedTo,
        if (limit != null) 'limit': limit.toString(),
        if (offset != null) 'offset': offset.toString(),
      };

  @override
  String toString() =>
      'FilterTicketsRequest(status: $status, priority: $priority, search: $search)';
}
