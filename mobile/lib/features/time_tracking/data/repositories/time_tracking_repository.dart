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

  /// Record time for a worker.
  ///
  /// Only the employee can clock themselves in; the employer records the hours
  /// they know about. The API keeps these hours PENDING for payroll so they are
  /// paid only once the employer decides to include them.
  Future<TimeEntryModel> createEntry({
    required String workerId,
    required DateTime clockIn,
    required DateTime clockOut,
    int? breakMinutes,
    String? notes,
  }) async {
    try {
      final response = await _api.timeTracking.createEntry(
        workerId: workerId,
        clockIn: clockIn.toUtc().toIso8601String(),
        clockOut: clockOut.toUtc().toIso8601String(),
        breakMinutes: breakMinutes,
        notes: notes,
      );
      return _entryFrom(response.data, 'time entry');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is TimeTrackingException) rethrow;
      throw TimeTrackingException('Failed to record time: $e');
    }
  }

  /// Correct an existing entry. The API recalculates the hours and the entry
  /// returns to PENDING, because the earlier payroll decision was about
  /// different numbers.
  Future<TimeEntryModel> correctEntry(
    String entryId, {
    DateTime? clockIn,
    DateTime? clockOut,
    int? breakMinutes,
    required String reason,
  }) async {
    try {
      final response = await _api.timeTracking.adjustEntry(
        entryId,
        clockIn: clockIn?.toUtc().toIso8601String(),
        clockOut: clockOut?.toUtc().toIso8601String(),
        breakMinutes: breakMinutes,
        reason: reason,
      );
      return _entryFrom(response.data, 'correction');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is TimeTrackingException) rethrow;
      throw TimeTrackingException('Failed to correct the entry: $e');
    }
  }

  /// What payroll would pay for a period, and what still needs a decision.
  Future<PayrollReview> getPayrollReview({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _api.timeTracking.getPayrollReview(
        startDate: ApiDateRange.startOfDay(startDate),
        endDate: ApiDateRange.endOfDay(endDate),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) return const PayrollReview();
      return PayrollReview.fromJson(data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is TimeTrackingException) rethrow;
      throw TimeTrackingException('Failed to load the payroll review: $e');
    }
  }

  /// Include or exclude entries from payroll. Returns how many were updated.
  Future<int> decidePayroll({
    required List<String> entryIds,
    required bool include,
  }) async {
    try {
      final response = await _api.timeTracking.decidePayroll(
        entryIds: entryIds,
        decision: include ? 'INCLUDED' : 'EXCLUDED',
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return (data['updated'] as num?)?.toInt() ?? entryIds.length;
      }
      return entryIds.length;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is TimeTrackingException) rethrow;
      throw TimeTrackingException('Failed to save the payroll decision: $e');
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
