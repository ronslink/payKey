import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../models/property_model.dart';
import '../mock/property_mock_data.dart';

final propertiesRepositoryProvider = Provider<PropertiesRepository>((ref) {
  return PropertiesRepository(ApiService().dio);
});

/// Repository for properties with 403 fallback to mock data.
/// 
/// When the user doesn't have PLATINUM subscription, the backend returns 403.
/// This repository catches those errors and returns mock data for preview mode.
class PropertiesRepository {
  final Dio _dio;

  /// Feature key for gating
  static const String featureKey = 'property_management';

  PropertiesRepository(this._dio);

  Future<List<PropertyModel>> getProperties({String status = 'all'}) async {
    try {
      final response = await _dio.get(
        '/properties',
        queryParameters: {'status': status},
      );
      return (response.data as List)
          .map((e) => PropertyModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        print('[$featureKey] 403 Forbidden - returning mock properties');
        return PropertyMockData.properties;
      }
      throw _handleError(e);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<PropertyModel>> getPropertySummaries({String status = 'all'}) async {
    try {
      final response = await _dio.get(
        '/properties/summaries',
        queryParameters: {'status': status},
      );
      return (response.data as List)
          .map((e) => PropertyModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        print('[$featureKey] 403 Forbidden - returning mock property summaries');
        return PropertyMockData.properties;
      }
      throw _handleError(e);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<PropertyModel> getProperty(String id) async {
    try {
      final response = await _dio.get('/properties/$id');
      return PropertyModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        print('[$featureKey] 403 Forbidden - returning mock property');
        return PropertyMockData.getProperty(id);
      }
      throw _handleError(e);
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
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('Upgrade to PLATINUM to create properties');
      }
      throw _handleError(e);
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
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('Upgrade to PLATINUM to update properties');
      }
      throw _handleError(e);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteProperty(String id) async {
    try {
      await _dio.delete('/properties/$id');
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('Upgrade to PLATINUM to delete properties');
      }
      throw _handleError(e);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<PropertyModel> restoreProperty(String id) async {
    try {
      final response = await _dio.post('/properties/$id/restore');
      return PropertyModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('Upgrade to PLATINUM to restore properties');
      }
      throw _handleError(e);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> permanentlyDeleteProperty(String id) async {
    try {
      await _dio.delete('/properties/$id/permanent');
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('Upgrade to PLATINUM to permanently delete properties');
      }
      throw _handleError(e);
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
