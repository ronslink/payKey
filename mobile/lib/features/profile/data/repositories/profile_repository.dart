
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/api_client.dart';
import '../models/profile_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    dio: ref.read(apiClientProvider),
    storage: const FlutterSecureStorage(),
  );
});

class ProfileRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  ProfileRepository({required Dio dio, required FlutterSecureStorage storage})
      : _dio = dio,
        _storage = storage;

  Future<String?> _getToken() => _storage.read(key: 'access_token');

  Future<ProfileModel> getProfile() async {
    final token = await _getToken();
    final response = await _dio.get(
      '/users/profile',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ProfileModel.fromJson(response.data);
  }

  Future<void> updateComplianceProfile(Map<String, dynamic> data) async {
    final token = await _getToken();
    await _dio.patch(
      '/users/compliance',
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}
