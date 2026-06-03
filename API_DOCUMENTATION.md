# 📱 E-Ticketing Helpdesk API Documentation

**Version:** 1.0.0  
**Base URL:** Supabase REST API  
**Last Updated:** 2024-01-15

---

## 📑 Table of Contents

1. [Overview](#overview)
2. [Authentication](#authentication)
3. [API Endpoints](#api-endpoints)
   - [Auth Endpoints](#auth-endpoints)
   - [Ticket Endpoints](#ticket-endpoints)
   - [Comment Endpoints](#comment-endpoints)
4. [Error Handling](#error-handling)
5. [Response Format](#response-format)

---

## Overview

E-Ticketing Helpdesk API menyediakan endpoints untuk mengelola tiket support, user authentication, dan komentar tiket. API dibangun menggunakan **Supabase** sebagai backend dan menggunakan **Dart/Flutter** di frontend.

### Architecture

```
UI Layer (Flutter)
    ↓
Repository Layer (Business Logic)
    ↓
API Service Layer (API Wrapper)
    ↓
Supabase Service (Client)
    ↓
Supabase Backend (PostgreSQL + REST API)
```

### Tech Stack

- **Backend:** Supabase (PostgreSQL + Realtime)
- **Frontend:** Flutter 3.0+
- **HTTP Client:** Dio 5.4.0
- **State Management:** Flutter Riverpod 2.4.9
- **Authentication:** Supabase Auth (Email/Password)

---

## Authentication

Semua endpoint (kecuali login & register) memerlukan token authentication.

### Token Management

Token disimpan di **SharedPreferences** secara local dan dikirim melalui Supabase session. Supabase secara otomatis menambahkan token ke header setiap request.

```dart
Authorization: Bearer <access_token>
```

### Token Expiration

- Default expiration: 1 hour
- Refresh token tersedia di Supabase session
- Automatic refresh dilakukan oleh Supabase client

---

## API Endpoints

### Auth Endpoints

#### 1. Login

```http
POST /api/auth/login
```

**Description:** Authenticate user dengan email dan password

**Request Body:**

```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response 200 OK:**

```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "John Doe",
      "email": "user@example.com",
      "phone": "+6281234567890",
      "department": "IT",
      "role": "user",
      "avatar": "https://...",
      "created_at": "2024-01-15T10:00:00Z"
    }
  }
}
```

**Error Responses:**

| Status | Message               | Description               |
| ------ | --------------------- | ------------------------- |
| 401    | Unauthorized          | Email atau password salah |
| 400    | Bad Request           | Missing required fields   |
| 500    | Internal Server Error | Server error              |

**Dart Implementation:**

```dart
final authService = AuthApiService();
final response = await authService.login(
  LoginRequest(
    email: 'user@example.com',
    password: 'password123',
  ),
);
```

---

#### 2. Register

```http
POST /api/auth/register
```

**Description:** Daftar user baru ke sistem

**Request Body:**

```json
{
  "name": "John Doe",
  "email": "user@example.com",
  "password": "password123",
  "phone": "+6281234567890",
  "department": "IT",
  "role": "user"
}
```

**Response 201 Created:**

```json
{
  "success": true,
  "message": "Registration successful. Please verify your email.",
  "data": {
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "John Doe",
      "email": "user@example.com",
      "phone": "+6281234567890",
      "department": "IT",
      "role": "user",
      "created_at": "2024-01-15T10:00:00Z"
    }
  }
}
```

**Error Responses:**

| Status | Message               | Description                        |
| ------ | --------------------- | ---------------------------------- |
| 400    | Bad Request           | Email sudah terdaftar atau invalid |
| 422    | Unprocessable Entity  | Validation error                   |
| 500    | Internal Server Error | Server error                       |

**Dart Implementation:**

```dart
final authService = AuthApiService();
final user = await authService.register(
  RegisterRequest(
    name: 'John Doe',
    email: 'user@example.com',
    password: 'password123',
    phone: '+6281234567890',
    department: 'IT',
  ),
);
```

---

#### 3. Logout

```http
POST /api/auth/logout
```

**Description:** Logout user dan invalidate token

**Request Body:** (empty)

**Response 200 OK:**

```json
{
  "success": true,
  "message": "Logout successful",
  "data": {
    "message": "Logout successful",
    "timestamp": "2024-01-15T11:00:00Z"
  }
}
```

**Error Responses:**

| Status | Message               | Description                |
| ------ | --------------------- | -------------------------- |
| 401    | Unauthorized          | Token expired atau invalid |
| 500    | Internal Server Error | Server error               |

**Dart Implementation:**

```dart
final authService = AuthApiService();
await authService.logout();
```

---

#### 4. Reset Password

```http
POST /api/auth/reset-password
```

**Description:** Send password reset email

**Request Body:**

```json
{
  "email": "user@example.com"
}
```

**Response 200 OK:**

```json
{
  "success": true,
  "message": "Password reset email sent",
  "data": {
    "message": "Check your email for reset link"
  }
}
```

**Error Responses:**

| Status | Message               | Description           |
| ------ | --------------------- | --------------------- |
| 404    | Not Found             | Email tidak ditemukan |
| 500    | Internal Server Error | Server error          |

**Dart Implementation:**

```dart
final authService = AuthApiService();
await authService.resetPassword(
  ResetPasswordRequest(email: 'user@example.com'),
);
```

---

#### 5. Get Current User

```http
GET /api/auth/me
```

**Description:** Ambil data user yang sedang login

**Request Headers:**

```
Authorization: Bearer <access_token>
```

**Response 200 OK:**

```json
{
  "success": true,
  "message": "User retrieved successfully",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "John Doe",
    "email": "user@example.com",
    "phone": "+6281234567890",
    "department": "IT",
    "role": "user",
    "avatar": "https://...",
    "created_at": "2024-01-15T10:00:00Z"
  }
}
```

**Error Responses:**

| Status | Message               | Description                |
| ------ | --------------------- | -------------------------- |
| 401    | Unauthorized          | Token expired atau invalid |
| 500    | Internal Server Error | Server error               |

**Dart Implementation:**

```dart
final authService = AuthApiService();
final user = await authService.getCurrentUser();
```

---

#### 6. Update Profile

```http
PUT /api/auth/profile
```

**Description:** Update user profile data

**Request Headers:**

```
Authorization: Bearer <access_token>
```

**Request Body:**

```json
{
  "name": "John Doe Updated",
  "phone": "+6281234567890",
  "department": "IT Ops",
  "avatar": "https://..."
}
```

**Response 200 OK:**

```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "John Doe Updated",
    "email": "user@example.com",
    "phone": "+6281234567890",
    "department": "IT Ops",
    "role": "user",
    "avatar": "https://...",
    "created_at": "2024-01-15T10:00:00Z"
  }
}
```

**Error Responses:**

| Status | Message               | Description                |
| ------ | --------------------- | -------------------------- |
| 400    | Bad Request           | Invalid data               |
| 401    | Unauthorized          | Token expired atau invalid |
| 500    | Internal Server Error | Server error               |

**Dart Implementation:**

```dart
final authService = AuthApiService();
final user = await authService.updateProfile(
  UpdateProfileRequest(
    name: 'John Doe Updated',
    phone: '+6281234567890',
    department: 'IT Ops',
  ),
);
```

---

### Ticket Endpoints

#### 1. Get All Tickets

```http
GET /api/tickets?status=open&priority=high&limit=20&offset=0
```

**Description:** Ambil daftar semua tiket dengan filter

**Query Parameters:**

| Parameter   | Type    | Description                                            | Example   |
| ----------- | ------- | ------------------------------------------------------ | --------- |
| status      | string  | Filter by status (open, in_progress, resolved, closed) | open      |
| priority    | string  | Filter by priority (high, medium, low, critical)       | high      |
| search      | string  | Search by title/description/ticket_no                  | login     |
| category    | string  | Filter by category                                     | technical |
| assigned_to | string  | Filter by assignee user_id                             | user-123  |
| limit       | integer | Pagination limit (default: 20)                         | 20        |
| offset      | integer | Pagination offset (default: 0)                         | 0         |

**Request Headers:**

```
Authorization: Bearer <access_token>
```

**Response 200 OK:**

```json
{
  "success": true,
  "message": "Tickets retrieved successfully",
  "data": {
    "tickets": [
      {
        "id": "ticket-123",
        "ticket_no": "TKT-001",
        "title": "Cannot login",
        "description": "I cannot login to the system",
        "category": "technical",
        "priority": "high",
        "status": "open",
        "user_id": "user-123",
        "assigned_to": "admin-456",
        "created_at": "2024-01-15T10:00:00Z",
        "updated_at": "2024-01-15T10:00:00Z",
        "user": {
          "id": "user-123",
          "name": "John Doe",
          "email": "john@example.com",
          "role": "user"
        },
        "assignee": {
          "id": "admin-456",
          "name": "Admin User",
          "email": "admin@example.com",
          "role": "admin"
        },
        "comments": [...],
        "attachments": [...]
      }
    ],
    "total": 10,
    "limit": 20,
    "offset": 0
  }
}
```

**Error Responses:**

| Status | Message               | Description                |
| ------ | --------------------- | -------------------------- |
| 400    | Bad Request           | Invalid query parameters   |
| 401    | Unauthorized          | Token expired atau invalid |
| 500    | Internal Server Error | Server error               |

**Dart Implementation:**

```dart
final ticketService = TicketApiService();
final response = await ticketService.getTickets(
  status: 'open',
  priority: 'high',
  limit: 20,
  offset: 0,
);
```

---

#### 2. Get Ticket Detail

```http
GET /api/tickets/:id
```

**Description:** Ambil detail ticket berdasarkan ID

**Path Parameters:**

| Parameter | Type   | Description |
| --------- | ------ | ----------- |
| id        | string | Ticket ID   |

**Request Headers:**

```
Authorization: Bearer <access_token>
```

**Response 200 OK:**

```json
{
  "success": true,
  "message": "Ticket retrieved successfully",
  "data": {
    "id": "ticket-123",
    "ticket_no": "TKT-001",
    "title": "Cannot login",
    "description": "I cannot login to the system",
    "category": "technical",
    "priority": "high",
    "status": "open",
    "user_id": "user-123",
    "assigned_to": "admin-456",
    "created_at": "2024-01-15T10:00:00Z",
    "updated_at": "2024-01-15T10:00:00Z",
    "user": {
      "id": "user-123",
      "name": "John Doe",
      "email": "john@example.com",
      "role": "user"
    },
    "assignee": {
      "id": "admin-456",
      "name": "Admin User",
      "email": "admin@example.com",
      "role": "admin"
    },
    "comments": [
      {
        "id": "comment-789",
        "content": "We are investigating",
        "user_id": "admin-456",
        "created_at": "2024-01-15T10:30:00Z",
        "is_internal": false,
        "user": {
          "id": "admin-456",
          "name": "Admin User",
          "role": "admin"
        }
      }
    ],
    "attachments": [
      {
        "id": "attach-001",
        "file_url": "https://...",
        "file_name": "screenshot.png",
        "file_type": "image/png",
        "created_at": "2024-01-15T10:00:00Z"
      }
    ],
    "history": [
      {
        "id": "hist-001",
        "old_status": "open",
        "new_status": "in_progress",
        "note": "Started investigation",
        "changed_by": "admin-456",
        "created_at": "2024-01-15T10:15:00Z",
        "user": {
          "id": "admin-456",
          "name": "Admin User"
        }
      }
    ]
  }
}
```

**Error Responses:**

| Status | Message               | Description                          |
| ------ | --------------------- | ------------------------------------ |
| 404    | Not Found             | Ticket tidak ditemukan               |
| 401    | Unauthorized          | Token expired atau invalid           |
| 403    | Forbidden             | Anda tidak punya akses ke ticket ini |
| 500    | Internal Server Error | Server error                         |

**Dart Implementation:**

```dart
final ticketService = TicketApiService();
final ticket = await ticketService.getTicketById('ticket-123');
```

---

#### 3. Create Ticket

```http
POST /api/tickets
```

**Description:** Buat ticket baru

**Request Headers:**

```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Request Body:**

```json
{
  "title": "Cannot login",
  "description": "I cannot login to the system",
  "category": "technical",
  "priority": "high"
}
```

**Response 201 Created:**

```json
{
  "success": true,
  "message": "Ticket created successfully",
  "data": {
    "id": "ticket-123",
    "ticket_no": "TKT-001",
    "title": "Cannot login",
    "description": "I cannot login to the system",
    "category": "technical",
    "priority": "high",
    "status": "open",
    "user_id": "user-123",
    "created_at": "2024-01-15T10:00:00Z",
    "updated_at": "2024-01-15T10:00:00Z"
  }
}
```

**Error Responses:**

| Status | Message               | Description                               |
| ------ | --------------------- | ----------------------------------------- |
| 400    | Bad Request           | Missing required fields atau invalid data |
| 401    | Unauthorized          | Token expired atau invalid                |
| 500    | Internal Server Error | Server error                              |

**Dart Implementation:**

```dart
final ticketService = TicketApiService();
final ticket = await ticketService.createTicket(
  CreateTicketRequest(
    title: 'Cannot login',
    description: 'I cannot login to the system',
    category: 'technical',
    priority: 'high',
  ),
);
```

---

#### 4. Update Ticket

```http
PUT /api/tickets/:id
```

**Description:** Update ticket

**Path Parameters:**

| Parameter | Type   | Description |
| --------- | ------ | ----------- |
| id        | string | Ticket ID   |

**Request Headers:**

```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Request Body:**

```json
{
  "title": "Cannot login - UPDATED",
  "description": "Updated description",
  "status": "in_progress",
  "priority": "critical",
  "assigned_to": "admin-456"
}
```

**Response 200 OK:**

```json
{
  "success": true,
  "message": "Ticket updated successfully",
  "data": {
    "id": "ticket-123",
    "ticket_no": "TKT-001",
    "title": "Cannot login - UPDATED",
    "description": "Updated description",
    "category": "technical",
    "priority": "critical",
    "status": "in_progress",
    "user_id": "user-123",
    "assigned_to": "admin-456",
    "created_at": "2024-01-15T10:00:00Z",
    "updated_at": "2024-01-15T11:00:00Z"
  }
}
```

**Error Responses:**

| Status | Message               | Description                                    |
| ------ | --------------------- | ---------------------------------------------- |
| 400    | Bad Request           | Invalid data                                   |
| 404    | Not Found             | Ticket tidak ditemukan                         |
| 401    | Unauthorized          | Token expired atau invalid                     |
| 403    | Forbidden             | Anda tidak punya akses untuk update ticket ini |
| 500    | Internal Server Error | Server error                                   |

**Dart Implementation:**

```dart
final ticketService = TicketApiService();
final updated = await ticketService.updateTicket(
  'ticket-123',
  UpdateTicketRequest(
    status: 'in_progress',
    priority: 'critical',
    assignedTo: 'admin-456',
  ),
);
```

---

#### 5. Delete Ticket

```http
DELETE /api/tickets/:id
```

**Description:** Hapus ticket

**Path Parameters:**

| Parameter | Type   | Description |
| --------- | ------ | ----------- |
| id        | string | Ticket ID   |

**Request Headers:**

```
Authorization: Bearer <access_token>
```

**Response 200 OK:**

```json
{
  "success": true,
  "message": "Ticket deleted successfully",
  "data": {
    "message": "Ticket deleted successfully"
  }
}
```

**Error Responses:**

| Status | Message               | Description                                    |
| ------ | --------------------- | ---------------------------------------------- |
| 404    | Not Found             | Ticket tidak ditemukan                         |
| 401    | Unauthorized          | Token expired atau invalid                     |
| 403    | Forbidden             | Anda tidak punya akses untuk delete ticket ini |
| 500    | Internal Server Error | Server error                                   |

**Dart Implementation:**

```dart
final ticketService = TicketApiService();
await ticketService.deleteTicket('ticket-123');
```

---

### Comment Endpoints

#### 1. Add Comment to Ticket

```http
POST /api/tickets/:id/comments
```

**Description:** Tambah komentar ke ticket

**Path Parameters:**

| Parameter | Type   | Description |
| --------- | ------ | ----------- |
| id        | string | Ticket ID   |

**Request Headers:**

```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Request Body:**

```json
{
  "content": "Please check this issue",
  "is_internal": false
}
```

**Response 201 Created:**

```json
{
  "success": true,
  "message": "Comment added successfully",
  "data": {
    "id": "comment-789",
    "ticket_id": "ticket-123",
    "content": "Please check this issue",
    "user_id": "user-123",
    "created_at": "2024-01-15T10:30:00Z",
    "is_internal": false,
    "user": {
      "id": "user-123",
      "name": "John Doe",
      "role": "user"
    }
  }
}
```

**Error Responses:**

| Status | Message               | Description                |
| ------ | --------------------- | -------------------------- |
| 400    | Bad Request           | Missing required fields    |
| 404    | Not Found             | Ticket tidak ditemukan     |
| 401    | Unauthorized          | Token expired atau invalid |
| 500    | Internal Server Error | Server error               |

**Dart Implementation:**

```dart
final ticketService = TicketApiService();
final comment = await ticketService.addComment(
  'ticket-123',
  AddCommentRequest(
    content: 'Please check this issue',
    isInternal: false,
  ),
);
```

---

#### 2. Get Comments for Ticket

```http
GET /api/tickets/:id/comments
```

**Description:** Ambil semua komentar untuk ticket

**Path Parameters:**

| Parameter | Type   | Description |
| --------- | ------ | ----------- |
| id        | string | Ticket ID   |

**Query Parameters:**

| Parameter        | Type    | Description            | Default |
| ---------------- | ------- | ---------------------- | ------- |
| include_internal | boolean | Include internal notes | false   |

**Request Headers:**

```
Authorization: Bearer <access_token>
```

**Response 200 OK:**

```json
{
  "success": true,
  "message": "Comments retrieved successfully",
  "data": {
    "comments": [
      {
        "id": "comment-789",
        "ticket_id": "ticket-123",
        "content": "Please check this issue",
        "user_id": "user-123",
        "created_at": "2024-01-15T10:30:00Z",
        "is_internal": false,
        "user": {
          "id": "user-123",
          "name": "John Doe",
          "role": "user"
        }
      },
      {
        "id": "comment-790",
        "ticket_id": "ticket-123",
        "content": "Internal note: Need more info",
        "user_id": "admin-456",
        "created_at": "2024-01-15T10:45:00Z",
        "is_internal": true,
        "user": {
          "id": "admin-456",
          "name": "Admin User",
          "role": "admin"
        }
      }
    ],
    "total": 2
  }
}
```

**Error Responses:**

| Status | Message               | Description                |
| ------ | --------------------- | -------------------------- |
| 404    | Not Found             | Ticket tidak ditemukan     |
| 401    | Unauthorized          | Token expired atau invalid |
| 500    | Internal Server Error | Server error               |

**Dart Implementation:**

```dart
final ticketService = TicketApiService();
final comments = await ticketService.getComments(
  'ticket-123',
  includeInternal: false,
);
```

---

## Error Handling

### Error Response Format

Semua error response mengikuti format yang konsisten:

```json
{
  "success": false,
  "message": "Error message",
  "data": null,
  "error": {
    "message": "Error message",
    "statusCode": 400,
    "details": "Additional error details"
  }
}
```

### HTTP Status Codes

| Code | Meaning               | Description                                |
| ---- | --------------------- | ------------------------------------------ |
| 200  | OK                    | Request successful                         |
| 201  | Created               | Resource created successfully              |
| 400  | Bad Request           | Invalid request data                       |
| 401  | Unauthorized          | Authentication required atau invalid token |
| 403  | Forbidden             | Tidak punya akses ke resource ini          |
| 404  | Not Found             | Resource tidak ditemukan                   |
| 422  | Unprocessable Entity  | Validation error                           |
| 500  | Internal Server Error | Server error                               |

### Common Error Cases

#### Invalid Token

```json
{
  "statusCode": 401,
  "message": "Unauthorized",
  "details": "Token expired atau invalid"
}
```

#### Resource Not Found

```json
{
  "statusCode": 404,
  "message": "Not Found",
  "details": "Ticket dengan ID 'xxx' tidak ditemukan"
}
```

#### Validation Error

```json
{
  "statusCode": 422,
  "message": "Unprocessable Entity",
  "details": "Title is required"
}
```

---

## Response Format

### Success Response

```json
{
  "success": true,
  "message": "Success message",
  "data": {
    // Response data sesuai endpoint
  }
}
```

### Data Types

#### User Model

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+6281234567890",
  "department": "IT",
  "role": "user",
  "avatar": "https://...",
  "created_at": "2024-01-15T10:00:00Z"
}
```

#### Ticket Model

```json
{
  "id": "ticket-123",
  "ticket_no": "TKT-001",
  "title": "Cannot login",
  "description": "I cannot login to the system",
  "category": "technical",
  "priority": "high",
  "status": "open",
  "user_id": "user-123",
  "assigned_to": "admin-456",
  "created_at": "2024-01-15T10:00:00Z",
  "updated_at": "2024-01-15T10:00:00Z"
}
```

#### Comment Model

```json
{
  "id": "comment-789",
  "ticket_id": "ticket-123",
  "content": "Please check this issue",
  "user_id": "user-123",
  "created_at": "2024-01-15T10:30:00Z",
  "is_internal": false,
  "user": {
    "id": "user-123",
    "name": "John Doe",
    "role": "user"
  }
}
```

---

## Appendix

### Enum Values

#### Status

- `open` - Ticket baru
- `in_progress` - Sedang dikerjakan
- `resolved` - Sudah diselesaikan
- `closed` - Ditutup

#### Priority

- `critical` - Prioritas tertinggi
- `high` - Prioritas tinggi
- `medium` - Prioritas normal
- `low` - Prioritas rendah

#### Role

- `user` - Regular user
- `admin` - Administrator
- `support` - Support staff

---

**End of Documentation**
