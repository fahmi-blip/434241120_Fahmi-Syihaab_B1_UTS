# 🚀 API Service Layer Implementation Guide

Panduan lengkap untuk menggunakan API Service Layer yang baru dibuat di project E-Ticketing Helpdesk.

---

## 📁 Project Structure

```
lib/
├── data/
│   ├── datasources/
│   │   └── api/
│   │       ├── base_api_service.dart          # Base class untuk semua API services
│   │       ├── auth_api_service.dart          # Authentication endpoints
│   │       ├── ticket_api_service.dart        # Ticket management endpoints
│   │       └── api_services_export.dart       # Export file
│   │
│   ├── models/
│   │   ├── requests/
│   │   │   ├── auth_request.dart              # Request models untuk auth
│   │   │   ├── ticket_request.dart            # Request models untuk tickets
│   │   │   └── requests_export.dart           # Export file
│   │   │
│   │   ├── responses/
│   │   │   ├── api_response.dart              # Generic response wrapper
│   │   │   ├── auth_response.dart             # Response models untuk auth
│   │   │   ├── ticket_response.dart           # Response models untuk tickets
│   │   │   └── responses_export.dart          # Export file
│   │   │
│   │   └── (existing models tetap di sini)
│   │
│   └── repositories/
│       └── (gunakan API services di sini)
│
├── presentation/
│   └── (UI layer)
│
└── main.dart
```

---

## 🔌 Quick Start

### 1. Import API Services

```dart
// Import dari API services export file
import 'package:e_ticketing_helpdesk/data/datasources/api/api_services_export.dart';
import 'package:e_ticketing_helpdesk/data/models/requests/requests_export.dart';
import 'package:e_ticketing_helpdesk/data/models/responses/responses_export.dart';
```

### 2. Gunakan di Repository

```dart
class SupabaseAuthRepository {
  final _authService = AuthApiService();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _authService.login(
        LoginRequest(email: email, password: password),
      );

      return {
        'token': response.token,
        'user': response.user,
      };
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }
}
```

### 3. Gunakan di Provider/ViewModel

```dart
final loginProvider = FutureProvider<AuthResponse>((ref) async {
  final authService = AuthApiService();
  final response = await authService.login(
    LoginRequest(email: 'user@example.com', password: 'password123'),
  );
  return response;
});
```

---

## 📚 API Service Details

### AuthApiService

**Endpoints yang tersedia:**

| Method              | Endpoint                      | Description        |
| ------------------- | ----------------------------- | ------------------ |
| `login()`           | POST /api/auth/login          | Login user         |
| `register()`        | POST /api/auth/register       | Register user baru |
| `logout()`          | POST /api/auth/logout         | Logout user        |
| `resetPassword()`   | POST /api/auth/reset-password | Reset password     |
| `getCurrentUser()`  | GET /api/auth/me              | Get current user   |
| `updateProfile()`   | PUT /api/auth/profile         | Update profile     |
| `isAuthenticated()` | GET /api/auth/check           | Check auth status  |

**Usage Examples:**

```dart
final authService = AuthApiService();

// Login
final authResponse = await authService.login(
  LoginRequest(
    email: 'user@example.com',
    password: 'password123',
  ),
);

// Register
final user = await authService.register(
  RegisterRequest(
    name: 'John Doe',
    email: 'john@example.com',
    password: 'password123',
    phone: '+6281234567890',
    department: 'IT',
  ),
);

// Get Current User
final currentUser = await authService.getCurrentUser();

// Update Profile
final updatedUser = await authService.updateProfile(
  UpdateProfileRequest(
    name: 'John Updated',
    phone: '+6281234567890',
  ),
);

// Logout
await authService.logout();
```

---

### TicketApiService

**Endpoints yang tersedia:**

| Method            | Endpoint                       | Description       |
| ----------------- | ------------------------------ | ----------------- |
| `getTickets()`    | GET /api/tickets               | Get all tickets   |
| `getTicketById()` | GET /api/tickets/:id           | Get ticket detail |
| `createTicket()`  | POST /api/tickets              | Create new ticket |
| `updateTicket()`  | PUT /api/tickets/:id           | Update ticket     |
| `deleteTicket()`  | DELETE /api/tickets/:id        | Delete ticket     |
| `addComment()`    | POST /api/tickets/:id/comments | Add comment       |
| `getComments()`   | GET /api/tickets/:id/comments  | Get comments      |

**Usage Examples:**

