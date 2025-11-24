import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/time_tracking_model.dart';
import '../../data/repositories/time_tracking_repository.dart';

final timeTrackingProvider =
    StateNotifierProvider<TimeTrackingNotifier, AsyncValue<TimeEntry?>>((ref) {
  return TimeTrackingNotifier(ref.read(timeTrackingRepositoryProvider));
});

final timeEntriesProvider =
    StateNotifierProvider<TimeEntriesNotifier, AsyncValue<List<TimeEntry>>>((ref) {
  return TimeEntriesNotifier(ref.read(timeTrackingRepositoryProvider));
});

class TimeTrackingNotifier extends StateNotifier<AsyncValue<TimeEntry?>> {
  final TimeTrackingRepository _repository;

  TimeTrackingNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> getActiveEntry(String workerId) async {
    state = const AsyncValue.loading();
    try {
      final entry = await _repository.getActiveEntry(workerId);
      state = AsyncValue.data(entry);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> clockIn(String workerId, {String? notes}) async {
    state = const AsyncValue.loading();
    try {
      // Get current location
      final position = await _getCurrentLocation();
      
      final request = ClockInRequest(
        workerId: workerId,
        latitude: position.latitude,
        longitude: position.longitude,
        notes: notes,
      );

      final entry = await _repository.clockIn(request);
      state = AsyncValue.data(entry);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> clockOut(String timeEntryId, {String? notes}) async {
    state = const AsyncValue.loading();
    try {
      // Get current location
      final position = await _getCurrentLocation();
      
      final request = ClockOutRequest(
        timeEntryId: timeEntryId,
        latitude: position.latitude,
        longitude: position.longitude,
        notes: notes,
      );

      final entry = await _repository.clockOut(request);
      state = AsyncValue.data(entry);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Position> _getCurrentLocation() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable them.');
    }

    // Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permissions are permanently denied. Please enable them in settings.',
      );
    }

    // Get current position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

class TimeEntriesNotifier extends StateNotifier<AsyncValue<List<TimeEntry>>> {
  final TimeTrackingRepository _repository;

  TimeEntriesNotifier(this._repository) : super(const AsyncValue.data([]));

  Future<void> fetchTimeEntries({
    String? workerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = const AsyncValue.loading();
    try {
      final entries = await _repository.getTimeEntries(
        workerId: workerId,
        startDate: startDate,
        endDate: endDate,
      );
      state = AsyncValue.data(entries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
