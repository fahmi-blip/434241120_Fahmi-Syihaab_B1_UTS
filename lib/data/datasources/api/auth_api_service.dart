// import 'package:dio/dio.dart';

// final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api'));

// Future<AuthResponse> login(LoginRequest request) async {
//   // Melakukan POST request ke REST API Express.js
//   final response = await dio.post('/auth/login', data: {
//     'email': request.email,
//     'password': request.password,
//   });

//   if (response.statusCode == 200) {
//     final data = response.data['data'];
//     final token = data['token'];
//     final user = UserModel.fromJson(data['user']);
    
//     // Simpan token ke SharedPreferences untuk request berikutnya
//     await saveAuthToken(token);
    
//     return AuthResponse(token: token, user: user);
//   } else {
//     throw Exception('Login gagal');
//   }
// }