```dart
final ticketService = TicketApiService();

// Get all tickets dengan filter
final ticketsResponse = await ticketService.getTickets(
  status: 'open',
  priority: 'high',
  limit: 20,
  offset: 0,
);
print('Total tickets: ${ticketsResponse.total}');
print('Tickets: ${ticketsResponse.tickets}');

// Get ticket detail
final ticket = await ticketService.getTicketById('ticket-123');

// Create ticket
final newTicket = await ticketService.createTicket(
  CreateTicketRequest(
    title: 'Cannot login',
    description: 'I cannot login to the system',
    category: 'technical',
    priority: 'high',
  ),
);

// Update ticket
final updatedTicket = await ticketService.updateTicket(
  'ticket-123',
  UpdateTicketRequest(
    status: 'in_progress',
    priority: 'critical',
    assignedTo: 'admin-456',
  ),
);

// Add comment
final comment = await ticketService.addComment(
  'ticket-123',
  AddCommentRequest(
    content: 'Please check this issue',
    isInternal: false,
  ),
);

// Get comments
final comments = await ticketService.getComments(
  'ticket-123',
  includeInternal: false,
);

// Delete ticket
await ticketService.deleteTicket('ticket-123');
```

---

## 🔒 Error Handling

Semua API service throw `Exception` ketika terjadi error. Anda perlu handle dengan try-catch:

```dart
try {
  final response = await authService.login(
    LoginRequest(email: 'user@example.com', password: 'password123'),
  );
} catch (e) {
  print('Login error: $e');
  // Handle error di UI
}
```

### Error Response Format

```dart
{
  "success": false,
  "message": "Login failed",
  "error": {
    "message": "Email atau password salah",
    "statusCode": 401,
    "details": "Invalid credentials"
  }
}
```

---

## 📡 BaseApiService - Helper Methods

`BaseApiService` menyediakan helper methods yang bisa digunakan di semua API services:

```dart
class CustomApiService extends BaseApiService {
  // Get Supabase client
  final supabaseClient = client;

  // Get current user ID
  String userId = userId;

  // Get auth token
  final token = await getAuthToken();

  // Save auth token
  await saveAuthToken('new-token');

  // Get user role
  final role = await getUserRole();

  // Check if authenticated
  if (isAuthenticated()) {
    // User is authenticated
  }

  // Require authentication (throw if not authenticated)
  requireAuth();

  // Handle error
  throw handleError(error, customMessage: 'Custom error message');

  // Log API call
  logApiCall('POST', '/api/tickets', params: {'title': 'Test'});

  // Log API response
  logApiResponse('/api/tickets', responseData);
}
```

---

## 🔄 Integration dengan Repository

### Update SupabaseAuthRepository

```dart
import 'package:e_ticketing_helpdesk/data/datasources/api/api_services_export.dart';
import 'package:e_ticketing_helpdesk/data/models/requests/requests_export.dart';

class SupabaseAuthRepository {
  final _authService = AuthApiService();
  final _client = SupabaseService.client;

  /// Login dengan API service
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _authService.login(
      LoginRequest(email: email, password: password),
    );

    return {'token': response.token, 'user': response.user};
  }

  /// Register dengan API service
  Future<UserModel> register(
    String name,
    String email,
    String password,
    String? phone,
    String? department,
  ) async {
    return await _authService.register(
      RegisterRequest(
        name: name,
        email: email,
        password: password,
        phone: phone,
        department: department,
      ),
    );
  }

  /// Logout dengan API service
  Future<void> logout() async {
    await _authService.logout();
  }

  /// Get current user dengan API service
  Future<UserModel?> getCurrentUser() async {
    return await _authService.getCurrentUser();
  }

  /// Update profile dengan API service
  Future<UserModel> updateProfile(
    String name,
    String phone,
    String department,
  ) async {
    return await _authService.updateProfile(
      UpdateProfileRequest(
        name: name,
        phone: phone,
        department: department,
      ),
    );
  }

  /// Reset password dengan API service
  Future<void> resetPassword(String email) async {
    await _authService.resetPassword(
      ResetPasswordRequest(email: email),
    );
  }
}
```

### Update SupabaseTicketRepository

```dart
import 'package:e_ticketing_helpdesk/data/datasources/api/api_services_export.dart';
import 'package:e_ticketing_helpdesk/data/models/requests/requests_export.dart';

class SupabaseTicketRepository {
  final _ticketService = TicketApiService();

  Future<List<TicketModel>> getTickets({
    String? status,
    String? priority,
    String? search,
  }) async {
    final response = await _ticketService.getTickets(
      status: status,
      priority: priority,
      search: search,
      limit: 20,
    );
    return response.tickets;
  }

  Future<TicketModel> getTicketById(String id) async {
    return await _ticketService.getTicketById(id);
  }

  Future<TicketModel> createTicket({
    required String title,
    required String description,
    String? category,
    String priority = 'medium',
  }) async {
    return await _ticketService.createTicket(
      CreateTicketRequest(
        title: title,
        description: description,
        category: category,
        priority: priority,
      ),
    );
  }

  Future<TicketModel> updateTicket(
    String id, {
    String? title,
    String? status,
    String? priority,
  }) async {
    return await _ticketService.updateTicket(
      id,
      UpdateTicketRequest(
        title: title,
        status: status,
        priority: priority,
      ),
    );
  }

  Future<void> deleteTicket(String id) async {
    await _ticketService.deleteTicket(id);
  }

  Future<List<CommentModel>> getComments(String ticketId) async {
    return await _ticketService.getComments(ticketId);
  }

  Future<CommentModel> addComment(
    String ticketId,
    String content,
    bool isInternal,
  ) async {
    return await _ticketService.addComment(
      ticketId,
      AddCommentRequest(content: content, isInternal: isInternal),
    );
  }
}
```

