# 🎯 API Service Layer - Quick Reference Card

## 📌 Endpoints Overview

### Authentication (7 Endpoints)

```
POST   /api/auth/login              → AuthResponse
POST   /api/auth/register            → UserModel
POST   /api/auth/logout              → void
POST   /api/auth/reset-password      → void
GET    /api/auth/me                  → UserModel?
PUT    /api/auth/profile             → UserModel
GET    /api/auth/check               → bool
```

### Tickets (5 Endpoints)

```
GET    /api/tickets                  → TicketsResponse
GET    /api/tickets/:id              → TicketModel
POST   /api/tickets                  → TicketModel
PUT    /api/tickets/:id              → TicketModel
DELETE /api/tickets/:id              → void
```

### Comments (2 Endpoints)

```
POST   /api/tickets/:id/comments     → CommentModel
GET    /api/tickets/:id/comments     → List<CommentModel>
```

---

## 🔌 Import Quick Reference

```dart
// API Services
import 'package:e_ticketing_helpdesk/data/datasources/api/api_services_export.dart';

// Request Models
import 'package:e_ticketing_helpdesk/data/models/requests/requests_export.dart';

// Response Models
import 'package:e_ticketing_helpdesk/data/models/responses/responses_export.dart';
```

---

## 💻 Code Snippets

### Login

```dart
final authService = AuthApiService();
try {
  final response = await authService.login(
    LoginRequest(
      email: 'user@example.com',
      password: 'password123',
    ),
  );
  print('Token: ${response.token}');
  print('User: ${response.user.name}');
} catch (e) {
  print('Error: $e');
}
```

### Register (NEW!)

```dart
final authService = AuthApiService();
try {
  final user = await authService.register(
    RegisterRequest(
      name: 'John Doe',
      email: 'john@example.com',
      password: 'password123',
      phone: '+6281234567890',
      department: 'IT',
    ),
  );
  print('Registered: ${user.name}');
} catch (e) {
  print('Error: $e');
}
```

### Get Tickets

```dart
final ticketService = TicketApiService();
try {
  final response = await ticketService.getTickets(
    status: 'open',
    priority: 'high',
    limit: 20,
  );
  print('Total: ${response.total}');
  print('Tickets: ${response.tickets}');
} catch (e) {
  print('Error: $e');
}
```

### Create Ticket

```dart
final ticketService = TicketApiService();
try {
  final ticket = await ticketService.createTicket(
    CreateTicketRequest(
      title: 'Cannot login',
      description: 'I cannot login to the system',
      category: 'technical',
      priority: 'high',
    ),
  );
  print('Created: ${ticket.ticketNo}');
} catch (e) {
  print('Error: $e');
}
```

### Get Ticket Detail

```dart
final ticketService = TicketApiService();
try {
  final ticket = await ticketService.getTicketById('ticket-123');
  print('Ticket: ${ticket.title}');
  print('Comments: ${ticket.comments.length}');
  print('Attachments: ${ticket.attachments.length}');
} catch (e) {
  print('Error: $e');
}
```

### Update Ticket

```dart
final ticketService = TicketApiService();
try {
  final updated = await ticketService.updateTicket(
    'ticket-123',
    UpdateTicketRequest(
      status: 'in_progress',
      priority: 'critical',
      assignedTo: 'admin-456',
    ),
  );
  print('Updated: ${updated.status}');
} catch (e) {
  print('Error: $e');
}
```

### Add Comment

```dart
final ticketService = TicketApiService();
try {
  final comment = await ticketService.addComment(
    'ticket-123',
    AddCommentRequest(
      content: 'Please check this issue',
      isInternal: false,
    ),
  );
  print('Added: ${comment.content}');
} catch (e) {
  print('Error: $e');
}
```

### Get Comments

```dart
final ticketService = TicketApiService();
try {
  final comments = await ticketService.getComments('ticket-123');
  for (var comment in comments) {
    print('${comment.user?.name}: ${comment.content}');
  }
} catch (e) {
  print('Error: $e');
}
```

---

## 🔑 Enums Reference

### Status

```dart
const statuses = ['open', 'in_progress', 'resolved', 'closed'];
```

### Priority

```dart
const priorities = ['critical', 'high', 'medium', 'low'];
```

### Role

```dart
const roles = ['user', 'admin', 'support'];
```

---

## 📋 Query Parameters

### Get Tickets

