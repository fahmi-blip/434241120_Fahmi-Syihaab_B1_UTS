import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/api_client.dart';
import '../../core/services/supabase_service.dart';
import '../models/user_model.dart';

class SupabaseAuthRepository {
  /// Login dengan email & password via REST API
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await ApiClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.data['success'] == true) {
        final resData = response.data['data'];
        final token = resData['token']?.toString() ?? '';
        final user = UserModel.fromJson(resData['user'] as Map<String, dynamic>);

        // Simpan session ke cache memori SupabaseService
        await SupabaseService.cacheSession(user.id, user.role);

        // Simpan ke SharedPreferences untuk akses cepat
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', user.id);
        await prefs.setString('user_name', user.name);
        await prefs.setString('user_email', user.email);
        await prefs.setString('user_role', user.role);
        await prefs.setString('auth_token', token);

        return {'token': token, 'user': user};
      } else {
        throw Exception(response.data['message'] ?? 'Login gagal');
      }
    } catch (e) {
      print('❌ login error: $e');
      throw Exception('Email atau password salah');
    }
  }

  /// Register user baru via REST API
  Future<UserModel> register(String name, String email, String password) async {
    try {
      final response = await ApiClient.dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
      });

      if (response.data['success'] == true) {
        final resData = response.data['data']['user'];
        return UserModel.fromJson(resData as Map<String, dynamic>);
      } else {
        throw Exception(response.data['message'] ?? 'Registrasi gagal');
      }
    } catch (e) {
      print('❌ register error: $e');
      throw Exception('Registrasi gagal. Email mungkin sudah terdaftar.');
    }
  }

  /// Logout via REST API
  Future<void> logout() async {
    try {
      await ApiClient.dio.post('/auth/logout');
    } catch (e) {
      print('⚠️ Server logout warning: $e');
    } finally {
      // Selalu bersihkan cache session lokal sekalipun request server error
      await SupabaseService.clearCache();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    }
  }

  /// Reset password via email via REST API
  Future<void> resetPassword(String email) async {
    try {
      await ApiClient.dio.post('/auth/reset-password', data: {
        'email': email,
      });
    } catch (e) {
      print('❌ resetPassword error: $e');
      throw Exception('Reset password gagal. Email tidak ditemukan.');
    }
  }

  /// Cek apakah sudah login (dengan mengecek token lokal)
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token != null && token.isNotEmpty;
  }

  /// Ambil data current user dari server REST API
  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await ApiClient.dio.get('/auth/me');
      if (response.data['success'] == true) {
        final userMap = response.data['data'] as Map<String, dynamic>;
        return UserModel.fromJson(userMap);
      }
    } catch (e) {
      print('⚠️ Fetch getCurrentUser from server failed: $e. Fallback to cache.');
    }

    // Fallback: Membaca dari SharedPreferences lokal jika server tidak terjangkau
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final name = prefs.getString('user_name');
      final email = prefs.getString('user_email');
      final role = prefs.getString('user_role');

      if (userId != null && name != null && email != null) {
        return UserModel(
          id: userId,
          name: name,
          email: email,
          role: role ?? 'user',
          createdAt: DateTime.now(),
        );
      }
    } catch (_) {}

    return null;
  }

  // Helpers untuk SharedPreferences
  Future<String?> getRole() async =>
      (await SharedPreferences.getInstance()).getString('user_role');
  Future<String?> getUserId() async =>
      (await SharedPreferences.getInstance()).getString('user_id');
  Future<String?> getUserName() async =>
      (await SharedPreferences.getInstance()).getString('user_name');
  Future<String?> getUserEmail() async =>
      (await SharedPreferences.getInstance()).getString('user_email');
}
