import 'package:dio/dio.dart';
import '../api_service.dart';

extension AuthService on ApiService {
  Future<Response> login(String email, String password) async {
    final loginData = {
      'email': email,
      'password': password,
    };
    try {
      final response = await dio.post('/auth/login', data: loginData);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> register(String email, String password, {String? firstName, String? lastName}) async {
    return dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
    });
  }

  Future<Response> updateUserProfile(Map<String, dynamic> data) async {
    return dio.patch('/users/profile', data: data);
  }

  // Token management
  Future<void> saveToken(String token) async {
    await secureStorage.write(key: 'access_token', value: token);
  }

  Future<void> clearToken() async {
    await secureStorage.delete(key: 'access_token');
  }

  Future<String?> getToken() async {
    return await secureStorage.read(key: 'access_token');
  }
}