```dart
await ticketService.getTickets(
  status: 'open',              // Filter by status
  priority: 'high',             // Filter by priority
  search: 'login',              // Search in title/description
  category: 'technical',        // Filter by category
  assignedTo: 'user-123',       // Filter by assignee
  limit: 20,                    // Pagination limit
  offset: 0,                    // Pagination offset
);
```

### Get Comments

```dart
await ticketService.getComments(
  'ticket-123',
  includeInternal: false,       // Include internal notes (for admins)
);
```

---

## 🛡️ Error Handling Pattern

```dart
try {
  final response = await authService.login(request);
  // Success handling
} on Exception catch (e) {
  if (e.toString().contains('401')) {
    // Unauthorized - redirect to login
  } else if (e.toString().contains('404')) {
    // Not found
  } else if (e.toString().contains('422')) {
    // Validation error
  } else {
    // Generic error
  }
}
```

---

## 🧠 Best Practices

### ✅ DO

```dart
// Use API services directly
final authService = AuthApiService();
final response = await authService.login(request);

// Handle all exceptions
try {
  await ticketService.getTickets();
} catch (e) {
  // Handle error
}

// Use request models (type-safe)
final request = LoginRequest(email: email, password: password);
```

### ❌ DON'T

```dart
// Don't use raw Supabase client directly
// ❌ final data = await _client.from('tickets').select();

// Don't ignore exceptions
// ❌ await ticketService.getTickets(); // Missing try-catch

// Don't pass raw objects
// ❌ await authService.login({'email': email, 'password': password});
```

---

## 🔄 Integration Example

```dart
// In Repository
class TicketRepository {
  final _ticketService = TicketApiService();

  Future<List<TicketModel>> fetchTickets() async {
    try {
      final response = await _ticketService.getTickets();
      return response.tickets;
    } catch (e) {
      throw Exception('Failed to fetch tickets: $e');
    }
  }
}

// In Provider
final ticketsProvider = FutureProvider<List<TicketModel>>((ref) async {
  final repository = TicketRepository();
  return repository.fetchTickets();
});

// In Widget
@override
Widget build(BuildContext context, WidgetRef ref) {
  final tickets = ref.watch(ticketsProvider);
  return tickets.when(
    data: (data) => TicketListView(tickets: data),
    loading: () => LoadingWidget(),
    error: (err, st) => ErrorWidget(error: err),
  );
}
```

---

## 📊 Status Codes Reference

| Code | Meaning          | Action                   |
| ---- | ---------------- | ------------------------ |
| 200  | OK               | Success                  |
| 201  | Created          | Resource created         |
| 400  | Bad Request      | Check input              |
| 401  | Unauthorized     | Redirect to login        |
| 403  | Forbidden        | Check permissions        |
| 404  | Not Found        | Resource doesn't exist   |
| 422  | Validation Error | Check input validation   |
| 500  | Server Error     | Retry or contact support |

---

## 📁 File Structure

```
lib/
├── data/
│   ├── datasources/api/
│   │   ├── base_api_service.dart      ✅ Helper methods
│   │   ├── auth_api_service.dart      ✅ Auth endpoints
│   │   ├── ticket_api_service.dart    ✅ Ticket endpoints
│   │   └── api_services_export.dart   ✅ Export
│   │
│   ├── models/
│   │   ├── requests/
│   │   │   ├── auth_request.dart      ✅ Auth requests
│   │   │   ├── ticket_request.dart    ✅ Ticket requests
│   │   │   └── requests_export.dart   ✅ Export
│   │   │
│   │   └── responses/
│   │       ├── api_response.dart      ✅ Generic wrapper
│   │       ├── auth_response.dart     ✅ Auth responses
│   │       ├── ticket_response.dart   ✅ Ticket responses
│   │       └── responses_export.dart  ✅ Export
│   │
│   └── repositories/
│       ├── supabase_auth_repository.dart   (Update with API services)
│       └── supabase_ticket_repository.dart (Update with API services)
```

---

## 📚 Documentation Files

| File                            | Purpose                |
| ------------------------------- | ---------------------- |
| `API_DOCUMENTATION.md`          | Complete API reference |
| `API_SERVICE_LAYER_GUIDE.md`    | Implementation guide   |
| `API_IMPLEMENTATION_SUMMARY.md` | Quick summary          |
| `postman_collection.json`       | Postman collection     |

---

## 🚀 Quick Checklist

- [ ] Import API services
- [ ] Create API service instance
- [ ] Create request model
- [ ] Call API service method
- [ ] Handle response/error
- [ ] Update UI

---

**Last Updated**: 2024-01-15  
**Version**: 1.0.0  
**Status**: Ready for Use ✅
