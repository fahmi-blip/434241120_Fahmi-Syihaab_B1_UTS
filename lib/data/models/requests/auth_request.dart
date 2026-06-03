/// Request model untuk Login endpoint
///
/// POST /api/auth/login
/// ```json
/// {
///   "email": "user@example.com",
///   "password": "password123"
/// }
/// ```
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };

  @override
  String toString() => 'LoginRequest(email: $email, password: ****)';
}

/// Request model untuk Register endpoint
///
/// POST /api/auth/register
/// ```json
/// {
///   "name": "John Doe",
///   "email": "user@example.com",
///   "password": "password123",
///   "phone": "+6281234567890",
///   "department": "IT",
///   "role": "user"
/// }
/// ```
class RegisterRequest {
  final String name;
  final String email;
  final String password;
  final String? phone;
  final String? department;
  final String role;

  RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    this.phone,
    this.department,
    this.role = 'user', // Default role
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'department': department,
        'role': role,
      };

  @override
  String toString() =>
      'RegisterRequest(name: $name, email: $email, phone: $phone, department: $department, role: $role)';
}

/// Request model untuk Reset Password endpoint
///
/// POST /api/auth/reset-password
/// ```json
/// {
///   "email": "user@example.com"
/// }
/// ```
class ResetPasswordRequest {
  final String email;

  ResetPasswordRequest({required this.email});

  Map<String, dynamic> toJson() => {'email': email};

  @override
  String toString() => 'ResetPasswordRequest(email: $email)';
}

/// Request model untuk Update Profile endpoint
///
/// PUT /api/auth/profile
/// ```json
/// {
///   "name": "John Doe Updated",
///   "phone": "+6281234567890",
///   "department": "IT"
/// }
/// ```
class UpdateProfileRequest {
  final String? name;
  final String? phone;
  final String? department;
  final String? avatar;

  UpdateProfileRequest({
    this.name,
    this.phone,
    this.department,
    this.avatar,
  });

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (department != null) 'department': department,
        if (avatar != null) 'avatar': avatar,
      };

  @override
  String toString() =>
      'UpdateProfileRequest(name: $name, phone: $phone, department: $department)';
}