---

## 📊 Response Models

### ApiResponse<T> - Generic Response Wrapper

```dart
// Success response
final response = ApiResponse<String>.success(
  data: 'Some data',
  message: 'Success!',
);

// Error response
final errorResponse = ApiResponse<String>.error(
  message: 'Something went wrong',
  statusCode: 500,
  details: 'Database error',
);

// Check success
if (response.success) {
  print(response.data);
}
```

### AuthResponse

```dart
final authResponse = AuthResponse(
  token: 'eyJhbGc...',
  user: UserModel(...),
);

print(authResponse.token);
print(authResponse.user.name);
```

### TicketsResponse

```dart
final ticketsResponse = TicketsResponse(
  tickets: [...],
  total: 10,
  limit: 20,
  offset: 0,
);

print('Total: ${ticketsResponse.total}');
print('Tickets: ${ticketsResponse.tickets.length}');
```

---

## 🧪 Testing

### Unit Test Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:e_ticketing_helpdesk/data/datasources/api/auth_api_service.dart';
import 'package:e_ticketing_helpdesk/data/models/requests/requests_export.dart';

void main() {
  group('AuthApiService', () {
    late AuthApiService authService;

    setUp(() {
      authService = AuthApiService();
    });

    test('login should return AuthResponse on success', () async {
      final response = await authService.login(
        LoginRequest(
          email: 'test@example.com',
          password: 'password123',
        ),
      );

      expect(response.token, isNotNull);
      expect(response.user, isNotNull);
    });

    test('login should throw on invalid credentials', () async {
      expect(
        () => authService.login(
          LoginRequest(
            email: 'invalid@example.com',
            password: 'wrong',
          ),
        ),
        throwsException,
      );
    });
  });
}
```

---

## 📝 Postman Collection

File `postman_collection.json` sudah disediakan untuk testing API endpoints.

**Cara menggunakan:**

1. Buka Postman
2. Click `Import` → `File` → Pilih `postman_collection.json`
3. Set variables:
   - `base_url`: URL Supabase Anda
   - `access_token`: Token dari login
   - `user_id`: User ID Anda
   - `ticket_id`: Ticket ID untuk testing

---

## 📖 Documentation

File `API_DOCUMENTATION.md` berisi dokumentasi lengkap semua endpoints dengan:

- Deskripsi endpoint
- Request/Response format
- Error handling
- Contoh usage
- Enum values

---

## 🔐 Security Notes

1. **Token Management**: Token disimpan di SharedPreferences dan dikelola oleh Supabase client
2. **HTTPS Only**: Semua komunikasi melalui HTTPS
3. **RLS (Row Level Security)**: Database menggunakan RLS untuk security di level database
4. **Input Validation**: Validasi input dilakukan di service layer
5. **Error Messages**: Jangan expose sensitive info di error messages

---

## ⚠️ Common Issues & Solutions

### Issue 1: "User is not authenticated" Error

**Cause**: Belum login atau token expired

**Solution**:

```dart
// Check authentication first
final authService = AuthApiService();
final isAuth = await authService.isAuthenticated();

if (!isAuth) {
  // Redirect to login
}
```

### Issue 2: CORS Error

**Cause**: Supabase CORS configuration

**Solution**:

- Pastikan app URL sudah ditambahkan di Supabase CORS settings
- Atau gunakan Supabase client library yang handle CORS

### Issue 3: Token Expired

**Cause**: Session sudah expired

**Solution**:

```dart
try {
  final tickets = await ticketService.getTickets();
} catch (e) {
  if (e.toString().contains('401')) {
    // Token expired, redirect to login
    await authService.logout();
  }
}
```

---

## 📞 Support

Untuk pertanyaan atau issues, silakan:

1. Cek `API_DOCUMENTATION.md` untuk dokumentasi lengkap
2. Review request/response models di `/lib/data/models/`
3. Lihat contoh implementation di repository files

---

**Last Updated**: 2024-01-15  
**Version**: 1.0.0
