import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_ticketing_helpdesk/core/services/supabase_service.dart';

/// Base API Service - Menyediakan helper methods untuk semua API service
///
/// Handles:
/// - Error handling & logging
/// - Token management
/// - Response validation
/// - Retry logic
abstract class BaseApiService {
  /// Supabase client instance
  final _client = SupabaseService.client;

  /// Get Supabase client
  get client => _client;

  /// Get current user ID
  String get userId => SupabaseService.currentUserId ?? '';

  /// Get current auth token
  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Save auth token
  Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  /// Get current user role
  Future<String> getUserRole() async {
    try {
      final profile = await _client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();
      return profile['role'] as String? ?? 'user';
    } catch (e) {
      return 'user';
    }
  }

  /// Validate if user is authenticated
  bool isAuthenticated() {
    return SupabaseService.isAuthenticated;
  }

  /// Throw exception if not authenticated
  void requireAuth() {
    if (!isAuthenticated()) {
      throw Exception('User is not authenticated. Please login first.');
    }
  }

  /// Handle API error
  Exception handleError(dynamic error, {String? customMessage}) {
    final message = customMessage ?? error.toString();
    print('❌ API Error: $message');
    return Exception(message);
  }

  /// Log API call
  void logApiCall(String method, String endpoint,
      {Map<String, dynamic>? params}) {
    print('📡 API Call: $method $endpoint');
    if (params != null) {
      print('📦 Params: $params');
    }
  }

  /// Log API response
  void logApiResponse(String endpoint, dynamic response) {
    print('✅ API Response: $endpoint');
    if (response is List) {
      print('📊 Response count: ${response.length}');
    }
  }
}
