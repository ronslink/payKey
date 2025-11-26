import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/api_client.dart';
import '../models/time_tracking_model.dart';

final timeTrackingRepositoryProvider = Provider<TimeTrackingRepository>((ref) {
  return TimeTrackingRepository(
    ref.read(apiClientProvider),
    const FlutterSecureStorage(),
  );
});

class TimeTrackingRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  TimeTrackingRepository(this._dio, this._storage);

  Future<TimeEntry> clockIn(ClockInRequest request) async {
    try {
      final token = await _storage.read(key: 'access_token');
      final response = await _dio.post(
        '/time-tracking/clock-in',
        data: request.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return TimeEntry.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<TimeEntry> clockOut(ClockOutRequest request) async {
    try {
      final token = await _storage.read(key: 'access_token');
      final response = await _dio.post(
        '/time-tracking/clock-out',
        data: request.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return TimeEntry.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<TimeEntry?> getActiveEntry(String workerId) async {
    try {
      final token = await _storage.read(key: 'access_token');
      final response = await _dio.get(
        '/time-tracking/active',
        queryParameters: {'workerId': workerId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data != null ? TimeEntry.fromJson(response.data) : null;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        return null;
      }
      throw _handleError(e);
    }
  }

  Future<List<TimeEntry>> getTimeEntries({
    String? workerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final token = await _storage.read(key: 'access_token');
      final queryParams = <String, dynamic>{};
      if (workerId != null) queryParams['workerId'] = workerId;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final response = await _dio.get(
        '/time-tracking/entries',
        queryParameters: queryParams,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return (response.data as List)
          .map((json) => TimeEntry.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        return Exception(error.response?.data['message'] ?? 'An error occurred');
      }
      return Exception(error.message);
    }
    return Exception(error.toString());
  }
}
