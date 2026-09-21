import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Raised when the device cannot produce a position, with a message that can be
/// shown to the user.
class LocationException implements Exception {
  final String message;

  const LocationException(this.message);

  @override
  String toString() => message;
}

/// Device location helpers.
class LocationUtils {
  const LocationUtils._();

  /// The current position, throwing a readable [LocationException] when no fix
  /// can be taken.
  ///
  /// Used where the location *is* the point — pinning a worksite for its
  /// geofence — so the user is told what to fix rather than silently getting
  /// nothing. Highest accuracy is requested because a geofence is only as good
  /// as the pin it is measured from.
  static Future<Position> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(
        'Turn on location services to capture this position.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException(
        'Location permission is needed to capture this position.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Location permission is permanently denied. Enable it in Settings.',
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } catch (e) {
      debugPrint('Location fix failed: $e');
      throw const LocationException(
        'Could not get a GPS fix. Move outdoors or near a window and try again.',
      );
    }
  }

  /// The current position, or null when it cannot be read.
  ///
  /// This never throws: the time-tracking API decides whether coordinates are
  /// required (PLATINUM plan plus a property with a geofence) and answers with a
  /// precise message when they are missing, so a denied permission, a device
  /// with location switched off or a slow fix must not make clock-in unusable.
  static Future<Position?> currentPositionOrNull() async {
    try {
      return await currentPosition();
    } on LocationException catch (e) {
      debugPrint('Location unavailable: $e');
      return null;
    }
  }
}
