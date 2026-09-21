import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/time_entry_model.dart';
import '../../data/repositories/time_tracking_repository.dart';

final timeTrackingProvider =
    AsyncNotifierProvider<TimeTrackingNotifier, TimeEntryModel?>(
        TimeTrackingNotifier.new);

// Provider for all time entries (Dashboard Overview)
final allTimeEntriesProvider =
    AsyncNotifierProvider<TimeEntriesNotifier, List<TimeEntryModel>>(
        TimeEntriesNotifier.new);

// Provider for specific worker entries (Drill Down)
final workerTimeEntriesProvider =
    AsyncNotifierProvider<TimeEntriesNotifier, List<TimeEntryModel>>(
        TimeEntriesNotifier.new);

// Legacy provider (keep for backward compatibility if needed, or deprecate)
final timeEntriesProvider =
    AsyncNotifierProvider<TimeEntriesNotifier, List<TimeEntryModel>>(
        TimeEntriesNotifier.new);

class TimeTrackingNotifier extends AsyncNotifier<TimeEntryModel?> {
  late TimeTrackingRepository _repository;

  @override
  FutureOr<TimeEntryModel?> build() {
    _repository = ref.watch(timeTrackingRepositoryProvider);
    return null;
  }

  Future<void> getActiveEntry(String workerId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        return await _repository.getActiveEntry(workerId);
      } on TimeTrackingException catch (e) {
        if (e.isNetworkError) return null;
        rethrow;
      }
    });
  }

  /// Record hours for a worker. The hours arrive in payroll as PENDING.
  Future<TimeEntryModel?> createEntry({
    required String workerId,
    required DateTime clockIn,
    required DateTime clockOut,
    int? breakMinutes,
    String? notes,
  }) async {
    TimeEntryModel? created;
    state = await AsyncValue.guard(() async {
      created = await _repository.createEntry(
        workerId: workerId,
        clockIn: clockIn,
        clockOut: clockOut,
        breakMinutes: breakMinutes,
        notes: notes,
      );
      return created;
    });
    return created;
  }

  /// Correct an existing entry; its payroll decision returns to PENDING.
  Future<TimeEntryModel?> correctEntry(
    String entryId, {
    DateTime? clockIn,
    DateTime? clockOut,
    int? breakMinutes,
    required String reason,
  }) async {
    TimeEntryModel? corrected;
    state = await AsyncValue.guard(() async {
      corrected = await _repository.correctEntry(
        entryId,
        clockIn: clockIn,
        clockOut: clockOut,
        breakMinutes: breakMinutes,
        reason: reason,
      );
      return corrected;
    });
    return corrected;
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

class TimeEntriesNotifier extends AsyncNotifier<List<TimeEntryModel>> {
  late TimeTrackingRepository _repository;

  @override
  FutureOr<List<TimeEntryModel>> build() {
    _repository = ref.watch(timeTrackingRepositoryProvider);
    return [];
  }

  Future<void> fetchTimeEntries({
    String? workerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        return await _repository.getTimeEntries(
          workerId: workerId,
          startDate: startDate,
          endDate: endDate,
        );
      } on TimeTrackingException catch (e) {
        if (e.isNetworkError) return <TimeEntryModel>[];
        rethrow;
      }
    });
  }

  void reset() {
    state = const AsyncValue.data([]);
  }
}
