import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../models/time_tracking_model.dart';

final timeTrackingRepositoryProvider = Provider<TimeTrackingRepository>((ref) {
  return TimeTrackingRepository(ApiService());
});

class TimeTrackingRepository {
  final ApiService _apiService;

  TimeTrackingRepository(this._apiService);

  Future<TimeEntry> clockIn(ClockInRequest request) async {
    try {
      final response = await _apiService.post(
        '/time-tracking/clock-in',
        data: request.toJson(),
      );

      final data = response.data;
      if (data == null) {
        throw TimeTrackingException('No data received from clock-in request');
      }

      return TimeEntry.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is TimeTrackingException) rethrow;
      throw TimeTrackingException('Failed to clock in: ${e.toString()}');
    }
  }

  Future<TimeEntry> clockOut(ClockOutRequest request) async {
    try {
      final response = await _apiService.post(
        '/time-tracking/clock-out',
        data: request.toJson(),
      );

      final data = response.data;
      if (data == null) {
        throw TimeTrackingException('No data received from clock-out request');
      }

      return TimeEntry.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is TimeTrackingException) rethrow;
      throw TimeTrackingException('Failed to clock out: ${e.toString()}');
    }
  }

  Future<TimeEntry?> getActiveEntry(String workerId) async {
    try {
      final response = await _apiService.get(
        '/time-tracking/active',
        queryParams: {'workerId': workerId},
      );

      final data = response.data;
      if (data == null) {
        return null;
      }

      return TimeEntry.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      // 404 means no active entry exists - this is expected
      if (e.response?.statusCode == 404) {
        return null;
      }

      // For timeout/connection errors, throw with network flag
      if (_isNetworkError(e)) {
        throw TimeTrackingException(
          'Unable to check active entry. Please check your connection.',
          isNetworkError: true,
        );
      }

      throw _handleDioError(e);
    } catch (e) {
      if (e is TimeTrackingException) rethrow;
      throw TimeTrackingException('Failed to get active entry: ${e.toString()}');
    }
  }

  Future<List<TimeEntry>> getTimeEntries({
    String? workerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (workerId != null) queryParams['workerId'] = workerId;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final response = await _apiService.get(
        '/time-tracking/entries',
        queryParams: queryParams,
      );

      final data = response.data;
      if (data == null) {
        return [];
      }

      if (data is! List) {
        throw TimeTrackingException('Invalid response format: expected list');
      }

      return data
          .map((json) => TimeEntry.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is TimeTrackingException) rethrow;
      throw TimeTrackingException('Failed to get time entries: ${e.toString()}');
    }
  }

  bool _isNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError;
  }

  TimeTrackingException _handleDioError(DioException error) {
    if (error.response != null) {
      final data = error.response?.data;
      String message = 'An error occurred';

      if (data is Map<String, dynamic>) {
        message = data['message'] as String? ?? message;
      }

      return TimeTrackingException(
        message,
        statusCode: error.response?.statusCode,
      );
    }

    if (_isNetworkError(error)) {
      return TimeTrackingException(
        'Network error. Please check your connection.',
        isNetworkError: true,
      );
    }

    return TimeTrackingException(
      error.message ?? 'An unexpected error occurred',
    );
  }
}

/// Custom exception for time tracking operations
class TimeTrackingException implements Exception {
  final String message;
  final int? statusCode;
  final bool isNetworkError;

  TimeTrackingException(
    this.message, {
    this.statusCode,
    this.isNetworkError = false,
  });

  @override
  String toString() => message;
}