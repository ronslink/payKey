import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Best-effort device location for APIs that geofence by coordinates.
class LocationUtils {
  const LocationUtils._();

  /// The current position, or null when it cannot be read.
  ///
  /// This never throws: the time-tracking API decides whether coordinates are
  /// required (PLATINUM plan plus a property with a geofence) and answers with a
  /// precise message when they are missing, so a denied permission, a device
  /// with location switched off or a slow fix must not make clock-in unusable.
  static Future<Position?> currentPositionOrNull() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      debugPrint('Location unavailable: $e');
      return null;
    }
  }
}
