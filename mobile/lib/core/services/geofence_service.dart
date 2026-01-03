import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../network/api_service.dart';

/// Service for managing geofence-based auto clock-out
///
/// Refactored to use [Geolocator] instead of `flutter_background_geolocation`.
/// Native geofencing is replaced by periodic location matching.
class GeofenceService {
  static GeofenceService? _instance;
  static GeofenceService get instance => _instance ??= GeofenceService._();

  GeofenceService._();

  bool _isInitialized = false;
  String? _currentWorkerId;
  String? _currentGeofenceId;
  
  // Geofence parameters
  double? _targetLat;
  double? _targetLng;
  double? _radiusMeters;
  StreamSubscription<Position>? _positionStreamSubscription;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Request permission if needed
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied.');
      return;
    }

    _isInitialized = true;
  }

  /// Start monitoring a property geofence when worker clocks in
  Future<void> startMonitoring({
    required String workerId,
    required String propertyId,
    required String propertyName,
    required double latitude,
    required double longitude,
    required double radiusMeters,
  }) async {
    await initialize();

    _currentWorkerId = workerId;
    _currentGeofenceId = propertyId;
    _targetLat = latitude;
    _targetLng = longitude;
    _radiusMeters = radiusMeters;

    // Stop existing stream if any
    await _positionStreamSubscription?.cancel();

    // Start listening to location updates
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _checkLocation(position);
    }, onError: (e) {
      debugPrint('Location stream error: $e');
    });
  }

  /// Check if current position is outside the geofence
  void _checkLocation(Position position) {
    if (_targetLat == null || _targetLng == null || _radiusMeters == null) return;
    if (_currentWorkerId == null) return;

    final double distanceInMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      _targetLat!,
      _targetLng!,
    );

    // If worker is OUTSIDE the radius
    if (distanceInMeters > _radiusMeters!) {
      _triggerExit(position);
    }
  }

  Future<void> _triggerExit(Position position) async {
    if (_currentWorkerId == null) return;

    // Worker left the geofence - trigger auto clock-out
    try {
      await ApiService().timeTracking.autoClockOut(
        _currentWorkerId!,
        lat: position.latitude,
        lng: position.longitude,
      );

      // Stop monitoring after clock-out
      await stopMonitoring();

    } catch (e) {
      debugPrint('Auto clock-out failed: $e');
    }
  }

  /// Stop monitoring when worker clocks out
  Future<void> stopMonitoring() async {
    _currentWorkerId = null;
    _currentGeofenceId = null;
    _targetLat = null;
    _targetLng = null;
    _radiusMeters = null;

    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  /// Check if currently monitoring
  bool get isMonitoring => _currentWorkerId != null;

  /// Get current geofence ID being monitored
  String? get currentGeofenceId => _currentGeofenceId;
}
