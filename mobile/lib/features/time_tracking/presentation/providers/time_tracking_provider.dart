import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/utils/location_utils.dart';
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

  Future<void> clockIn(String workerId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final position = await _tryGetCurrentLocation();
      return _repository.clockIn(
        workerId,
        lat: position?.latitude,
        lng: position?.longitude,
      );
    });
  }

  Future<void> clockOut(String workerId, {String? notes}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final position = await _tryGetCurrentLocation();
      await _repository.clockOut(
        workerId,
        notes: notes,
        lat: position?.latitude,
        lng: position?.longitude,
      );
      // The worker is no longer on the clock, so the card must offer CLOCK IN
      // again instead of showing the entry that was just completed.
      return null;
    });
  }

  /// Reads the current position for geofenced properties.
  ///
  /// Location is optional here on purpose. The API decides whether it is
  /// required (PLATINUM plan plus a property with coordinates) and answers with
  /// a precise message when it is missing, so an unavailable fix, a denied
  /// permission or a device with location switched off must not make the
  /// clock-in button unusable.
  Future<Position?> _tryGetCurrentLocation() => LocationUtils.currentPositionOrNull();

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
