import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static late final Dio dio;

  static Future<void> initialize() async {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api';
    print('🌐 Initializing ApiClient with Base URL: $baseUrl');

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
            print('🔑 Bearer token appended to request: ${options.path}');
          }

          print('📡 ApiClient Request: ${options.method} ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('✅ ApiClient Response: ${response.statusCode} for ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          print('❌ ApiClient Error: ${error.response?.statusCode} - ${error.message}');
          print('❌ Error details: ${error.response?.data}');
          return handler.next(error);
        },
      ),
    );
  }
}
