import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/utils/api_date_range.dart';
import '../mock/time_tracking_mock_data.dart';
import '../models/time_entry_model.dart';

final timeTrackingRepositoryProvider = Provider<TimeTrackingRepository>((ref) {
  return TimeTrackingRepository();
});

/// Time-tracking data layer used by the employer screens.
///
/// Every call is worker-scoped, because that is what the API exposes:
///
///   POST /time-tracking/clock-in/:workerId
///   POST /time-tracking/clock-out/:workerId
///   GET  /time-tracking/status/:workerId
///   GET  /time-tracking/entries/:workerId
///   GET  /time-tracking/entries
///
/// There is no `/time-tracking/active` route, so "is this worker on the clock?"
/// is answered with `/status/:workerId`
/// (`{ isClockedIn, currentEntry, todayTotal }`).
///
/// A 403 response means the employer's plan does not include time tracking;
/// preview (mock) data is returned so the screen still renders.
class TimeTrackingRepository {
  ApiService get _api => ApiService();

  /// The worker's open entry, or null when the worker is not clocked in.
  Future<TimeEntryModel?> getActiveEntry(String workerId) async {
    try {
      final response = await _api.timeTracking.getStatus(workerId);
      final data = response.data;
      if (data is! Map<String, dynamic>) return null;
      return ClockStatus.fromJson(data).currentEntry;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        return TimeTrackingMockData.getActiveEntry(workerId);
      }
      // An unknown worker means "not clocked in" rather than an error.
      if (e.response?.statusCode == 404) return null;
      throw _handleDioError(e);
    } catch (e) {
      if (e is TimeTrackingException) rethrow;
      throw TimeTrackingException('Failed to check clock-in status: $e');
    }
  }

  /// Clock a worker in.
  ///
  /// Location is best effort: the API only rejects a clock-in without
  /// coordinates when the employer's plan enables geofencing for the property.
  Future<TimeEntryModel> clockIn(
    String workerId, {
    double? lat,
    double? lng,
  }) async {
    try {
      final response = await _api.timeTracking.clockIn(
        workerId,
        lat: lat,
        lng: lng,
      );
      return _entryFrom(response.data, 'clock-in');
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw const TimeTrackingException(
          'The PLATINUM plan is required to use time tracking',
          statusCode: 403,
        );
      }
      throw _handleDioError(e);
    } catch (e) {
      if (e is TimeTrackingException) rethrow;
      throw TimeTrackingException('Failed to clock in: $e');
    }
  }

  /// Clock a worker out. The API finds the worker's open entry itself, so
  /// clock-out is addressed by worker rather than by time entry.
  Future<TimeEntryModel> clockOut(
    String workerId, {
    int? breakMinutes,
    String? notes,
    double? lat,
    double? lng,
  }) async {
    try {
      final response = await _api.timeTracking.clockOut(
        workerId,
        breakMinutes: breakMinutes,
        notes: notes,
        lat: lat,
        lng: lng,
      );
      return _entryFrom(response.data, 'clock-out');
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw const TimeTrackingException(
          'The PLATINUM plan is required to use time tracking',
          statusCode: 403,
        );
      }
      throw _handleDioError(e);
    } catch (e) {
      if (e is TimeTrackingException) rethrow;
      throw TimeTrackingException('Failed to clock out: $e');
    }
  }

  /// Time entries for one worker, or for the whole business when [workerId] is
  /// null. With no range the last 30 days are used, because the API requires
  /// both bounds. Bounds are widened to whole local days and sent as UTC
  /// instants — see [ApiDateRange].
  Future<List<TimeEntryModel>> getTimeEntries({
    String? workerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final endDay = endDate ?? DateTime.now();
    final startDay = startDate ?? endDay.subtract(const Duration(days: 30));
    final start = ApiDateRange.startOfDay(startDay);
    final end = ApiDateRange.endOfDay(endDay);
    try {
      final Response response = workerId != null
          ? await _api.timeTracking.getEntriesForWorker(
              workerId,
              startDate: start,
              endDate: end,
            )
          : await _api.timeTracking.getAllEntries(
              startDate: start,
              endDate: end,
            );

      final data = response.data;
      if (data is! List) return [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(TimeEntryModel.fromJson)
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        return workerId != null
            ? TimeTrackingMockData.getEntriesForWorker(workerId)
            : TimeTrackingMockData.timeEntries;
      }
      throw _handleDioError(e);
    } catch (e) {
      if (e is TimeTrackingException) rethrow;
      throw TimeTrackingException('Failed to get time entries: $e');
    }
  }

  TimeEntryModel _entryFrom(Object? data, String action) {
    if (data is! Map<String, dynamic>) {
      throw TimeTrackingException('No data received from $action request');
    }
    return TimeEntryModel.fromJson(data);
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
      } else if (data is String && data.isNotEmpty) {
        message = data;
      }

      return TimeTrackingException(
        message,
        statusCode: error.response?.statusCode,
      );
    }

    if (_isNetworkError(error)) {
      return const TimeTrackingException(
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

  const TimeTrackingException(
    this.message, {
    this.statusCode,
    this.isNetworkError = false,
  });

  @override
  String toString() => message;
}
