import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_provider.dart';
import '../models/property_model.dart';

final propertiesRepositoryProvider = Provider<PropertiesRepository>((ref) {
  return PropertiesRepository(ref.read(dioProvider));
});

class PropertiesRepository {
  final Dio _dio;

  PropertiesRepository(this._dio);

  Future<List<Property>> getProperties() async {
    try {
      final response = await _dio.get('/properties');
      return (response.data as List)
          .map((e) => Property.fromJson(e))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<PropertySummary>> getPropertySummaries() async {
    try {
      final response = await _dio.get('/properties/summaries');
      return (response.data as List)
          .map((e) => PropertySummary.fromJson(e))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Property> getProperty(String id) async {
    try {
      final response = await _dio.get('/properties/$id');
      return Property.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Property> createProperty(CreatePropertyRequest request) async {
    try {
      final response = await _dio.post(
        '/properties',
        data: request.toJson(),
      );
      return Property.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Property> updateProperty(String id, UpdatePropertyRequest request) async {
    try {
      final response = await _dio.patch(
        '/properties/$id',
        data: request.toJson(),
      );
      return Property.fromJson(response.data);
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
