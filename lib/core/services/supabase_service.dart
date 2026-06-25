import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupabaseService {
  static String? _cachedUserId;
  static String? _cachedRole;

  // Dummy client to prevent compilation errors in unused legacy files
  static get client => null;

  static Future<void> initialize() async {
    // Load environment variables (.env)
    await dotenv.load(fileName: '.env');
    
    // Load cached session data from SharedPreferences
    await loadCachedSession();
  }

  // Session state getters
  static bool get isAuthenticated => _cachedUserId != null && _cachedUserId!.isNotEmpty;
  static String? get currentUserId => _cachedUserId;
  static String? get currentUserRole => _cachedRole;

  // Session helper methods
  static Future<void> cacheSession(String userId, String role) async {
    _cachedUserId = userId;
    _cachedRole = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    await prefs.setString('user_role', role);
  }

  static Future<void> loadCachedSession() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedUserId = prefs.getString('user_id');
    _cachedRole = prefs.getString('user_role');
  }

  static Future<void> clearCache() async {
    _cachedUserId = null;
    _cachedRole = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_role');
  }
}