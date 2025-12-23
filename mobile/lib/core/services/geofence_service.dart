import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import '../network/api_service.dart';

/// Service for managing geofence-based auto clock-out
class GeofenceService {
  static GeofenceService? _instance;
  static GeofenceService get instance => _instance ??= GeofenceService._();

  GeofenceService._();

  bool _isInitialized = false;
  String? _currentWorkerId;
  String? _currentGeofenceId;

  /// Initialize the background geolocation plugin
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Listen to geofence events
    bg.BackgroundGeolocation.onGeofence(_onGeofence);

    // Configure the plugin
    await bg.BackgroundGeolocation.ready(bg.Config(
      debug: false,
      logLevel: bg.Config.LOG_LEVEL_WARNING,
      desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
      distanceFilter: 10.0,
      stopOnTerminate: false,
      startOnBoot: true,
      enableHeadless: true,
      notification: bg.Notification(
        title: 'PayKey Time Tracking',
        text: 'Monitoring work location',
        channelName: 'PayKey Location',
      ),
    ));

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

    // Remove any existing geofence first
    await bg.BackgroundGeolocation.removeGeofences();

    // Add new geofence for the property
    await bg.BackgroundGeolocation.addGeofence(bg.Geofence(
      identifier: propertyId,
      radius: radiusMeters,
      latitude: latitude,
      longitude: longitude,
      notifyOnEntry: true,
      notifyOnExit: true,
      notifyOnDwell: false,
      extras: {
        'propertyName': propertyName,
        'workerId': workerId,
      },
    ));

    // Start tracking
    await bg.BackgroundGeolocation.start();
  }

  /// Stop monitoring when worker clocks out
  Future<void> stopMonitoring() async {
    _currentWorkerId = null;
    _currentGeofenceId = null;

    await bg.BackgroundGeolocation.removeGeofences();
    await bg.BackgroundGeolocation.stop();
  }

  /// Handle geofence events
  void _onGeofence(bg.GeofenceEvent event) async {
    if (event.action == 'EXIT' && _currentWorkerId != null) {
      // Worker left the geofence - trigger auto clock-out
      try {
        final location = event.location;
        await ApiService().timeTracking.autoClockOut(
          _currentWorkerId!,
          lat: location.coords.latitude,
          lng: location.coords.longitude,
        );

        // Clear state
        _currentWorkerId = null;
        _currentGeofenceId = null;
      } catch (e) {
        // Log error but don't crash
        print('Auto clock-out failed: $e');
      }
    }
  }

  /// Check if currently monitoring
  bool get isMonitoring => _currentWorkerId != null;

  /// Get current geofence ID being monitored
  String? get currentGeofenceId => _currentGeofenceId;
}
