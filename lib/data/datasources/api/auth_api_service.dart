import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_ticketing_helpdesk/data/datasources/api/base_api_service.dart';
import 'package:e_ticketing_helpdesk/data/models/requests/auth_request.dart';
import 'package:e_ticketing_helpdesk/data/models/responses/auth_response.dart';
import 'package:e_ticketing_helpdesk/data/models/user_model.dart';
import 'package:e_ticketing_helpdesk/core/services/supabase_service.dart';

/// Auth API Service
///
/// Handles all authentication related API calls
///
/// Endpoints:
/// - POST /api/auth/login
/// - POST /api/auth/register
/// - POST /api/auth/logout
/// - POST /api/auth/reset-password
/// - GET /api/auth/me
/// - PUT /api/auth/profile
class AuthApiService extends BaseApiService {
  /// Login user dengan email dan password
  ///
  /// POST /api/auth/login
  ///
  /// Request:
  /// ```json
  /// {
  ///   "email": "user@example.com",
  ///   "password": "password123"
  /// }
  /// ```
  ///
  /// Response 200:
  /// ```json
  /// {
  ///   "token": "eyJhbGc...",
  ///   "user": {
  ///     "id": "123",
  ///     "name": "John Doe",
  ///     "email": "john@example.com",
  ///     "role": "user"
  ///   }
  /// }
  /// ```
  ///
  /// Response 401: Unauthorized
  /// Response 400: Bad Request
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      logApiCall('POST', '/api/auth/login', params: {'email': request.email});

      final res = await client.auth.signInWithPassword(
        email: request.email,
        password: request.password,
      );

      if (res.user == null) {
        throw Exception('Login failed: User not found');
      }

      // Ambil profile dari tabel profiles
      final profile = await client
          .from('profiles')
          .select()
          .eq('id', res.user!.id)
          .single();

      final user = UserModel.fromJson(profile);
      final token = res.session?.accessToken ?? '';

      // Simpan ke SharedPreferences untuk akses cepat
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', user.id);
      await prefs.setString('user_name', user.name);
      await prefs.setString('user_email', user.email);
      await prefs.setString('user_role', user.role);
      await saveAuthToken(token);

      logApiResponse('/api/auth/login', user);

      return AuthResponse(token: token, user: user);
    } catch (e) {
      throw handleError(e, customMessage: 'Login gagal: ${e.toString()}');
    }
  }

  /// Register user baru
  ///
  /// POST /api/auth/register
  ///
  /// Request:
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
  ///
  /// Response 201: Created
  /// ```json
  /// {
  ///   "user": {
  ///     "id": "123",
  ///     "name": "John Doe",
  ///     "email": "john@example.com",
  ///     "phone": "+6281234567890",
  ///     "department": "IT",
  ///     "role": "user"
  ///   }
  /// }
  /// ```
  ///
  /// Response 400: Bad Request (email sudah terdaftar)
  /// Response 422: Unprocessable Entity
  Future<UserModel> register(RegisterRequest request) async {
    try {
      logApiCall('POST', '/api/auth/register',
          params: {'email': request.email});

      final res = await client.auth.signUp(
        email: request.email,
        password: request.password,
        data: {
          'name': request.name,
          'phone': request.phone ?? '',
          'department': request.department ?? '',
          'role': request.role,
        },
      );

      if (res.user == null) {
        throw Exception('Registration failed');
      }

      // Tunggu trigger handle_new_user selesai (jika ada di Supabase)
      await Future.delayed(const Duration(milliseconds: 500));

      // Ambil profile dari tabel profiles
      final profile = await client
          .from('profiles')
          .select()
          .eq('id', res.user!.id)
          .single();

      final user = UserModel.fromJson(profile);

      logApiResponse('/api/auth/register', user);

      return user;
    } catch (e) {
      throw handleError(e, customMessage: 'Registrasi gagal: ${e.toString()}');
    }
  }

  /// Logout user
  ///
  /// POST /api/auth/logout
  ///
  /// Response 200: OK
  /// ```json
  /// {
  ///   "message": "Logout successful"
  /// }
  /// ```
  Future<void> logout() async {
    try {
      logApiCall('POST', '/api/auth/logout');

      await client.auth.signOut();

      // Hapus dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      logApiResponse('/api/auth/logout', null);
    } catch (e) {
      throw handleError(e, customMessage: 'Logout gagal: ${e.toString()}');
    }
  }

  /// Reset password via email
  ///
  /// POST /api/auth/reset-password
  ///
  /// Request:
  /// ```json
  /// {
  ///   "email": "user@example.com"
  /// }
  /// ```
  ///
  /// Response 200: OK
  /// ```json
  /// {
  ///   "message": "Password reset email sent"
  /// }
  /// ```
  ///
  /// Response 404: Not Found (email tidak ditemukan)
  Future<void> resetPassword(ResetPasswordRequest request) async {
    try {
      logApiCall('POST', '/api/auth/reset-password',
          params: {'email': request.email});

      await client.auth.resetPasswordForEmail(request.email);

      logApiResponse('/api/auth/reset-password', null);
    } catch (e) {
      throw handleError(e,
          customMessage: 'Reset password gagal: ${e.toString()}');
    }
  }

  /// Get current logged in user
  ///
  /// GET /api/auth/me
  ///
  /// Response 200:
  /// ```json
  /// {
  ///   "id": "123",
  ///   "name": "John Doe",
  ///   "email": "john@example.com",
  ///   "phone": "+6281234567890",
  ///   "department": "IT",
  ///   "role": "user",
  ///   "avatar": "https://..."
  /// }
  /// ```
  ///
  /// Response 401: Unauthorized
  Future<UserModel?> getCurrentUser() async {
    try {
      logApiCall('GET', '/api/auth/me');

      final user = client.auth.currentUser;
      if (user == null) return null;

      final profile =
          await client.from('profiles').select().eq('id', user.id).single();

      final userModel = UserModel.fromJson(profile);

      logApiResponse('/api/auth/me', userModel);

      return userModel;
    } catch (e) {
      throw handleError(e,
          customMessage: 'Gagal mendapatkan user: ${e.toString()}');
    }
  }

  /// Update user profile
  ///
  /// PUT /api/auth/profile
  ///
  /// Request:
  /// ```json
  /// {
  ///   "name": "John Doe Updated",
  ///   "phone": "+6281234567890",
  ///   "department": "IT",
  ///   "avatar": "https://..."
  /// }
  /// ```
  ///
  /// Response 200:
  /// ```json
  /// {
  ///   "id": "123",
  ///   "name": "John Doe Updated",
  ///   "email": "john@example.com",
  ///   "phone": "+6281234567890",
  ///   "department": "IT",
  ///   "role": "user"
  /// }
  /// ```
  ///
  /// Response 401: Unauthorized
  /// Response 400: Bad Request
  Future<UserModel> updateProfile(UpdateProfileRequest request) async {
    try {
      requireAuth();

      logApiCall('PUT', '/api/auth/profile', params: request.toJson());

      final updateData = request.toJson();
      updateData['updated_at'] = DateTime.now().toIso8601String();

      final profile = await client
          .from('profiles')
          .update(updateData)
          .eq('id', userId)
          .select()
          .single();

      final user = UserModel.fromJson(profile);

      // Update SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', user.name);
      if (user.phone.isNotEmpty) {
        await prefs.setString('user_phone', user.phone);
      }

      logApiResponse('/api/auth/profile', user);

      return user;
    } catch (e) {
      throw handleError(e,
          customMessage: 'Update profile gagal: ${e.toString()}');
    }
  }
}
