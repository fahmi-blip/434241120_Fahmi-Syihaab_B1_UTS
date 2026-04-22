import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MockAuthRepository {
  static const String _usersKey = 'mock_users';

  // Static variables supaya semua instance pakai data yang sama
  static List<Map<String, dynamic>> _mockUsers = [];
  static Map<String, dynamic>? _currentUser;

  /// Initialize default users jika belum ada
  Future<void> _initUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);

    if (usersJson != null) {
      MockAuthRepository._mockUsers = (json.decode(usersJson) as List)
          .cast<Map<String, dynamic>>();
    } else {
      // Default users pertama kali
      MockAuthRepository._mockUsers = [
        // ==================== USERS ====================
        {
          'id': 'user-1',
          'name': 'Budi Santoso',
          'email': 'user@demo.com',
          'password': 'demo123',
          'role': 'user',
        },
        {
          'id': 'user-2',
          'name': 'Ani Wijaya',
          'email': 'ani@demo.com',
          'password': 'demo123',
          'role': 'user',
        },
        {
          'id': 'user-3',
          'name': 'Dewi Lestari',
          'email': 'dewi@demo.com',
          'password': 'demo123',
          'role': 'user',
        },
        {
          'id': 'user-4',
          'name': 'Rudi Hartono',
          'email': 'rudi@demo.com',
          'password': 'demo123',
          'role': 'user',
        },
        {
          'id': 'user-5',
          'name': 'Sari Purnama',
          'email': 'sari@demo.com',
          'password': 'demo123',
          'role': 'user',
        },
        // ==================== HELPDESK ====================
        {
          'id': 'helpdesk-1',
          'name': 'Siti Helpdesk',
          'email': 'helpdesk@demo.com',
          'password': 'demo123',
          'role': 'helpdesk',
        },
        {
          'id': 'helpdesk-2',
          'name': 'Agus Staff',
          'email': 'agus@demo.com',
          'password': 'demo123',
          'role': 'helpdesk',
        },
        {
          'id': 'helpdesk-3',
          'name': 'Rina Support',
          'email': 'rina@demo.com',
          'password': 'demo123',
          'role': 'helpdesk',
        },
        // ==================== ADMIN ====================
        {
          'id': 'admin-1',
          'name': 'Admin Helpdesk',
          'email': 'admin@demo.com',
          'password': 'demo123',
          'role': 'admin',
        },
      ];
      await _saveUsers();
    }
  }

  Future<void> _saveUsers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, json.encode(MockAuthRepository._mockUsers));
  }

  /// Login dengan email & password
  Future<Map<String, dynamic>> login(String email, String password) async {
    await _initUsers();
    await Future.delayed(const Duration(milliseconds: 500));

    final user = MockAuthRepository._mockUsers.firstWhere(
      (u) => u['email'] == email && u['password'] == password,
      orElse: () => throw Exception('Email atau password salah'),
    );

    MockAuthRepository._currentUser = user;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', 'mock-token-${user['id']}');
    await prefs.setString('user_id', user['id']);
    await prefs.setString('user_email', user['email']);
    await prefs.setString('user_name', user['name']);
    await prefs.setString('user_role', user['role']);

    return {
      'token': 'mock-token-${user['id']}',
      'user': UserModel(
        id: user['id'],
        name: user['name'],
        email: user['email'],
        role: user['role'],
        createdAt: DateTime.now(),
      ),
    };
  }

  /// Register user baru
  Future<UserModel> register(String name, String email, String password) async {
    await _initUsers();
    await Future.delayed(const Duration(milliseconds: 500));

    final existing = MockAuthRepository._mockUsers.any((u) => u['email'] == email);
    if (existing) {
      throw Exception('Email sudah terdaftar');
    }

    final newUser = {
      'id': 'user-${DateTime.now().millisecondsSinceEpoch}',
      'name': name,
      'email': email,
      'password': password,
      'role': 'user',
    };

    MockAuthRepository._mockUsers.add(newUser);
    await _saveUsers();

    return UserModel(
      id: newUser['id'] as String,
      name: name,
      email: email,
      role: 'user',
      createdAt: DateTime.now(),
    );
  }

  /// Reset password (mock)
  Future<void> resetPassword(String email) async {
    await _initUsers();
    await Future.delayed(const Duration(milliseconds: 300));
    final exists = MockAuthRepository._mockUsers.any((u) => u['email'] == email);
    if (!exists) {
      throw Exception('Email tidak ditemukan');
    }
  }

  /// Logout
  Future<void> logout() async {
    MockAuthRepository._currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_role');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
  }

  /// Get current user
  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final name = prefs.getString('user_name');
    final email = prefs.getString('user_email');
    final role = prefs.getString('user_role');

    if (userId == null) return null;

    return UserModel(
      id: userId,
      name: name ?? 'User',
      email: email ?? '',
      role: role ?? 'user',
      createdAt: DateTime.now(),
    );
  }

  /// Get token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Get role
  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  /// Get user ID
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  /// Get user name
  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name');
  }

  /// Get user email
  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  /// Check if logged in
  bool get isLoggedIn => MockAuthRepository._currentUser != null;

  /// Refresh session (mock)
  Future<void> refreshSession() async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  /// Clear all data (untuk testing/reset)
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usersKey);
    await prefs.remove('tickets');
    await prefs.remove('notifications');
    await prefs.remove('ticket_history');
    MockAuthRepository._mockUsers = [];
    MockAuthRepository._currentUser = null;
  }
}
