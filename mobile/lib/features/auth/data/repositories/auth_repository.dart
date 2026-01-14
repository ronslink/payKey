import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

class AuthRepository {
  final ApiService _apiService = ApiService();

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _apiService.login(request.email, request.password);
      final data = response.data;
      
      await _apiService.saveToken(data['access_token']);
      
      return LoginResponse(
        accessToken: data['access_token'],
      );
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<LoginResponse> register(RegisterRequest request) async {
    try {
      final response = await _apiService.register(
        request.email,
        request.password,
        firstName: request.firstName,
        lastName: request.lastName,
      );
      final data = response.data;
      
      await _apiService.saveToken(data['access_token']);
      
      return LoginResponse(
        accessToken: data['access_token'],
      );
    } on DioException catch (e) {
      throw Exception(_apiService.getErrorMessage(e));
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  Future<void> logout() async {
    await _apiService.clearToken();
  }

  // Direct API methods for auth provider compatibility
  Future<Response> loginApi(String email, String password) async {
    return _apiService.login(email, password);
  }

  Future<Response> registerApi(String email, String password, String firstName, String lastName) async {
    return _apiService.register(email, password, firstName: firstName, lastName: lastName);
  }

  Future<Response> socialLoginApi({
    required String provider,
    required String token,
    required String email,
    String? firstName,
    String? lastName,
    String? photoUrl,
  }) async {
    return _apiService.auth.socialLogin(
      provider: provider,
      token: token,
      email: email,
      firstName: firstName,
      lastName: lastName,
      photoUrl: photoUrl,
    );
  }

  Future<void> saveToken(String token) async {
    await _apiService.saveToken(token);
  }

  Future<void> clearToken() async {
    await _apiService.clearToken();
  }
}
