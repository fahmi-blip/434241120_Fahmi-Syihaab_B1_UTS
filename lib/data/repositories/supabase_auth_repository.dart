import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../../core/services/supabase_service.dart';

class SupabaseAuthRepository {
  final _client = SupabaseService.client;

  /// Login dengan email & password
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (res.user == null) throw Exception('Login gagal');

    // Ambil profile dari tabel profiles
    final profile =
        await _client.from('profiles').select().eq('id', res.user!.id).single();

    final user = UserModel.fromJson(profile);

    // Simpan ke SharedPreferences untuk akses cepat
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', user.id);
    await prefs.setString('user_name', user.name);
    await prefs.setString('user_email', user.email);
    await prefs.setString('user_role', user.role);
    await prefs.setString('auth_token', res.session?.accessToken ?? '');

    return {'token': res.session?.accessToken ?? '', 'user': user};
  }

  /// Register user baru
  Future<UserModel> register(String name, String email, String password) async {
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'role': 'user'},
    );

    if (res.user == null) throw Exception('Registrasi gagal');

    // Tunggu trigger handle_new_user selesai
    await Future.delayed(const Duration(milliseconds: 500));

    final profile =
        await _client.from('profiles').select().eq('id', res.user!.id).single();

    return UserModel.fromJson(profile);
  }

  /// Logout
  Future<void> logout() async {
    await _client.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Reset password via email
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Cek apakah sudah login (dari session Supabase)
  Future<bool> isLoggedIn() async {
    final session = _client.auth.currentSession;
    return session != null && !session.isExpired;
  }

  /// Ambil current user
  Future<UserModel?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final profile =
          await _client.from('profiles').select().eq('id', user.id).single();
      return UserModel.fromJson(profile);
    } catch (_) {
      return null;
    }
  }

  // Helpers for SharedPreferences
  Future<String?> getRole() async =>
      (await SharedPreferences.getInstance()).getString('user_role');
  Future<String?> getUserId() async =>
      (await SharedPreferences.getInstance()).getString('user_id');
  Future<String?> getUserName() async =>
      (await SharedPreferences.getInstance()).getString('user_name');
  Future<String?> getUserEmail() async =>
      (await SharedPreferences.getInstance()).getString('user_email');
}
