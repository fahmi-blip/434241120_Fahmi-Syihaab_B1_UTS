import '../user_model.dart';

/// Response model untuk Login endpoint
///
/// POST /api/auth/login
/// Response 200:
/// ```json
/// {
///   "success": true,
///   "message": "Login successful",
///   "data": {
///     "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
///     "user": {
///       "id": "123",
///       "name": "John Doe",
///       "email": "john@example.com",
///       "role": "user"
///     }
///   }
/// }
/// ```
class AuthResponse {
  final String token;
  final UserModel user;

  AuthResponse({
    required this.token,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        token: json['token']?.toString() ?? '',
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'token': token,
        'user': user.toJson(),
      };

  @override
  String toString() =>
      'AuthResponse(token: ${token.substring(0, 20)}..., user: ${user.name})';
}

/// Response model untuk Register endpoint
///
/// POST /api/auth/register
/// Response 201:
/// ```json
/// {
///   "success": true,
///   "message": "Registration successful. Please check your email to verify.",
///   "data": {
///     "user": {
///       "id": "123",
///       "name": "John Doe",
///       "email": "john@example.com",
///       "phone": "+6281234567890",
///       "department": "IT",
///       "role": "user",
///       "created_at": "2024-01-15T10:00:00Z"
///     }
///   }
/// }
/// ```
class RegisterResponse {
  final UserModel user;
  final String? verificationEmail;

  RegisterResponse({
    required this.user,
    this.verificationEmail,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) =>
      RegisterResponse(
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
        verificationEmail: json['verification_email']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'user': user.toJson(),
        'verification_email': verificationEmail,
      };

  @override
  String toString() =>
      'RegisterResponse(user: ${user.name}, verificationEmail: $verificationEmail)';
}

/// Response model untuk Get Current User endpoint
///
/// GET /api/auth/me
/// Response 200:
/// ```json
/// {
///   "success": true,
///   "message": "User retrieved successfully",
///   "data": {
///     "id": "123",
///     "name": "John Doe",
///     "email": "john@example.com",
///     "phone": "+6281234567890",
///     "department": "IT",
///     "role": "user",
///     "avatar": "https://...",
///     "created_at": "2024-01-15T10:00:00Z"
///   }
/// }
/// ```
class UserResponse {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String department;
  final String role;
  final String? avatar;
  final DateTime createdAt;

  UserResponse({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.department,
    required this.role,
    this.avatar,
    required this.createdAt,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) => UserResponse(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        department: json['department']?.toString() ?? '',
        role: json['role']?.toString() ?? 'user',
        avatar: json['avatar']?.toString(),
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'department': department,
        'role': role,
        'avatar': avatar,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  String toString() =>
      'UserResponse(id: $id, name: $name, email: $email, role: $role)';
}

/// Response model untuk Logout endpoint
///
/// POST /api/auth/logout
/// Response 200:
/// ```json
/// {
///   "success": true,
///   "message": "Logout successful"
/// }
/// ```
class LogoutResponse {
  final String message;
  final DateTime timestamp;

  LogoutResponse({
    required this.message,
    required this.timestamp,
  });

  factory LogoutResponse.fromJson(Map<String, dynamic> json) => LogoutResponse(
        message: json['message']?.toString() ?? 'Logout successful',
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'])
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'message': message,
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  String toString() =>
      'LogoutResponse(message: $message, timestamp: $timestamp)';
}
