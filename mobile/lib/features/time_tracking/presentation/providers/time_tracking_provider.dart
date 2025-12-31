import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/time_tracking_model.dart';
import '../../data/repositories/time_tracking_repository.dart';
import '../../data/mock/time_tracking_mock_data.dart';

final timeTrackingProvider =
    AsyncNotifierProvider<TimeTrackingNotifier, TimeEntry?>(TimeTrackingNotifier.new);

// Provider for all time entries (Dashboard Overview)
final allTimeEntriesProvider =
    AsyncNotifierProvider<TimeEntriesNotifier, List<TimeEntry>>(TimeEntriesNotifier.new);

// Provider for specific worker entries (Drill Down)
final workerTimeEntriesProvider =
    AsyncNotifierProvider<TimeEntriesNotifier, List<TimeEntry>>(TimeEntriesNotifier.new);

// Legacy provider (keep for backward compatibility if needed, or deprecate)
final timeEntriesProvider =
    AsyncNotifierProvider<TimeEntriesNotifier, List<TimeEntry>>(TimeEntriesNotifier.new);

class TimeTrackingNotifier extends AsyncNotifier<TimeEntry?> {
  late TimeTrackingRepository _repository;

  @override
  FutureOr<TimeEntry?> build() {
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

  Future<void> clockIn(String workerId, {String? notes}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final position = await _getCurrentLocation();
      final request = ClockInRequest(
        workerId: workerId,
        latitude: position.latitude,
        longitude: position.longitude,
        notes: notes,
      );
      return _repository.clockIn(request);
    });
  }

  Future<void> clockOut(String timeEntryId, {String? notes}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final position = await _getCurrentLocation();
      final request = ClockOutRequest(
        timeEntryId: timeEntryId,
        latitude: position.latitude,
        longitude: position.longitude,
        notes: notes,
      );
      return _repository.clockOut(request);
    });
  }

  Future<Position> _getCurrentLocation() async {
    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException('Location services are disabled. Please enable them.');
    }

    // Check location permissions
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'Location permissions are permanently denied. Please enable them in settings.',
      );
    }

    // Get current position
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

class TimeEntriesNotifier extends AsyncNotifier<List<TimeEntry>> {
  late TimeTrackingRepository _repository;

  @override
  FutureOr<List<TimeEntry>> build() {
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
        if (e.isNetworkError) return [];
        // Check if feature is gated (403) - return mock data instead of showing error
        if (e.statusCode == 403) {
          print('[TimeTrackingProvider] Feature gated, returning mock time entries');
          if (workerId != null) {
            return TimeTrackingMockData.getEntriesForWorker(workerId);
          }
          return TimeTrackingMockData.timeEntries;
        }
        rethrow;
      }
    });
  }

  void reset() {
    state = const AsyncValue.data([]);
  }
}

/// Custom exception for location-related errors
class LocationException implements Exception {
  final String message;

  LocationException(this.message);

  @override
  String toString() => message;
}