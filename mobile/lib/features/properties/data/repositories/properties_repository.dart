import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../models/property_model.dart';

final propertiesRepositoryProvider = Provider<PropertiesRepository>((ref) {
  return PropertiesRepository(ApiService().dio);
});

class PropertiesRepository {
  final Dio _dio;

  PropertiesRepository(this._dio);

  Future<List<PropertyModel>> getProperties() async {
    try {
      final response = await _dio.get('/properties');
      return (response.data as List)
          .map((e) => PropertyModel.fromJson(e))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<PropertyModel>> getPropertySummaries() async {
    try {
      final response = await _dio.get('/properties/summaries');
      return (response.data as List)
          .map((e) => PropertyModel.fromJson(e))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<PropertyModel> getProperty(String id) async {
    try {
      final response = await _dio.get('/properties/$id');
      return PropertyModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<PropertyModel> createProperty(CreatePropertyRequest request) async {
    try {
      final response = await _dio.post(
        '/properties',
        data: request.toJson(),
      );
      return PropertyModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<PropertyModel> updateProperty(String id, UpdatePropertyRequest request) async {
    try {
      final response = await _dio.patch(
        '/properties/$id',
        data: request.toJson(),
      );
      return PropertyModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteProperty(String id) async {
    try {
      await _dio.delete('/properties/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic e) {
    if (e is DioException) {
      return Exception(e.response?.data['message'] ?? 'Network error occurred');
    }
    return Exception(e.toString());
  }
}
